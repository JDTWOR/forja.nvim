import contextlib
import io
import runpy
import unittest


class PublicTests(unittest.TestCase):
    def test_uses_named_values_to_calculate_seconds(self):
        output = io.StringIO()
        with contextlib.redirect_stdout(output):
            namespace = runpy.run_path("solution.py")
        self.assertEqual(namespace["minutes"], 3)
        self.assertEqual(namespace["seconds_per_minute"], 60)
        self.assertEqual(namespace["total_seconds"], 180)
        self.assertEqual(output.getvalue(), "180\n")


if __name__ == "__main__":
    unittest.main()
