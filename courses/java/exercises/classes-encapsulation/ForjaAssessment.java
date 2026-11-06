public class ForjaAssessment {
    private static void check(boolean condition, String label) {
        if (!condition) throw new AssertionError(label);
    }

    private static void throwsIllegalArgument(Runnable action, String label) {
        try {
            action.run();
        } catch (IllegalArgumentException expected) {
            return;
        }
        throw new AssertionError(label + " should throw IllegalArgumentException");
    }

    public static void main(String[] args) {
        throwsIllegalArgument(() -> new Solution.Wallet(" ", 0), "blank owner");
        throwsIllegalArgument(() -> new Solution.Wallet("Ada", -1), "negative initial balance");
        Solution.Wallet wallet = new Solution.Wallet("Lin", Integer.MAX_VALUE - 2);
        check(!wallet.deposit(3), "overflow deposit rejected");
        check(wallet.balanceCents() == Integer.MAX_VALUE - 2, "rejected deposit leaves state intact");
        check(wallet.deposit(2), "boundary deposit accepted");
        check(!wallet.deposit(1), "deposit beyond max rejected");
        check(wallet.withdraw(Integer.MAX_VALUE), "exact full withdrawal accepted");
        check(wallet.balanceCents() == 0, "balance remains nonnegative");
        check(!wallet.withdraw(0), "zero withdrawal rejected");
        check(!wallet.deposit(-1), "negative deposit rejected");
    }
}
