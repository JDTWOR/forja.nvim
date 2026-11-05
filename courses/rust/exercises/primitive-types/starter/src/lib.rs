/// Return whether a requested number of seats fits outside maintenance mode.
pub fn can_reserve_seats(available: u8, requested: u8, maintenance_mode: bool) -> bool {
    todo!("Combine the scalar values into a boolean result")
}

/// Return the arithmetic mean without discarding fractional precision.
pub fn mean_temperature(first_celsius: f64, second_celsius: f64) -> f64 {
    todo!("Keep the calculation in f64")
}

/// Keep a requested seat count and a safety buffer available.
pub fn can_reserve_with_buffer(
    available: u8,
    requested: u8,
    reserve: u8,
    maintenance_mode: bool,
) -> bool {
    todo!("Compare the total capacity without overflowing u8")
}
