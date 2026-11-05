fn discounted_amount(subtotal: u32, percent: u8) -> u32 {
    subtotal * (100 - u32::from(percent)) / 100
}

fn add_tax(amount: u32, percent: u8) -> u32 {
    amount + amount * u32::from(percent) / 100
}

pub fn checkout_total(subtotal_cents: u32, discount_percent: u8, tax_percent: u8) -> u32 {
    let discounted = discounted_amount(subtotal_cents, discount_percent);
    add_tax(discounted, tax_percent)
}

pub fn reading_minutes(word_count: u32, words_per_minute: u32) -> u32 {
    if words_per_minute == 0 {
        return 0;
    }
    let whole_minutes = word_count / words_per_minute;
    let has_partial_minute = word_count % words_per_minute != 0;
    whole_minutes + u32::from(has_partial_minute)
}

pub fn checked_reading_minutes(word_count: u32, words_per_minute: u32) -> Option<u32> {
    if words_per_minute == 0 {
        return None;
    }
    let whole_minutes = word_count / words_per_minute;
    let has_partial_minute = word_count % words_per_minute != 0;
    Some(whole_minutes + u32::from(has_partial_minute))
}
