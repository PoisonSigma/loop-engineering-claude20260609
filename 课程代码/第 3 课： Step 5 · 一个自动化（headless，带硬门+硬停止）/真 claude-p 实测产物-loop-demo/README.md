# 真 `claude -p` 实测产物（loop-demo）

这是用**真实 `claude -p`**（claude 2.1.193，非 stub）跑完 `loop.sh` 后的仓库快照，
完整保留了 git 历史,供你对照「AI 到底改了什么、有没有作弊」。

## 仓库里的状态

- `git log` 里有一个 **`failing baseline`** 提交 = AI 动手前的「会失败」原始版本。
- **工作区的改动 = 真 AI 第 1 轮的修复**（尚未 commit，方便你直接 `git diff` 看）。

## 自己复看 AI 改了什么

```bash
cd "真 claude-p 实测产物-loop-demo"

git diff --stat
#  STATE.md    | 7 +++++--
#  src/calc.py | 8 ++++++--      ← 只动了 src/ 和状态文件

git diff test_calc.py
# 空 → ✅ 没碰测试，没作弊

git diff src/calc.py
# 看 AI 怎么把 divide 改成 b==0 返回 None、并补了格式空格
```

## 想恢复成「失败原始版」重新自己跑？

```bash
git stash            # 收起 AI 的改动，回到 failing baseline
pytest -q            # 会重新看到 test_divide_zero 失败
./loop.sh            # 装好 claude CLI 后，真 claude -p 再跑一遍（会消耗 token）
git stash pop        # 想要回 AI 那版改动的话
```

## 说明

- 这是**已修复、门全绿**的状态：`pytest` 2/2 通过、`ruff check` 干净、`ruff format --check` 干净。
- 完整的实测过程与三条契约验证，见上层目录的 `运行结果.md` 第 3 节。
- `loop.sh` 用的门是修正后的 `pytest -q && ruff check src/ && ruff format --check src/`（见课程 README 勘误）。
