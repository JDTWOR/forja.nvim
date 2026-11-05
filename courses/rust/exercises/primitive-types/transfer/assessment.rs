use forja_transfer_primitives::sensor_mean;

#[test]
fn transfer_handles_signed_extremes_and_fractional_results() {
    assert_eq!(sensor_mean(i16::MAX, i16::MAX), f64::from(i16::MAX));
    assert_eq!(sensor_mean(i16::MIN, i16::MAX), -0.5);
    assert_eq!(sensor_mean(0, 1), 0.5);
}
