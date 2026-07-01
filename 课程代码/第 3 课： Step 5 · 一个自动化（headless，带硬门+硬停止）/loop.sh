#!/bin/bash
# 第 3 课 · Step 5 · 一个自动化（headless，带硬门+硬停止）
# 在 loop-demo/ 目录里运行： ./loop.sh
# 需要本机已装好 claude CLI，并接入可用的 token（会真实消耗）。
#
# 注意：门已修正为 pytest + ruff check + ruff format --check（见 README 勘误）。
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
