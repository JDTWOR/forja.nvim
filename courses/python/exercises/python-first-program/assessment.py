import contextlib
import io
import runpy
import unittest


class TestForjaAssessment(unittest.TestCase):
    def test_greeting_is_exact_and_has_one_line(self):
        output = io.StringIO()
        with contextlib.redirect_stdout(output):
            runpy.run_path("solution.py")
        self.assertEqual(output.getvalue(), "Hola, mundo\n")


if __name__ == "__main__":
    unittest.main()
