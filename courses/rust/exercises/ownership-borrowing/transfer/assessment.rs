use forja_transfer_borrowing::first_token;

#[test]
fn transfer_handles_empty_whitespace_and_unicode_tokens() {
    let text = String::from("\n  🦀Rust token");
    assert_eq!(first_token(&text), Some("🦀Rust"));
    assert_eq!(text, "\n  🦀Rust token");
    assert_eq!(first_token(" \t\n"), None);
}
