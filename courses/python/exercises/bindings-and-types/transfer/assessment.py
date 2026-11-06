import unittest

from solution import duration_seconds, format_duration, is_at_least_one_hour


class TestForjaAssessment(unittest.TestCase):
    def test_seconds_are_added_to_minutes(self):
        self.assertEqual(duration_seconds(3, 75), 255)

    def test_threshold_is_inclusive(self):
        self.assertTrue(is_at_least_one_hour(0, 3600))
        self.assertFalse(is_at_least_one_hour(0, 3599))

    def test_format_preserves_the_label(self):
        self.assertEqual(format_duration("focus block", 1, 30), "focus block: 90 seconds")
