import java.util.Arrays;
import java.util.List;
import java.util.Map;

public class PublicTests {
    private static void equal(Object expected, Object actual, String label) {
        if (!expected.equals(actual)) throw new AssertionError(label + ": expected " + expected + ", got " + actual);
    }

    public static void main(String[] args) {
        equal(6L, Solution.sum(new int[] {1, 2, 3}), "array sum");
        equal(Arrays.asList("a", "b"), Solution.uniqueInOrder(Arrays.asList("a", "b", "a", null)), "stable unique");
        equal(Map.of("blue", 2, "red", 1), Solution.wordCounts(Arrays.asList("blue", "red", "blue", null)), "word counts");
    }
}
