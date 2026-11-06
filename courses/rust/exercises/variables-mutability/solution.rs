pub fn add_fee(subtotal: u32, fee: u32) -> u32 {
    let mut total = subtotal;
    total += fee;
    total
}
