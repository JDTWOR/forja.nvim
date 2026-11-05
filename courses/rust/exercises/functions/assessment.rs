use forja_functions::{checked_reading_minutes, checkout_total, reading_minutes};

#[test]
fn assessment_checkout_boundaries() {
    assert_eq!(checkout_total(100, 0, 0), 100);
    assert_eq!(checkout_total(10_000, 50, 10), 5500);
}

#[test]
fn assessment_reading_rounding_and_zero_rate() {
    assert_eq!(reading_minutes(400, 200), 2);
    assert_eq!(reading_minutes(401, 200), 3);
    assert_eq!(reading_minutes(500, 0), 0);
}

#[test]
fn assessment_checked_duration_boundaries() {
    assert_eq!(checked_reading_minutes(0, 200), Some(0));
    assert_eq!(checked_reading_minutes(u32::MAX, 1), Some(u32::MAX));
    assert_eq!(checked_reading_minutes(u32::MAX, 0), None);
}
