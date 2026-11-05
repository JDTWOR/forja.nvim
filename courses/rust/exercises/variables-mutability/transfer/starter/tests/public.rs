use forja_transfer_variables::score_after_round;

#[test]
fn applies_penalty_before_bonus() {
    assert_eq!(score_after_round(2, 3, 4), 4);
    assert_eq!(score_after_round(10, 2, 5), 13);
}
