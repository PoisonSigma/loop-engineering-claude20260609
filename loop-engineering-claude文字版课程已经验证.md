# 循环工程落地课（Claude Code 版）

> 5 节课。从「该不该建」到「跑通一个真循环」。所有命令已对齐 Claude Code 2026-06 真实能力。

---

## 第 0 课 · 先判定：你现在该建吗（5 分钟）

**4 条件，缺一不建：**

| # | 条件 | 你的答案 |
|---|---|---|
| 1 | 任务 ≥ 每周一次 | □ |
| 2 | 有自动验证:ruff风格 + 低级错 ,pytest行为对不对 | □ |
| 3 | token 预算扛得住重读+重试 （国产token包月包年套餐接入claude） | □ |
| 4 | Agent 能跑代码看结果（日志+可复现环境） | □ |

**再加 30 秒战术检查（具体任务级）：**

- □ 有硬停止（`--max-turns` / 时间 / `for` 轮次上限）下面有详细文字介绍
  - 注：Claude Code **没有** `--max-budget-usd` 这种预算上限 flag；要控成本用 `--max-turns` + 外层轮次/时间限制

- gate门： 循环判工作成功/失败的那个客观信号。

- 不可逆操作必须有人工门：在自动循环里插一个「必须人点头才能继续」的卡口。

  - **不可逆操作**指做了就难撤回、出错代价大的动作：
  - **合并**（merge 进 main，污染主干）
  - **部署**（推上生产，影响真实用户）
  - **依赖变更**（升级/降级一个包，可能连环破坏）

  

  

**后台程序员最常卡第 2 条**：缺集成/端到端测试 → 门是软的 → 别建，先补测试。

**起步选这两个**：CI 失败分诊（每夜）、依赖升级 PR（每周）。
**禁止入循环**：架构、认证、支付、模糊产品决策。

---

## 第 1 课 · 五构件 → Claude Code 真实映射

| 构件 | Claude Code 实现（已核实） |
|---|---|
| Automations 心跳 | `/loop 30m <prompt>`（会话级，**7 天**自动过期，可用 `--resume`/`--continue` 恢复未过期任务）；`/schedule`（= claude.ai 的 **Routines**）；`crontab + claude -p`（重启存活，自己机器） |
| 跑到条件成立 | 在 prompt 里写明客观停止条件；headless 用 `--max-turns` 兜底 |
| Worktrees | `git worktree` + `--worktree` 标志 + 子 Agent `isolation: worktree` |
| Skills | `.claude/skills/<name>/SKILL.md` |
| Connectors（MCP） | 你已连 **GitHub / Gmail**；可加 Linear/Slack/Sentry 等（官方目录还支持 Notion/Asana/Figma/Google Calendar/Microsoft 365 等十多种，列表不止这几个） |
| Sub-agents | `.claude/agents/*` + **SubagentStop hook** 当硬验证门 |

**maker≠checker**：写代码和判对错必须不同 Agent。Claude Code 里用独立 verifier 子 Agent + SubagentStop hook，比「再找个 Agent 评审」硬。

---

## 第 2 课 · 最小可用循环 = 四件套

```
一个自动化  +  一个 skill  +  一个状态文件  +  一个门
```

- **自动化**：`/loop` 或 crontab+`claude -p`
- **skill**：`SKILL.md` 存项目上下文（否则每轮从零重推）
- **状态文件**：`STATE.md` 记 done/next/lessons（Agent 会忘，文件不会）
- **门**：`pytest && ruff check . && ruff format --check .` 的退出码（客观，非主观评审）
  - 行为门用 `pytest`；lint 门用 `ruff check`；**格式门必须用 `ruff format --check`**（`ruff check` 抓不到空格/缩进这类纯格式问题）

**顺序铁律**：手动跑通 → 封 skill → 包 `/loop` → 上 Routine。跳步必翻车。
**验收指标**：每个被接受变更的成本；接受率 < 50% 就停掉重设计。

---

## 第 3 课 · 手把手小例子：lint-and-fix 循环

