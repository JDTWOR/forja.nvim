import unittest

from solution import duration_seconds, format_duration, is_at_least_one_hour


class PublicTests(unittest.TestCase):
    def test_converts_components_to_seconds(self):
        self.assertEqual(duration_seconds(2, 5), 125)
        self.assertEqual(duration_seconds(0, 0), 0)

    def test_hour_boundary(self):
        self.assertFalse(is_at_least_one_hour(59, 59))
        self.assertTrue(is_at_least_one_hour(60, 0))
        self.assertTrue(is_at_least_one_hour(61, 0))

    def test_format_includes_label_and_total(self):
        self.assertEqual(format_duration("run", 2, 5), "run: 125 seconds")


if __name__ == "__main__":
    unittest.main()
