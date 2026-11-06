import re
from decimal import Decimal


def parse_quantity(text: str) -> int:
    # TODO: accept a positive base-10 integer and reject invalid values.
    pass


def parse_price_cents(text: str) -> int:
    # TODO: parse a non-negative decimal price with at most two places.
    pass


def parse_item(line: str) -> tuple[str, int]:
    # TODO: parse "name,quantity" and reuse parse_quantity.
    pass
