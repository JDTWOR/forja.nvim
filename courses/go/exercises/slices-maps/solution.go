package exercise

import (
	"strings"
)

func AverageTemperature(readings []int16) float64 {
	if len(readings) == 0 {
		return 0
	}

	var total float64
	for _, reading := range readings {
		total += float64(reading)
	}
	return total / float64(len(readings))
}

func CountWords(input string) map[string]int {
	counts := make(map[string]int)
	for _, word := range strings.Fields(input) {
		counts[strings.ToLower(word)]++
	}
	return counts
}
