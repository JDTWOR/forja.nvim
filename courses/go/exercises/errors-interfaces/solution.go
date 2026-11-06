package exercise

import "errors"

var ErrInvalidQuantity = errors.New("quantity must be positive")
var ErrInvalidPrice = errors.New("price must not be negative")
var ErrQuoteOverflow = errors.New("quote total overflows int")

type PriceLookup interface {
	PriceFor(sku string) (int, error)
}

func Quote(source PriceLookup, sku string, quantity int) (int, error) {
	if quantity <= 0 {
		return 0, ErrInvalidQuantity
	}
	price, err := source.PriceFor(sku)
	if err != nil {
		return 0, err
	}
	if price < 0 {
		return 0, ErrInvalidPrice
	}
	maxInt := int(^uint(0) >> 1)
	if price != 0 && quantity > maxInt/price {
		return 0, ErrQuoteOverflow
	}
	return price * quantity, nil
}
