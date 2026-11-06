public class ForjaAssessment {
    private static void check(boolean condition, String label) {
        if (!condition) throw new AssertionError(label);
    }

    private static void throwsIllegalArgument(Runnable action, String label) {
        try {
            action.run();
        } catch (IllegalArgumentException expected) {
            return;
        }
        throw new AssertionError(label + " should throw IllegalArgumentException");
    }

    public static void main(String[] args) {
        throwsIllegalArgument(() -> new Solution.SeatPool(-1), "negative capacity");
        Solution.SeatPool pool = new Solution.SeatPool(0);
        check(!pool.reserve(1), "zero capacity rejects reservation");
        check(!pool.reserve(0) && !pool.reserve(-1), "reservation requires positive count");
        check(!pool.release(1) && !pool.release(0) && !pool.release(-1), "release requires reserved positive count");
        check(pool.reserved() == 0, "invalid operations preserve empty state");

        Solution.SeatPool full = new Solution.SeatPool(Integer.MAX_VALUE);
        check(full.reserve(Integer.MAX_VALUE), "large valid reservation");
        check(!full.reserve(1), "reservation cannot overflow capacity");
        check(full.reserved() == Integer.MAX_VALUE, "failed overflow attempt preserves state");
        check(full.release(Integer.MAX_VALUE), "release all seats");
        check(full.reserved() == 0, "pool returns to empty state");
    }
}
