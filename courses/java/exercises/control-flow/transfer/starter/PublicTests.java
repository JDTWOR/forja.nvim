public class PublicTests {
    private static void equal(String expected, String actual, String label) {
        if (!expected.equals(actual)) throw new AssertionError(label + ": expected " + expected + ", got " + actual);
    }

    public static void main(String[] args) {
        equal("fast", Solution.classifyLatency(0), "zero latency");
        equal("fast", Solution.classifyLatency(50), "fast boundary");
        equal("normal", Solution.classifyLatency(120), "ordinary latency");
        equal("slow", Solution.classifyLatency(201), "slow range");
    }
}
