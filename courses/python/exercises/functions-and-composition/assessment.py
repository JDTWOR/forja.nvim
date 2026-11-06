import unittest

from solution import checkout_total, discount_cents, tax_cents


class TestForjaAssessment(unittest.TestCase):
    def test_fractional_cent_results_use_floor_division(self):
        self.assertEqual(discount_cents(199, 10), 19)
        self.assertEqual(tax_cents(181, 8), 14)

    def test_tax_is_based_on_discounted_subtotal(self):
        self.assertEqual(checkout_total(999, 12, 7), 941)
        self.assertNotEqual(checkout_total(999, 12, 7), 999 + tax_cents(999, 7) - discount_cents(999, 12))

    def test_zero_rates(self):
        self.assertEqual(checkout_total(12345, 0, 0), 12345)
