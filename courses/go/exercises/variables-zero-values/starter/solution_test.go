package exercise

import "testing"

func TestPublicRetryLimit(t *testing.T) {
	if got := RetryLimit(5); got != 5 {
		t.Fatalf("RetryLimit(5) = %d, want 5", got)
	}
	if got := RetryLimit(0); got != 3 {
		t.Fatalf("RetryLimit(0) = %d, want default 3", got)
	}
}
