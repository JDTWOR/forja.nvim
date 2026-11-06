import unittest

from solution import calculate_subtotal, format_item_line


class TestForjaAssessment(unittest.TestCase):
    def test_large_values_remain_exact(self):
        self.assertEqual(calculate_subtotal(10_000, 12_345), 123_450_000)

    def test_formatting_does_not_round_cents(self):
        self.assertEqual(format_item_line("cable", 3, 199), "cable x3: 597 cents")
        self.assertEqual(format_item_line("empty", 0, 199), "empty x0: 0 cents")
