def total_units(stock: dict[str, int]) -> int:
    return sum(stock.values())


def most_stocked_sku(stock: dict[str, int]) -> str | None:
    if not stock:
        return None
    return max(stock, key=lambda sku: (stock[sku], sku))


def merge_inventory(current: dict[str, int], received: dict[str, int]) -> dict[str, int]:
    merged = current.copy()
    for sku, quantity in received.items():
        merged[sku] = merged.get(sku, 0) + quantity
    return merged


def inventory_report(stock: dict[str, int]) -> list[tuple[str, int]]:
    return sorted(stock.items(), key=lambda item: (-item[1], item[0]))
