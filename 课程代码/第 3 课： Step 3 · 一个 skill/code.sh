#!/bin/bash
# 第 3 课 · Step 3 · 一个 skill
# 在 loop-demo/ 目录里运行： bash code.sh
# skill = 把项目上下文写进文件，否则 Agent 每轮从零重推。
set -e

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
