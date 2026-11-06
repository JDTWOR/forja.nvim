package exercise

func RetryPolicy(statusCode int) string {
	switch {
	case statusCode < 100 || statusCode > 599:
		return "invalid"
	case statusCode >= 100 && statusCode <= 199:
		return "informational"
	case statusCode >= 200 && statusCode <= 299:
		return "success"
	case statusCode == 429:
		return "backoff"
	case statusCode >= 400 && statusCode <= 499:
		return "reject"
	case statusCode >= 500 && statusCode <= 599:
		return "retry"
	case statusCode >= 300 && statusCode <= 399:
		return "redirect"
	default:
		return "invalid"
	}
}
