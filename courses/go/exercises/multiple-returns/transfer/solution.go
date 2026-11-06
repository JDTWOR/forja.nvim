package exercise

import "errors"

var ErrNegativeDuration = errors.New("duration must not be negative")

func SplitDuration(totalSeconds int) (hours, minutes, seconds int, err error) {
	if totalSeconds < 0 {
		return 0, 0, 0, ErrNegativeDuration
	}
	hours = totalSeconds / 3600
	remainder := totalSeconds % 3600
	minutes = remainder / 60
	seconds = remainder % 60
	return hours, minutes, seconds, nil
}
