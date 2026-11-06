import unittest

from solution import parse_readings


class PublicTests(unittest.TestCase):
    def test_parses_signed_temperatures_as_tenths(self):
        self.assertEqual(
            parse_readings("north,12.3\nsouth,-4.5\n"),
            [("north", 123), ("south", -45)],
        )

    def test_ignores_blank_lines_and_trims_fields(self):
        self.assertEqual(parse_readings("  \n station-a , 0.7 \n"), [("station-a", 7)])

    def test_error_has_physical_line_number(self):
        with self.assertRaisesRegex(ValueError, "line 2"):
            parse_readings("north,10\n south,1.25\n")


if __name__ == "__main__":
    unittest.main()
