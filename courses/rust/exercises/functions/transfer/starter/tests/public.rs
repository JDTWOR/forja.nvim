use forja_transfer_functions::checked_chunk_count;

#[test]
fn counts_chunks_and_represents_invalid_size() {
    assert_eq!(checked_chunk_count(10, 4), Some(3));
    assert_eq!(checked_chunk_count(0, 4), Some(0));
    assert_eq!(checked_chunk_count(10, 0), None);
}
