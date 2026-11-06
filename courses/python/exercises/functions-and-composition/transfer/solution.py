import math


def segment_minutes(distance_km: float, speed_kph: float) -> int:
    return math.ceil(distance_km * 60 / speed_kph)


def break_minutes(stop_count: int, minutes_per_stop: int) -> int:
    return stop_count * minutes_per_stop


def trip_minutes(
    segments: list[tuple[float, float]],
    stop_count: int,
    minutes_per_stop: int,
) -> int:
    travel = sum(segment_minutes(distance, speed) for distance, speed in segments)
    return travel + break_minutes(stop_count, minutes_per_stop)
