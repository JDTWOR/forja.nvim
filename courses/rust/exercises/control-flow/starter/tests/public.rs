use forja_control_flow::{score_band, score_band_optional, shipping_cost};

#[test]
fn prices_weight_ranges_and_express() {
    assert_eq!(shipping_cost(500, false), 500);
    assert_eq!(shipping_cost(501, true), 1700);
}

#[test]
fn classifies_scores() {
    assert_eq!(score_band(90), "excellent");
    assert_eq!(score_band(60), "passing");
    assert_eq!(score_band(59), "retry");
}

#[test]
fn transfer_matches_absence_and_score_ranges() {
    assert_eq!(score_band_optional(None), "missing");
    assert_eq!(score_band_optional(Some(90)), "excellent");
    assert_eq!(score_band_optional(Some(60)), "passing");
    assert_eq!(score_band_optional(Some(0)), "retry");
}
