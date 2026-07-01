# Loop state · lint-fix
## Last run
2026-06-26 — PASS
- 改了 src/calc.py：divide 除零返回 None；修正 add 格式（加空格）
- pytest 2/2 通过，ruff check 零报错，ruff format --check 干净
## In progress
(无)
## Lessons learned
- divide 契约：b==0 返回 None 而非抛异常
