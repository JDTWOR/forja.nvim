package exercise

func RetryLimit(configured int) int {
	limit := configured
	if limit <= 0 {
		limit = 3
	}
	return limit
}
