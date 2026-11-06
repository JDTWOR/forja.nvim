public class ForjaAssessment {
    private static void equal(int expected, int actual, String label) {
        if (expected != actual) throw new AssertionError(label + ": expected " + expected + ", got " + actual);
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
        equal(0, Solution.scoreAfterRound(0, Integer.MAX_VALUE, 0), "large penalty clamps at zero");
        equal(7, Solution.scoreAfterRound(10, 3, 0), "zero bonus");
        equal(Integer.MAX_VALUE, Solution.scoreAfterRound(10, 0, Integer.MAX_VALUE), "exact cap");
        throwsIllegalArgument(() -> Solution.scoreAfterRound(-1, 0, 0), "negative score");
        throwsIllegalArgument(() -> Solution.scoreAfterRound(0, -1, 0), "negative penalty");
        throwsIllegalArgument(() -> Solution.scoreAfterRound(0, 0, -1), "negative bonus");
    }
}
