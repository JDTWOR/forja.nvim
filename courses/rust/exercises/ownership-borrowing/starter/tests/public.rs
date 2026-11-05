use forja_ownership_borrowing::{first_non_empty_line, normalized_tag, prefix_by_chars};

#[test]
fn normalizes_owned_input() {
    assert_eq!(normalized_tag(String::from("  Rust Ownership  ")), "rust-ownership");
}

#[test]
fn borrows_the_first_non_empty_line() {
    let text = String::from("\n  borrow me  \nnext");
    assert_eq!(first_non_empty_line(&text), Some("borrow me"));
    assert_eq!(text, "\n  borrow me  \nnext");
}

#[test]
fn transfer_truncates_unicode_without_breaking_utf8() {
    assert_eq!(prefix_by_chars("a🦀b", 2), "a🦀");
    assert_eq!(prefix_by_chars("Rust", 0), "");
}
