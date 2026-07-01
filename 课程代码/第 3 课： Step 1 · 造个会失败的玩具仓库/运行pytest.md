cd 进入：loop-demo

```
pytest
```

会报错如下：

```
pytest
============================= test session starts ==============================
platform darwin -- Python 3.13.7, pytest-9.1.1, pluggy-1.6.0
rootdir: /Users/poison
configfile: pyproject.toml
plugins: langsmith-0.4.10, anyio-4.10.0
collected 2 items

test_calc.py .F                                                          [100%]

=================================== FAILURES ===================================
_______________________________ test_divide_zero _______________________________

    def test_divide_zero():
        # 期望除零返回 None，当前实现会抛异常 → 故意失败
>       assert divide(1, 0) is None
               ^^^^^^^^^^^^

test_calc.py:6:
_ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _

a = 1, b = 0

    def divide(a, b):
>       return a / b
               ^^^^^
E       ZeroDivisionError: division by zero

src/calc.py:4: ZeroDivisionError
=========================== short test summary info ============================
FAILED test_calc.py::test_divide_zero - ZeroDivisionError: division by zero
========================= 1 failed, 1 passed in 0.04s ==========================
poison@poisondeMac-mini loop-demo %
```

