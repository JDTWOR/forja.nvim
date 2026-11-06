public class PublicTests {
    private static void check(boolean condition, String label) {
        if (!condition) throw new AssertionError(label);
    }

    public static void main(String[] args) {
        Solution.SeatPool pool = new Solution.SeatPool(3);
        check(pool.capacity() == 3 && pool.reserved() == 0, "initial state");
        check(pool.reserve(2), "reserve available seats");
        check(pool.reserved() == 2, "reservation updates count");
        check(!pool.reserve(2), "cannot exceed capacity");
        check(pool.reserved() == 2, "failed reservation preserves count");
        check(pool.release(1), "release reserved seat");
        check(pool.reserved() == 1, "release updates count");
    }
}
