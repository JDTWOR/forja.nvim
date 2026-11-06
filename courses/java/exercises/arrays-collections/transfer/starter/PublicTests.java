import java.util.Arrays;

public class PublicTests {
    private static void equal(Object expected, Object actual, String label) {
        if (expected == null ? actual != null : !expected.equals(actual)) {
            throw new AssertionError(label + ": expected " + expected + ", got " + actual);
        }
    }

    public static void main(String[] args) {
        equal("pear", Solution.mostFrequent(Arrays.asList("pear", "plum", "pear", "plum")),
                "tie uses first appearance");
        equal("blue", Solution.mostFrequent(Arrays.asList(null, "blue", "red", "blue")),
                "null ignored");
        equal("", Solution.mostFrequent(Arrays.asList("", "x", "")), "empty word is valid");
    }
}
