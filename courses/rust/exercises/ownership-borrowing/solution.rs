pub fn normalized_tag(input: String) -> String {
    input
        .split_whitespace()
        .map(str::to_lowercase)
        .collect::<Vec<_>>()
        .join("-")
}

pub fn first_non_empty_line(text: &str) -> Option<&str> {
    text.lines().map(str::trim).find(|line| !line.is_empty())
}

pub fn prefix_by_chars(text: &str, max_chars: usize) -> String {
    text.chars().take(max_chars).collect()
}
