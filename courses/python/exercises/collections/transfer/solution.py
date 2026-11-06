def event_counts(events: list[str]) -> dict[str, int]:
    counts: dict[str, int] = {}
    for event in events:
        counts[event] = counts.get(event, 0) + 1
    return counts


def rank_events(events: list[str], limit: int) -> list[tuple[str, int]]:
    if limit <= 0:
        return []
    ranked = sorted(event_counts(events).items(), key=lambda item: (-item[1], item[0]))
    return ranked[:limit]
