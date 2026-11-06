import unittest

from solution import break_minutes, segment_minutes, trip_minutes


class PublicTests(unittest.TestCase):
    def test_rounds_up_each_segment(self):
        self.assertEqual(segment_minutes(1, 60), 1)
        self.assertEqual(segment_minutes(3, 60), 3)

    def test_break_time(self):
        self.assertEqual(break_minutes(2, 10), 20)

    def test_composes_travel_and_breaks(self):
        self.assertEqual(trip_minutes([(3, 60), (6, 60)], 1, 10), 19)


if __name__ == "__main__":
    unittest.main()
