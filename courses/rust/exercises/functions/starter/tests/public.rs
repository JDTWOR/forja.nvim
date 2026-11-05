use forja_functions::{checked_reading_minutes, checkout_total, reading_minutes};

#[test]
fn composes_checkout_calculations() {
    assert_eq!(checkout_total(10_000, 10, 20), 10_800);
}

#[test]
fn rounds_reading_time_upward() {
    assert_eq!(reading_minutes(401, 200), 3);
    assert_eq!(reading_minutes(0, 200), 0);
}

#[test]
fn transfer_represents_invalid_rate_as_absent() {
    assert_eq!(checked_reading_minutes(401, 200), Some(3));
    assert_eq!(checked_reading_minutes(500, 0), None);
}
