package exercise

import (
	"math"
	"testing"
)

func TestForjaAssessmentAverageTemperatureEdges(t *testing.T) {
	if got := AverageTemperature(nil); got != 0 {
		t.Fatalf("empty average = %v, want 0", got)
	}
	if got := AverageTemperature([]int16{math.MinInt16, math.MaxInt16}); got != -0.5 {
		t.Fatalf("extreme average = %v, want -0.5", got)
	}
	if got := AverageTemperature([]int16{1, 2}); got != 1.5 {
		t.Fatalf("fractional average = %v, want 1.5", got)
	}
}

func TestForjaAssessmentCountWordsNormalization(t *testing.T) {
	got := CountWords("  Go\tgo\nMAPS maps  ")
	if len(got) != 2 || got["go"] != 2 || got["maps"] != 2 {
		t.Fatalf("CountWords normalized = %#v, want go:2 maps:2", got)
	}
	if empty := CountWords(" \n\t "); empty == nil || len(empty) != 0 {
		t.Fatalf("empty CountWords = %#v, want initialized empty map", empty)
	}
}

func TestForjaAssessmentInputIsNotMutated(t *testing.T) {
	readings := []int16{4, 8}
	_ = AverageTemperature(readings)
	if readings[0] != 4 || readings[1] != 8 {
		t.Fatalf("AverageTemperature changed input: %v", readings)
	}
}
