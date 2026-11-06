package exercise

import "testing"

func TestForjaAssessmentAddFeeZeroAndNegative(t *testing.T) {
	if got := AddFee(0, 0); got != 0 {
		t.Fatalf("AddFee(0, 0) = %d, want 0", got)
	}
	if got := AddFee(-200, 50); got != -150 {
		t.Fatalf("AddFee(-200, 50) = %d, want -150", got)
	}
}

func TestForjaAssessmentRetryDefaults(t *testing.T) {
	for _, configured := range []int{0, -1, -100} {
		if got := RetryLimit(configured); got != 3 {
			t.Errorf("RetryLimit(%d) = %d, want 3", configured, got)
		}
	}
	if got := RetryLimit(1); got != 1 {
		t.Fatalf("RetryLimit(1) = %d, want 1", got)
	}
}

func TestForjaAssessmentCanProcess(t *testing.T) {
	cases := []struct {
		enabled bool
		retries int
		want    bool
	}{{true, 1, true}, {true, 0, false}, {false, 10, false}, {false, 0, false}, {true, -1, false}}
	for _, test := range cases {
		if got := CanProcess(test.enabled, test.retries); got != test.want {
			t.Errorf("CanProcess(%t, %d) = %t, want %t", test.enabled, test.retries, got, test.want)
		}
	}
}
