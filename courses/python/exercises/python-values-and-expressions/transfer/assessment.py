import contextlib
import io
import runpy
import unittest


class TestForjaAssessment(unittest.TestCase):
    def test_checks_hour_conversion(self):
        output = io.StringIO()
        with contextlib.redirect_stdout(output):
            runpy.run_path("solution.py")
        self.assertEqual(output.getvalue(), '7200\n')


if __name__ == "__main__":
    unittest.main()
