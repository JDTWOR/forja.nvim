public class Solution {
    public static final class Wallet {
        private final String owner;
        private int balanceCents;

        public Wallet(String owner, int initialCents) {
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
            return false;
        }

        public boolean withdraw(int cents) {
            return false;
        }
    }
}