目标：建一个本地循环，自动跑测试+lint、把坏代码修到门通过、写状态文件。全程可复制。

需要：机器上得有 `python` + `pip` + `git` + 装好 `claude` CLI。后台程序员这些通常都有。

### Step 1 · 造个会失败的玩具仓库

```bash
mkdir loop-demo && cd loop-demo && git init
mkdir -p src .claude/skills/lint-fix

cat > src/calc.py <<'EOF'
def add(a,b):
    return a+b
def divide(a, b):
    return a / b
EOF

cat > test_calc.py <<'EOF'
from src.calc import add, divide
def test_add():
    assert add(2, 3) == 5
def test_divide_zero():
    # 期望除零返回 None，当前实现会抛异常 → 故意失败
    assert divide(1, 0) is None
EOF

pip install pytest ruff -q
# 若报 TLS CA 证书错误，检查 ~/.pip/pip.conf 里的 cert= 是否指向了不存在的路径，删掉即可。
```

### Step 2 · 一个门（先手动确认它真能判失败）

```bash
pytest -q ; ruff check src/ ; ruff format --check src/
# 预期：pytest 1 failed（divide 抛 ZeroDivisionError）+ ruff format「Would reformat」→ 门有效
# 注意：ruff check src/ 在默认配置下对这种空格格式问题会输出 All checks passed！
#       格式问题归 ruff format 管（E225/E231 在新版 ruff 是 preview 规则，默认不生效），
#       所以「格式门」必须用 ruff format --check，不能只用 ruff check。
```

### Step 3 · 一个 skill

```bash
cat > .claude/skills/lint-fix/SKILL.md <<'EOF'
---
name: lint-fix
description: 修到 pytest 通过且 ruff 干净。只改 src/，禁碰测试文件。
---

# Lint-Fix Skill

## Goal
让 `pytest -q` 全绿且 `ruff check src/` 零报错、`ruff format --check src/` 干净。

## Fix patterns
- 除零等运行时错误：按测试期望的契约改实现，不改测试。
- 格式问题：直接 `ruff format src/`（ruff check 抓不到纯格式问题）。

## Never do
- 不修改 test_*.py（改测试=作弊）
- 不删/跳过失败测试
- 只动 src/ 目录

## State
每轮结束更新 STATE.md：改了哪些文件、门是否通过、遗留问题。
EOF
```

### Step 4 · 一个状态文件

```bash
cat > STATE.md <<'EOF'
# Loop state · lint-fix
## Last run
(empty)
## In progress
- src/calc.py divide 除零未处理
## Lessons learned
EOF
```

### Step 5 · 一个自动化（headless，带硬门+硬停止）

```bash
cat > loop.sh <<'EOF'
#!/bin/bash
set -e
for i in 1 2 3; do            # 硬停止：最多 3 轮
  echo "=== round $i ==="
  claude -p "读 .claude/skills/lint-fix/SKILL.md 和 STATE.md。\
修 src/ 让 pytest 通过且 ruff check src/、ruff format --check src/ 都干净。只改 src/，禁碰 test_*.py。\
改完更新 STATE.md。" \
    --allowedTools "Read,Edit,Bash(pytest*),Bash(ruff*)" \
    --max-turns 15 \
    --permission-mode acceptEdits

  if pytest -q && ruff check src/ && ruff format --check src/ ; then   # 客观门（行为+lint+格式）
    echo "✅ 门通过，停止"; exit 0
  fi
done
echo "❌ 3 轮未通过，升级给人"; exit 1
EOF
chmod +x loop.sh
./loop.sh
```

跑完：门绿则退出 0，`git diff` 看它只改了 `src/calc.py`，`STATE.md` 有记录。这就是一个完整的四件套循环。

### Step 6 · 上调度（二选一）

```bash
# A. 会话内（最快，7天过期）：在 claude 交互里
/loop 30m 跑 ./loop.sh，门绿则什么都不做

# B. 重启存活（你自己机器）：crontab -e
0 3 * * * cd ~/loop-demo && ./loop.sh >> ~/loop.log 2>&1

# C. 云端关机也跑（Max+）：/schedule 或 claude.ai 的 Routines
```

