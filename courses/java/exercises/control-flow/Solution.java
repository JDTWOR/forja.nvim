public class Solution {
    public static int shippingCost(int grams, boolean express) {
        if (grams < 0) return -1;
        int base;
        if (grams <= 500) {
            base = 500;
        } else if (grams <= 2_000) {
            base = 1_200;
        } else {
            base = 2_500;
        }
        return express ? base + 700 : base;
    }

    public static String scoreLabel(int score) {
        if (score < 0 || score > 100) return "invalid";
        if (score >= 90) return "excellent";
        if (score >= 60) return "passing";
        return "retry";
    }

    public static String scoreLabelOrMissing(Integer score) {
        if (score == null) return "missing";
        return scoreLabel(score.intValue());
    }
}
