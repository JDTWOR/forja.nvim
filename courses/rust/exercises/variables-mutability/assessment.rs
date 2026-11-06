use forja_variables_mutability::add_fee;

#[test]
fn assessment_fee_and_boundary_values() {
    assert_eq!(add_fee(0, 0), 0);
    assert_eq!(add_fee(1, 9), 10);
    assert_eq!(add_fee(u32::MAX - 1, 1), u32::MAX);
}
