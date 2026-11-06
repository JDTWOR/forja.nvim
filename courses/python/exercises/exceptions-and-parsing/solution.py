import re
from decimal import Decimal, DecimalException, localcontext


def parse_quantity(text: str) -> int:
    value = text.strip()
    if not re.fullmatch(r"[0-9]+", value):
        raise ValueError("quantity must be a positive integer")
    quantity = int(value)
    if quantity <= 0:
        raise ValueError("quantity must be positive")
    return quantity


def parse_price_cents(text: str) -> int:
    value = text.strip()
    if not re.fullmatch(r"[0-9]+(?:\.[0-9]{1,2})?", value):
        raise ValueError("price must have at most two decimal places")
    try:
        with localcontext() as context:
            context.prec = max(28, len(value) + 2)
            cents = Decimal(value) * 100
        if cents != cents.to_integral_value():
            raise ValueError("price must map to whole cents")
        return int(cents)
    except (DecimalException, OverflowError, ValueError) as error:
        raise ValueError("price must be a finite non-negative amount") from error


def parse_item(line: str) -> tuple[str, int]:
    name, separator, quantity_text = line.partition(",")
    name = name.strip()
    if not separator or not name:
        raise ValueError("item must contain a name and quantity")
    return name, parse_quantity(quantity_text)
