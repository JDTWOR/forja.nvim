public class PublicTests {
    private static void check(boolean condition, String label) {
        if (!condition) throw new AssertionError(label);
    }

    public static void main(String[] args) {
        Solution.Wallet wallet = new Solution.Wallet("Ada", 1000);
        check(wallet.owner().equals("Ada"), "owner");
        check(wallet.balanceCents() == 1000, "initial balance");
        check(wallet.deposit(500), "deposit succeeds");
        check(wallet.withdraw(200), "withdraw succeeds");
        check(wallet.balanceCents() == 1300, "updated balance");
        check(!wallet.withdraw(2000), "cannot overdraw");
        check(wallet.balanceCents() == 1300, "failed withdrawal keeps balance");
    }
}
