pub fn add_fee(subtotal: u32, fee: u32) -> u32 {
    let mut total = subtotal;
    total += fee;
    total
}

pub fn final_price(subtotal: u32, discount_percent: u8, tax_percent: u8) -> u32 {
    let mut total = subtotal;
    let discount = total * u32::from(discount_percent) / 100;
    total -= discount;
    total += total * u32::from(tax_percent) / 100;
    total
}

pub fn final_price_tax_first(subtotal: u32, discount_percent: u8, tax_percent: u8) -> u32 {
    let mut total = subtotal;
    total += total * u32::from(tax_percent) / 100;
    let discount = total * u32::from(discount_percent) / 100;
    total -= discount;
    total
}
