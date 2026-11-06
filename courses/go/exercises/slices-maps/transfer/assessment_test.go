package exercise

import "testing"

func TestForjaAssessmentCountMethodsNormalization(t *testing.T) {
	got := CountMethods([]string{string([]byte{9}) + "patch", "Patch", " options ", "OPTIONS", "connect", string([]byte{10})})
	want := map[string]int{"PATCH": 2, "OPTIONS": 2, "CONNECT": 1}
	for key, count := range want {
		if got[key] != count {
			t.Errorf("count for %q = %d, want %d", key, got[key], count)
		}
	}
	if len(got) != len(want) {
		t.Errorf("unexpected keys: got %v", got)
	}
	empty := CountMethods([]string{" ", string([]byte{9}), ""})
	if empty == nil || len(empty) != 0 {
		t.Errorf("whitespace-only input = %#v, want initialized empty map", empty)
	}
}
