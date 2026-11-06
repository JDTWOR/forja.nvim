public class Solution {
    public static int addFee(int subtotalCents, int feeCents) {
        if (subtotalCents < 0 || feeCents < 0) {
            throw new IllegalArgumentException("amounts must not be negative");
        }
        int runningTotal = subtotalCents;
        runningTotal = Math.addExact(runningTotal, feeCents);
        return runningTotal;
    }
}