> 升级到真项目时，把 `src/calc.py` 换成 `src/auth`，修复 PR 推 `claude/` 前缀分支（保护 main），GitHub 事件触发用 `anthropics/claude-code-action@v1`。

---

## 第 4 课 · 避坑 + 安全税

**三大失败模式：**
1. **安静失败**：没真门/软完成/没硬停 → 例子里用「退出码门 + `for 1 2 3` + `--max-turns`」三道闸挡住。

   ```
    三道闸：
   病因例子里的闸怎么堵的没真门pytest -q && ruff check src/ && ruff format --check src/ 的退出码通过=退出码 0，失败=非 0。客观信号，不是让 Agent「看看对不对」软完成（Agent 自己说"够了"）for 1 2 3 + 上面那个退出码判断「完成」只由门的退出码定义；Agent 嘴上说做完没用，门不绿就继续下一轮没硬停（一直跑到烧钱）for i in 1 2 3（最多 3 轮）+ --max-turns 15（单轮最多 15 步）两层上限：循环最多 3 轮，每轮 Agent 最多动 15 步，到顶强制停
   ```

   

2. 代码跑的比人理解速度还快：读 diff、抽查门、禁碰架构、结对设计。

   ```
   循环越快交付你没写的代码，「仓库里有什么」和「你脑子里懂什么」的差距越大。这笔债平时不疼，到你必须 debug 一个全队没人读过的系统那天，集中爆发——比烧的 token 贵得多。
   四个缓解措施都是「逼你保持理解」，不是技术手段：
   读 diff
   
   循环开的每个 PR，合并前自己看一遍改了什么。不读=以复利借理解债，欠的越来越多。
   抽查门
   
   挑几个循环开的 PR，验证「批准它的那个测试」是不是真能抓住你在意的 bug。门会腐烂——可能测试一直绿，但其实根本没覆盖关键路径，循环只是在通过一个假门。
   禁碰架构
   
   让循环只做小的、机器可校验的改动（lint、依赖、简单修复）。一旦让它碰架构这种判断题，它一次改一大片你看不懂的结构，理解债瞬间飙升。
   结对设计
   
   和队友一起设计循环。一个人设计会有盲点，而循环会把这个盲点永远利用下去（它每天重复同样的错）；两双眼睛在设计阶段就堵住。
   ```

   

3. **需要付出的代价**：循环无人值守地跑 = 一个无人值守的攻击面在跑。没人盯着的时候，出事没人拦。这五条是你必须「交的税」——五个具体防线，对应五种威胁。

   **`--allowedTools` 最小授权（例子只给 pytest/ruff）**
    只给循环完成任务**必需**的工具，别多给。例子里 Agent 只能跑 `pytest`/`ruff`、读写文件，不能执行任意 shell、不能联网。威胁：权限给宽了，prompt 注入或跑飞的 Agent 能用多余权限干坏事（删库、外发数据）。

   **GitHub 写权限锁 `claude/`**
    循环只能往 `claude/` 前缀的分支推，碰不到 main。威胁：循环开 PR 比人读得快，没锁就可能把未审代码直接合进主干。锁前缀 = 天然的人工门，坏东西最多停在临时分支。

   **MCP/skill 装前审源**
    装第三方 skill / 连接器前，先读它的源码和描述。威胁：skill 描述里能藏 prompt 注入，循环自动装就自动中招。文章数据：审计的 17,022 个 skill 里 **520 个泄露凭证**。

   **生产关 verbose 日志**
    长跑循环的调试日志会把密钥、token 撒进你不监控的日志文件。威胁：日志变成泄密渠道。生产环境关掉 verbose，确实要记的也做脱敏。

   **每 30 天重审权限**
    权限会**蔓延**：今天为了方便加「就一个」写权限，之后没人再回头看，越积越多。定期重审，把临时加的、不再需要的收回去。

   一句话：循环帮你省了人力，但省下的人力得拿一部分回来交「安全税」——五条都是「没人盯着时，怎么防它被利用或自己闯祸」。

---

## 

