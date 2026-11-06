package exercise

func EffectiveWorkers(configuredWorkers, queueLength int) int {
	if queueLength <= 0 {
		return 0
	}
	workers := configuredWorkers
	if workers <= 0 {
		workers = 4
	}
	if workers > queueLength {
		workers = queueLength
	}
	return workers
}
