package exercise

import "errors"

var ErrInvalidQuantity = errors.New("quantity must be positive")
var ErrInvalidStockCount = errors.New("available stock must not be negative")
var ErrInsufficientStock = errors.New("insufficient stock")
var ErrNilStockSource = errors.New("stock source is nil")

type StockSource interface {
	Available(sku string) (int, error)
}

func ValidateReservation(source StockSource, sku string, quantity int) error {
	if quantity <= 0 {
		return ErrInvalidQuantity
	}
	if source == nil {
		return ErrNilStockSource
	}
	available, err := source.Available(sku)
	if err != nil {
		return err
	}
	if available < 0 {
		return ErrInvalidStockCount
	}
	if available < quantity {
		return ErrInsufficientStock
	}
	return nil
}
