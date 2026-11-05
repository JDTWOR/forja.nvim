pub fn can_reserve_seats(available: u8, requested: u8, maintenance_mode: bool) -> bool {
    !maintenance_mode && requested <= available
}

pub fn mean_temperature(first_celsius: f64, second_celsius: f64) -> f64 {
    (first_celsius + second_celsius) / 2.0
}

pub fn can_reserve_with_buffer(
    available: u8,
    requested: u8,
    reserve: u8,
    maintenance_mode: bool,
) -> bool {
    !maintenance_mode
        && u16::from(available) >= u16::from(requested) + u16::from(reserve)
}
