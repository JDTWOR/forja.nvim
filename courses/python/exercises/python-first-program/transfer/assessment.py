import contextlib
import io
import runpy
import unittest


class TestForjaAssessment(unittest.TestCase):
    def test_checks_exact_two_line_output(self):
        output = io.StringIO()
        with contextlib.redirect_stdout(output):
            runpy.run_path("solution.py")
        self.assertEqual(output.getvalue(), 'Hola, Python\nEstoy aprendiendo a programar\n')


if __name__ == "__main__":
    unittest.main()
