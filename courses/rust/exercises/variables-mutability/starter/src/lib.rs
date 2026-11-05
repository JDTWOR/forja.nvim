/// Add a fee to a subtotal using a mutable local binding.
pub fn add_fee(subtotal: u32, fee: u32) -> u32 {
    todo!("Use a mutable binding to add the fee: {:?}", (subtotal, fee))
}

/// Apply a percentage discount, then a percentage tax to the discounted amount.
pub fn final_price(subtotal: u32, discount_percent: u8, tax_percent: u8) -> u32 {
    todo!("Update the running price in the required order: {:?}", (subtotal, discount_percent, tax_percent))
}

/// Apply tax first and then a discount, rounding down at each step.
pub fn final_price_tax_first(subtotal: u32, discount_percent: u8, tax_percent: u8) -> u32 {
    todo!("Change the order and account for integer rounding: {:?}", (subtotal, discount_percent, tax_percent))
}
