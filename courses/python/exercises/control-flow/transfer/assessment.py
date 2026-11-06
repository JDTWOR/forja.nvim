import unittest

from solution import retry_delay_seconds


class TestForjaAssessment(unittest.TestCase):
    def test_nonpositive_attempts_do_not_schedule_retry(self):
        self.assertEqual(retry_delay_seconds(-2, 40), 0)

    def test_negative_hint_cannot_reduce_backoff(self):
        self.assertEqual(retry_delay_seconds(3, -5), 4)

    def test_backoff_cap_and_global_cap_are_distinct(self):
        self.assertEqual(retry_delay_seconds(6), 30)
        self.assertEqual(retry_delay_seconds(1000), 30)
        self.assertEqual(retry_delay_seconds(1, 59), 59)
        self.assertEqual(retry_delay_seconds(6, 120), 60)
