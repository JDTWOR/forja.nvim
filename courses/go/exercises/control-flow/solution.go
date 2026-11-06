package exercise

func ShippingCost(weightGrams int, express bool) int {
	if weightGrams < 0 {
		return -1
	}

	cost := 2500
	if weightGrams <= 1000 {
		cost = 500
	} else if weightGrams <= 5000 {
		cost = 1000
	}
	if express {
		cost += 250
	}
	return cost
}

func ScoreBand(score int) string {
	switch {
	case score >= 90:
		return "excellent"
	case score >= 60:
		return "passing"
	default:
		return "retry"
	}
}

func ScoreBandOrMissing(score int, hasScore bool) string {
	if !hasScore {
		return "missing"
	}
	return ScoreBand(score)
}
