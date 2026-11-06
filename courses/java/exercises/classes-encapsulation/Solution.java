public class Solution {
    public static final class Wallet {
        private final String owner;
        private int balanceCents;

        public Wallet(String owner, int initialCents) {
            if (owner == null || owner.isBlank()) throw new IllegalArgumentException("owner must not be blank");
            if (initialCents < 0) throw new IllegalArgumentException("initial balance must not be negative");
            this.owner = owner;
            this.balanceCents = initialCents;
        }

        public String owner() {
            return owner;
        }

        public int balanceCents() {
            return balanceCents;
        }

        public boolean deposit(int cents) {
            if (cents <= 0 || cents > Integer.MAX_VALUE - balanceCents) return false;
            balanceCents += cents;
            return true;
        }

        public boolean withdraw(int cents) {
            if (cents <= 0 || cents > balanceCents) return false;
            balanceCents -= cents;
            return true;
        }
    }
}
