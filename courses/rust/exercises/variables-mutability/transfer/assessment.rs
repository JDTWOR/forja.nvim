use forja_transfer_variables::score_after_round;

#[test]
fn transfer_handles_order_and_saturation() {
    assert_eq!(score_after_round(2, 3, 4), 4);
    assert_eq!(score_after_round(0, u32::MAX, u32::MAX), u32::MAX);
    assert_eq!(score_after_round(u32::MAX, 0, 1), u32::MAX);
}
