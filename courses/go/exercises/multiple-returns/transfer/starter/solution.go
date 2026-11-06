package exercise

import "errors"

var ErrNegativeDuration = errors.New("duration must not be negative")

func SplitDuration(totalSeconds int) (hours, minutes, seconds int, err error) {
	return 0, 0, 0, ErrNegativeDuration // TODO: reject negatives and split the remaining seconds
}
