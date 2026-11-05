use forja_transfer_branches::classify_latency;

#[test]
fn transfer_classifies_all_edges() {
    assert_eq!(classify_latency(0), "fast");
    assert_eq!(classify_latency(50), "fast");
    assert_eq!(classify_latency(51), "normal");
    assert_eq!(classify_latency(200), "normal");
    assert_eq!(classify_latency(201), "slow");
    assert_eq!(classify_latency(u32::MAX), "slow");
}
