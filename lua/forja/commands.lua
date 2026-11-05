local config = require("forja.config")
local curriculum = require("forja.core.curriculum")
local progress = require("forja.core.progress")
local workspace = require("forja.core.workspace")
local storage = require("forja.storage.json")
local runner = require("forja.runner.process")
local ui = require("forja.ui")
local M = {}
local registered = false
local review_session

local function load_state()
  local state, err = progress.load()
  if not state then ui.notify(err, vim.log.levels.ERROR) end
  return state
end

local function save_state(state)
  local ok, err = progress.save(state)
  if not ok then ui.notify("could not save progress: " .. tostring(err), vim.log.levels.ERROR) end
  return ok
end

local function get_track(state, requested)
  local tracks, err = curriculum.list()
  if not tracks then ui.notify(err, vim.log.levels.ERROR); return nil end
  local wanted = requested or state.active_track
  if wanted then
    for _, track in ipairs(tracks) do
      if track.id == wanted then return track end
    end
    if requested then ui.notify("unknown track: " .. requested, vim.log.levels.ERROR); return nil end
  end
  return tracks[1]
end

local function ordered(track)
  return track and track._ordered_lessons or {}
end

local function record_for(state, track, lesson)
  return progress.lesson_status(state, track.id, lesson.id)
end

local function prerequisites_met(state, track, lesson)
  local track_progress = progress.track(state, track.id)
  for _, prerequisite in ipairs(lesson.prerequisites or {}) do
    local prerequisite_record = track_progress.lessons[prerequisite]
    if not prerequisite_record or not prerequisite_record.completed then return false, prerequisite end
  end
  return true
end

local function open_lesson(state, track, lesson, mode, override_workspace)
  if not lesson then ui.notify("no eligible lesson is available", vim.log.levels.WARN); return false end
  local eligible, prerequisite = prerequisites_met(state, track, lesson)
  if not eligible then
    ui.notify("complete prerequisite " .. prerequisite .. " with :ForjaTest first", vim.log.levels.WARN)
    return false
  end
  local path, err
  if override_workspace then
    path = override_workspace
  else
    path, err = workspace.ensure(track, lesson)
  end
  if not path then ui.notify(err, vim.log.levels.ERROR); return false end
  local source = workspace.source_file(path)
  if not source then ui.notify("exercise has no src/lib.rs or src/main.rs", vim.log.levels.ERROR); return false end
  state.active_track = track.id
  state.current_lesson = lesson.id
  state.session_started_at = state.session_started_at or os.time()
  if not save_state(state) then return false end
  ui.close()
  local ok, edit_err = pcall(vim.api.nvim_cmd, { cmd = "edit", args = { source } }, {})
  if not ok then ui.notify("could not open learner file: " .. tostring(edit_err), vim.log.levels.ERROR); return false end
  require("forja.ui.lesson").render(lesson, path, mode)
  return true
end

local function active_context(state)
  if review_session then return review_session.track, review_session.lesson, review_session.path, true end
  local track = get_track(state)
  if not track then return nil end
  local lesson = state.current_lesson and curriculum.lesson(track, state.current_lesson) or nil
  lesson = lesson or progress.first_incomplete(track, state)
  if not lesson then
    for _, item in ipairs(ordered(track)) do lesson = item end
  end
  if not lesson then return nil end
  local path, err = workspace.ensure(track, lesson)
  if not path then ui.notify(err, vim.log.levels.ERROR); return nil end
  return track, lesson, path, false
end

