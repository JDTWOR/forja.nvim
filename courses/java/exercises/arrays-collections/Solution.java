import java.util.ArrayList;
import java.util.LinkedHashSet;
import java.util.List;
import java.util.Map;
import java.util.HashMap;

public class Solution {
    public static long sum(int[] values) {
        if (values == null) return 0L;
        long total = 0L;
        for (int value : values) total += value;
        return total;
    }

    public static List<String> uniqueInOrder(List<String> values) {
        if (values == null) return new ArrayList<>();
        LinkedHashSet<String> unique = new LinkedHashSet<>();
        for (String value : values) if (value != null) unique.add(value);
        return new ArrayList<>(unique);
    }

    public static Map<String, Integer> wordCounts(List<String> values) {
        Map<String, Integer> counts = new HashMap<>();
        if (values == null) return counts;
        for (String value : values) {
            if (value != null) counts.merge(value, 1, Integer::sum);
        }
        return counts;
    }
}
