import unittest

from solution import checkout_total, discount_cents, tax_cents


class PublicTests(unittest.TestCase):
    def test_discount_and_tax(self):
        self.assertEqual(discount_cents(10_000, 15), 1_500)
        self.assertEqual(tax_cents(8_500, 10), 850)

    def test_checkout_composes_in_order(self):
        self.assertEqual(checkout_total(10_000, 15, 10), 9_350)
        self.assertEqual(checkout_total(1, 100, 10), 0)


if __name__ == "__main__":
    unittest.main()
