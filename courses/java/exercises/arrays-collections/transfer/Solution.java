import java.util.HashMap;
import java.util.List;
import java.util.Map;

public class Solution {
    public static String mostFrequent(List<String> values) {
        if (values == null || values.isEmpty()) return null;
        Map<String, Integer> counts = new HashMap<>();
        for (String value : values) {
            if (value != null) counts.merge(value, 1, Integer::sum);
        }
        String best = null;
        int bestCount = 0;
        for (String value : values) {
            if (value == null) continue;
            int count = counts.get(value);
            if (count > bestCount) {
                best = value;
                bestCount = count;
            }
        }
        return best;
    }
}
