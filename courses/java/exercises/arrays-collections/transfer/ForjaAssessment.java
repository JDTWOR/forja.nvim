import java.util.Arrays;
import java.util.List;

public class ForjaAssessment {
    private static void equal(Object expected, Object actual, String label) {
        if (expected == null ? actual != null : !expected.equals(actual)) {
            throw new AssertionError(label + ": expected " + expected + ", got " + actual);
        }
    }

    public static void main(String[] args) {
        equal(null, Solution.mostFrequent(null), "null list");
        equal(null, Solution.mostFrequent(Arrays.asList(null, null)), "only null entries");
        equal("a", Solution.mostFrequent(List.of("a", "b", "a", "B", "b", "a")), "unequal counts");
        equal("A", Solution.mostFrequent(List.of("A", "a", "a", "A")), "case-sensitive tie");
        equal("first", Solution.mostFrequent(List.of("first", "second", "second", "first")),
                "tie remains with earliest first occurrence");
    }
}
