public class ForjaAssessment {
    private static void equal(Object expected, Object actual, String label) {
        if (!expected.equals(actual)) throw new AssertionError(label + ": expected " + expected + ", got " + actual);
    }

    public static void main(String[] args) {
        equal(-1, Solution.shippingCost(-1, false), "negative weight");
        equal(1200, Solution.shippingCost(2000, false), "second boundary");
        equal(3200, Solution.shippingCost(2001, true), "heavy express");
        equal(1200, Solution.shippingCost(0, true), "zero weight express");
        equal("invalid", Solution.scoreLabel(-1), "negative score");
        equal("invalid", Solution.scoreLabel(101), "score above range");
        equal("excellent", Solution.scoreLabel(100), "maximum score");
        equal("invalid", Solution.scoreLabelOrMissing(101), "boxed invalid score");
    }
}
