use forja_primitive_types::{can_reserve_seats, can_reserve_with_buffer, mean_temperature};

#[test]
fn checks_capacity_and_maintenance() {
    assert!(can_reserve_seats(8, 5, false));
    assert!(!can_reserve_seats(8, 9, false));
    assert!(!can_reserve_seats(8, 1, true));
}

#[test]
fn preserves_fractional_mean() {
    assert_eq!(mean_temperature(10.0, 13.0), 11.5);
}

#[test]
fn transfer_keeps_a_buffer_without_u8_overflow() {
    assert!(can_reserve_with_buffer(12, 8, 4, false));
    assert!(!can_reserve_with_buffer(12, 9, 4, false));
    assert!(!can_reserve_with_buffer(u8::MAX, u8::MAX, 1, false));
}
