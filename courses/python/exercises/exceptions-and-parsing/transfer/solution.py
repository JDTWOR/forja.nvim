import csv
import re
from decimal import Decimal, DecimalException


_TEMPERATURE = re.compile(r"[+-]?[0-9]+(?:\.[0-9])?")


def parse_readings(csv_text: str) -> list[tuple[str, int]]:
    readings: list[tuple[str, int]] = []

    for line_number, raw_line in enumerate(csv_text.splitlines(), start=1):
        if not raw_line.strip():
            continue

        try:
            row = next(csv.reader([raw_line], strict=True))
        except csv.Error as error:
            raise ValueError(f"line {line_number}: invalid CSV") from error

        if len(row) != 2:
            raise ValueError(f"line {line_number}: expected sensor_id,temperature")
        sensor_id, raw_temperature = (part.strip() for part in row)
        if not sensor_id:
            raise ValueError(f"line {line_number}: sensor_id must not be empty")
        if not _TEMPERATURE.fullmatch(raw_temperature):
            raise ValueError(f"line {line_number}: invalid temperature")

        try:
            temperature = Decimal(raw_temperature)
            tenths = temperature * 10
            if temperature < Decimal("-80") or temperature > Decimal("80"):
                raise ValueError(f"line {line_number}: temperature is outside -80..80 C")
            if tenths != tenths.to_integral_value():
                raise ValueError(f"line {line_number}: temperature must use whole tenths")
            readings.append((sensor_id, int(tenths)))
        except DecimalException as error:
            raise ValueError(f"line {line_number}: invalid temperature") from error

    return readings
