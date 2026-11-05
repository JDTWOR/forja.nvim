/// Normalize a consumed label by trimming it, lowercasing, and joining words with `-`.
pub fn normalized_tag(input: String) -> String {
    todo!("Transform the owned String")
}

/// Return the first non-empty trimmed line as a borrowed string slice.
pub fn first_non_empty_line(text: &str) -> Option<&str> {
    todo!("Return a slice borrowed from the input")
}

/// Copy at most `max_chars` Unicode scalar values from borrowed text.
pub fn prefix_by_chars(text: &str, max_chars: usize) -> String {
    todo!("Read through a borrow and create a safe owned prefix")
}
