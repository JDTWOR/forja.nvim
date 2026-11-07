import unittest

from solution import double


class PublicTests(unittest.TestCase):
    def test_doubles_positive_integer(self):
        self.assertEqual(double(6), 12)

    def test_doubles_zero(self):
        self.assertEqual(double(0), 0)

    def test_doubles_negative_integer(self):
        self.assertEqual(double(-4), -8)


if __name__ == "__main__":
    unittest.main()
