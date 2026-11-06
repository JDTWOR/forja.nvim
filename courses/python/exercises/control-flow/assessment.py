import unittest

from solution import shipping_band, shipping_cost


class TestForjaAssessment(unittest.TestCase):
    def test_band_extremes(self):
        self.assertEqual(shipping_band(2**31), "large")
        self.assertEqual(shipping_band(-(2**31)), "invalid")

    def test_every_base_price(self):
        self.assertEqual(shipping_cost(500, False), 500)
        self.assertEqual(shipping_cost(501, False), 1000)
        self.assertEqual(shipping_cost(2000, False), 1000)
        self.assertEqual(shipping_cost(2001, False), 2500)

    def test_surcharge_is_independent_of_band(self):
        for weight, base in ((1, 500), (501, 1000), (2001, 2500)):
            with self.subTest(weight=weight):
                self.assertEqual(shipping_cost(weight, True), base + 750)
