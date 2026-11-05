pub fn classify_latency(milliseconds: u32) -> &'static str {
    if milliseconds <= 50 {
        "fast"
    } else if milliseconds <= 200 {
        "normal"
    } else {
        "slow"
    }
}
