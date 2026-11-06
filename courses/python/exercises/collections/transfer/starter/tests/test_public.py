import unittest

from solution import event_counts, rank_events


class PublicTests(unittest.TestCase):
    def test_counts_duplicates(self):
        self.assertEqual(event_counts(["open", "close", "open"]), {"open": 2, "close": 1})

    def test_ranking_and_tie_break(self):
        self.assertEqual(
            rank_events(["z", "a", "z", "a", "m"], 3),
            [("a", 2), ("z", 2), ("m", 1)],
        )

    def test_limit(self):
        self.assertEqual(rank_events(["x", "y"], 1), [("x", 1)])
        self.assertEqual(rank_events(["x"], 0), [])


if __name__ == "__main__":
    unittest.main()
