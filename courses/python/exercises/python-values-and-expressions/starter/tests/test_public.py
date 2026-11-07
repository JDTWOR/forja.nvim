import contextlib
import io
import runpy
import unittest


class PublicTests(unittest.TestCase):
    def test_displays_seconds_in_three_minutes(self):
        output = io.StringIO()
        with contextlib.redirect_stdout(output):
            runpy.run_path("solution.py")
        self.assertEqual(output.getvalue(), "180\n")


if __name__ == "__main__":
    unittest.main()
