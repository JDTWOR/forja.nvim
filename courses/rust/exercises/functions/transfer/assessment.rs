use forja_transfer_functions::checked_chunk_count;

#[test]
fn transfer_covers_ceiling_division_edges() {
    assert_eq!(checked_chunk_count(usize::MAX, usize::MAX), Some(1));
    assert_eq!(checked_chunk_count(usize::MAX, 1), Some(usize::MAX));
    assert_eq!(checked_chunk_count(5, 2), Some(3));
    assert_eq!(checked_chunk_count(5, 0), None);
}
