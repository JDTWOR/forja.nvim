import java.util.Arrays;

public class PublicTests {
    private static void equal(int[] expected, int[] actual, String label) {
        if (!Arrays.equals(expected, actual)) {
            throw new AssertionError(label + ": expected " + Arrays.toString(expected)
                    + ", got " + Arrays.toString(actual));
        }
    }

    public static void main(String[] args) {
        equal(new int[] {0, 10}, Solution.pageRange(23, 0, 10), "first page");
        equal(new int[] {10, 20}, Solution.pageRange(23, 1, 10), "middle page");
        equal(new int[] {20, 23}, Solution.pageRange(23, 2, 10), "partial last page");
        equal(new int[] {23, 23}, Solution.pageRange(23, 3, 10), "page after end");
    }
}
