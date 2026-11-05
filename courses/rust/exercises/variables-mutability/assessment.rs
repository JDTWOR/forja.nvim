use forja_variables_mutability::{add_fee, final_price, final_price_tax_first};

#[test]
fn assessment_fee_and_zero_values() {
    assert_eq!(add_fee(0, 0), 0);
    assert_eq!(add_fee(1, 9), 10);
}

#[test]
fn assessment_order_and_boundaries() {
    assert_eq!(final_price(100, 0, 0), 100);
    assert_eq!(final_price(10_000, 50, 10), 5_500);
}

#[test]
fn assessment_distinguishes_rounding_order() {
    assert_eq!(final_price_tax_first(1, 50, 50), 1);
    assert_eq!(final_price_tax_first(10, 33, 50), 11);
}
