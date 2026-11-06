package exercise

import "testing"

func TestForjaAssessmentRetryDefaults(t *testing.T) {
	for _, configured := range []int{0, -1, -100} {
		if got := RetryLimit(configured); got != 3 {
			t.Errorf("RetryLimit(%d) = %d, want 3", configured, got)
		}
	}
	for _, configured := range []int{1, 5} {
		if got := RetryLimit(configured); got != configured {
			t.Errorf("RetryLimit(%d) = %d, want unchanged value", configured, got)
		}
	}
}
