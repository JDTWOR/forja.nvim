import contextlib
import io
import runpy
import unittest


class TestForjaAssessment(unittest.TestCase):
    def test_named_calculation_has_expected_result(self):
        output = io.StringIO()
        with contextlib.redirect_stdout(output):
            namespace = runpy.run_path("solution.py")
        self.assertEqual(namespace.get("total_seconds"), 180)
        self.assertEqual(output.getvalue(), "180\n")

    def test_calculation_uses_the_given_named_inputs(self):
        namespace = runpy.run_path("solution.py")
        self.assertEqual(namespace.get("minutes"), 3)
        self.assertEqual(namespace.get("seconds_per_minute"), 60)


if __name__ == "__main__":
    unittest.main()
