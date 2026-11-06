public class ForjaAssessment {
    private static void equal(String expected, String actual, String label) {
        if (!expected.equals(actual)) throw new AssertionError(label + ": expected " + expected + ", got " + actual);
    }

    public static void main(String[] args) {
        equal("invalid", Solution.classifyLatency(-1), "negative latency");
        equal("fast", Solution.classifyLatency(50), "inclusive fast maximum");
        equal("normal", Solution.classifyLatency(51), "normal minimum");
        equal("normal", Solution.classifyLatency(200), "inclusive normal maximum");
        equal("slow", Solution.classifyLatency(Integer.MAX_VALUE), "maximum latency");
    }
}
