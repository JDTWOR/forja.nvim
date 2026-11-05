local storage = require("forja.storage.json")
local M = {}

function M.load()
  return storage.load()
end

function M.save(state)
  return storage.save(state)
end

function M.track(state, track_id)
  state.tracks[track_id] = state.tracks[track_id] or { lessons = {} }
  state.tracks[track_id].lessons = state.tracks[track_id].lessons or {}
  return state.tracks[track_id]
end

function M.lesson_status(state, track_id, lesson_id)
  local track = M.track(state, track_id)
  track.lessons[lesson_id] = track.lessons[lesson_id] or {
    attempts = {}, hints = 0, ai_assistance = 0,
    pending_hints = 0, pending_ai_assistance = 0, completed = false,
  }
  return track.lessons[lesson_id]
end

function M.first_incomplete(track, state)
  local progress = M.track(state, track.id)
  for _, lesson in ipairs(track._ordered_lessons) do
    local eligible = true
    for _, prerequisite in ipairs(lesson.prerequisites or {}) do
      local record = progress.lessons[prerequisite]
      if not record or not record.completed then eligible = false; break end
    end
    if eligible then
      local record = progress.lessons[lesson.id]
      if not record or not record.completed then return lesson end
    end
  end
  return nil
end

function M.record_attempt(state, track, lesson, result)
  local record = M.lesson_status(state, track.id, lesson.id)
  local first_assessment_attempt = result.assessment == true and record.first_assessment_at == nil
  local attempt_hints = result.hints
  if attempt_hints == nil then attempt_hints = record.pending_hints or 0 end
  local attempt_ai_assistance = result.ai_assistance
  if attempt_ai_assistance == nil then attempt_ai_assistance = record.pending_ai_assistance or 0 end
  local attempt = {
    at = os.time(),
    passed = result.passed == true,
    assessment = result.assessment == true,
    test_scope = result.assessment == true and "assessment" or "visible",
    first_assessment_attempt = first_assessment_attempt,
    independent = result.passed == true and result.assessment == true and attempt_hints == 0 and attempt_ai_assistance == 0,
    hints = attempt_hints,
    ai_assistance = attempt_ai_assistance,
    execution_seconds = result.execution_seconds or 0,
    exam = result.exam == true,
    review = result.review == true,
  }
  table.insert(record.attempts, attempt)
  record.pending_hints = 0
  record.pending_ai_assistance = 0
  if first_assessment_attempt then
    record.first_assessment_at = attempt.at
    record.first_assessment_success = attempt.passed
  end
  if result.passed and result.assessment then
    record.completed = true
    record.mastery_evidence = {
      level = attempt.independent and "independently_demonstrated" or "reproduced",
      at = attempt.at,
      attempts = #record.attempts,
      variation = result.variation or false,
    }
  end
  table.insert(state.history, {
    at = attempt.at,
    track_id = track.id,
    lesson_id = lesson.id,
    passed = attempt.passed,
    assessment = attempt.assessment,
    independent = attempt.independent,
  })
  return attempt
end

function M.add_hint(state, track_id, lesson_id)
  local record = M.lesson_status(state, track_id, lesson_id)
  record.hints = record.hints + 1
  record.pending_hints = (record.pending_hints or 0) + 1
  return record.hints
end

function M.add_ai_assistance(state, track_id, lesson_id)
  local record = M.lesson_status(state, track_id, lesson_id)
  record.ai_assistance = (record.ai_assistance or 0) + 1
  record.pending_ai_assistance = (record.pending_ai_assistance or 0) + 1
  return record.ai_assistance
end

function M.reset_pending_assistance(state, track_id, lesson_id)
  local record = M.lesson_status(state, track_id, lesson_id)
  record.pending_hints = 0
  record.pending_ai_assistance = 0
end

return M
