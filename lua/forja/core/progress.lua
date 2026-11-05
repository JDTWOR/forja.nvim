local storage = require("forja.storage.json")
local M = {}

local function count(value, default)
  value = tonumber(value)
  if not value or value ~= value or value == math.huge or value < 0 then return default or 0 end
  return math.floor(value)
end

local function exposure(record)
  -- Legacy records have no attempt boundary. Preserve known exposure rather
  -- than upgrading an old assisted implementation to independent evidence.
  if type(record.session) ~= "table" then
    record.session = {
      id = 1, hints = record.hints or 0, ai_assistance = record.ai_assistance or 0,
      solution_disclosed = record.abandoned_at ~= nil,
    }
  end
  local session = record.session
  session.id = math.max(1, count(session.id, 1))
  session.hints = count(session.hints, count(record.hints))
  session.ai_assistance = count(session.ai_assistance, count(record.ai_assistance))
  session.solution_disclosed = session.solution_disclosed == true or record.abandoned_at ~= nil
  session.resumed_uncertified = session.resumed_uncertified == true
  return session
end

function M.begin_clean_attempt(state, track_id, lesson_id, variation_mode, workspace_path)
  assert(type(workspace_path) == "string" and workspace_path ~= "", "a fresh starter workspace is required")
  workspace_path = (vim.uv or vim.loop).fs_realpath(workspace_path) or workspace_path
  local record = variation_mode and M.variation_status(state, track_id, lesson_id) or M.lesson_status(state, track_id, lesson_id)
  local previous = exposure(record)
  record.session = { id = previous.id + 1, hints = 0, ai_assistance = 0,
    solution_disclosed = false, workspace = workspace_path, started_at = os.time() }
  record.pending_hints, record.pending_ai_assistance = 0, 0
  return record.session
end

function M.record_solution_disclosure(state, track_id, lesson_id, variation_mode)
  local record = variation_mode and M.variation_status(state, track_id, lesson_id) or M.lesson_status(state, track_id, lesson_id)
  exposure(record).solution_disclosed = true
  record.solution_disclosures = (record.solution_disclosures or 0) + 1
  record.abandoned_at = os.time()
end

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

function M.variation_status(state, track_id, lesson_id)
  local record = M.lesson_status(state, track_id, lesson_id)
  record.variation = record.variation or { attempts = {}, hints = 0, ai_assistance = 0, pending_hints = 0, pending_ai_assistance = 0 }
  return record.variation
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
  local target = result.variation and M.variation_status(state, track.id, lesson.id) or record
  local session = exposure(target)
  session.hints = math.max(session.hints, result.hints or 0)
  session.ai_assistance = math.max(session.ai_assistance, result.ai_assistance or 0)
  local independent = result.passed == true and result.assessment == true
    and session.hints == 0 and session.ai_assistance == 0 and not session.solution_disclosed
    and not session.resumed_uncertified
    and (not session.workspace or result.workspace == session.workspace)
  if result.variation then
    local variation = M.variation_status(state, track.id, lesson.id)
    local attempt = {
      at = os.time(), passed = result.passed == true, assessment = result.assessment == true,
      test_scope = result.assessment == true and "transfer_assessment" or "transfer_visible",
      independent = independent, session_id = session.id, solution_disclosed = session.solution_disclosed,
      resumed_uncertified = session.resumed_uncertified == true,
      workspace_match = not session.workspace or result.workspace == session.workspace,
      session_hints = session.hints, session_ai_assistance = session.ai_assistance,
      hints = result.hints or 0, ai_assistance = result.ai_assistance or 0,
      execution_seconds = result.execution_seconds or 0, exam = result.exam == true,
    }
    table.insert(variation.attempts, attempt)
    variation.pending_hints, variation.pending_ai_assistance = 0, 0
    table.insert(state.history, { at = attempt.at, track_id = track.id, lesson_id = lesson.id,
      passed = attempt.passed, assessment = attempt.assessment, independent = attempt.independent, variation = true })
    return attempt
  end
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
    independent = independent, session_id = session.id, solution_disclosed = session.solution_disclosed,
    resumed_uncertified = session.resumed_uncertified == true,
    workspace_match = not session.workspace or result.workspace == session.workspace,
    session_hints = session.hints, session_ai_assistance = session.ai_assistance,
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
    record.latest_assessment = {
      level = attempt.independent and "independently_demonstrated" or "reproduced",
      at = attempt.at, independent = attempt.independent, session_id = session.id,
    }
    if not record.mastery_evidence or attempt.independent
      or record.mastery_evidence.level ~= "independently_demonstrated" then
      record.mastery_evidence = {
        level = record.latest_assessment.level,
        at = attempt.at,
        attempts = #record.attempts,
        variation = result.variation or false,
      }
    end
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

function M.add_hint(state, track_id, lesson_id, variation_mode)
  local record = variation_mode and M.variation_status(state, track_id, lesson_id) or M.lesson_status(state, track_id, lesson_id)
  local session = exposure(record)
  session.hints = session.hints + 1
  record.hints = record.hints + 1
  record.pending_hints = (record.pending_hints or 0) + 1
  return record.hints
end

function M.add_ai_assistance(state, track_id, lesson_id, variation_mode)
  local record = variation_mode and M.variation_status(state, track_id, lesson_id) or M.lesson_status(state, track_id, lesson_id)
  local session = exposure(record)
  session.ai_assistance = session.ai_assistance + 1
  record.ai_assistance = (record.ai_assistance or 0) + 1
  record.pending_ai_assistance = (record.pending_ai_assistance or 0) + 1
  return record.ai_assistance
end

function M.record_recall(state, track_id, lesson_id, answers)
  local record = M.lesson_status(state, track_id, lesson_id)
  record.recall_history = record.recall_history or {}
  local recall = { at = os.time(), answers = answers }
  table.insert(record.recall_history, recall)
  return recall
end

function M.reset_pending_assistance(state, track_id, lesson_id, variation_mode)
  local record = variation_mode and M.variation_status(state, track_id, lesson_id) or M.lesson_status(state, track_id, lesson_id)
  record.pending_hints = 0
  record.pending_ai_assistance = 0
end

return M
