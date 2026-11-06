package exercise

import (
	"errors"
	"math"
	"testing"
)

type assessmentPrices struct {
	price int
	err   error
	calls int
}

func (source *assessmentPrices) PriceFor(string) (int, error) {
	source.calls++
	return source.price, source.err
}

func TestForjaAssessmentQuoteValidationAndLookup(t *testing.T) {
	source := &assessmentPrices{price: 10}
	if total, err := Quote(source, "x", 0); total != 0 || !errors.Is(err, ErrInvalidQuantity) || source.calls != 0 {
		t.Fatalf("invalid quantity returned (%d, %v), calls=%d", total, err, source.calls)
	}
	if total, err := Quote(source, "x", -1); total != 0 || !errors.Is(err, ErrInvalidQuantity) || source.calls != 0 {
		t.Fatalf("negative quantity returned (%d, %v), calls=%d", total, err, source.calls)
	}
	lookupErr := errors.New("catalog unavailable")
	source.err = lookupErr
	if total, err := Quote(source, "x", 2); total != 0 || !errors.Is(err, lookupErr) {
		t.Fatalf("lookup error returned (%d, %v), want propagated error", total, err)
	}
}

func TestForjaAssessmentQuotePriceAndOverflow(t *testing.T) {
	source := &assessmentPrices{price: -1}
	if total, err := Quote(source, "x", 1); total != 0 || !errors.Is(err, ErrInvalidPrice) {
		t.Fatalf("negative price returned (%d, %v), want ErrInvalidPrice", total, err)
	}
	source.price = math.MaxInt
	if total, err := Quote(source, "x", 2); total != 0 || !errors.Is(err, ErrQuoteOverflow) {
		t.Fatalf("overflow returned (%d, %v), want ErrQuoteOverflow", total, err)
	}
}

func TestForjaAssessmentQuoteZeroPriceAndMaximumSafeProduct(t *testing.T) {
	source := &assessmentPrices{price: 0}
	if total, err := Quote(source, "x", 7); total != 0 || err != nil {
		t.Fatalf("zero price returned (%d, %v), want (0, nil)", total, err)
	}
	source.price = 11
	if total, err := Quote(source, "x", 3); total != 33 || err != nil {
		t.Fatalf("valid product returned (%d, %v), want (33, nil)", total, err)
	}
}
