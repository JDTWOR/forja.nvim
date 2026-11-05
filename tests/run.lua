vim.opt.runtimepath:prepend(vim.fn.getcwd())

local function check(value, message)
  if not value then error("FAIL: " .. message, 2) end
end

local graph = require("forja.core.graph")
local curriculum = require("forja.core.curriculum")
local migrations = require("forja.storage.migrations")
local progress = require("forja.core.progress")
local storage = require("forja.storage.json")
local fs = require("forja.util.fs")
local ai = require("forja.ai.interface")
local config = require("forja.config")
local commands = require("forja.commands")
local ui = require("forja.ui")
local runner = require("forja.runner.process")

local root = vim.fn.getcwd()
local temporary = vim.fn.tempname()
vim.fn.mkdir(temporary, "p")
config.setup({ data_dir = temporary, runner = { timeout_ms = 30000 } })

local tracks, curriculum_err = curriculum.list()
check(tracks ~= nil, curriculum_err or "curriculum list failed")
check(#tracks == 1 and #tracks[1]._ordered_lessons == 5, "five real lessons load")
local track = tracks[1]

local function graph_lesson(id, prerequisite)
  return {
    id = id, module = "module", title = id, objective = id,
    concepts = { id }, prerequisites = { prerequisite },
    explanation = "Explanation", example = "Example", guided = "Guided strategy",
    variation = "Transfer variation", questions = { "Question?" }, requirements = { "Requirement" },
    hints = { "one", "two", "three", "four", "five", "six" }, exercise = {},
  }
end
local cycle = {
  schema_version = 1, id = "cycle", version = "1",
  title = "Cycle", modules = { { id = "module", title = "Module" } },
  lessons = { graph_lesson("a", "b"), graph_lesson("b", "a") },
}
local _, cycle_err = graph.validate(cycle)
check(cycle_err and cycle_err:find("cycle"), "prerequisite cycles are rejected")
local missing = vim.deepcopy(cycle)
missing.lessons[1].prerequisites = { "missing" }
local _, missing_err = graph.validate(missing)
check(missing_err and missing_err:find("missing prerequisite"), "missing prerequisites are rejected")
local duplicate = vim.deepcopy(cycle)
duplicate.lessons[2].id = "a"
duplicate.lessons[1].prerequisites = {}
local _, duplicate_err = graph.validate(duplicate)
check(duplicate_err and duplicate_err:find("duplicate"), "duplicate lesson ids are rejected")
local incomplete = vim.deepcopy(cycle)
incomplete.lessons[1].guided = nil
local _, incomplete_err = graph.validate(incomplete)
check(incomplete_err and incomplete_err:find("guided"), "incomplete lessons are rejected before rendering")

local migrated, migration_err = migrations.upgrade({ schema_version = 0 })
check(migrated ~= nil and migrated.schema_version == 1 and migrated.tracks ~= nil, migration_err or "schema v0 migration")
local too_new = migrations.upgrade({ schema_version = 99 })
check(too_new == nil, "newer data schema is not silently overwritten")

local state = storage.default()
state.active_track = track.id
local first = track._ordered_lessons[1]
local rec = progress.lesson_status(state, track.id, first.id)
check(rec.hints == 0, "new lesson progress initializes hint accounting")
progress.add_hint(state, track.id, first.id)
progress.add_ai_assistance(state, track.id, first.id)
local assisted = progress.record_attempt(state, track, first, {
  passed = true, assessment = true, hints = 1, ai_assistance = 1,
})
check(assisted.independent == false and rec.mastery_evidence.level == "reproduced", "assisted success is separate from independent mastery")
local later_state = storage.default()
progress.add_hint(later_state, track.id, first.id)
local failed_after_hint = progress.record_attempt(later_state, track, first, {
  passed = false, assessment = true,
})
local later_unaided = progress.record_attempt(later_state, track, first, {
  passed = true, assessment = true,
})
check(failed_after_hint.independent == false and later_unaided.independent == true, "lifetime assistance stays recorded while a later unaided attempt can demonstrate independence")
local fresh_state = storage.default()
local first_attempt = progress.record_attempt(fresh_state, track, first, {
  passed = true, assessment = true, hints = 0, ai_assistance = 0,
})
check(first_attempt.independent == true and fresh_state.tracks[track.id].lessons[first.id].first_assessment_success == true, "unaided first assessment is recorded as independent evidence")
local exam_state = storage.default()
progress.add_hint(exam_state, track.id, first.id)
local exam_attempt = progress.record_attempt(exam_state, track, first, {
  passed = true, assessment = true, hints = 0, ai_assistance = 0, exam = true,
})
check(exam_attempt.independent == true, "Exam Mode can establish independent evidence after prior assisted practice")
check(progress.first_incomplete(track, fresh_state).id == track._ordered_lessons[2].id, "verified completion unlocks the next lesson")

check(fs.safe_relative("exercises/rust"), "relative curriculum paths are accepted")
check(not fs.safe_relative("../outside"), "parent traversal paths are rejected")
check(not fs.safe_relative("/tmp/outside"), "absolute curriculum paths are rejected")
local copy_source = fs.join(temporary, "copy-source")
fs.ensure_dir(fs.join(copy_source, "target/debug"))
fs.ensure_dir(fs.join(copy_source, "src"))
fs.write(fs.join(copy_source, "src/lib.rs"), "pub fn fresh() {}\n")
fs.write(fs.join(copy_source, "target/debug/stale-artifact"), "stale")
local copy_destination = fs.join(temporary, "copy-destination")
check(fs.copy_tree(copy_source, copy_destination, { target = true }), "assessment copy supports excluded build artifacts")
check(vim.uv.fs_stat(fs.join(copy_destination, "src/lib.rs")) ~= nil and vim.uv.fs_stat(fs.join(copy_destination, "target")) == nil, "assessment copy omits Cargo target cache")

local save_ok, save_err = storage.save(fresh_state)
check(save_ok, save_err or "atomic progress save")
local loaded, load_err = storage.load()
check(loaded and loaded.tracks[track.id].lessons[first.id].completed, load_err or "progress round trip")
local second_state = vim.deepcopy(loaded)
second_state.history[1].at = 123
check(storage.save(second_state), "second atomic save succeeds")
check(vim.uv.fs_stat(storage.path() .. ".bak") ~= nil, "previous progress snapshot is kept as backup")

local no_provider_response
ai.request(nil, {}, function(response) no_provider_response = response end)
check(no_provider_response and no_provider_response.error, "missing AI provider fails clearly")
local malformed_response
ai.request({ complete = function(_, callback) callback({ json = "{}" }) end }, {}, function(response) malformed_response = response end)
check(malformed_response and malformed_response.error, "malformed AI response is rejected")

vim.cmd("source plugin/forja.lua")
config.setup({ data_dir = temporary, runner = { timeout_ms = 30000 } })
check(vim.fn.exists(":Forja") == 2, "plugin runtime registers commands when sourced")
commands.setup()
for _, command in ipairs({ "Forja", "ForjaStart", "ForjaTracks", "ForjaLesson", "ForjaNext", "ForjaRun", "ForjaTest", "ForjaHint", "ForjaTutor", "ForjaReview", "ForjaPractice", "ForjaExam", "ForjaProgress", "ForjaHealth", "ForjaTrustLocal", "ForjaCancel", "ForjaExport" }) do
  check(vim.fn.exists(":" .. command) == 2, "command is registered: " .. command)
end
vim.api.nvim_cmd({ cmd = "Forja" }, {})
check(ui.current and vim.api.nvim_buf_is_valid(ui.current.buf), ":Forja opens the native dashboard")
ui.close()
local export_path = fs.join(temporary, "export/progress-copy.json")
commands.export(export_path)
local export_text = fs.read(export_path)
check(export_text and vim.json.decode(export_text).schema_version == 1, "progress can be exported as versioned JSON")
local ui_buf = ui.open({ "first" }, "cleanup test")
check(vim.api.nvim_buf_is_valid(ui_buf), "UI buffer opens")
ui.close()
check(ui.current == nil and not vim.api.nvim_buf_is_valid(ui_buf), "UI view closes and buffer is cleaned up")

-- Real command-path exercise: an incorrect starter fails without unlocking; a
-- learner workspace changed to the verified solution passes hidden tests.
local lesson = first
local exercise_workspace, workspace_err = require("forja.core.workspace").ensure(track, lesson)
check(exercise_workspace ~= nil, workspace_err or "starter workspace created")
local source_file = fs.join(exercise_workspace, "src/lib.rs")
local workspace_text = fs.read(source_file)
check(workspace_text and workspace_text:find("todo!", 1, true), "starter contains a real incomplete implementation")
local key = track.id .. "/" .. lesson.id
state = storage.default()
state.active_track = track.id
state.current_lesson = lesson.id
state.trusted_exercises[key] = true
check(progress.save(state), "test state saved")
commands.start(track.id)
local function run_command()
  vim.api.nvim_cmd({ cmd = "ForjaTest" }, {})
end
vim.api.nvim_cmd({ cmd = "ForjaRun" }, {})
local reached_visible_attempt = vim.wait(20000, function()
  local current = progress.load()
  local entry = current and current.tracks[track.id] and current.tracks[track.id].lessons[lesson.id]
  return entry and #entry.attempts >= 1 and entry.attempts[1].test_scope == "visible"
end, 25)
check(reached_visible_attempt, "ForjaRun executes visible Cargo tests asynchronously")
run_command()
local reached_first_attempt = vim.wait(20000, function()
  local current = progress.load()
  local entry = current and current.tracks[track.id] and current.tracks[track.id].lessons[lesson.id]
  return entry and #entry.attempts >= 2 and entry.attempts[2].assessment
end, 25)
check(reached_first_attempt, "assessment runner reports the incorrect starter")
state = progress.load()
check(state.tracks[track.id].lessons[lesson.id].completed ~= true, "incorrect assessment does not unlock progress")
check(state.tracks[track.id].lessons[lesson.id].first_assessment_success == false, "first assessment outcome is preserved")
local next_before_pass = state.current_lesson
commands.next()
state = progress.load()
check(state.current_lesson == next_before_pass, "next lesson remains gated after failure")

local solution = fs.read(fs.join(lesson.exercise._dir, lesson.exercise.solution_file))
check(solution ~= nil, "reference solution is available to the verification harness")
check(fs.write(source_file, solution), "learner workspace can be edited without replacing it from curriculum")
check(vim.uv.fs_stat(fs.join(exercise_workspace, "tests/forja_assessment.rs")) == nil, "hidden tests are absent from normal workspace")
run_command()
local reached_pass = vim.wait(30000, function()
  local current = progress.load()
  local entry = current and current.tracks[track.id] and current.tracks[track.id].lessons[lesson.id]
  return entry and #entry.attempts >= 3 and entry.completed == true
end, 25)
check(reached_pass, "verified assessment passes and persists completion")
state = progress.load()
check(state.tracks[track.id].lessons[lesson.id].mastery_evidence.level == "independently_demonstrated", "assessment stores mastery evidence")
check(vim.uv.fs_stat(fs.join(exercise_workspace, "tests/forja_assessment.rs")) == nil, "assessment copy is removed after the process")
commands.next()
state = progress.load()
check(state.current_lesson == track._ordered_lessons[2].id, "ForjaNext opens the newly eligible lesson")

commands.hint()
state = progress.load()
local hinted_lesson = state.tracks[track.id].lessons[state.current_lesson]
check(hinted_lesson.hints == 1 and hinted_lesson.pending_hints == 1, "ForjaHint records lifetime and current-attempt assistance")

local original_input = vim.ui.input
vim.ui.input = function(_, callback) callback("Explícame cómo empezar sin darme la solución") end
commands.tutor()
vim.ui.input = original_input
local tutor_recorded = vim.wait(1000, function()
  local current = progress.load()
  local entry = current.tracks[track.id].lessons[state.current_lesson]
  return entry and (entry.ai_assistance or 0) == 1
end, 20)
check(tutor_recorded, "offline Socratic tutor is available and assistance is recorded")

commands.practice(track._ordered_lessons[2].id)
local practice_source = vim.api.nvim_buf_get_name(0)
check(practice_source:find("/reviews/", 1, true) ~= nil, "focused practice opens a separate clean workspace")
local practice_text = fs.read(practice_source)
check(practice_text and practice_text:find("todo!", 1, true), "focused practice does not reveal the saved learner solution")
commands.review("stop")
local returned_source = vim.api.nvim_buf_get_name(0)
check(returned_source:find("/workspaces/", 1, true) ~= nil, "stopping focused practice restores the persistent learner workspace")
check(vim.uv.fs_stat(practice_source) ~= nil, "stopping practice preserves its separate workspace")

state.exam_active = true
local before_hints = progress.lesson_status(state, track.id, track._ordered_lessons[2].id).hints
progress.save(state)
commands.hint()
state = progress.load()
check(progress.lesson_status(state, track.id, track._ordered_lessons[2].id).hints == before_hints, "Exam Mode blocks plugin hints")
state.exam_active = false
progress.save(state)

-- The process adapter must respect a timeout and accept explicit cancellation.
local slow_workspace = fs.join(temporary, "slow-workspace")
fs.ensure_dir(fs.join(slow_workspace, "src"))
fs.ensure_dir(fs.join(slow_workspace, "tests"))
fs.write(fs.join(slow_workspace, "Cargo.toml"), "[package]\nname=\"forja_slow_check\"\nversion=\"0.1.0\"\nedition=\"2021\"\n")
fs.write(fs.join(slow_workspace, "src/lib.rs"), "pub fn value() -> u8 { 1 }\n")
fs.write(fs.join(slow_workspace, "tests/slow.rs"), "#[test] fn slow() { std::thread::sleep(std::time::Duration::from_secs(5)); }\n")
local function wait_for_process(timeout, cancel)
  local done, result = false, nil
  runner.run(track, lesson, slow_workspace, false, timeout, function(value) result, done = value, true end)
  if cancel then vim.defer_fn(function() runner.cancel() end, 150) end
  local completed = vim.wait(timeout + 10000, function() return done end, 20)
  check(completed, "asynchronous Cargo process completes")
  return result
end
local timed = wait_for_process(1500, false)
check(timed.code ~= 0, "Cargo process timeout ends with a nonzero result")
local cancelled = wait_for_process(30000, true)
check(cancelled.cancelled == true, "running Cargo process can be cancelled")

ui.close()
fs.remove_tree(temporary)
print("Forja tests passed: curriculum, graph, storage, mastery, AI validation, commands, UI, assessment gating, async runner, timeout and cancellation")
vim.cmd("qa!")
