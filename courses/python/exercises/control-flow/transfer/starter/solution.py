def retry_delay_seconds(failed_attempts: int, retry_after_seconds: int | None = None) -> int:
    # TODO: apply exponential backoff, an optional server hint, and the global cap.
    pass
