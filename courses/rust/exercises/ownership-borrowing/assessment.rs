use forja_ownership_borrowing::{first_non_empty_line, normalized_tag, prefix_by_chars};

#[test]
fn assessment_normalization_collapses_whitespace() {
    assert_eq!(normalized_tag(String::from("  Rust\tBorrowing\n")), "rust-borrowing");
    assert_eq!(normalized_tag(String::new()), "");
}

#[test]
fn assessment_borrowed_result_and_empty_input() {
    let text = String::from(" \n  ownership\n borrowing");
    let result = first_non_empty_line(&text);
    assert_eq!(result, Some("ownership"));
    assert_eq!(text.lines().count(), 3);
    assert_eq!(first_non_empty_line(" \n\t\n"), None);
}

#[test]
fn assessment_unicode_prefix_uses_character_boundaries() {
    assert_eq!(prefix_by_chars("🦀rust", 1), "🦀");
    assert_eq!(prefix_by_chars("🦀rust", usize::MAX), "🦀rust");
}
