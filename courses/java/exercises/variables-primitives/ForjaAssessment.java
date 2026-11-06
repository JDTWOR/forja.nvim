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

    private static void throwsArithmetic(Runnable action, String label) {
        try {
            action.run();
        } catch (ArithmeticException expected) {
            return;
        }
        throw new AssertionError(label + " should throw ArithmeticException");
    }

    public static void main(String[] args) {
        equal(1_000_000_001, Solution.addFee(1_000_000_000, 1), "large fee");
        equal(Integer.MAX_VALUE, Solution.addFee(Integer.MAX_VALUE - 1, 1), "exact maximum");
        throwsIllegalArgument(() -> Solution.addFee(-1, 0), "negative subtotal");
        throwsIllegalArgument(() -> Solution.addFee(0, -1), "negative fee");
        throwsArithmetic(() -> Solution.addFee(Integer.MAX_VALUE, 1), "fee overflow");
    }
}
