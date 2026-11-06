import unittest

from solution import parse_readings


class TestForjaAssessment(unittest.TestCase):
    def test_quoted_identifier_can_contain_comma(self):
        self.assertEqual(parse_readings('"sensor, west", -1.2'), [("sensor, west", -12)])

    def test_rejects_bad_columns_and_empty_identifier_with_line(self):
        for text in ("a,1,extra", ",2.0"):
            with self.subTest(text=text):
                with self.assertRaisesRegex(ValueError, "line 1"):
                    parse_readings(text)

    def test_reports_first_bad_row_and_checks_range(self):
        with self.assertRaisesRegex(ValueError, "line 3"):
            parse_readings("a,0\n\nb,80.1\nc,1")
        with self.assertRaisesRegex(ValueError, "line 1"):
            parse_readings("a,-80.1")

    def test_malformed_csv_is_translated_with_line_number(self):
        with self.assertRaisesRegex(ValueError, "line 1"):
            parse_readings('"unfinished,1')

    def test_empty_document(self):
        self.assertEqual(parse_readings("\n \n"), [])
