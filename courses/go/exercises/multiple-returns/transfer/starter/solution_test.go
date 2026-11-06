package exercise

import (
	"errors"
	"testing"
)

func TestSplitDuration(t *testing.T) {
	tests := []struct{ total, h, m, s int }{{0, 0, 0, 0}, {59, 0, 0, 59}, {60, 0, 1, 0}, {3600, 1, 0, 0}, {3661, 1, 1, 1}, {90061, 25, 1, 1}}
	for _, tt := range tests {
		h, m, s, err := SplitDuration(tt.total)
		if err != nil || h != tt.h || m != tt.m || s != tt.s {
			t.Errorf("SplitDuration(%d) = (%d,%d,%d,%v), want (%d,%d,%d,nil)", tt.total, h, m, s, err, tt.h, tt.m, tt.s)
		}
	}
	h, m, s, err := SplitDuration(-1)
	if !errors.Is(err, ErrNegativeDuration) || h != 0 || m != 0 || s != 0 {
		t.Fatalf("negative input = (%d,%d,%d,%v), want zero parts and ErrNegativeDuration", h, m, s, err)
	}
}
