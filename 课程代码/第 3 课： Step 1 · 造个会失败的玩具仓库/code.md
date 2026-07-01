#!/bin/bash
# 第 3 课 · Step 1 · 造个会失败的玩具仓库
# 目标：搭一个「故意会失败」的小仓库，给循环一个真能判失败的靶子。
# 直接运行： bash code.sh   （会在当前目录下创建 loop-demo/）
set -e

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
# 本机若报 TLS CA 证书错误，改用： pip install --cert /etc/ssl/cert.pem pytest ruff -q
