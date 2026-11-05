use forja_transfer_primitives::sensor_mean;

#[test]
fn keeps_fractional_sensor_means() {
    assert_eq!(sensor_mean(10, 13), 11.5);
    assert_eq!(sensor_mean(-3, -2), -2.5);
}
