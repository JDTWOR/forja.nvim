pub fn sensor_mean(first: i16, second: i16) -> f64 {
    (f64::from(first) + f64::from(second)) / 2.0
}
