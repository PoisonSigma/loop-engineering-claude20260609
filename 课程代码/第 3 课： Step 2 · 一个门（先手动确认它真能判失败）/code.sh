#!/bin/bash
# 第 3 课 · Step 2 · 一个门（先手动确认它真能判失败）
# 在 loop-demo/ 目录里运行： bash ../<本文件>  或 cd loop-demo 后逐条粘贴。

# —— 笔记原版（注意：新版 ruff 下 `ruff check src/` 抓不到格式，见下方勘误）——
pytest -q ; ruff check src/
# 预期：1 failed（divide 抛 ZeroDivisionError）→ pytest 门有效

# —— 修正版：格式问题要用 ruff format --check 才抓得到 ——
pytest -q ; ruff check src/ ; ruff format --check src/
# 预期：pytest 1 failed + ruff format「Would reformat」→ 行为门 + 格式门都有效
