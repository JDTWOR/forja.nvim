import unittest

from solution import parse_item, parse_price_cents, parse_quantity


class PublicTests(unittest.TestCase):
    def test_positive_quantity_with_whitespace(self):
        self.assertEqual(parse_quantity(" 12 "), 12)
        for invalid in ("", "0", "-1", "1.0", "many"):
            with self.subTest(invalid=invalid):
                with self.assertRaises(ValueError):
                    parse_quantity(invalid)

    def test_prices_are_exact_cents(self):
        self.assertEqual(parse_price_cents("12"), 1200)
        self.assertEqual(parse_price_cents("12.3"), 1230)
        self.assertEqual(parse_price_cents("0.09"), 9)

    def test_item(self):
        self.assertEqual(parse_item(" tea, 3 "), ("tea", 3))


if __name__ == "__main__":
    unittest.main()
