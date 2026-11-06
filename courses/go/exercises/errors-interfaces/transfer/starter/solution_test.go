package exercise

import (
	"errors"
	"testing"
)

type stockStub struct {
	count int
	err   error
	calls int
	sku   string
}

func (s *stockStub) Available(sku string) (int, error) { s.calls++; s.sku = sku; return s.count, s.err }

func TestValidateReservation(t *testing.T) {
	t.Run("exact quantity succeeds", func(t *testing.T) {
		s := &stockStub{count: 3}
		if err := ValidateReservation(s, "SKU-1", 3); err != nil {
			t.Fatal(err)
		}
		if s.calls != 1 || s.sku != "SKU-1" {
			t.Fatalf("lookup state = %d calls, %q", s.calls, s.sku)
		}
	})
	t.Run("invalid quantity skips lookup", func(t *testing.T) {
		s := &stockStub{count: 10}
		if err := ValidateReservation(s, "SKU-1", 0); !errors.Is(err, ErrInvalidQuantity) {
			t.Fatalf("error = %v", err)
		}
		if s.calls != 0 {
			t.Fatalf("lookup called %d times", s.calls)
		}
	})
	t.Run("insufficient stock", func(t *testing.T) {
		if err := ValidateReservation(&stockStub{count: 2}, "SKU-1", 3); !errors.Is(err, ErrInsufficientStock) {
			t.Fatalf("error = %v", err)
		}
	})
	t.Run("negative stock is invalid", func(t *testing.T) {
		if err := ValidateReservation(&stockStub{count: -1}, "SKU-1", 1); !errors.Is(err, ErrInvalidStockCount) {
			t.Fatalf("error = %v", err)
		}
	})
}
