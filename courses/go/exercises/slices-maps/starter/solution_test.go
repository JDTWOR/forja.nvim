package exercise

import "testing"

func TestPublicAverageTemperature(t *testing.T) {
	if got := AverageTemperature([]int16{10, 20, 30}); got != 20 {
		t.Fatalf("AverageTemperature = %v, want 20", got)
	}
}

func TestPublicCountWords(t *testing.T) {
	got := CountWords("Go go maps")
	if got["go"] != 2 || got["maps"] != 1 {
		t.Fatalf("CountWords = %#v, want go:2 and maps:1", got)
	}
}
