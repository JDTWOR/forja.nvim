package exercise

import "errors"

var ErrZeroDivisor = errors.New("divisor must not be zero")
var ErrInvalidReadingInput = errors.New("words must be non-negative and reading speed must be positive")

func DivideWithRemainder(dividend, divisor int) (int, int, error) {
	if divisor == 0 {
		return 0, 0, ErrZeroDivisor
	}
	return dividend / divisor, dividend % divisor, nil
}

func ReadingMinutes(words, wordsPerMinute int) (int, error) {
	if words < 0 || wordsPerMinute <= 0 {
		return 0, ErrInvalidReadingInput
	}

	minutes := words / wordsPerMinute
	if words%wordsPerMinute != 0 {
		minutes++
	}
	return minutes, nil
}
