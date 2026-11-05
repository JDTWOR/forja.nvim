pub fn first_token(text: &str) -> Option<&str> {
    text.split_whitespace().next()
}
