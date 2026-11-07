import contextlib
import io
import runpy
import unittest


class TestForjaAssessment(unittest.TestCase):
    def test_checks_quantity_times_unit_price(self):
        output = io.StringIO()
        with contextlib.redirect_stdout(output):
            runpy.run_path("solution.py")
        self.assertEqual(output.getvalue(), '500\n')


if __name__ == "__main__":
    unittest.main()
