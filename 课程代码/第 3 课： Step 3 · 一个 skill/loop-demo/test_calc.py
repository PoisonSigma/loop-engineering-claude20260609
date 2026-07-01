from src.calc import add, divide
def test_add():
    assert add(2, 3) == 5
def test_divide_zero():
    # 期望除零返回 None，当前实现会抛异常 → 故意失败
    assert divide(1, 0) is None
