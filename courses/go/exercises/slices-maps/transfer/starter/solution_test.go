package exercise

import "testing"

func TestCountMethods(t *testing.T) {
	got := CountMethods([]string{"get", " POST ", "GET", "", "  ", "delete"})
	want := map[string]int{"GET": 2, "POST": 1, "DELETE": 1}
	if len(got) != len(want) {
		t.Fatalf("CountMethods returned %v, want %v", got, want)
	}
	for method, count := range want {
		if got[method] != count {
			t.Errorf("count for %s = %d, want %d", method, got[method], count)
		}
	}
	if empty := CountMethods(nil); empty == nil || len(empty) != 0 {
		t.Fatalf("CountMethods(nil) = %#v, want initialized empty map", empty)
	}
}
