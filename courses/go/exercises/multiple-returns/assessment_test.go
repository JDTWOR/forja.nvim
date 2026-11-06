package exercise

import (
	"errors"
	"math"
	"testing"
)

func TestForjaAssessmentDivisionSignsAndError(t *testing.T) {
	cases := []struct {
		a, b int
		q, r int
	}{{10, 3, 3, 1}, {-10, 3, -3, -1}, {10, -3, -3, 1}, {-10, -3, 3, -1}, {0, 7, 0, 0}}
	for _, test := range cases {
		q, r, err := DivideWithRemainder(test.a, test.b)
		if err != nil || q != test.q || r != test.r {
			t.Errorf("DivideWithRemainder(%d, %d) = (%d, %d, %v), want (%d, %d, nil)", test.a, test.b, q, r, err, test.q, test.r)
		}
	}
	q, r, err := DivideWithRemainder(9, 0)
	if q != 0 || r != 0 || !errors.Is(err, ErrZeroDivisor) {
		t.Fatalf("zero divisor returned (%d, %d, %v), want zero values and ErrZeroDivisor", q, r, err)
	}
}

func TestForjaAssessmentReadingBoundaries(t *testing.T) {
	cases := []struct {
		words, speed int
		want         int
	}{{0, 200, 0}, {1, 200, 1}, {200, 200, 1}, {201, 200, 2}, {math.MaxInt, math.MaxInt, 1}}
	for _, test := range cases {
		got, err := ReadingMinutes(test.words, test.speed)
		if err != nil || got != test.want {
			t.Errorf("ReadingMinutes(%d, %d) = (%d, %v), want (%d, nil)", test.words, test.speed, got, err, test.want)
		}
	}
}

func TestForjaAssessmentInvalidReadingInputs(t *testing.T) {
	for _, test := range []struct{ words, speed int }{{-1, 10}, {10, 0}, {10, -1}} {
		got, err := ReadingMinutes(test.words, test.speed)
		if got != 0 || !errors.Is(err, ErrInvalidReadingInput) {
			t.Errorf("ReadingMinutes(%d, %d) = (%d, %v), want zero and ErrInvalidReadingInput", test.words, test.speed, got, err)
		}
	}
}
