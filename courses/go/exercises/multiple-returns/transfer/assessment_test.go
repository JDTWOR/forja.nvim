package exercise

import (
	"errors"
	"testing"
)

func TestForjaAssessmentSplitDurationBoundaries(t *testing.T) {
	for _, total := range []int{1, 3599, 3601, 7199, 7200, 86399, 86400} {
		h, m, s, err := SplitDuration(total)
		if err != nil || h*3600+m*60+s != total || m < 0 || m >= 60 || s < 0 || s >= 60 {
			t.Errorf("SplitDuration(%d) = (%d,%d,%d,%v), invalid decomposition", total, h, m, s, err)
		}
	}
	_, _, _, err := SplitDuration(-3601)
	if !errors.Is(err, ErrNegativeDuration) {
		t.Fatalf("negative duration error = %v", err)
	}
}
