import unittest

from solution import break_minutes, segment_minutes, trip_minutes


class TestForjaAssessment(unittest.TestCase):
    def test_each_fractional_segment_rounds_independently(self):
        self.assertEqual(trip_minutes([(0.1, 60), (0.1, 60)], 0, 5), 2)

    def test_empty_trip_can_still_have_a_break(self):
        self.assertEqual(trip_minutes([], 2, 7), 14)

    def test_multiple_helpers(self):
        self.assertEqual(segment_minutes(2.5, 30), 5)
        self.assertEqual(break_minutes(3, 4), 12)
