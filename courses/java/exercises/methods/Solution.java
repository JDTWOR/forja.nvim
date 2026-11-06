public class Solution {
    public static int percentageOf(int amountCents, int ratePercent) {
        if (amountCents < 0 || ratePercent < 0 || ratePercent > 100) {
            throw new IllegalArgumentException("amount or rate is outside the supported range");
        }
        return Math.toIntExact((long) amountCents * ratePercent / 100);
    }

    public static int checkoutTotal(int subtotalCents, int discountPercent, int taxPercent) {
        if (subtotalCents < 0 || discountPercent < 0 || discountPercent > 100
                || taxPercent < 0 || taxPercent > 100) {
            throw new IllegalArgumentException("subtotal or rate is outside the supported range");
        }
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
