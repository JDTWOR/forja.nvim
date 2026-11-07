import contextlib
import io
import runpy
import unittest


class PublicTests(unittest.TestCase):
    def test_prints_two_messages_in_order(self):
        output = io.StringIO()
        with contextlib.redirect_stdout(output):
            runpy.run_path("solution.py")
        self.assertEqual(output.getvalue(), 'Hola, Python\nEstoy aprendiendo a programar\n')


if __name__ == "__main__":
    unittest.main()
