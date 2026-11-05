pub fn shipping_cost(weight_grams: u32, express: bool) -> u32 {
    let base = if weight_grams <= 500 {
        500
    } else if weight_grams <= 2000 {
        1000
    } else {
        2500
    };
    if express { base + 700 } else { base }
}

pub fn score_band(score: u8) -> &'static str {
    if score >= 90 {
        "excellent"
    } else if score >= 60 {
        "passing"
    } else {
        "retry"
    }
}

pub fn score_band_optional(score: Option<u8>) -> &'static str {
    match score {
        None => "missing",
        Some(value) if value >= 90 => "excellent",
        Some(value) if value >= 60 => "passing",
        Some(_) => "retry",
    }
}
