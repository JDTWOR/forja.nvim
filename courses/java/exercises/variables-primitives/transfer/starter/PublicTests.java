public class PublicTests {
    private static void equal(int expected, int actual, String label) {
        if (expected != actual) throw new AssertionError(label + ": expected " + expected + ", got " + actual);
    }

    public static void main(String[] args) {
        equal(4, Solution.scoreAfterRound(2, 5, 4), "penalty bottoms out before bonus");
        equal(20, Solution.scoreAfterRound(30, 15, 5), "ordinary round");
        equal(Integer.MAX_VALUE, Solution.scoreAfterRound(Integer.MAX_VALUE - 3, 0, 10), "saturated bonus");
    }
}
