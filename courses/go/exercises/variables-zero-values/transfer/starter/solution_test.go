package exercise

import "testing"

func TestEffectiveWorkers(t *testing.T) {
	tests := []struct {
		name                    string
		configured, queue, want int
	}{
		{"configured workers", 3, 10, 3},
		{"default workers", 0, 10, 4},
		{"negative configuration uses default", -2, 8, 4},
		{"queue caps workers", 8, 2, 2},
		{"no pending work", 4, 0, 0},
		{"negative queue", 4, -1, 0},
	}
	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			if got := EffectiveWorkers(tt.configured, tt.queue); got != tt.want {
				t.Fatalf("EffectiveWorkers(%d, %d) = %d, want %d", tt.configured, tt.queue, got, tt.want)
			}
		})
	}
}
