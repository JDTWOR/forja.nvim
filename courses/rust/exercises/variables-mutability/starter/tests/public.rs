use forja_variables_mutability::add_fee;

#[test]
fn adds_a_fee_to_the_existing_subtotal() {
    assert_eq!(add_fee(1200, 300), 1500);
    assert_eq!(add_fee(0, 7), 7);
}
