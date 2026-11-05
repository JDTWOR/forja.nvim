pub fn checked_chunk_count(items: usize, chunk_size: usize) -> Option<usize> {
    if chunk_size == 0 {
        return None;
    }
    let whole = items / chunk_size;
    let partial = usize::from(items % chunk_size != 0);
    Some(whole + partial)
}
