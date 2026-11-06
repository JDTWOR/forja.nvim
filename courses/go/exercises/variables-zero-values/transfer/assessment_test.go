package exercise

import "testing"

func TestForjaAssessmentWorkersBoundaries(t *testing.T) {
	if got := EffectiveWorkers(1, 1); got != 1 {
		t.Fatalf("one job: got %d", got)
	}
	if got := EffectiveWorkers(4, 3); got != 3 {
		t.Fatalf("cap: got %d", got)
	}
	if got := EffectiveWorkers(0, 3); got != 3 {
		t.Fatalf("default capped by queue: got %d", got)
	}
	if got := EffectiveWorkers(-1, 1); got != 1 {
		t.Fatalf("negative setting capped by queue: got %d", got)
	}
	if got := EffectiveWorkers(9, -5); got != 0 {
		t.Fatalf("negative queue: got %d", got)
	}
}
