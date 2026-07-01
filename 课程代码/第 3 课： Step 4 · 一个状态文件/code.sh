#!/bin/bash
# 第 3 课 · Step 4 · 一个状态文件
# 在 loop-demo/ 目录里运行： bash code.sh
# 状态文件 = Agent 会忘，文件不会。记 done / next / lessons。
set -e

cat > STATE.md <<'EOF'
# Loop state · lint-fix
## Last run
(empty)
## In progress
- src/calc.py divide 除零未处理
## Lessons learned
EOF
