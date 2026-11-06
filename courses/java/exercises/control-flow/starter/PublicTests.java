public class PublicTests {
    private static void equal(Object expected, Object actual, String label) {
        if (!expected.equals(actual)) throw new AssertionError(label + ": expected " + expected + ", got " + actual);
    }

    public static void main(String[] args) {
        equal(500, Solution.shippingCost(500, false), "first boundary");
        equal(1900, Solution.shippingCost(501, true), "middle range express");
        equal(2500, Solution.shippingCost(2001, false), "heavy shipment");
        equal("excellent", Solution.scoreLabel(90), "excellent boundary");
        equal("passing", Solution.scoreLabel(60), "passing boundary");
        equal("retry", Solution.scoreLabel(59), "retry");
        equal("missing", Solution.scoreLabelOrMissing(null), "missing score");
    }
}
