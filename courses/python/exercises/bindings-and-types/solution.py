def calculate_subtotal(quantity: int, unit_price_cents: int) -> int:
    return quantity * unit_price_cents


def format_item_line(name: str, quantity: int, unit_price_cents: int) -> str:
    subtotal = calculate_subtotal(quantity, unit_price_cents)
    return f"{name} x{quantity}: {subtotal} cents"
