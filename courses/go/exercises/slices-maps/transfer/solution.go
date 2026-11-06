package exercise

import "strings"

func CountMethods(methods []string) map[string]int {
	counts := make(map[string]int)
	for _, method := range methods {
		key := strings.ToUpper(strings.TrimSpace(method))
		if key == "" {
			continue
		}
		counts[key]++
	}
	return counts
}
