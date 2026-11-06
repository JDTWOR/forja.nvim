public class Solution {
    public static int addFee(int subtotalCents, int feeCents) {
        int totalCents = subtotalCents;
        totalCents += feeCents;
        return totalCents;
    }

    public static int discountThenTax(int subtotalCents, int discountPercent, int taxPercent) {
        long discountCents = (long) subtotalCents * discountPercent / 100;
        long discountedCents = subtotalCents - discountCents;
        long taxCents = discountedCents * taxPercent / 100;
        return Math.toIntExact(discountedCents + taxCents);
    }

    public static int taxThenDiscount(int subtotalCents, int discountPercent, int taxPercent) {
        long taxCents = (long) subtotalCents * taxPercent / 100;
        long taxedCents = subtotalCents + taxCents;
        long discountCents = taxedCents * discountPercent / 100;
        return Math.toIntExact(taxedCents - discountCents);
    }
}
