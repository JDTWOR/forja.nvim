package exercise

import "testing"

func TestForjaAssessmentRetryPolicyEdges(t *testing.T) {
	cases := map[int]string{100: "informational", 199: "informational", 299: "success", 300: "redirect", 398: "redirect", 400: "reject", 428: "reject", 429: "backoff", 430: "reject", 499: "reject", 500: "retry", 598: "retry", 599: "retry", 0: "invalid", 1000: "invalid"}
	for code, want := range cases {
		if got := RetryPolicy(code); got != want {
			t.Errorf("RetryPolicy(%d) = %q, want %q", code, got, want)
		}
	}
}
