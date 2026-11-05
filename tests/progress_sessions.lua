vim.opt.runtimepath:prepend(vim.fn.getcwd())
local progress = require("forja.core.progress")
local storage = require("forja.storage.json")
local track, lesson = { id = "track" }, { id = "lesson" }
local function check(value, message) assert(value, message) end
local function pass(state, variation, workspace)
  return progress.record_attempt(state, track, lesson, {
    passed = true, assessment = true, hints = 0, ai_assistance = 0, exam = true, variation = variation,
    workspace = workspace,
  })
end
for _, variation in ipairs({ false, true }) do
  local state = storage.default()
  progress.add_hint(state, track.id, lesson.id, variation)
  progress.record_attempt(state, track, lesson, { passed = true, assessment = false, variation = variation })
  progress.reset_pending_assistance(state, track.id, lesson.id, variation)
  check(not pass(state, variation).independent, "visible tests and Exam counters cannot erase hint exposure")
  progress.begin_clean_attempt(state, track.id, lesson.id, variation, "/fresh/starter")
  check(pass(state, variation, "/fresh/starter").independent, "a clean retrieval attempt can demonstrate independence")
  check(not pass(state, variation, "/different/workspace").independent, "assessment from a different workspace cannot use clean-session evidence")
  local resumed_record = variation and progress.variation_status(state, track.id, lesson.id)
    or progress.lesson_status(state, track.id, lesson.id)
  resumed_record.session.resumed_uncertified = true
  check(not pass(state, variation, "/fresh/starter").independent, "browsed historical workspaces cannot establish fresh independent evidence")
  progress.begin_clean_attempt(state, track.id, lesson.id, variation, "/fresh/after-resume")
  progress.add_ai_assistance(state, track.id, lesson.id, variation)
  check(not pass(state, variation, "/fresh/after-resume").independent, "AI exposure persists through assessment retries")
  progress.begin_clean_attempt(state, track.id, lesson.id, variation, "/fresh/second-starter")
  progress.record_solution_disclosure(state, track.id, lesson.id, variation)
  check(not pass(state, variation, "/fresh/second-starter").independent, "reference disclosure taints the active attempt")
  local roundtrip = vim.json.decode(vim.json.encode(state))
  check(not pass(roundtrip, variation, "/fresh/second-starter").independent, "exposure survives persistence and restart")
end
local legacy = storage.default()
local record = progress.lesson_status(legacy, track.id, lesson.id)
record.hints, record.pending_hints, record.abandoned_at = 1, 0, 123
check(not pass(legacy).independent, "legacy assistance is preserved conservatively")
local preserved = storage.default()
check(pass(preserved).independent, "initial clean assessment is independent")
progress.add_hint(preserved, track.id, lesson.id)
local assisted = pass(preserved)
local preserved_record = progress.lesson_status(preserved, track.id, lesson.id)
check(not assisted.independent and preserved_record.mastery_evidence.level == "independently_demonstrated"
  and preserved_record.latest_assessment.level == "reproduced",
  "later assisted success does not erase stronger independent evidence")
print("Progress session regression tests passed")
vim.cmd("qa!")
