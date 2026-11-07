import contextlib
import io
import runpy
import unittest


class PublicTests(unittest.TestCase):
    def test_prints_the_required_greeting(self):
        output = io.StringIO()
        with contextlib.redirect_stdout(output):
            runpy.run_path("solution.py")
        self.assertEqual(output.getvalue(), "Hola, mundo\n")


if __name__ == "__main__":
    unittest.main()