local function status_text(state, track, lesson)
  if not track then return { "Sin una ruta activa. Usa `:ForjaTracks` para elegir una." } end
  local done, total = 0, #ordered(track)
  local track_progress = progress.track(state, track.id)
  for _, item in ipairs(ordered(track)) do
    if track_progress.lessons[item.id] and track_progress.lessons[item.id].completed then done = done + 1 end
  end
  local lines = {
    "# Forja.nvim",
    "",
    "Ruta activa: " .. track.title .. "  ·  " .. done .. "/" .. total .. " lessons demostradas",
    "",
    lesson and ("Lección actual: " .. lesson.title) or "Ruta completada.",
    lesson and ("Objetivo: " .. lesson.objective) or "",
    "",
    "Siguiente acción: " .. (lesson and "s · Start/resume or l · open lesson" or "t · browse tracks"),
    "",
    "Revisiones programadas: scheduler todavía no habilitado (consulta docs/roadmap.md).",
    "",
    "Conceptos con intentos fallidos:",
  }
  local weak = {}
  for _, item in ipairs(ordered(track)) do
    local entry = track_progress.lessons[item.id]
    if entry and not entry.completed and #(entry.attempts or {}) > 0 then
      table.insert(weak, "- " .. item.title .. " · " .. table.concat(item.concepts, ", "))
    end
  end
  if #weak == 0 then table.insert(lines, "- Todavía no hay evidencia de errores.") else vim.list_extend(lines, weak) end
  vim.list_extend(lines, { "", "Resultados recientes:" })
  local start = math.max(1, #state.history - 2)
  for i = #state.history, start, -1 do
    local item = state.history[i]
    local label = item.passed and "visible/assessment passed" or "not passed"
    table.insert(lines, "- " .. os.date("%Y-%m-%d %H:%M", item.at) .. " · " .. item.lesson_id .. " · " .. label)
  end
  if #state.history == 0 then table.insert(lines, "- Sin intentos aún.") end
  vim.list_extend(lines, {
    "",
    "Atajos: s start · t tracks · l lesson · n next · p progress · r review · q close",
    "Comandos: :ForjaRun · :ForjaTest · :ForjaHint · :ForjaExam · :ForjaHealth",
  })
  return lines
end

function M.dashboard()
  local state = load_state()
  if not state then return end
  local track = get_track(state)
  local lesson = track and (state.current_lesson and curriculum.lesson(track, state.current_lesson) or progress.first_incomplete(track, state)) or nil
  ui.dashboard(status_text(state, track, lesson), {
    start = M.start,
    tracks = M.tracks,
    lesson = M.lesson,
    next = M.next,
    progress = M.progress,
    review = M.review,
  })
end

function M.tracks()
  local state = load_state()
  if not state then return end
  local tracks, err = curriculum.list()
  if not tracks then ui.notify(err, vim.log.levels.ERROR); return end
  local lines = { "# Rutas disponibles", "" }
  for index, track in ipairs(tracks) do
    table.insert(lines, string.format("%d. %s · %s · %d lessons", index, track.title, track.id, #track.lessons))
  end
  table.insert(lines, "")
  table.insert(lines, "Presiona un número para iniciar esa ruta; q cierra esta ventana.")
  local buf = ui.open(lines, "Rutas de Forja")
  for index, track in ipairs(tracks) do
    local key = tostring(index)
    vim.keymap.set("n", key, function() review_session = nil; M.start(track.id) end, { buffer = buf, silent = true })
  end
end

function M.start(track_id)
  review_session = nil
  local state = load_state()
  if not state then return end
  local track = get_track(state, track_id)
  if not track then return end
  state.active_track = track.id
  local lesson = progress.first_incomplete(track, state)
  if not lesson then
    state.current_lesson = nil
    save_state(state)
    ui.notify("has demostrado todas las lecciones de " .. track.title)
    M.dashboard()
    return
  end
  open_lesson(state, track, lesson)
end

function M.lesson(lesson_id)
  local state = load_state()
  if not state then return end
  if review_session and (not lesson_id or lesson_id == review_session.lesson.id) then
    return open_lesson(state, review_session.track, review_session.lesson, review_session.mode, review_session.path)
  end
  review_session = nil
  local track = get_track(state)
  if not track then return end
  local lesson = lesson_id and curriculum.lesson(track, lesson_id) or nil
  if lesson_id and not lesson then ui.notify("unknown lesson: " .. lesson_id, vim.log.levels.ERROR); return end
  if not lesson then lesson = progress.first_incomplete(track, state) end
  if not lesson then ui.notify("all lessons in this track are complete", vim.log.levels.INFO); return end
  open_lesson(state, track, lesson)
end

function M.next()
  review_session = nil
  local state = load_state()
  if not state then return end
  local track = get_track(state)
  if not track then return end
  local current = state.current_lesson and curriculum.lesson(track, state.current_lesson) or nil
  if current then
    local record = progress.lesson_status(state, track.id, current.id)
    if not record.completed then
      ui.notify("pass :ForjaTest for " .. current.title .. " to unlock the next lesson", vim.log.levels.WARN)
      return
    end
  end
  local lesson = progress.first_incomplete(track, state)
  if not lesson then
    ui.notify("all lessons are complete; use :ForjaReview for a clean retrieval attempt")
    return
  end
  open_lesson(state, track, lesson)
end

function M.progress()
  local state = load_state()
  if not state then return end
  local track = get_track(state)
  if not track then ui.notify("no curriculum tracks found", vim.log.levels.WARN); return end
  local track_progress = progress.track(state, track.id)
  local lines = { "# Progreso · " .. track.title, "" }
  for _, lesson in ipairs(ordered(track)) do
    local entry = track_progress.lessons[lesson.id] or {}
    local marker = entry.completed and "[x]" or "[ ]"
    local level = entry.mastery_evidence and entry.mastery_evidence.level or "not demonstrated"
    table.insert(lines, string.format("%s %s — %s · attempts %d · hints %d · AI %d", marker, lesson.title, level, #(entry.attempts or {}), entry.hints or 0, entry.ai_assistance or 0))
  end
  table.insert(lines, "")
  table.insert(lines, "Test correctness and assistance are recorded separately; completion alone is not a mastery claim.")
  ui.lines("Progreso de Forja", lines)
end

function M.review(lesson_id)
  if lesson_id == "stop" then
    local session = review_session
    if not session then ui.notify("no focused practice session is active", vim.log.levels.WARN); return end
    local current = vim.api.nvim_get_current_buf()
    local current_name = vim.api.nvim_buf_get_name(current)
    if current_name:find(session.path .. "/", 1, true) == 1 and vim.bo[current].modified then
      local saved, save_err = pcall(vim.api.nvim_cmd, { cmd = "write" }, {})
      if not saved then ui.notify("could not preserve practice workspace: " .. tostring(save_err), vim.log.levels.ERROR); return end
    end
    review_session = nil
    local state = load_state()
    if not state then review_session = session; return end
    if not open_lesson(state, session.track, session.lesson) then
      review_session = session
      return
    end
    ui.notify("returned to the learner workspace; the focused practice copy was preserved")
    return
  end
  local state = load_state()
  if not state then return end
  local track = get_track(state)
  if not track then return end
  local candidates = {}
  local track_progress = progress.track(state, track.id)
  for _, lesson in ipairs(ordered(track)) do
    if track_progress.lessons[lesson.id] and track_progress.lessons[lesson.id].completed then
      table.insert(candidates, lesson)
    end
  end
  if lesson_id then
    local selected
    for _, candidate in ipairs(candidates) do
      if candidate.id == lesson_id then selected = candidate; break end
    end
    if not selected then ui.notify("no completed lesson matches " .. lesson_id, vim.log.levels.WARN); return end
    candidates = { selected }
  end
  if #candidates == 0 then
    ui.notify("no completed lesson is ready for retrieval practice yet", vim.log.levels.INFO)
    return
  end
  local function begin(lesson)
    local path, err = workspace.new_review(track, lesson)
    if not path then ui.notify(err, vim.log.levels.ERROR); return end
    review_session = { track = track, lesson = lesson, path = path, mode = "review" }
    open_lesson(state, track, lesson, "review", path)
  end
  if #candidates == 1 then begin(candidates[1]); return end
  vim.ui.select(candidates, {
    prompt = "Choose a completed lesson for a clean retrieval attempt",
    format_item = function(item) return item.title .. " · " .. item.id end,
  }, function(choice) if choice then begin(choice) end end)
end

local function trust_key(track, lesson)
  return track.id .. "/" .. lesson.id
end

function M.trust_local()
  local state = load_state()
  if not state then return end
  local track, lesson = active_context(state)
  if not track or not lesson then ui.notify("start a lesson first", vim.log.levels.WARN); return end
  local options = { "Allow local Cargo execution for " .. lesson.id, "Cancel" }
  vim.ui.select(options, {
    prompt = "Local test runs execute your Rust code and build scripts on this machine.",
  }, function(choice)
    if choice ~= options[1] then return end
    workspace.trust(state, track, lesson)
    save_state(state)
    ui.notify("local Cargo execution approved for " .. trust_key(track, lesson))
  end)
end

local function test_run(assessment)
  local state = load_state()
  if not state then return end
  local track, lesson, path, is_review = active_context(state)
  if not track or not lesson then ui.notify("start a lesson first", vim.log.levels.WARN); return end
  if not workspace.trusted(state, track, lesson) then
    ui.notify("local execution is not approved yet; run :ForjaTrustLocal and confirm", vim.log.levels.WARN)
    return
  end
  ui.notify(assessment and "assessment started (Cargo runs asynchronously)" or "visible tests started (Cargo runs asynchronously)")
  local started = os.time()
  local initial_assistance = record_for(state, track, lesson)
  local attempt_exam = state.exam_active == true
  local attempt_hints = attempt_exam and 0 or (initial_assistance.pending_hints or 0)
  local attempt_ai_assistance = attempt_exam and 0 or (initial_assistance.pending_ai_assistance or 0)
  runner.run(track, lesson, path, assessment, config.get().runner.timeout_ms, function(result)
    if result.error then
      ui.notify(result.error, vim.log.levels.ERROR)
      return
    end
    if result.cancelled then
      ui.notify("run cancelled; no result recorded", vim.log.levels.WARN)
      return
    end
    local passed = result.code == 0
    local latest = load_state()
    if not latest then return end
    local assistance = record_for(latest, track, lesson)
    local pending_hints_after_start = math.max(0, (assistance.pending_hints or 0) - (initial_assistance.pending_hints or 0))
    local pending_ai_after_start = math.max(0, (assistance.pending_ai_assistance or 0) - (initial_assistance.pending_ai_assistance or 0))
    assistance.pending_hints = attempt_hints
    assistance.pending_ai_assistance = attempt_ai_assistance
    local record = progress.record_attempt(latest, track, lesson, {
      passed = passed,
      assessment = assessment,
      hints = attempt_hints,
      ai_assistance = attempt_ai_assistance,
      exam = attempt_exam,
      execution_seconds = os.time() - started,
      review = is_review,
    })
    assistance.pending_hints = pending_hints_after_start
    assistance.pending_ai_assistance = pending_ai_after_start
    save_state(latest)
    local output = result.output
    if assessment and not passed then
      if output:find("error%[E%d+%]") or output:find("could not compile") then
        local lines = vim.split(output, "\n", { plain = true })
        while #lines > 24 do table.remove(lines) end
        output = "Assessment did not compile. Rust diagnostics:\n\n" .. table.concat(lines, "\n")
      else
        output = "Assessment not passed. Hidden assertions remain outside your exercise workspace.\n\nReview the requirements, run :ForjaRun for visible feedback, and try again."
      end
    elseif passed and assessment then
      output = (record.independent and "✅ Assessment passed independently.\n" or "✅ Assessment passed with assistance recorded separately.\n")
        .. "The next eligible lesson is available with :ForjaNext.\n\n" .. output
    elseif passed then
      output = "✅ Visible tests passed. The lesson unlocks only after :ForjaTest passes.\n\n" .. output
    else
      output = "❌ Visible tests failed. Read the compiler/test output, then use the failure as evidence about the concept.\n\n" .. output
    end
    ui.lines(assessment and "Evaluación · " .. lesson.title or "Tests visibles · " .. lesson.title, vim.split(output, "\n", { plain = true }))
  end)
end

function M.hint()
  local state = load_state()
  if not state then return end
  if state.exam_active then ui.notify("hints are disabled during Exam Mode", vim.log.levels.WARN); return end
  local track, lesson = active_context(state)
  if not track or not lesson then return end
  local count = progress.add_hint(state, track.id, lesson.id)
  save_state(state)
  local hint = lesson.hints[count]
  if not hint then
    ui.notify("hint ladder exhausted; :ForjaAbandon reveals the reference solution after you stop the attempt", vim.log.levels.WARN)
    return
  end
  ui.lines("Pista " .. count .. "/6 · " .. lesson.title, {
    "# Pista " .. count .. "/6",
    "",
    hint,
    "",
    "La pista queda registrada como asistencia; los errores siguen siendo evidencia útil.",
  })
end

function M.practice(lesson_id)
  local state = load_state()
  if not state then return end
  local track, lesson, path
  if lesson_id then
    track = get_track(state)
    lesson = track and curriculum.lesson(track, lesson_id)
    if not lesson then ui.notify("unknown lesson: " .. lesson_id, vim.log.levels.ERROR); return end
  elseif review_session then
    track, lesson = review_session.track, review_session.lesson
  else
    track = get_track(state)
    lesson = track and (state.current_lesson and curriculum.lesson(track, state.current_lesson) or progress.first_incomplete(track, state))
  end
  if not track or not lesson then ui.notify("start a lesson before focused practice", vim.log.levels.WARN); return end
  local eligible, prerequisite = prerequisites_met(state, track, lesson)
  if not eligible then
    ui.notify("complete prerequisite " .. prerequisite .. " before focused practice", vim.log.levels.WARN)
    return
  end
  local err
  path, err = workspace.new_review(track, lesson)
  if not path then ui.notify(err, vim.log.levels.ERROR); return end
  review_session = { track = track, lesson = lesson, path = path, mode = "practice" }
  open_lesson(state, track, lesson, "practice", path)
end

function M.exam(argument)
  local state = load_state()
  if not state then return end
  if argument == "stop" or state.exam_active then
    state.exam_active = false
    state.exam_started_at = nil
    save_state(state)
    ui.notify("Exam Mode ended. This only disables tutor-controlled assistance; it cannot block external tools.")
    return
  end
  local track, lesson = active_context(state)
  if not track or not lesson then ui.notify("start a lesson before Exam Mode", vim.log.levels.WARN); return end
  progress.reset_pending_assistance(state, track.id, lesson.id)
  state.exam_active = true
  state.exam_started_at = os.time()
  save_state(state)
  ui.notify("Exam Mode active for " .. lesson.title .. ": AI and hints are disabled; run :ForjaTest when ready")
end

function M.abandon()
  local state = load_state()
  if not state then return end
  local track, lesson = active_context(state)
  if not track or not lesson then return end
  local record = record_for(state, track, lesson)
  record.abandoned_at = os.time()
  save_state(state)
  local path = require("forja.util.fs").join(lesson.exercise._dir, lesson.exercise.solution_file)
  local solution, err = require("forja.util.fs").read(path)
  if not solution then ui.notify("cannot read reference solution: " .. tostring(err), vim.log.levels.ERROR); return end
  ui.lines("Revisión de solución · " .. lesson.title, {
    "# Solución de referencia",
    "",
    "La solución se muestra después de abandonar explícitamente este intento.",
    "Tu workspace no se modifica. Cierra con q y vuelve a implementarla de memoria.",
    "",
    "```rust",
    vim.trim(solution),
    "```",
  })
end

function M.tutor()
  local state = load_state()
  if not state then return end
  if state.exam_active then ui.notify("the tutor is disabled during Exam Mode", vim.log.levels.WARN); return end
  local track, lesson = active_context(state)
  if not track or not lesson then return end
  vim.ui.input({ prompt = "¿En qué parte te atascaste? " }, function(question)
    if not question or question == "" then return end
    local provider = config.get().ai.provider
    local request = {
      system = require("forja.ai.prompts").system,
      context = require("forja.ai.context").build(track, lesson, state, question, "socratic"),
    }
    local complete = require("forja.ai.interface").request
    if not provider then provider = require("forja.ai.mock") end
    complete(provider, request, function(response)
      if not response or response.error or type(response.text) ~= "string" then
        ui.notify(response and response.error or "AI response was malformed", vim.log.levels.ERROR)
        return
      end
      local latest = load_state()
      if not latest then return end
      if latest.exam_active then
        ui.notify("tutor response discarded because Exam Mode is active", vim.log.levels.WARN)
        return
      end
      progress.add_ai_assistance(latest, track.id, lesson.id)
      save_state(latest)
      ui.lines("Tutor socrático · " .. lesson.title, {
        "# Guía socrática",
        "",
        response.text,
        "",
        provider == require("forja.ai.mock") and "Modo offline: pregunta fija, no es una respuesta de IA." or "La respuesta es orientación educativa, no un veredicto de competencia.",
      })
    end)
  end)
end

function M.health()
  local checks = {}
  table.insert(checks, { "Neovim >= 0.10", vim.fn.has("nvim-0.10") == 1 })
  table.insert(checks, { "vim.system async process API", type(vim.system) == "function" })
  table.insert(checks, { "/bin/sh fixed runner wrapper", vim.fn.executable("/bin/sh") == 1 })
  table.insert(checks, { "Rust compiler (rustc)", vim.fn.executable("rustc") == 1 })
  table.insert(checks, { "Cargo", vim.fn.executable("cargo") == 1 })
  local tracks = curriculum.list()
  table.insert(checks, { "Curriculum JSON and DAG", tracks ~= nil })
  local state, state_err = progress.load()
  table.insert(checks, { "Progress storage", state ~= nil })
  local lines = { "# Forja health", "" }
  for _, check in ipairs(checks) do table.insert(lines, (check[2] and "[ok] " or "[missing] ") .. check[1]) end
  if state_err then table.insert(lines, "Storage detail: " .. state_err) end
  table.insert(lines, "")
  table.insert(lines, "AI provider: " .. (config.get().ai.provider and "configured" or "optional / not configured"))
  ui.lines("Forja health", lines)
end

function M.export(path)
  local state = load_state()
  if not state then return end
  local function write_export(destination)
    if not destination or destination == "" then return end
    local absolute = vim.fn.fnamemodify(vim.fn.expand(destination), ":p")
    local source = vim.fn.fnamemodify(storage.path(), ":p")
    if absolute == source or absolute == source .. ".bak" then
      ui.notify("choose a different path from the active progress file", vim.log.levels.ERROR)
      return
    end
    if not save_state(state) then return end
    local contents, err = require("forja.util.fs").read(storage.path())
    if not contents then ui.notify("could not read progress for export: " .. tostring(err), vim.log.levels.ERROR); return end
    local ok, write_err = require("forja.util.fs").atomic_write(absolute, contents)
    if not ok then ui.notify("export failed: " .. tostring(write_err), vim.log.levels.ERROR); return end
    ui.notify("progress exported to " .. absolute)
  end
  if path and path ~= "" then write_export(path); return end
  vim.ui.input({ prompt = "Export progress JSON to: " }, write_export)
end

local function register(name, opts, callback)
  vim.api.nvim_create_user_command(name, callback, opts)
end

function M.setup()
  if not registered then
    registered = true
    register("Forja", { desc = "Open Forja learning dashboard" }, M.dashboard)
    register("ForjaStart", { nargs = "?", complete = function() return { "rust-foundations" } end, desc = "Start or resume a learning track" }, function(args) M.start(args.args ~= "" and args.args or nil) end)
    register("ForjaTracks", { desc = "Browse learning tracks" }, M.tracks)
    register("ForjaLesson", { nargs = "?", desc = "Open the current or named lesson" }, function(args) M.lesson(args.args ~= "" and args.args or nil) end)
    register("ForjaNext", { desc = "Open the next eligible lesson" }, M.next)
    register("ForjaRun", { desc = "Run visible exercise tests asynchronously" }, function() test_run(false) end)
    register("ForjaTest", { desc = "Run the isolated exercise assessment" }, function() test_run(true) end)
    register("ForjaTrustLocal", { desc = "Approve local execution for this exercise" }, M.trust_local)
    register("ForjaCancel", { desc = "Cancel a running Forja process" }, function()
      if runner.cancel() then ui.notify("process cancellation requested") else ui.notify("no Forja process is running", vim.log.levels.WARN) end
    end)
    register("ForjaHint", { desc = "Request the next graduated hint" }, M.hint)
    register("ForjaTutor", { desc = "Ask the Socratic tutor" }, M.tutor)
    register("ForjaReview", { nargs = "?", desc = "Start a clean retrieval practice on a completed lesson" }, function(args) M.review(args.args ~= "" and args.args or nil) end)
    register("ForjaPractice", { nargs = "?", desc = "Open the lesson's transfer variation" }, function(args) M.practice(args.args ~= "" and args.args or nil) end)
    register("ForjaExam", { nargs = "?", complete = function() return { "stop" } end, desc = "Toggle independent Exam Mode" }, function(args) M.exam(args.args) end)
    register("ForjaAbandon", { desc = "Abandon the attempt and reveal its reference solution" }, M.abandon)
    register("ForjaProgress", { desc = "Show per-lesson progress and assistance" }, M.progress)
    register("ForjaHealth", { desc = "Check Forja and Rust dependencies" }, M.health)
    register("ForjaExport", { nargs = "?", desc = "Export local progress JSON" }, function(args) M.export(args.args) end)
  end
  if config.get().keymaps.enabled then
    local prefix = config.get().keymaps.prefix
    vim.keymap.set("n", prefix, M.dashboard, { desc = "Forja dashboard" })
  end
end

return M
