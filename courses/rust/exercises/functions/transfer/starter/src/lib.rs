/// Return the number of chunks needed, or None if chunk_size is zero.
pub fn checked_chunk_count(items: usize, chunk_size: usize) -> Option<usize> {
    todo!("Compose a safe ceiling division with an explicit invalid-input result: {:?}", (items, chunk_size))
}
