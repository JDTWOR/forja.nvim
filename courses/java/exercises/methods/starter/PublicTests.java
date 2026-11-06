public class PublicTests {
    private static void equal(int expected, int actual, String label) {
        if (expected != actual) throw new AssertionError(label + ": expected " + expected + ", got " + actual);
    }

    public static void main(String[] args) {
        equal(120, Solution.percentageOf(1000, 12), "percentage");
        equal(1178, Solution.checkoutTotal(1099, 10, 19), "checkout stages");
        equal(3, Solution.readingMinutes(121, 60), "round up");
        equal(0, Solution.readingMinutes(0, 60), "empty reading");
    }
}
