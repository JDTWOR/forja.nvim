package exercise

import "testing"

func TestPublicAddFee(t *testing.T) {
	if got := AddFee(1000, 250); got != 1250 {
		t.Fatalf("AddFee(1000, 250) = %d, want 1250", got)
	}
}

func TestPublicRetryLimit(t *testing.T) {
	if got := RetryLimit(5); got != 5 {
		t.Fatalf("RetryLimit(5) = %d, want 5", got)
	}
	if got := RetryLimit(0); got != 3 {
		t.Fatalf("RetryLimit(0) = %d, want default 3", got)
	}
}
