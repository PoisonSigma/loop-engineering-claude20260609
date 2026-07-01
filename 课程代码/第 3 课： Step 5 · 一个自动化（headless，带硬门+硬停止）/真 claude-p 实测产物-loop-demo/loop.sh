#!/bin/bash
set -e
for i in 1 2 3; do
  echo "=== round $i ==="
  claude -p "读 .claude/skills/lint-fix/SKILL.md 和 STATE.md。\
修 src/ 让 pytest 通过且 ruff check src/、ruff format --check src/ 都干净。只改 src/，禁碰 test_*.py。\
改完更新 STATE.md。" \
    --allowedTools "Read,Edit,Bash(pytest*),Bash(ruff*)" \
    --max-turns 15 \
    --permission-mode acceptEdits

  if pytest -q && ruff check src/ && ruff format --check src/ ; then
    echo "✅ 门通过，停止"; exit 0
  fi
done
echo "❌ 3 轮未通过，升级给人"; exit 1
