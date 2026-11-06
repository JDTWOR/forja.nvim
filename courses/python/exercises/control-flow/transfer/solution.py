def retry_delay_seconds(failed_attempts: int, retry_after_seconds: int | None = None) -> int:
    if failed_attempts <= 0:
        return 0

    backoff = 30 if failed_attempts >= 6 else 2 ** (failed_attempts - 1)
    server_hint = max(0, retry_after_seconds or 0)
    return min(60, max(backoff, server_hint))
