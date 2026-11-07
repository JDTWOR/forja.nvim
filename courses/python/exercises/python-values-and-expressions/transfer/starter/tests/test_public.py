import contextlib
import io
import runpy
import unittest


class PublicTests(unittest.TestCase):
    def test_converts_two_hours_to_seconds(self):
        output = io.StringIO()
        with contextlib.redirect_stdout(output):
            runpy.run_path("solution.py")
        self.assertEqual(output.getvalue(), '7200\n')


if __name__ == "__main__":
    unittest.main()
