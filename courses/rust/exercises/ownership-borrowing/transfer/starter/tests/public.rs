use forja_transfer_borrowing::first_token;

#[test]
fn returns_the_first_borrowed_token() {
    let text = String::from("  borrowed 🦀 token");
    assert_eq!(first_token(&text), Some("borrowed"));
    assert_eq!(text, "  borrowed 🦀 token");
}
