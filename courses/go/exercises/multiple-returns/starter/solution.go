package exercise

import "errors"

var ErrZeroDivisor = errors.New("divisor must not be zero")
var ErrInvalidReadingInput = errors.New("words must be non-negative and reading speed must be positive")

func DivideWithRemainder(dividend, divisor int) (int, int, error) {
	return 0, 0, ErrZeroDivisor // TODO: return quotient and remainder, or an error
}

func ReadingMinutes(words, wordsPerMinute int) (int, error) {
	return 0, ErrInvalidReadingInput // TODO: validate inputs and round up partial minutes
}
