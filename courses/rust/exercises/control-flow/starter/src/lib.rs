/// Price a parcel by weight and add a fixed surcharge for express delivery.
pub fn shipping_cost(weight_grams: u32, express: bool) -> u32 {
    todo!("Cover every weight range, then apply express delivery: {:?}", (weight_grams, express))
}

/// Classify a score: 90+ is excellent, 60+ passes, otherwise retry.
pub fn score_band(score: u8) -> &'static str {
    todo!("Return the correct band for every score: {:?}", score)
}

/// Classify an optional score, including the case where no score was submitted.
pub fn score_band_optional(score: Option<u8>) -> &'static str {
    todo!("Handle absence and all score bands: {:?}", score)
}
