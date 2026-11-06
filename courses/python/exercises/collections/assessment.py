import unittest

from solution import inventory_report, merge_inventory, most_stocked_sku, total_units


class TestForjaAssessment(unittest.TestCase):
    def test_merging_new_and_existing_keys(self):
        self.assertEqual(merge_inventory({}, {"x": 2}), {"x": 2})
        self.assertEqual(merge_inventory({"x": 2}, {}), {"x": 2})

    def test_tie_rule_is_stable(self):
        self.assertEqual(most_stocked_sku({"a": 5, "b": 5, "c": 1}), "b")

    def test_results_are_independent_objects(self):
        current = {"a": 1}
        merged = merge_inventory(current, {"b": 2})
        self.assertIsNot(merged, current)
        merged["a"] = 99
        self.assertEqual(current["a"], 1)
        self.assertEqual(total_units({"negative": -1, "positive": 3}), 2)

    def test_report_handles_empty_and_tied_inventory(self):
        self.assertEqual(inventory_report({}), [])
        self.assertEqual(inventory_report({"b": 0, "a": 0}), [("a", 0), ("b", 0)])
