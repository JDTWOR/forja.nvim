pub fn score_after_round(starting_points: u32, penalty: u32, bonus: u32) -> u32 {
    let mut score = starting_points;
    score = score.saturating_sub(penalty);
    score = score.saturating_add(bonus);
    score
}
