public class Solution {
    public static int[] pageRange(int totalItems, int pageNumber, int pageSize) {
        if (totalItems < 0 || pageNumber < 0 || pageSize <= 0) {
            return new int[] {-1, -1};
        }
        long start = (long) pageNumber * pageSize;
        if (start >= totalItems) {
            return new int[] {totalItems, totalItems};
        }
        long end = Math.min((long) totalItems, start + pageSize);
        return new int[] {(int) start, (int) end};
    }
}
