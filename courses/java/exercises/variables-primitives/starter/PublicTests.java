public class PublicTests {
    private static void equal(int expected, int actual, String label) {
        if (expected != actual) throw new AssertionError(label + ": expected " + expected + ", got " + actual);
    }

    public static void main(String[] args) {
        equal(1450, Solution.addFee(1200, 250), "fee");
        equal(1200, Solution.addFee(1200, 0), "zero fee");
        equal(Integer.MAX_VALUE, Solution.addFee(Integer.MAX_VALUE, 0), "int boundary");
    }
}
