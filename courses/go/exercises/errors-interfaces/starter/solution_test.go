package exercise

import (
	"testing"
)

type publicPrices map[string]int

func (prices publicPrices) PriceFor(sku string) (int, error) {
	return prices[sku], nil
}

func TestPublicQuote(t *testing.T) {
	total, err := Quote(publicPrices{"book": 1200}, "book", 3)
	if err != nil || total != 3600 {
		t.Fatalf("Quote = (%d, %v), want (3600, nil)", total, err)
	}
}
