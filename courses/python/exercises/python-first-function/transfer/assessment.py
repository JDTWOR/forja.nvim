import unittest

from solution import minutes_to_seconds


class TestForjaAssessment(unittest.TestCase):
    def test_converts_large_minute_values(self):
        self.assertEqual(minutes_to_seconds(100_000), 6_000_000)

    def test_does_not_print_instead_of_returning(self):
        import contextlib
        import io
        output = io.StringIO()
        with contextlib.redirect_stdout(output):
            result = minutes_to_seconds(2)
        self.assertEqual(result, 120)
        self.assertEqual(output.getvalue(), "")


if __name__ == "__main__":
    unittest.main()
