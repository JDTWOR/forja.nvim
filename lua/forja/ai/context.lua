local M = {}

function M.build(track, lesson, state, question, mode, variation)
  local record = state.tracks[track.id] and state.tracks[track.id].lessons[lesson.id] or {}
  if variation then record = record.variation or {} end
  return {
    mode = mode or "socratic",
    language = "es",
    task_kind = variation and "transfer" or "lesson",
    objective = variation and lesson.variation or lesson.objective,
    task = variation and lesson.variation or table.concat(lesson.requirements, "\n"),
    concepts = lesson.concepts,
    assistance_level = record.hints or 0,
    recent_attempt_count = #(record.attempts or {}),
    question = question,
    learner_code_included = false,
  }
end

return M
