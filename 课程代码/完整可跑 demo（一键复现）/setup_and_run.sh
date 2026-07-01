#!/bin/bash
# 第 3 课 · 完整四件套循环 · 一键复现（不需要 claude CLI / 不烧 token）
# 用法： bash setup_and_run.sh
# 它会在当前目录建 loop-demo/，跑完 Step1~Step5，最后门变绿、exit 0。
set -e

ROOT="$(pwd)"
rm -rf loop-demo

echo "==================== Step 1 · 造个会失败的玩具仓库 ===================="
mkdir loop-demo && cd loop-demo && git init -q
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

# 装依赖（本机 pip.conf 的 cert 失效时自动回退到系统证书）
if ! pip install pytest ruff -q 2>/dev/null; then
  echo "[info] 默认 pip 装失败，回退 --cert /etc/ssl/cert.pem"
  pip install --cert /etc/ssl/cert.pem pytest ruff -q
fi

echo "==================== Step 2 · 门（手动确认能判失败）===================="
set +e
pytest -q; echo "[pytest exit=$?]"
ruff check src/; echo "[ruff check exit=$?]"
ruff format --check src/; echo "[ruff format exit=$?]"
set -e

echo "==================== Step 3 · skill ===================="
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
- 格式问题：直接 `ruff format src/` 或按 ruff 建议修。

## Never do
- 不修改 test_*.py（改测试=作弊）
- 不删/跳过失败测试
- 只动 src/ 目录

## State
每轮结束更新 STATE.md：改了哪些文件、门是否通过、遗留问题。
EOF
echo "[skill written]"

echo "==================== Step 4 · 状态文件 ===================="
cat > STATE.md <<'EOF'
# Loop state · lint-fix
## Last run
(empty)
## In progress
- src/calc.py divide 除零未处理
## Lessons learned
EOF
echo "[STATE.md written]"

# 提交一个「失败基线」，这样最后的 git diff 能干净证明「只改了 src/，没碰 test」
printf '__pycache__/\n*.pyc\n.stubbin/\n' > .gitignore
git add -A && git commit -qm "failing baseline (Step1~4)" && echo "[baseline committed]"

echo "==================== Step 5 · 自动化（loop.sh + stub claude）===================="
cat > loop.sh <<'EOF'
#!/bin/bash
set -e
for i in 1 2 3; do            # 硬停止：最多 3 轮
  echo "=== round $i ==="
  claude -p "读 .claude/skills/lint-fix/SKILL.md 和 STATE.md。\
修 src/ 让 pytest 通过且 ruff check src/ 干净。只改 src/，禁碰 test_*.py。\
改完更新 STATE.md。" \
    --allowedTools "Read,Edit,Bash(pytest*),Bash(ruff*)" \
    --max-turns 15 \
    --permission-mode acceptEdits

  if pytest -q && ruff check src/ && ruff format --check src/ ; then   # 客观门
    echo "✅ 门通过，停止"; exit 0
  fi
done
echo "❌ 3 轮未通过，升级给人"; exit 1
EOF
chmod +x loop.sh
bash -n loop.sh && echo "[loop.sh 语法 OK]"

# stub claude：模拟 lint-fix Agent，只改 src/ + 更新 STATE.md
mkdir -p .stubbin
cat > .stubbin/claude <<'STUB'
#!/bin/bash
echo "[stub claude] 模拟 lint-fix Agent：只改 src/ ..."
cat > src/calc.py <<'PY'
def add(a, b):
    return a + b


def divide(a, b):
    if b == 0:
        return None
    return a / b
PY
ruff format src/ >/dev/null 2>&1
printf '# Loop state · lint-fix\n## Last run\n- 改 src/calc.py：divide 除零返回 None；格式化 add\n- 门：全绿 ✅\n## In progress\n(none)\n## Lessons learned\n- 除零按测试契约返回 None，不改测试\n' > STATE.md
STUB
chmod +x .stubbin/claude

echo "---------- 运行 loop.sh（stub claude，真实控制流）----------"
set +e
PATH="$PWD/.stubbin:$PATH" ./loop.sh
RC=$?
set -e
echo "[loop final exit=$RC]"

echo "==================== 收尾验证 ===================="
echo "----- git diff --stat（相对失败基线；test_calc.py 应未出现）-----"
git diff --stat
echo "----- 最终门（应全绿）-----"
pytest -q && ruff check src/ && ruff format --check src/ && echo "✅ 全绿，四件套循环跑通"

cd "$ROOT"
