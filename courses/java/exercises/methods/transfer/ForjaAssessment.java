import java.util.Arrays;

public class ForjaAssessment {
    private static void equal(int[] expected, int[] actual, String label) {
        if (!Arrays.equals(expected, actual)) {
            throw new AssertionError(label + ": expected " + Arrays.toString(expected)
                    + ", got " + Arrays.toString(actual));
        }
    }

    public static void main(String[] args) {
        equal(new int[] {-1, -1}, Solution.pageRange(-1, 0, 5), "negative total");
        equal(new int[] {-1, -1}, Solution.pageRange(5, -1, 5), "negative page number");
        equal(new int[] {-1, -1}, Solution.pageRange(5, 0, 0), "zero page size");
        equal(new int[] {0, 0}, Solution.pageRange(0, Integer.MAX_VALUE, 1), "empty collection");
        equal(new int[] {Integer.MAX_VALUE, Integer.MAX_VALUE},
                Solution.pageRange(Integer.MAX_VALUE, Integer.MAX_VALUE, Integer.MAX_VALUE),
                "large page index clamps to end");
        equal(new int[] {0, Integer.MAX_VALUE},
                Solution.pageRange(Integer.MAX_VALUE, 0, Integer.MAX_VALUE), "large page size");
    }
}
