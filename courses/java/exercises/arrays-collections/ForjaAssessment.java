import java.util.Arrays;
import java.util.List;
import java.util.Map;

public class ForjaAssessment {
    private static void equal(Object expected, Object actual, String label) {
        if (!expected.equals(actual)) throw new AssertionError(label + ": expected " + expected + ", got " + actual);
    }

    public static void main(String[] args) {
        equal(0L, Solution.sum(null), "null array");
        equal(4_294_967_294L, Solution.sum(new int[] {Integer.MAX_VALUE, Integer.MAX_VALUE}), "long accumulator");
        equal(List.of(), Solution.uniqueInOrder(null), "null list");
        equal(Arrays.asList("", "x"), Solution.uniqueInOrder(Arrays.asList("", "x", "", null)), "empty string distinct from null");
        equal(Map.of("A", 2, "a", 1), Solution.wordCounts(Arrays.asList("A", "a", "A")), "case-sensitive words");
        equal(Map.of(), Solution.wordCounts(null), "null counts");
    }
}
