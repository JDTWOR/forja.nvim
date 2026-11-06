package exercise

func AddFee(subtotal, fee int) int {
	total := subtotal
	total += fee
	return total
}

func RetryLimit(configured int) int {
	limit := configured
	if limit <= 0 {
		limit = 3
	}
	return limit
}

func CanProcess(enabled bool, retries int) bool {
	return enabled && retries > 0
}
