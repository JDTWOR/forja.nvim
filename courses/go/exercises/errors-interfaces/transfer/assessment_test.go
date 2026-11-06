package exercise

import (
	"errors"
	"testing"
)

type assessmentStock struct {
	count int
	err   error
	calls int
}

func (s *assessmentStock) Available(string) (int, error) { s.calls++; return s.count, s.err }

func TestForjaAssessmentValidateReservationErrors(t *testing.T) {
	lookupErr := errors.New("database unavailable")
	s := &assessmentStock{err: lookupErr}
	if err := ValidateReservation(s, "x", 1); !errors.Is(err, lookupErr) {
		t.Fatalf("lookup error not preserved: %v", err)
	}
	if s.calls != 1 {
		t.Fatalf("lookup calls = %d, want 1", s.calls)
	}
	for _, quantity := range []int{-1, 0} {
		bad := &assessmentStock{count: 5}
		if err := ValidateReservation(bad, "x", quantity); !errors.Is(err, ErrInvalidQuantity) || bad.calls != 0 {
			t.Errorf("quantity %d: err=%v calls=%d", quantity, err, bad.calls)
		}
	}
	if err := ValidateReservation(nil, "x", 1); !errors.Is(err, ErrNilStockSource) {
		t.Fatalf("nil source error = %v", err)
	}
	if err := ValidateReservation(&assessmentStock{count: 9}, "x", 10); !errors.Is(err, ErrInsufficientStock) {
		t.Fatalf("insufficient stock error = %v", err)
	}
}
