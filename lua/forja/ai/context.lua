local M = {}

function M.build(track, lesson, state, question, mode)
  local record = state.tracks[track.id] and state.tracks[track.id].lessons[lesson.id] or {}
  return {
    mode = mode or "socratic",
    language = "es",
    objective = lesson.objective,
    concepts = lesson.concepts,
    assistance_level = record.hints or 0,
    recent_attempt_count = #(record.attempts or {}),
    question = question,
    learner_code_included = false,
  }
end

return M
