def discount_cents(subtotal_cents: int, percent: int) -> int:
    return subtotal_cents * percent // 100


def tax_cents(taxable_cents: int, tax_percent: int) -> int:
    return taxable_cents * tax_percent // 100


def checkout_total(subtotal_cents: int, discount_percent: int, tax_percent: int) -> int:
    taxable = subtotal_cents - discount_cents(subtotal_cents, discount_percent)
    return taxable + tax_cents(taxable, tax_percent)
