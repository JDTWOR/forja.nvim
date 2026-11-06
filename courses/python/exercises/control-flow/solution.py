def shipping_band(weight_grams: int) -> str:
    if weight_grams < 0:
        return "invalid"
    if weight_grams <= 500:
        return "small"
    if weight_grams <= 2000:
        return "medium"
    return "large"


def shipping_cost(weight_grams: int, express: bool) -> int:
    band = shipping_band(weight_grams)
    prices = {"small": 500, "medium": 1000, "large": 2500}
    if band == "invalid":
        return 0
    cost = prices[band]
    if express:
        cost += 750
    return cost
