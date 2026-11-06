public class Solution {
    public static int percentageOf(int amountCents, int ratePercent) {
        return Math.toIntExact((long) amountCents * ratePercent / 100);
    }

    public static int checkoutTotal(int subtotalCents, int discountPercent, int taxPercent) {
        int discount = percentageOf(subtotalCents, discountPercent);
        int discounted = subtotalCents - discount;
        return Math.addExact(discounted, percentageOf(discounted, taxPercent));
    }

    public static int readingMinutes(int words, int wordsPerMinute) {
        if (words < 0 || wordsPerMinute <= 0) return -1;
        int quotient = words / wordsPerMinute;
        int remainder = words % wordsPerMinute;
        return quotient + (remainder == 0 ? 0 : 1);
    }
}
