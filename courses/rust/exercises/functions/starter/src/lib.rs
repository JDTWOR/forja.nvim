/// Apply a percentage discount and then tax to the discounted cents amount.
pub fn checkout_total(subtotal_cents: u32, discount_percent: u8, tax_percent: u8) -> u32 {
    todo!("Decompose the calculation into clear functions: {:?}", (subtotal_cents, discount_percent, tax_percent))
}

/// Estimate reading time in minutes, rounding any partial minute upward.
/// A zero words-per-minute rate returns zero.
pub fn reading_minutes(word_count: u32, words_per_minute: u32) -> u32 {
    todo!("Handle the zero rate and round upward without floating point: {:?}", (word_count, words_per_minute))
}

/// Return None for an invalid zero rate, or the rounded reading duration.
pub fn checked_reading_minutes(word_count: u32, words_per_minute: u32) -> Option<u32> {
    todo!("Represent the zero-rate case in the return type: {:?}", (word_count, words_per_minute))
}
