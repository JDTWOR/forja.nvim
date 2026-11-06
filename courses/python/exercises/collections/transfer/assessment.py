import unittest

from solution import event_counts, rank_events


class TestForjaAssessment(unittest.TestCase):
    def test_empty_events_and_negative_limit(self):
        self.assertEqual(event_counts([]), {})
        self.assertEqual(rank_events([], 5), [])
        self.assertEqual(rank_events(["a"], -1), [])

    def test_case_sensitive_names_and_complete_tie_order(self):
        events = ["A", "a", "b", "a", "b", "A"]
        self.assertEqual(event_counts(events), {"A": 2, "a": 2, "b": 2})
        self.assertEqual(rank_events(events, 2), [("A", 2), ("a", 2)])

    def test_input_list_is_not_modified(self):
        events = ["deploy", "test", "deploy"]
        before = events.copy()
        rank_events(events, 2)
        self.assertEqual(events, before)
