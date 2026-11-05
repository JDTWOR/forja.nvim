use forja_primitive_types::{can_reserve_seats, can_reserve_with_buffer, mean_temperature};

#[test]
fn assessment_checks_exact_capacity_and_zero() {
    assert!(can_reserve_seats(0, 0, false));
    assert!(can_reserve_seats(4, 4, false));
    assert!(!can_reserve_seats(4, 4, true));
}

#[test]
fn assessment_keeps_negative_fractional_means() {
    assert_eq!(mean_temperature(-2.5, 1.0), -0.75);
}

#[test]
fn assessment_buffer_boundaries_do_not_overflow() {
    assert!(can_reserve_with_buffer(255, 200, 55, false));
    assert!(!can_reserve_with_buffer(255, 255, 1, false));
    assert!(!can_reserve_with_buffer(255, 0, 0, true));
}
