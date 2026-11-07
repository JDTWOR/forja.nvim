import unittest

from solution import minutes_to_seconds


class PublicTests(unittest.TestCase):
    def test_converts_positive_minutes(self):
        self.assertEqual(minutes_to_seconds(3), 180)

    def test_converts_zero(self):
        self.assertEqual(minutes_to_seconds(0), 0)


if __name__ == "__main__":
    unittest.main()
