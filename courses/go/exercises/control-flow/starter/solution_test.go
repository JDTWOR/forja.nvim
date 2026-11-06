package exercise

import "testing"

func TestPublicShippingBands(t *testing.T) {
	if got := ShippingCost(1000, false); got != 500 {
		t.Fatalf("ShippingCost(1000, false) = %d, want 500", got)
	}
	if got := ShippingCost(1001, false); got != 1000 {
		t.Fatalf("ShippingCost(1001, false) = %d, want 1000", got)
	}
}

func TestPublicScoreBand(t *testing.T) {
	if got := ScoreBand(90); got != "excellent" {
		t.Fatalf("ScoreBand(90) = %q, want excellent", got)
	}
	if got := ScoreBand(60); got != "passing" {
		t.Fatalf("ScoreBand(60) = %q, want passing", got)
	}
	if got := ScoreBand(59); got != "retry" {
		t.Fatalf("ScoreBand(59) = %q, want retry", got)
	}
}
