def duration_seconds(minutes: int, seconds: int) -> int:
    return minutes * 60 + seconds


def is_at_least_one_hour(minutes: int, seconds: int) -> bool:
    return duration_seconds(minutes, seconds) >= 3600


def format_duration(label: str, minutes: int, seconds: int) -> str:
    total = duration_seconds(minutes, seconds)
    return f"{label}: {total} seconds"
