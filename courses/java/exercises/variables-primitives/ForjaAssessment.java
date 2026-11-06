public class ForjaAssessment {
    private static void equal(int expected, int actual, String label) {
        if (expected != actual) throw new AssertionError(label + ": expected " + expected + ", got " + actual);
    }

    public static void main(String[] args) {
        equal(2_000_000_000, Solution.taxThenDiscount(1_000_000_000, 0, 100), "wide intermediate");
        equal(0, Solution.discountThenTax(1_000_000_000, 100, 100), "full discount");
        equal(0, Solution.taxThenDiscount(1_000_000_000, 100, 100), "full discount after tax");
        equal(1_000_000_001, Solution.addFee(1_000_000_000, 1), "large fee");
    }
}
