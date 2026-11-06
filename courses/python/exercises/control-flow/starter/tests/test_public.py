import unittest

from solution import shipping_band, shipping_cost


class PublicTests(unittest.TestCase):
    def test_band_boundaries(self):
        self.assertEqual(shipping_band(-1), "invalid")
        self.assertEqual(shipping_band(0), "small")
        self.assertEqual(shipping_band(500), "small")
        self.assertEqual(shipping_band(501), "medium")
        self.assertEqual(shipping_band(2000), "medium")
        self.assertEqual(shipping_band(2001), "large")

    def test_cost_and_express(self):
        self.assertEqual(shipping_cost(300, False), 500)
        self.assertEqual(shipping_cost(300, True), 1250)
        self.assertEqual(shipping_cost(-2, True), 0)


if __name__ == "__main__":
    unittest.main()
