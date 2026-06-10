"""Rigged to fail TYPECHECK under mypy --strict.

`safe_divide` is annotated to return `int`, but the zero-divisor branch returns
a string instead. mypy catches the return-type mismatch.
"""

from __future__ import annotations


def safe_divide(numerator: int, denominator: int) -> int:
    if denominator == 0:
        return "undefined"  # type mismatch: str returned where int declared
    return numerator // denominator


def main() -> None:
    result = safe_divide(10, 0)
    print(f"result = {result}")


if __name__ == "__main__":
    main()
