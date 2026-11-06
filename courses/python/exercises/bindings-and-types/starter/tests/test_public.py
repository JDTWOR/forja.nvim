import unittest

from solution import calculate_subtotal, format_item_line, has_sufficient_stock


class PublicTests(unittest.TestCase):
    def test_subtotal_uses_integer_cents(self):
        self.assertEqual(calculate_subtotal(3, 275), 825)
        self.assertEqual(calculate_subtotal(0, 999), 0)

    def test_stock_boundary(self):
        self.assertTrue(has_sufficient_stock(4, 4))
        self.assertTrue(has_sufficient_stock(0, 4))
        self.assertFalse(has_sufficient_stock(5, 4))
        self.assertFalse(has_sufficient_stock(-1, 4))

    def test_item_line(self):
        self.assertEqual(format_item_line("tea", 2, 350), "tea x2: 700 cents")


if __name__ == "__main__":
    unittest.main()
