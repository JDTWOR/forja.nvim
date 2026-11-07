import contextlib
import io
import runpy
import unittest


class TestForjaAssessment(unittest.TestCase):
    def test_output_is_a_calculated_number(self):
        output = io.StringIO()
        with contextlib.redirect_stdout(output):
            runpy.run_path("solution.py")
        self.assertEqual(output.getvalue(), "180\n")


if __name__ == "__main__":
    unittest.main()
