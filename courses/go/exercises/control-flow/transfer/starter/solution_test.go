package exercise

import "testing"

func TestRetryPolicy(t *testing.T) {
	tests := []struct {
		code int
		want string
	}{
		{200, "success"}, {204, "success"}, {301, "redirect"}, {399, "redirect"},
		{400, "reject"}, {404, "reject"}, {429, "backoff"}, {500, "retry"}, {599, "retry"},
		{99, "invalid"}, {100, "informational"}, {199, "informational"}, {600, "invalid"},
	}
	for _, tt := range tests {
		if got := RetryPolicy(tt.code); got != tt.want {
			t.Errorf("RetryPolicy(%d) = %q, want %q", tt.code, got, tt.want)
		}
	}
}
