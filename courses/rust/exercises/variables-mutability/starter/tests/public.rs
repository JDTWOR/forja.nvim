use forja_variables_mutability::{add_fee, final_price, final_price_tax_first};

#[test]
fn adds_a_fee() {
    assert_eq!(add_fee(1200, 300), 1500);
}

#[test]
fn discounts_before_applying_tax() {
    assert_eq!(final_price(10_000, 10, 20), 10_800);
}

#[test]
fn transfer_changes_order_before_rounding() {
    assert_eq!(final_price(10, 33, 50), 10);
    assert_eq!(final_price_tax_first(10, 33, 50), 11);
}
