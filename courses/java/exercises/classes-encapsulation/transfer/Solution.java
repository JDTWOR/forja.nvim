public class Solution {
    public static final class SeatPool {
        private final int capacity;
        private int reserved;

        public SeatPool(int capacity) {
            if (capacity < 0) throw new IllegalArgumentException("capacity must not be negative");
            this.capacity = capacity;
            this.reserved = 0;
        }

        public int capacity() {
            return capacity;
        }

        public int reserved() {
            return reserved;
        }

        public boolean reserve(int count) {
            if (count <= 0 || count > capacity - reserved) return false;
            reserved += count;
            return true;
        }

        public boolean release(int count) {
            if (count <= 0 || count > reserved) return false;
            reserved -= count;
            return true;
        }
    }
}
