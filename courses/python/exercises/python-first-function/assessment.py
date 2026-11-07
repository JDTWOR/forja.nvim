import unittest

from solution import double


class TestForjaAssessment(unittest.TestCase):
    def test_supports_large_integers(self):
        self.assertEqual(double(10**30), 2 * 10**30)

    def test_returns_a_value_without_printing(self):
        import contextlib
        import io

        output = io.StringIO()
        with contextlib.redirect_stdout(output):
            result = double(7)
        self.assertEqual(result, 14)
        self.assertEqual(output.getvalue(), "")


if __name__ == "__main__":
    unittest.main()
