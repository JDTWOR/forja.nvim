public class PublicTests {
    private static void equal(int expected, int actual, String label) {
        if (expected != actual) throw new AssertionError(label + ": expected " + expected + ", got " + actual);
    }

    public static void main(String[] args) {
        equal(1450, Solution.addFee(1200, 250), "fee");
        equal(1178, Solution.discountThenTax(1099, 10, 19), "discount then tax");
        equal(1177, Solution.taxThenDiscount(1099, 10, 19), "tax then discount");
        equal(0, Solution.discountThenTax(0, 0, 0), "zero amount");
    }
}
