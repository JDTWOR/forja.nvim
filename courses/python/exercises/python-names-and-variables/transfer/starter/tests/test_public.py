import contextlib
import io
import runpy
import unittest


class PublicTests(unittest.TestCase):
    def test_calculates_and_names_a_subtotal(self):
        output = io.StringIO()
        with contextlib.redirect_stdout(output):
            runpy.run_path("solution.py")
        self.assertEqual(output.getvalue(), '500\n')


if __name__ == "__main__":
    unittest.main()
