public class Solution {
    public static String classifyLatency(int milliseconds) {
        if (milliseconds < 0) return "invalid";
        if (milliseconds <= 50) return "fast";
        if (milliseconds <= 200) return "normal";
        return "slow";
    }
}
