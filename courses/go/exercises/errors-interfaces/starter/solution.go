package exercise

import "errors"

var ErrInvalidQuantity = errors.New("quantity must be positive")
var ErrInvalidPrice = errors.New("price must not be negative")
var ErrQuoteOverflow = errors.New("quote total overflows int")

type PriceLookup interface {
	PriceFor(sku string) (int, error)
}

func Quote(source PriceLookup, sku string, quantity int) (int, error) {
	return 0, ErrInvalidQuantity // TODO: validate, look up a price, propagate errors, and multiply safely
}
