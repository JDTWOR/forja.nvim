import unittest

from solution import calculate_subtotal, format_item_line, has_sufficient_stock


class TestForjaAssessment(unittest.TestCase):
    def test_large_values_remain_exact(self):
        self.assertEqual(calculate_subtotal(10_000, 12_345), 123_450_000)

    def test_stock_does_not_treat_negative_availability_as_stock(self):
        self.assertFalse(has_sufficient_stock(0, -1))
        self.assertTrue(has_sufficient_stock(0, 0))

    def test_formatting_does_not_round_cents(self):
        self.assertEqual(format_item_line("cable", 3, 199), "cable x3: 597 cents")
        self.assertEqual(format_item_line("empty", 0, 199), "empty x0: 0 cents")
