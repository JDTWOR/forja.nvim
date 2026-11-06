import unittest

from solution import parse_item, parse_price_cents, parse_quantity


class TestForjaAssessment(unittest.TestCase):
    def test_large_prices_remain_exact_without_float_rounding(self):
        self.assertEqual(parse_price_cents("123456789012345678901234567890.12"), 12345678901234567890123456789012)

    def test_invalid_prices_raise_value_error(self):
        for invalid in ("", "-1.00", "1.234", "1e2", "one"):
            with self.subTest(invalid=invalid):
                with self.assertRaises(ValueError):
                    parse_price_cents(invalid)

    def test_quantity_does_not_accept_signed_or_decimal_syntax(self):
        for invalid in ("+2", "2.0", "2_0", "  "):
            with self.subTest(invalid=invalid):
                with self.assertRaises(ValueError):
                    parse_quantity(invalid)

    def test_item_rejects_missing_parts(self):
        for invalid in ("tea", ",2", "tea,0", "tea,-2"):
            with self.subTest(invalid=invalid):
                with self.assertRaises(ValueError):
                    parse_item(invalid)
