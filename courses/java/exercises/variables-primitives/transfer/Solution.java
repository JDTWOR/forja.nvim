public class Solution {
    public static int scoreAfterRound(int startingScore, int penalty, int bonus) {
        if (startingScore < 0 || penalty < 0 || bonus < 0) {
            throw new IllegalArgumentException("scores and adjustments must not be negative");
        }
        int afterPenalty = Math.max(0, startingScore - penalty);
        long withBonus = (long) afterPenalty + bonus;
        return (int) Math.min(Integer.MAX_VALUE, withBonus);
    }
}
