use forja_transfer_branches::classify_latency;

#[test]
fn classifies_latency_boundaries() {
    assert_eq!(classify_latency(50), "fast");
    assert_eq!(classify_latency(51), "normal");
    assert_eq!(classify_latency(200), "normal");
    assert_eq!(classify_latency(201), "slow");
}
