package exercise

import (
	"errors"
	"testing"
)

func TestPublicDivideWithRemainder(t *testing.T) {
	quotient, remainder, err := DivideWithRemainder(17, 5)
	if err != nil || quotient != 3 || remainder != 2 {
		t.Fatalf("DivideWithRemainder(17, 5) = (%d, %d, %v), want (3, 2, nil)", quotient, remainder, err)
	}
}

func TestPublicReadingMinutes(t *testing.T) {
	minutes, err := ReadingMinutes(121, 60)
	if err != nil || minutes != 3 {
		t.Fatalf("ReadingMinutes(121, 60) = (%d, %v), want (3, nil)", minutes, err)
	}
}

func TestPublicZeroDivisorReturnsError(t *testing.T) {
	_, _, err := DivideWithRemainder(4, 0)
	if !errors.Is(err, ErrZeroDivisor) {
		t.Fatalf("error = %v, want ErrZeroDivisor", err)
	}
}
