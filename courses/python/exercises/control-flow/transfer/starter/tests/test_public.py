import unittest

from solution import retry_delay_seconds


class PublicTests(unittest.TestCase):
    def test_no_retry_and_exponential_backoff(self):
        self.assertEqual(retry_delay_seconds(0), 0)
        self.assertEqual(retry_delay_seconds(1), 1)
        self.assertEqual(retry_delay_seconds(4), 8)

    def test_server_hint_and_caps(self):
        self.assertEqual(retry_delay_seconds(2, 10), 10)
        self.assertEqual(retry_delay_seconds(5, 2), 16)
        self.assertEqual(retry_delay_seconds(8, 100), 60)


if __name__ == "__main__":
    unittest.main()
