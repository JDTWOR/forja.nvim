package exercise

import "testing"

func TestForjaAssessmentShippingBoundaries(t *testing.T) {
	cases := []struct {
		weight  int
		express bool
		want    int
	}{{0, false, 500}, {1000, true, 750}, {1001, true, 1250}, {5000, false, 1000}, {5001, false, 2500}, {-1, false, -1}}
	for _, test := range cases {
		if got := ShippingCost(test.weight, test.express); got != test.want {
			t.Errorf("ShippingCost(%d, %t) = %d, want %d", test.weight, test.express, got, test.want)
		}
	}
}

func TestForjaAssessmentScoreBoundaries(t *testing.T) {
	cases := []struct {
		score int
		want  string
	}{{-1, "retry"}, {0, "retry"}, {59, "retry"}, {60, "passing"}, {89, "passing"}, {90, "excellent"}, {100, "excellent"}}
	for _, test := range cases {
		if got := ScoreBand(test.score); got != test.want {
			t.Errorf("ScoreBand(%d) = %q, want %q", test.score, got, test.want)
		}
	}
}

func TestForjaAssessmentMissingScore(t *testing.T) {
	if got := ScoreBandOrMissing(0, false); got != "missing" {
		t.Fatalf("missing score = %q, want missing", got)
	}
	if got := ScoreBandOrMissing(0, true); got != "retry" {
		t.Fatalf("present zero score = %q, want retry", got)
	}
}
