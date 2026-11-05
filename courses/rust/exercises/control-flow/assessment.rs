use forja_control_flow::{score_band, score_band_optional, shipping_cost};

#[test]
fn assessment_covers_weight_boundaries() {
    assert_eq!(shipping_cost(0, false), 500);
    assert_eq!(shipping_cost(2000, false), 1000);
    assert_eq!(shipping_cost(2001, false), 2500);
    assert_eq!(shipping_cost(2001, true), 3200);
}

#[test]
fn assessment_covers_score_extremes() {
    assert_eq!(score_band(0), "retry");
    assert_eq!(score_band(100), "excellent");
}

#[test]
fn assessment_handles_optional_boundary_values() {
    assert_eq!(score_band_optional(Some(89)), "passing");
    assert_eq!(score_band_optional(Some(255)), "excellent");
    assert_eq!(score_band_optional(None), "missing");
}
