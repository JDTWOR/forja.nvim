import unittest

from solution import inventory_report, merge_inventory, most_stocked_sku, total_units


class PublicTests(unittest.TestCase):
    def test_total_and_empty(self):
        self.assertEqual(total_units({"tea": 4, "coffee": 2}), 6)
        self.assertEqual(total_units({}), 0)

    def test_most_stocked_and_tie(self):
        self.assertEqual(most_stocked_sku({"tea": 4, "coffee": 2}), "tea")
        self.assertEqual(most_stocked_sku({"z": 3, "a": 3}), "z")
        self.assertIsNone(most_stocked_sku({}))

    def test_merge_does_not_mutate_inputs(self):
        current = {"tea": 4}
        received = {"tea": 2, "coffee": 5}
        self.assertEqual(merge_inventory(current, received), {"tea": 6, "coffee": 5})
        self.assertEqual(current, {"tea": 4})
        self.assertEqual(received, {"tea": 2, "coffee": 5})

    def test_report_sorts_by_quantity_then_sku(self):
        self.assertEqual(inventory_report({"z": 2, "a": 4, "b": 4}), [("a", 4), ("b", 4), ("z", 2)])


if __name__ == "__main__":
    unittest.main()
