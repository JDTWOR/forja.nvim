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
check(#tracks == 4, "Rust, Python, Java, and Go learning tracks load")
local track_by_id = {}
for _, loaded_track in ipairs(tracks) do
  track_by_id[loaded_track.id] = loaded_track
  check(#loaded_track._ordered_lessons == 5, loaded_track.id .. " has five real lessons")
end
local track = assert(track_by_id["rust-foundations"], "Rust foundations track loads")
for _, item in ipairs(track._ordered_lessons) do
  check(item.exercise._variation_dir ~= nil and item.exercise._variation_manifest ~= nil,
    "each Rust lesson has a validated independent transfer project")
end
for _, id in ipairs({ "python-foundations", "java-foundations", "go-foundations" }) do
  local loaded_track = assert(track_by_id[id], id .. " is discoverable")
  for _, item in ipairs(loaded_track._ordered_lessons) do
    check(item.exercise._manifest and item.exercise._manifest.runner ~= "cargo-test",
      id .. " lesson has a language-specific executable exercise")
    check(item.language == loaded_track.language, id .. " carries language metadata into lesson views")
  end
end

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
check(failed_after_hint.independent == false and later_unaided.independent == false,
  "visible tests and retries do not erase assistance used in the same implementation workspace")
progress.begin_clean_attempt(later_state, track.id, first.id, false, "/fresh/retrieval")
local clean_retrieval = progress.record_attempt(later_state, track, first, { passed = true, assessment = true, workspace = "/fresh/retrieval" })
check(clean_retrieval.independent == true, "a newly created clean retrieval workspace can demonstrate independence")
local fresh_state = storage.default()
local first_attempt = progress.record_attempt(fresh_state, track, first, {
  passed = true, assessment = true, hints = 0, ai_assistance = 0,
})
check(first_attempt.independent == true and fresh_state.tracks[track.id].lessons[first.id].first_assessment_success == true, "unaided first assessment is recorded as independent evidence")
progress.record_recall(fresh_state, track.id, first.id, { "binding answer", "shadowing answer" })
check(#fresh_state.tracks[track.id].lessons[first.id].recall_history == 1, "recall answers are stored separately from graded attempts")
local exam_state = storage.default()
progress.add_hint(exam_state, track.id, first.id)
local exam_attempt = progress.record_attempt(exam_state, track, first, {
  passed = true, assessment = true, hints = 0, ai_assistance = 0, exam = true,
})
check(exam_attempt.independent == false, "Exam counters cannot erase assistance from the existing implementation workspace")
progress.begin_clean_attempt(exam_state, track.id, first.id, false, "/fresh/exam")
local fresh_exam_attempt = progress.record_attempt(exam_state, track, first, {
  passed = true, assessment = true, hints = 0, ai_assistance = 0, exam = true, workspace = "/fresh/exam",
})
check(fresh_exam_attempt.independent == true, "a fresh Exam Mode workspace can establish independent evidence after assisted practice")
local transfer_hint_state = storage.default()
progress.add_hint(transfer_hint_state, track.id, first.id, true)
check(progress.lesson_status(transfer_hint_state, track.id, first.id).hints == 0
  and progress.variation_status(transfer_hint_state, track.id, first.id).hints == 1,
  "transfer hint accounting is separate from base lesson assistance")
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
local base_context = require("forja.ai.context").build(track, first, fresh_state, "question", "socratic")
local transfer_context = require("forja.ai.context").build(track, first, fresh_state, "question", "socratic", true)
check(base_context.task_kind == "lesson" and transfer_context.task_kind == "transfer"
  and transfer_context.objective == first.variation and transfer_context.learner_code_included == false,
  "tutor context identifies transfer tasks without sending learner code")
local malformed_response
ai.request({ complete = function(_, callback) callback({ json = "{}" }) end }, {}, function(response) malformed_response = response end)
check(malformed_response and malformed_response.error, "malformed AI response is rejected")

vim.cmd("source plugin/forja.lua")
config.setup({ data_dir = temporary, runner = { timeout_ms = 30000 } })
check(vim.fn.exists(":Forja") == 2, "plugin runtime registers commands when sourced")
commands.setup()
for _, command in ipairs({ "Forja", "ForjaClose", "ForjaResult", "ForjaStart", "ForjaTracks", "ForjaLesson", "ForjaNext", "ForjaRun", "ForjaTest", "ForjaHint", "ForjaRecall", "ForjaTutor", "ForjaReview", "ForjaPractice", "ForjaExam", "ForjaProgress", "ForjaHealth", "ForjaTrustLocal", "ForjaCancel", "ForjaExport" }) do
  check(vim.fn.exists(":" .. command) == 2, "command is registered: " .. command)
end
vim.api.nvim_cmd({ cmd = "Forja" }, {})
check(ui.current and vim.api.nvim_buf_is_valid(ui.current.buf), ":Forja opens the native dashboard")
check(vim.fn.maparg("a", "n", false, true).buffer == 1, "dashboard exposes active recall as a buffer-local action")
local initial_dashboard = table.concat(vim.api.nvim_buf_get_lines(ui.current.buf, 0, -1, false), "\n")
check(initial_dashboard:find("Aún no has elegido una ruta", 1, true), "a fresh dashboard does not silently select the alphabetically first course")
local old_select_for_track = vim.ui.select
vim.ui.select = function(items, _, callback)
  for _, item in ipairs(items) do
    if item.id == "rust-foundations" then callback(item); return end
  end
  error("Rust track was missing from the initial track picker")
end
commands.start()
vim.ui.select = old_select_for_track
check(storage.load().active_track == "rust-foundations" and ui.lesson_view ~= nil,
  "starting from an empty dashboard asks the learner to choose a track")
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
vim.o.columns, vim.o.lines = 120, 40
commands.start(track.id)
check(ui.lesson_view and ui.lesson_view.win and vim.api.nvim_win_is_valid(ui.lesson_view.win), "starting a lesson opens a dedicated reading view")
check(ui.lesson_view.kind == "split" and vim.api.nvim_get_current_buf() == vim.fn.bufnr(source_file), "wide terminals keep code focused beside a lesson split")
check(vim.wo[ui.lesson_view.win].wrap and vim.wo[ui.lesson_view.win].linebreak, "lesson prose wraps at word boundaries")
local first_lesson_text = table.concat(vim.api.nvim_buf_get_lines(ui.lesson_view.buf, 0, -1, false), "\n")
check(first_lesson_text:find("bindings", 1, true) and not first_lesson_text:find("rust.binding", 1, true), "lesson concepts use learner-facing labels instead of raw IDs")
check(not first_lesson_text:find(exercise_workspace, 1, true), "lesson content does not expose the local workspace path")
check(first_lesson_text:find("[1 Reto]", 1, true) and first_lesson_text:find("2 Idea", 1, true),
  "lesson reading pane starts on a clearly labeled challenge section")
vim.api.nvim_set_current_win(ui.lesson_view.win)
vim.cmd("normal 2")
local concept_text = table.concat(vim.api.nvim_buf_get_lines(ui.lesson_view.buf, 0, -1, false), "\n")
check(concept_text:find("# Concepto", 1, true) and concept_text:find("[2 Idea]", 1, true)
  and not concept_text:find("# Reto", 1, true), "numbered lesson tabs replace the content and mark the active section")
vim.cmd("normal 1")
vim.api.nvim_set_current_win(ui.lesson_view.return_win)
local has_lesson_run_mapping = false
for _, mapping in ipairs(vim.api.nvim_buf_get_keymap(ui.lesson_view.buf, "n")) do
  if mapping.lhs == "r" then has_lesson_run_mapping = true end
end
check(has_lesson_run_mapping and vim.fn.maparg("r", "n") == "", "lesson actions are buffer-local and do not override source editing keys")
vim.o.columns, vim.o.lines = 100, 30
vim.api.nvim_exec_autocmds("VimResized", {})
check(vim.api.nvim_win_get_width(ui.lesson_view.win) <= 64, "lesson split resizes inside its configured bounds")
vim.o.columns, vim.o.lines = 80, 24
vim.api.nvim_exec_autocmds("VimResized", {})
check(ui.lesson_view.kind == "float" and vim.api.nvim_win_get_width(ui.lesson_view.win) <= 78,
  "resizing below the split threshold switches to a bounded reading float")
check(vim.api.nvim_get_current_buf() == vim.fn.bufnr(source_file), "responsive layout change preserves code focus")
vim.o.columns, vim.o.lines = 120, 40
vim.api.nvim_exec_autocmds("VimResized", {})
check(ui.lesson_view.kind == "split", "expanding the terminal restores the side-by-side lesson split")
vim.api.nvim_cmd({ cmd = "ForjaClose" }, {})
check(ui.lesson_view == nil and vim.api.nvim_buf_get_name(0) == source_file, "ForjaClose returns to the learner code buffer")
vim.o.columns, vim.o.lines = 80, 24
vim.api.nvim_cmd({ cmd = "ForjaLesson" }, {})
check(ui.lesson_view and ui.lesson_view.kind == "float" and vim.api.nvim_win_is_valid(ui.lesson_view.win), "narrow terminals use a focused, bounded reading view")
check(vim.api.nvim_win_get_width(ui.lesson_view.win) <= vim.o.columns - 2 and vim.api.nvim_win_get_height(ui.lesson_view.win) <= vim.o.lines - 2, "narrow lesson view fits the available terminal")
vim.api.nvim_buf_call(ui.lesson_view.buf, function() vim.cmd("normal q") end)
check(ui.lesson_view == nil and vim.api.nvim_buf_get_name(0) == source_file, "q closes the narrow lesson and restores code focus")
vim.o.columns, vim.o.lines = 120, 40
vim.api.nvim_cmd({ cmd = "ForjaClose" }, {})
vim.api.nvim_cmd({ cmd = "ForjaLesson" }, {})
local original_input_for_recall = vim.ui.input
local recall_index = 0
vim.ui.input = function(_, callback) recall_index = recall_index + 1; callback("respuesta recuperada " .. recall_index) end
commands.recall()
vim.ui.input = original_input_for_recall
local recalled = progress.load().tracks[track.id].lessons[lesson.id].recall_history
check(#recalled == 1 and recalled[1].answers[2] == "respuesta recuperada 2", "ForjaRecall collects and persists answers without grading them")
ui.close("float")
local source_buf = vim.fn.bufnr(source_file)
check(source_buf > 0 and vim.api.nvim_buf_is_loaded(source_buf), "learner source buffer is open")
local before_lines = vim.api.nvim_buf_get_lines(source_buf, 0, -1, false)
table.insert(before_lines, "// unsaved-buffer safety check")
vim.api.nvim_buf_set_lines(source_buf, 0, -1, false, before_lines)
vim.bo[source_buf].modified = true
local original_select = vim.ui.select
vim.ui.select = function(items, _, callback) callback(items[2]) end
vim.api.nvim_cmd({ cmd = "ForjaRun" }, {})
vim.ui.select = original_select
local cancelled_state = progress.load()
local cancelled_record = cancelled_state.tracks[track.id].lessons[lesson.id]
check(#cancelled_record.attempts == 0 and vim.bo[source_buf].modified, "canceling the unsaved-buffer prompt neither runs tests nor discards edits")
local focus_before_run = vim.api.nvim_get_current_win()
vim.ui.select = function(items, _, callback) callback(items[1]) end
vim.api.nvim_cmd({ cmd = "ForjaRun" }, {})
vim.ui.select = original_select
check(not vim.bo[source_buf].modified and fs.read(source_file):find("unsaved-buffer safety check", 1, true), "save-and-run persists the exact edited buffer before testing")
local function run_command()
  vim.api.nvim_cmd({ cmd = "ForjaTest" }, {})
end
local reached_visible_attempt = vim.wait(20000, function()
  local current = progress.load()
  local entry = current and current.tracks[track.id] and current.tracks[track.id].lessons[lesson.id]
  return entry and #entry.attempts >= 1 and entry.attempts[1].test_scope == "visible"
end, 25)
check(reached_visible_attempt, "ForjaRun executes visible Cargo tests asynchronously")
check(vim.api.nvim_get_current_win() == focus_before_run, "test completion does not steal editor focus")
check(ui.output_view and ui.output_view.kind == "split" and vim.api.nvim_win_is_valid(ui.output_view.win),
  "test feedback stays visible in a persistent bottom pane on a wide screen")
local visible_result_text = table.concat(ui.last_result.lines, "\n")
check(ui.last_result.title:find("Tests visibles", 1, true) and visible_result_text:find("test result: FAILED", 1, true),
  "visible assertion failures retain inspectable Cargo diagnostics")
vim.api.nvim_cmd({ cmd = "ForjaResult" }, {})
check(ui.output_view and vim.api.nvim_win_is_valid(ui.output_view.win), "ForjaResult reopens stored feedback in the persistent result pane")
vim.api.nvim_cmd({ cmd = "ForjaClose" }, {})
check(ui.output_view == nil and ui.lesson_view and vim.api.nvim_win_is_valid(ui.lesson_view.win),
  "ForjaClose from the result pane closes feedback while preserving the lesson")
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
local assessment_result_text = table.concat(ui.last_result.lines, "\n")
check(assessment_result_text:find("La evaluación no se aprobó", 1, true)
  and not assessment_result_text:find("assessment_fee_and_boundary_values", 1, true),
  "failed hidden assessments provide guidance without exposing hidden assertions")
local next_before_pass = state.current_lesson
commands.next()
state = progress.load()
check(state.current_lesson == next_before_pass, "next lesson remains gated after failure")

check(fs.write(source_file, 'pub fn broken() -> u32 { let value: u32 = "not a number"; value }\n'),
  "compiler-diagnostic fixture is written")
vim.api.nvim_cmd({ cmd = "ForjaRun" }, {})
local reached_compile_error = vim.wait(20000, function()
  local current = progress.load()
  local entry = current and current.tracks[track.id] and current.tracks[track.id].lessons[lesson.id]
  return entry and #entry.attempts >= 3 and ui.last_result and ui.last_result.title:find("Tests visibles", 1, true)
end, 25)
check(reached_compile_error and table.concat(ui.last_result.lines, "\n"):find("error[E0308]", 1, true),
  "compiler errors remain distinct and inspectable")

local solution = fs.read(fs.join(lesson.exercise._dir, lesson.exercise.solution_file))
check(solution ~= nil, "reference solution is available to the verification harness")
check(fs.write(source_file, solution), "learner workspace can be edited without replacing it from curriculum")
check(vim.uv.fs_stat(fs.join(exercise_workspace, "tests/forja_assessment.rs")) == nil, "hidden tests are absent from normal workspace")
run_command()
local reached_pass = vim.wait(30000, function()
  local current = progress.load()
  local entry = current and current.tracks[track.id] and current.tracks[track.id].lessons[lesson.id]
  return entry and #entry.attempts >= 4 and entry.completed == true
end, 25)
check(reached_pass, "verified assessment passes and persists completion")
state = progress.load()
check(state.tracks[track.id].lessons[lesson.id].mastery_evidence.level == "independently_demonstrated", "assessment stores mastery evidence")
check(vim.uv.fs_stat(fs.join(exercise_workspace, "tests/forja_assessment.rs")) == nil, "assessment copy is removed after the process")
local attempts_before_missing_cargo = #state.tracks[track.id].lessons[lesson.id].attempts
local original_path = vim.env.PATH
vim.env.PATH = ""
ui.last_result = nil
vim.api.nvim_cmd({ cmd = "ForjaRun" }, {})
local missing_cargo_reported = vim.wait(10000, function()
  return ui.last_result and ui.last_result.title == "Falta una herramienta"
end, 20)
vim.env.PATH = original_path
check(missing_cargo_reported, "missing language toolchain produces actionable execution guidance")
state = progress.load()
check(#state.tracks[track.id].lessons[lesson.id].attempts == attempts_before_missing_cargo,
  "missing Cargo is not counted as a learner attempt")
commands.next()
state = progress.load()
check(state.current_lesson == track._ordered_lessons[2].id, "ForjaNext opens the newly eligible lesson")
local second_source = vim.api.nvim_buf_get_name(0)
local second_code_buf = vim.api.nvim_get_current_buf()
vim.bo[second_code_buf].modified = true
vim.api.nvim_set_current_win(ui.lesson_view.win)
commands.lesson(first.id)
state = progress.load()
check(state.current_lesson == track._ordered_lessons[2].id and vim.api.nvim_buf_get_name(second_code_buf) == second_source,
  "failed navigation leaves active lesson/code unchanged (lesson=" .. tostring(state.current_lesson)
    .. ", expected=" .. track._ordered_lessons[2].id .. ", buffer=" .. vim.api.nvim_buf_get_name(second_code_buf) .. ")")
vim.bo[second_code_buf].modified = false
vim.api.nvim_set_current_win(ui.lesson_view.return_win)

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

state = progress.load()
local transfer_lesson = track._ordered_lessons[2]
require("forja.core.workspace").trust(state, track, transfer_lesson)
check(progress.save(state), "base exercise trust is saved for transfer-boundary verification")
check(require("forja.core.workspace").trusted(state, track, transfer_lesson)
  and not require("forja.core.workspace").trusted(state, track, transfer_lesson, true),
  "base exercise approval does not grant transfer workspace execution")
commands.practice(track._ordered_lessons[2].id)
local practice_source = vim.api.nvim_buf_get_name(0)
check(practice_source:find("/reviews/", 1, true) ~= nil, "focused practice opens a separate clean workspace")
local practice_text = fs.read(practice_source)
check(practice_text and practice_text:find("todo!", 1, true) and practice_text:find("sensor_mean", 1, true), "focused practice opens only its dedicated transfer task")
local transfer_solution = fs.read(fs.join(transfer_lesson.exercise._variation_dir, transfer_lesson.exercise._variation_manifest.solution_file))
check(transfer_solution ~= nil, "transfer reference solution is available to the verification harness")
local practice_buf = vim.api.nvim_get_current_buf()
vim.api.nvim_buf_set_lines(practice_buf, 0, -1, false, vim.split(transfer_solution, "\n", { plain = true }))
vim.bo[practice_buf].modified = true
local original_select_for_trust = vim.ui.select
vim.ui.select = function(items, _, callback) callback(items[1]) end
commands.trust_local()
vim.api.nvim_cmd({ cmd = "ForjaTest" }, {})
vim.ui.select = original_select_for_trust
local reached_transfer = vim.wait(30000, function()
  local current = progress.load()
  local entry = current and current.tracks[track.id] and current.tracks[track.id].lessons[transfer_lesson.id]
  return entry and entry.variation and #entry.variation.attempts > 0
end, 25)
check(reached_transfer, "dedicated transfer assessment executes")
state = progress.load()
local transfer_record = state.tracks[track.id].lessons[transfer_lesson.id]
check(transfer_record.variation.attempts[1].passed and transfer_record.variation.attempts[1].independent,
  "independent transfer evidence is stored separately")
check(not transfer_record.completed and #transfer_record.attempts == 0, "transfer success cannot unlock or complete the base lesson")
check(vim.uv.fs_stat(fs.join(vim.fn.fnamemodify(practice_source, ":h:h"), "tests/forja_assessment.rs")) == nil,
  "dedicated transfer assessment remains outside its learner workspace")
local saved_transfer_lines = vim.api.nvim_buf_get_lines(practice_buf, 0, -1, false)
table.insert(saved_transfer_lines, "// saved when detaching from transfer practice")
vim.api.nvim_buf_set_lines(practice_buf, 0, -1, false, saved_transfer_lines)
vim.bo[practice_buf].modified = true
vim.api.nvim_set_current_win(ui.lesson_view.win)
commands.review("stop")
local returned_source = vim.api.nvim_buf_get_name(0)
check(returned_source:find("/workspaces/", 1, true) ~= nil, "stopping focused practice restores the persistent learner workspace")
check(vim.uv.fs_stat(practice_source) ~= nil, "stopping practice preserves its separate workspace")
check(fs.read(practice_source):find("saved when detaching", 1, true) ~= nil,
  "stopping practice saves edits from code buffers behind the lesson pane")

commands.exam()
check(table.concat(vim.api.nvim_buf_get_lines(ui.lesson_view.buf, 0, -1, false), "\n"):find("EXAM MODE ACTIVO", 1, true) ~= nil,
  "Exam Mode is visible in the active lesson panel")
state = progress.load()
local before_hints = progress.lesson_status(state, track.id, track._ordered_lessons[2].id).hints
commands.hint()
state = progress.load()
check(progress.lesson_status(state, track.id, track._ordered_lessons[2].id).hints == before_hints, "Exam Mode blocks plugin hints")
commands.abandon()
state = progress.load()
check(state.tracks[track.id].lessons[track._ordered_lessons[2].id].abandoned_at == nil, "Exam Mode blocks reference-solution disclosure")
commands.exam("stop")
check(not table.concat(vim.api.nvim_buf_get_lines(ui.lesson_view.buf, 0, -1, false), "\n"):find("EXAM MODE ACTIVO", 1, true),
  "stopping Exam Mode removes its active banner")

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
check(timed.timed_out == true and (timed.code ~= 0 or timed.signal ~= nil),
  "Cargo timeout is reported and terminated: " .. vim.inspect(timed))
local cancelled = wait_for_process(30000, true)
check(cancelled.cancelled == true, "running Cargo process can be cancelled")

ui.close()
fs.remove_tree(temporary)
print("Forja tests passed: curriculum, graph, storage, mastery, recall, commands, responsive UI, transfer isolation, assessment gating, async runner, timeout and cancellation")
vim.cmd("qa!")
