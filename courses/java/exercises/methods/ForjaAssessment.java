public class ForjaAssessment {
    private static void equal(int expected, int actual, String label) {
        if (expected != actual) throw new AssertionError(label + ": expected " + expected + ", got " + actual);
    }

    public static void main(String[] args) {
        equal(0, Solution.percentageOf(99, 0), "zero percentage");
        equal(100, Solution.percentageOf(100, 100), "full percentage");
        equal(1_000_000_000, Solution.percentageOf(1_000_000_000, 100), "wide intermediate");
        equal(-1, Solution.readingMinutes(10, 0), "zero speed");
        equal(-1, Solution.readingMinutes(-1, 20), "negative words");
        equal(1, Solution.readingMinutes(Integer.MAX_VALUE, Integer.MAX_VALUE), "max values");
        equal(2, Solution.readingMinutes(Integer.MAX_VALUE, Integer.MAX_VALUE - 1), "large remainder");
    }
}
