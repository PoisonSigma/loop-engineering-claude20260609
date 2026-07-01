#!/bin/bash
# 「不需要 claude CLI / 不烧 token」也能把 Step 5 的循环控制流跑给你看。
# 做法：用一个 stub 假冒 claude -p 的「修 src/」动作，其余（for 1 2 3、硬门、退出码）
# 全部是真实的 loop.sh 逻辑。证明：自动化的骨架本身是跑得通的。
#
# 在 loop-demo/ 目录里运行： bash loop_demo_stub.sh
set -e

# 1) 把仓库还原成「会失败」的基线（以防之前已被修过）
cat > src/calc.py <<'PY'
def add(a,b):
    return a+b
def divide(a, b):
    return a / b
PY
rm -rf src/__pycache__

# 2) 造一个 stub「claude」：模拟 lint-fix Agent 的修复（只动 src/ + 更新 STATE.md）
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

# 3) 真实跑 loop.sh 的控制流（把 stub 放进 PATH 顶端）
PATH="$PWD/.stubbin:$PATH" ./loop.sh
echo "[loop final exit: $?]"
