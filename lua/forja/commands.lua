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
local session_loaded = false
local modified_workspace_buffers

local concept_labels = {
  ["rust.binding"] = "bindings", ["rust.mutability"] = "mutability", ["rust.shadowing"] = "shadowing",
  ["rust.scalar-types"] = "tipos escalares", ["rust.integer-types"] = "tipos enteros",
  ["rust.floating-point"] = "punto flotante", ["rust.bool"] = "booleanos",
  ["rust.if"] = "expresiones if", ["rust.matching-ranges"] = "rangos y match", ["rust.branch-coverage"] = "cobertura de ramas",
  ["rust.functions"] = "funciones", ["rust.parameters"] = "parámetros", ["rust.return-values"] = "valores de retorno",
  ["rust.decomposition"] = "descomposición", ["rust.ownership"] = "ownership", ["rust.borrowing"] = "borrowing",
  ["rust.string-slice"] = "string slices", ["rust.lifetimes-intro"] = "lifetimes",
}

local function concept_text(concepts)
  local labels = {}
  for _, concept in ipairs(concepts or {}) do
    local label = concept_labels[concept]
    if not label then label = concept:gsub("^[^.]+%.", ""):gsub("[%.%-]", " ") end
    table.insert(labels, label)
  end
  return table.concat(labels, ", ")
end

local mastery_labels = {
  not_demonstrated = "sin demostrar", recognized = "reconocido", understood = "comprendido",
  reproduced = "reproducido con asistencia", applied = "aplicado", transferred = "transferido",
  independently_demonstrated = "demostrado de forma independiente",
}

local function load_state()
  local state, err = progress.load()
  if not state then ui.notify(err, vim.log.levels.ERROR); return nil end
  if not session_loaded then
    session_loaded = true
    local saved = state.practice_session
    if saved then
      local fs = require("forja.util.fs")
      local root = vim.uv.fs_realpath(fs.join(config.get().data_dir, "reviews"))
      local path = type(saved.path) == "string" and vim.uv.fs_realpath(saved.path) or nil
      local stat = type(saved.path) == "string" and vim.uv.fs_lstat(saved.path) or nil
      local track = curriculum.get(saved.track_id)
      local lesson = track and curriculum.lesson(track, saved.lesson_id)
      local source = path and lesson and workspace.source_file(path, lesson.exercise)
      local source_stat = source and vim.uv.fs_lstat(source)
      local source_real = source and vim.uv.fs_realpath(source)
      local transfer_path = path and vim.fn.fnamemodify(path, ":t"):match("^transfer%-") ~= nil
      local mode_valid = saved.mode == "practice" and transfer_path and lesson and lesson.exercise._variation_dir
        or (saved.mode == "review" or saved.mode == "exam") and not transfer_path
      local exam_consistent = (state.exam_active == true) == (saved.exam == true)
      local expected = root and track and lesson and fs.join(root, track.id, lesson.id)
      if expected and path and path:sub(1, #expected + 1) == expected .. "/" and stat and stat.type == "directory"
        and source_stat and source_stat.type == "file" and source_real and source_real:sub(1, #path + 1) == path .. "/" and track and lesson
        and mode_valid and exam_consistent then
        review_session = { track = track, lesson = lesson, path = path, mode = saved.mode, exam = saved.exam == true }
      else
        state.practice_session = nil
        state.exam_active = false
        state.exam_started_at = nil
        progress.save(state)
        ui.notify("la sesión guardada no se pudo restaurar; la evaluación se interrumpió y no se ejecutará el código base", vim.log.levels.WARN)
      end
    elseif state.exam_active then
      state.exam_active = false
      state.exam_started_at = nil
      progress.save(state)
      ui.notify("la evaluación anterior se interrumpió sin un workspace recuperable", vim.log.levels.WARN)
    end
  end
  return state
end

local function save_state(state)
  state.practice_session = review_session and { track_id = review_session.track.id, lesson_id = review_session.lesson.id,
    path = review_session.path, mode = review_session.mode, exam = review_session.exam == true } or nil
  local ok, err = progress.save(state)
  if not ok then ui.notify("no se pudo guardar el progreso: " .. tostring(err), vim.log.levels.ERROR) end
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
    if requested then ui.notify("ruta desconocida: " .. requested, vim.log.levels.ERROR); return nil end
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
  if not lesson then ui.notify("no hay una lección disponible", vim.log.levels.WARN); return false end
  local eligible, prerequisite = prerequisites_met(state, track, lesson)
  if not eligible then
    ui.notify("completa primero el requisito " .. prerequisite .. " con :ForjaTest", vim.log.levels.WARN)
    return false
  end
  local path, err
  if override_workspace then
    path = override_workspace
  else
    path, err = workspace.ensure(track, lesson)
  end
  if not path then ui.notify(err, vim.log.levels.ERROR); return false end
  local source = workspace.source_file(path, lesson.exercise)
  if not source then ui.notify("no se encontró el archivo fuente configurado para este ejercicio", vim.log.levels.ERROR); return false end
  local previous_track = state.active_track and curriculum.get(state.active_track) or nil
  local previous_lesson = previous_track and state.current_lesson and curriculum.lesson(previous_track, state.current_lesson) or nil
  local has_unsaved_changes = vim.bo[vim.api.nvim_get_current_buf()].modified
  if not has_unsaved_changes and modified_workspace_buffers then
    local previous_path = review_session and review_session.path
      or (previous_track and previous_lesson and workspace.path(previous_track, previous_lesson))
    if previous_path then has_unsaved_changes = #modified_workspace_buffers(previous_path) > 0 end
  end
  if has_unsaved_changes then
    ui.notify("guarda con :write el archivo modificado del ejercicio y vuelve a cambiar de lección; tus cambios siguen intactos", vim.log.levels.WARN)
    return false
  end
  ui.close()
  local code_win = vim.api.nvim_get_current_win()
  local previous_buf = vim.api.nvim_win_get_buf(code_win)
  local ok, edit_err = pcall(vim.api.nvim_cmd, { cmd = "edit", args = { source } }, {})
  if not ok then
    ui.notify("no se pudo abrir el archivo de práctica: " .. tostring(edit_err), vim.log.levels.ERROR)
    if previous_lesson then
      local previous_path = workspace.path(previous_track, previous_lesson)
      if vim.uv.fs_stat(previous_path) then require("forja.ui.lesson").render(previous_lesson, previous_path, mode, state.exam_active) end
    end
    return false
  end
  local old_track, old_lesson, old_started = state.active_track, state.current_lesson, state.session_started_at
  progress.lesson_status(state, track.id, lesson.id)
  state.active_track = track.id
  state.current_lesson = lesson.id
  state.session_started_at = state.session_started_at or os.time()
  if not save_state(state) then
    state.active_track, state.current_lesson, state.session_started_at = old_track, old_lesson, old_started
    if vim.api.nvim_buf_is_valid(previous_buf) then vim.api.nvim_win_set_buf(code_win, previous_buf) end
    if previous_lesson then
      local previous_path = workspace.path(previous_track, previous_lesson)
      if vim.uv.fs_stat(previous_path) then require("forja.ui.lesson").render(previous_lesson, previous_path, mode, state.exam_active) end
    end
    return false
  end
  require("forja.ui.lesson").render(lesson, path, mode, state.exam_active)
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
    "Ruta activa: " .. track.title .. "  ·  " .. done .. "/" .. total .. " lecciones demostradas",
    state.exam_active and "Exam Mode: activo · asistencia Forja deshabilitada" or "",
    "",
    lesson and ("Lección actual: " .. lesson.title) or "Ruta completada.",
    lesson and ("Objetivo: " .. lesson.objective) or "",
    "",
    "Siguiente acción: " .. (lesson and "s · continuar · l · abrir lección · :ForjaRecall · recuperar" or "t · explorar rutas"),
    "",
    "Revisiones programadas: el scheduler aún no está habilitado (consulta docs/roadmap.md).",
    "",
    "Conceptos con intentos fallidos:",
  }
  local weak = {}
  for _, item in ipairs(ordered(track)) do
    local entry = track_progress.lessons[item.id]
    if entry and not entry.completed and #(entry.attempts or {}) > 0 then
      table.insert(weak, "- " .. item.title .. " · " .. concept_text(item.concepts))
    end
  end
  if #weak == 0 then table.insert(lines, "- Todavía no hay evidencia de errores.") else vim.list_extend(lines, weak) end
  vim.list_extend(lines, { "", "Resultados recientes:" })
  local start = math.max(1, #state.history - 2)
  for i = #state.history, start, -1 do
    local item = state.history[i]
    local title = curriculum.lesson(track, item.lesson_id)
    local label = item.passed and (item.variation and "transferencia aprobada" or "evaluación aprobada") or "sin aprobar"
    table.insert(lines, "- " .. os.date("%Y-%m-%d %H:%M", item.at) .. " · " .. (title and title.title or item.lesson_id) .. " · " .. label)
  end
  if #state.history == 0 then table.insert(lines, "- Sin intentos aún.") end
  vim.list_extend(lines, {
    "",
    "Atajos: s comenzar · t rutas · l lección · n siguiente · p progreso · r repaso · q cerrar",
    "Comandos: :ForjaRecall · :ForjaRun · :ForjaTest · :ForjaHint · :ForjaExam · :ForjaHealth",
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
    recall = M.recall,
  })
end

function M.tracks()
  local state = load_state()
  if not state then return end
  local tracks, err = curriculum.list()
  if not tracks then ui.notify(err, vim.log.levels.ERROR); return end
  local lines = { "# Rutas disponibles", "" }
  for index, track in ipairs(tracks) do
    table.insert(lines, string.format("%d. %s · %d lecciones", index, track.title, #track.lessons))
  end
  table.insert(lines, "")
  table.insert(lines, "Presiona un número para iniciar esa ruta; q cierra esta ventana.")
  local buf = ui.open(lines, "Rutas de Forja")
  for index, track in ipairs(tracks) do
    local key = tostring(index)
    vim.keymap.set("n", key, function() M.start(track.id) end, { buffer = buf, silent = true })
  end
end

function M.start(track_id)
  local state = load_state()
  if not state then return end
  if state.exam_active then ui.notify("termina la evaluación con :ForjaExam stop antes de navegar", vim.log.levels.WARN); return end
  local track = get_track(state, track_id)
  if not track then return end
  local lesson = progress.first_incomplete(track, state)
  if not lesson then
    state.active_track = track.id
    state.current_lesson = nil
    save_state(state)
    ui.notify("has demostrado todas las lecciones de " .. track.title)
    M.dashboard()
    return
  end
  if open_lesson(state, track, lesson) then review_session = nil; save_state(state) end
end

function M.lesson(lesson_id)
  local state = load_state()
  if not state then return end
  if review_session and (not lesson_id or lesson_id == review_session.lesson.id) then
    return open_lesson(state, review_session.track, review_session.lesson, review_session.mode, review_session.path)
  end
  if state.exam_active then ui.notify("termina la evaluación con :ForjaExam stop antes de navegar", vim.log.levels.WARN); return end
  local track = get_track(state)
  if not track then return end
  local lesson = lesson_id and curriculum.lesson(track, lesson_id) or nil
  if lesson_id and not lesson then ui.notify("lección desconocida: " .. lesson_id, vim.log.levels.ERROR); return end
  if not lesson then lesson = state.current_lesson and curriculum.lesson(track, state.current_lesson) or progress.first_incomplete(track, state) end
  if not lesson then ui.notify("ya demostraste todas las lecciones de esta ruta", vim.log.levels.INFO); return end
  if open_lesson(state, track, lesson) then review_session = nil; save_state(state) end
end

function M.next()
  local state = load_state()
  if not state then return end
  if state.exam_active then ui.notify("termina la evaluación con :ForjaExam stop antes de navegar", vim.log.levels.WARN); return end
  local track = get_track(state)
  if not track then return end
  local current = state.current_lesson and curriculum.lesson(track, state.current_lesson) or nil
  if current then
    local record = progress.lesson_status(state, track.id, current.id)
    if not record.completed then
      ui.notify("aprueba :ForjaTest en " .. current.title .. " para desbloquear la siguiente lección", vim.log.levels.WARN)
      return
    end
  end
  local lesson = progress.first_incomplete(track, state)
  if not lesson then
    ui.notify("todas las lecciones están demostradas; usa :ForjaReview para practicar de memoria")
    return
  end
  if open_lesson(state, track, lesson) then review_session = nil; save_state(state) end
end

function M.progress()
  local state = load_state()
  if not state then return end
  local track = get_track(state)
  if not track then ui.notify("no se encontraron rutas de aprendizaje", vim.log.levels.WARN); return end
  local track_progress = progress.track(state, track.id)
  local lines = { "# Progreso · " .. track.title, "" }
  for _, lesson in ipairs(ordered(track)) do
    local entry = track_progress.lessons[lesson.id] or {}
    local marker = entry.completed and "[x]" or "[ ]"
    local level = entry.mastery_evidence and entry.mastery_evidence.level or "not_demonstrated"
    local transfer = ""
    if entry.variation then
      local passed = 0
      for _, attempt in ipairs(entry.variation.attempts or {}) do if attempt.passed then passed = passed + 1 end end
      transfer = string.format(" · transferencia %d intentos (%d aprobados, %d pistas, %d tutor)",
        #(entry.variation.attempts or {}), passed, entry.variation.hints or 0, entry.variation.ai_assistance or 0)
    end
    local latest = entry.latest_assessment and (" · última evaluación " .. (mastery_labels[entry.latest_assessment.level] or entry.latest_assessment.level)) or ""
    table.insert(lines, string.format("%s %s — %s · intentos %d · pistas %d · tutor %d · recuperaciones %d%s", marker, lesson.title,
      mastery_labels[level] or level, #(entry.attempts or {}), entry.hints or 0, entry.ai_assistance or 0,
      #(entry.recall_history or {}), transfer .. latest))
  end
  table.insert(lines, "")
  table.insert(lines, "La corrección y la asistencia se registran por separado; completar no demuestra por sí solo el dominio.")
  ui.lines("Progreso de Forja", lines)
end

function M.review(lesson_id)
  local exam_state = load_state()
  if not exam_state then return end
  if exam_state.exam_active then ui.notify("termina la evaluación con :ForjaExam stop antes de navegar", vim.log.levels.WARN); return end
  if lesson_id == "stop" then
    local session = review_session
    if not session then ui.notify("no hay una sesión de práctica enfocada", vim.log.levels.WARN); return end
    for _, item in ipairs(modified_workspace_buffers(session.path)) do
      local saved, save_err = pcall(vim.api.nvim_buf_call, item.buf, function()
        vim.api.nvim_cmd({ cmd = "write" }, {})
      end)
      if not saved then
        ui.notify("no se pudo guardar " .. vim.fn.fnamemodify(item.name, ":t") .. " del workspace de práctica: " .. tostring(save_err), vim.log.levels.ERROR)
        return
      end
    end
    review_session = nil
    local state = load_state()
    if not state then review_session = session; return end
    if not open_lesson(state, session.track, session.lesson) then
      review_session = session
      return
    end
    ui.notify("volviste al workspace de la lección; se conservó la copia de práctica")
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
    if not selected then ui.notify("no hay una lección demostrada con el identificador " .. lesson_id, vim.log.levels.WARN); return end
    candidates = { selected }
  end
  if #candidates == 0 then
    ui.notify("todavía no hay una lección demostrada lista para repaso", vim.log.levels.INFO)
    return
  end
  local function begin(lesson)
    local path, err = workspace.new_review(track, lesson)
    if not path then ui.notify(err, vim.log.levels.ERROR); return end
    if open_lesson(state, track, lesson, "review", path) then
      review_session = { track = track, lesson = lesson, path = path, mode = "review" }
      progress.begin_clean_attempt(state, track.id, lesson.id, false, path)
      save_state(state)
    end
  end
  if #candidates == 1 then begin(candidates[1]); return end
  vim.ui.select(candidates, {
    prompt = "Elige una lección demostrada para practicar desde cero",
    format_item = function(item) return item.title end,
  }, function(choice) if choice then begin(choice) end end)
end

local function trust_key(track, lesson, variation)
  return track.id .. "/" .. lesson.id .. (variation and "/transfer" or "")
end

function M.trust_local()
  local state = load_state()
  if not state then return end
  local track, lesson = active_context(state)
  if not track or not lesson then ui.notify("abre una lección primero", vim.log.levels.WARN); return end
  local variation = review_session ~= nil and review_session.mode == "practice"
  local options = { "Permitir ejecución local para " .. lesson.title .. (variation and " · transferencia" or ""), "Cancelar" }
  vim.ui.select(options, {
    prompt = "El ejecutor compila y ejecuta código local con los permisos de tu usuario.",
  }, function(choice)
    if choice ~= options[1] then return end
    workspace.trust(state, track, lesson, variation)
    save_state(state)
    ui.notify("ejecución local aprobada para " .. trust_key(track, lesson, variation))
  end)
end

modified_workspace_buffers = function(path)
  local root = vim.fn.fnamemodify(path, ":p"):gsub("/+$", "")
  local result = {}
  for _, buf in ipairs(vim.api.nvim_list_bufs()) do
    if vim.api.nvim_buf_is_loaded(buf) and vim.bo[buf].modified then
      local name = vim.api.nvim_buf_get_name(buf)
      if name ~= "" then
        name = vim.fn.fnamemodify(name, ":p")
        if name == root or name:sub(1, #root + 1) == root .. "/" then
          table.insert(result, { buf = buf, name = name })
        end
      end
    end
  end
  return result
end

local function execute_test_run(state, track, lesson, path, is_review, assessment)
  local is_variation = review_session ~= nil and review_session.mode == "practice"
  ui.notify(assessment and "evaluación iniciada en segundo plano" or "tests visibles iniciados en segundo plano")
  local started = os.time()
  local initial_assistance = is_variation and progress.variation_status(state, track.id, lesson.id) or record_for(state, track, lesson)
  local attempt_exam = state.exam_active == true
  local attempt_hints = attempt_exam and 0 or (initial_assistance.pending_hints or 0)
  local attempt_ai_assistance = attempt_exam and 0 or (initial_assistance.pending_ai_assistance or 0)
  runner.run(track, lesson, path, assessment, config.get().runner.timeout_ms, function(result)
    if result.error then
      local error_text = result.error
        :gsub("^could not start ", "no se pudo iniciar ")
        :gsub("^A Forja process is already running", "ya hay un proceso de Forja en ejecución")
      if result.missing_tool then
        ui.result("Falta una herramienta", {
          "No se registró un intento porque no se pudo iniciar el entorno de ejecución.",
          "Instala `" .. result.tool .. "` para este lenguaje o revisa el PATH.",
          "Consulta :ForjaHealth después de instalarlo.",
        })
        ui.notify("falta " .. result.tool .. "; no se registró un intento", vim.log.levels.ERROR)
        return
      end
      ui.result("Error de ejecución", { error_text, "", "Revisa :ForjaHealth y vuelve a intentar." })
      ui.notify(error_text, vim.log.levels.ERROR)
      return
    end
    if result.cancelled then
      ui.result("Ejecución cancelada", { "La ejecución se canceló; no se registró un resultado." })
      ui.notify("ejecución cancelada; no se registró un resultado", vim.log.levels.WARN)
      return
    end
    local raw_output = result.output or ""
    local passed = result.code == 0
    local latest = load_state()
    if not latest then return end
    local assistance = is_variation and progress.variation_status(latest, track.id, lesson.id) or record_for(latest, track, lesson)
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
      variation = is_variation,
      workspace = vim.uv.fs_realpath(path) or path,
    })
    assistance.pending_hints = pending_hints_after_start
    assistance.pending_ai_assistance = pending_ai_after_start
    save_state(latest)
    local output = result.output
    raw_output = output
    if result.timed_out or (result.signal and result.signal > 0) then
      output = "La ejecución terminó por timeout o señal. Revisa el límite configurado y vuelve a intentar."
      if not assessment then output = output .. "\n\n" .. (result.output or "") end
    elseif is_variation and assessment and not passed then
      output = "Evaluación de transferencia no aprobada. Las aserciones ocultas se omiten. Revisa el requisito de esta variación y prueba casos límite."
    elseif is_variation and passed and assessment then
      output = (record.independent and "✅ Variación resuelta de forma independiente.\n" or "✅ Variación aprobada; la asistencia queda registrada.\n")
        .. "Este resultado se guarda por separado y no desbloquea la siguiente lección."
    elseif assessment and not passed then
      output = "La evaluación no se aprobó. Las aserciones ocultas se omiten. Revisa los requisitos, usa `r` para tests visibles y vuelve a intentarlo."
    elseif passed and assessment then
      output = (record.independent and "✅ Evaluación aprobada de forma independiente.\n" or "✅ Evaluación aprobada; la asistencia queda registrada por separado.\n")
        .. "La siguiente lección está disponible con :ForjaNext."
    elseif passed then
      output = "✅ Los tests visibles pasaron. La lección se desbloquea al aprobar :ForjaTest.\n\n" .. output
    else
      output = "❌ Fallaron los tests visibles. Lee el diagnóstico del compilador o del test y úsalo para revisar el concepto.\n\n" .. output
    end
    local title = (is_variation and "Transferencia · " or "") .. (assessment and "Evaluación · " .. lesson.title or "Tests visibles · " .. lesson.title)
    ui.result(title, vim.split(output, "\n", { plain = true }))
    local summary
    if passed then
      summary = is_variation and "variación aprobada" or "tests aprobados"
    elseif result.signal and result.signal > 0 then
      summary = "el proceso terminó por timeout o señal"
    elseif raw_output:find("FAILED", 1, true) or raw_output:find("FAIL", 1, true) then
      summary = assessment and "falló una o más comprobaciones de la evaluación" or "falló una o más comprobaciones visibles"
    elseif raw_output:find("error:", 1, true) or raw_output:find("Exception", 1, true)
      or raw_output:find("Traceback", 1, true) then
      summary = "error de compilación o ejecución"
    else
      summary = is_variation and "variación no aprobada" or (assessment and "evaluación no aprobada" or "fallaron los tests visibles")
    end
    ui.notify(summary .. " · usa :ForjaResult para ver el detalle",
      passed and vim.log.levels.INFO or vim.log.levels.WARN)
  end, is_variation)
end

local function test_run(assessment)
  local state = load_state()
  if not state then return end
  local track, lesson, path, is_review = active_context(state)
  if not track or not lesson then ui.notify("abre una lección primero", vim.log.levels.WARN); return end
  local is_variation = review_session ~= nil and review_session.mode == "practice"
  if not workspace.trusted(state, track, lesson, is_variation) then
    ui.notify("la ejecución local necesita aprobación para esta práctica; usa :ForjaTrustLocal", vim.log.levels.WARN)
    return
  end
  local modified = modified_workspace_buffers(path)
  if #modified == 0 then
    execute_test_run(state, track, lesson, path, is_review, assessment)
    return
  end
  vim.ui.select({ "Guardar los archivos del ejercicio y ejecutar", "Cancelar" }, {
    prompt = "Hay cambios sin guardar en el ejercicio",
    format_item = function(item) return item end,
  }, function(choice)
    if choice ~= "Guardar los archivos del ejercicio y ejecutar" then return end
    for _, item in ipairs(modified) do
      local ok, err = pcall(vim.api.nvim_buf_call, item.buf, function()
        vim.api.nvim_cmd({ cmd = "write" }, {})
      end)
      if not ok then
        ui.notify("no se pudo guardar " .. vim.fn.fnamemodify(item.name, ":t") .. ": " .. tostring(err), vim.log.levels.ERROR)
        return
      end
    end
    if #modified_workspace_buffers(path) > 0 then
      ui.notify("hay cambios sin guardar; no se ejecutaron los tests", vim.log.levels.ERROR)
      return
    end
    execute_test_run(state, track, lesson, path, is_review, assessment)
  end)
end

function M.hint()
  local state = load_state()
  if not state then return end
  if state.exam_active then ui.notify("las pistas están deshabilitadas durante Exam Mode", vim.log.levels.WARN); return end
  local track, lesson = active_context(state)
  if not track or not lesson then return end
  local is_variation = review_session ~= nil and review_session.mode == "practice"
  local count = progress.add_hint(state, track.id, lesson.id, is_variation)
  save_state(state)
  local hint = is_variation and (lesson.variation_hints or lesson.hints)[count] or lesson.hints[count]
  if not hint then
    ui.notify("se agotaron las pistas; :ForjaAbandon muestra la solución cuando termines el intento", vim.log.levels.WARN)
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

function M.recall()
  local state = load_state()
  if not state then return end
  if state.exam_active then
    ui.notify("la recuperación guiada está deshabilitada durante Exam Mode", vim.log.levels.WARN)
    return
  end
  local track, lesson = active_context(state)
  if not track or not lesson then return end
  ui.close("float")
  require("forja.ui.lesson").render(lesson, nil, "recall", state.exam_active)
  local answers = {}
  local function ask(index)
    local question = lesson.questions[index]
    if not question then
      local latest = load_state()
      if not latest then return end
      progress.record_recall(latest, track.id, lesson.id, answers)
      if not save_state(latest) then return end
      local lines = { "# Recuperación registrada · " .. lesson.title, "", "Tus respuestas quedan como evidencia de práctica; Forja no las califica automáticamente." }
      for i, response in ipairs(answers) do
        vim.list_extend(lines, { "", "## Pregunta " .. i, lesson.questions[i], "", response == "" and "(sin respuesta)" or response })
      end
      table.insert(lines, "")
      table.insert(lines, review_session
        and "Para volver a tu lección original, usa :ForjaReview stop; luego abre :ForjaLesson para comparar con la explicación."
        or "Usa :ForjaLesson para reabrir la explicación y comparar tus ideas.")
      ui.lines("Recuperación · " .. lesson.title, lines)
      return
    end
    vim.ui.input({ prompt = string.format("Recuperación %d/%d · %s: ", index, #lesson.questions, question), }, function(answer)
      if answer == nil then return end
      answers[index] = answer
      ask(index + 1)
    end)
  end
  ask(1)
end

function M.practice(lesson_id)
  local state = load_state()
  if not state then return end
  if state.exam_active then ui.notify("termina la evaluación con :ForjaExam stop antes de navegar", vim.log.levels.WARN); return end
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
  if not track or not lesson then ui.notify("abre una lección antes de iniciar una práctica enfocada", vim.log.levels.WARN); return end
  local eligible, prerequisite = prerequisites_met(state, track, lesson)
  if not eligible then
    ui.notify("completa el requisito " .. prerequisite .. " antes de iniciar esta práctica", vim.log.levels.WARN)
    return
  end
  local err
  path, err = workspace.new_practice(track, lesson)
  if not path then ui.notify(err, vim.log.levels.ERROR); return end
  if open_lesson(state, track, lesson, "practice", path) then
    review_session = { track = track, lesson = lesson, path = path, mode = "practice" }
    progress.begin_clean_attempt(state, track.id, lesson.id, true, path)
    save_state(state)
  end
end

function M.history()
  local state = load_state()
  if not state then return end
  if state.exam_active then ui.notify("termina la evaluación con :ForjaExam stop antes de navegar", vim.log.levels.WARN); return end
  local track = get_track(state)
  if not track then return end
  local fs = require("forja.util.fs")
  local entries = {}
  local root = fs.join(config.get().data_dir, "reviews", track.id)
  for _, lesson in ipairs(ordered(track)) do
    local record = progress.lesson_status(state, track.id, lesson.id)
    for _, recall in ipairs(record.recall_history or {}) do
      table.insert(entries, { label = "Recuperación · " .. lesson.title .. " · " .. os.date("%Y-%m-%d %H:%M", recall.at), lesson = lesson, recall = recall })
    end
    for _, path in ipairs(vim.fn.glob(fs.join(root, lesson.id, "*"), false, true)) do
      local stat = vim.uv.fs_lstat(path)
      local real = vim.uv.fs_realpath(path)
      local real_root = vim.uv.fs_realpath(root)
      if stat and stat.type == "directory" and real and real_root and real:sub(1, #real_root + 1) == real_root .. "/" then
        local transfer = vim.fn.fnamemodify(path, ":t"):match("^transfer%-") ~= nil
        local source = workspace.source_file(path, lesson.exercise)
        local source_real = source and vim.uv.fs_realpath(source)
        local source_stat = source and vim.uv.fs_lstat(source)
        if source_real and source_real:sub(1, #real + 1) == real .. "/" and source_stat and source_stat.type == "file" then
          table.insert(entries, { label = (transfer and "Transferencia" or "Repaso/evaluación") .. " · " .. lesson.title .. " · " .. vim.fn.fnamemodify(path, ":t"),
            lesson = lesson, path = path, mode = transfer and "practice" or "review" })
        end
      end
    end
  end
  if #entries == 0 then ui.notify("todavía no hay recuperaciones ni workspaces de práctica guardados"); return end
  vim.ui.select(entries, { prompt = "Historial: revisar respuestas o reanudar un workspace", format_item = function(item) return item.label end }, function(item)
    if not item then return end
    if item.recall then
      local lines = { "# " .. item.label, "", "Respuestas guardadas; no son una calificación automática." }
      for index, answer in ipairs(item.recall.answers or {}) do
        vim.list_extend(lines, { "", "## " .. (item.lesson.questions[index] or ("Pregunta " .. index)), answer })
      end
      table.insert(lines, "")
      table.insert(lines, review_session
        and "Para comparar con la explicación, termina la sesión con :ForjaReview stop y abre :ForjaLesson."
        or "Para comparar con la explicación, abre :ForjaLesson.")
      ui.lines("Historial de recuperación", lines)
    elseif open_lesson(state, track, item.lesson, item.mode, item.path) then
      review_session = { track = track, lesson = item.lesson, path = item.path, mode = item.mode }
      local record = item.mode == "practice" and progress.variation_status(state, track.id, item.lesson.id) or progress.lesson_status(state, track.id, item.lesson.id)
      record.session = record.session or { id = 0, hints = 0, ai_assistance = 0, solution_disclosed = false }
      record.session.resumed_uncertified = true
      save_state(state)
      ui.notify("workspace reanudado; se conserva la evidencia de asistencia previa")
    end
  end)
end

function M.exam(argument)
  local state = load_state()
  if not state then return end
  local function refresh()
    if not state.current_lesson and not review_session then return end
    local track, lesson, path = active_context(state)
    if track and lesson and path then
      require("forja.ui.lesson").render(lesson, path, review_session and review_session.mode or nil, state.exam_active)
    end
  end
  if argument == "stop" or state.exam_active then
    state.exam_active = false
    state.exam_started_at = nil
    save_state(state)
    ui.notify("Exam Mode terminó. Desactiva la asistencia de Forja, pero no controla herramientas externas.")
    if review_session and review_session.exam then
      M.review("stop")
    else
      refresh()
    end
    return
  end
  local track, lesson = active_context(state)
  if not track or not lesson then ui.notify("abre una lección antes de iniciar Exam Mode", vim.log.levels.WARN); return end
  local variation = review_session ~= nil and review_session.mode == "practice"
  local path, err
  if variation then path, err = workspace.new_practice(track, lesson) else path, err = workspace.new_review(track, lesson) end
  if not path then ui.notify(err, vim.log.levels.ERROR); return end
  if not open_lesson(state, track, lesson, variation and "practice" or "exam", path) then return end
  review_session = { track = track, lesson = lesson, path = path, mode = variation and "practice" or "exam", exam = true }
  progress.begin_clean_attempt(state, track.id, lesson.id, variation, path)
  state.exam_active = true
  state.exam_started_at = os.time()
  save_state(state)
  ui.notify("Exam Mode activo para " .. lesson.title .. ": tutor y pistas deshabilitados; ejecuta :ForjaTest al terminar")
  refresh()
end

function M.abandon()
  local state = load_state()
  if not state then return end
  if state.exam_active then
    ui.notify("cierra Exam Mode con :ForjaExam stop antes de revisar la solución", vim.log.levels.WARN)
    return
  end
  local track, lesson = active_context(state)
  if not track or not lesson then return end
  local is_variation = review_session ~= nil and review_session.mode == "practice"
  local record = is_variation and progress.variation_status(state, track.id, lesson.id) or record_for(state, track, lesson)
  progress.record_solution_disclosure(state, track.id, lesson.id, is_variation)
  record.abandoned_at = os.time()
  save_state(state)
  local path = is_variation
      and require("forja.util.fs").join(lesson.exercise._variation_dir, lesson.exercise._variation_manifest.solution_file)
      or require("forja.util.fs").join(lesson.exercise._dir, lesson.exercise.solution_file)
  local solution, err = require("forja.util.fs").read(path)
  if not solution then ui.notify("no se pudo leer la solución de referencia: " .. tostring(err), vim.log.levels.ERROR); return end
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

function M.close_view()
  local current = vim.api.nvim_get_current_win()
  if ui.current and ui.current.win == current then
    ui.close("float")
  elseif ui.lesson_view then
    ui.close("lesson")
  else
    ui.close()
  end
end

function M.tutor()
  local state = load_state()
  if not state then return end
  if state.exam_active then ui.notify("el tutor está deshabilitado durante Exam Mode", vim.log.levels.WARN); return end
  local track, lesson = active_context(state)
  if not track or not lesson then return end
  local is_variation = review_session ~= nil and review_session.mode == "practice"
  vim.ui.input({ prompt = "¿En qué parte te atascaste? " }, function(question)
    if not question or question == "" then return end
    local current_state = load_state()
    if not current_state or current_state.exam_active then
      ui.notify("el tutor está deshabilitado durante Exam Mode", vim.log.levels.WARN)
      return
    end
    local provider = config.get().ai.provider
    local request = {
      system = require("forja.ai.prompts").system,
      context = require("forja.ai.context").build(track, lesson, state, question, "socratic", is_variation),
    }
    local complete = require("forja.ai.interface").request
    if not provider then provider = require("forja.ai.mock") end
    complete(provider, request, function(response)
      if not response or response.error or type(response.text) ~= "string" then
        ui.notify(response and response.error or "la respuesta del tutor no tiene el formato esperado", vim.log.levels.ERROR)
        return
      end
      local latest = load_state()
      if not latest then return end
      if latest.exam_active then
        ui.notify("se descartó la respuesta porque Exam Mode está activo", vim.log.levels.WARN)
        return
      end
      progress.add_ai_assistance(latest, track.id, lesson.id, is_variation)
      save_state(latest)
      ui.lines("Tutor socrático · " .. lesson.title, {
        "# Guía socrática",
        "",
        response.text,
        "",
        provider == require("forja.ai.mock") and "Modo offline: pregunta fija; no es una respuesta generada por IA." or "La respuesta es orientación educativa, no un veredicto de competencia.",
      })
    end)
  end)
end

function M.health()
  local checks = {}
  table.insert(checks, { "Neovim >= 0.10", vim.fn.has("nvim-0.10") == 1 })
  table.insert(checks, { "API asíncrona vim.system", type(vim.system) == "function" })
  local tracks, curriculum_err = curriculum.list()
  table.insert(checks, { "Currículo JSON y grafo de requisitos", tracks ~= nil })
  local adapters = require("forja.runner.adapters")
  if tracks then
    for _, track in ipairs(tracks) do
      local required, seen, missing = {}, {}, {}
      for _, lesson in ipairs(track._ordered_lessons) do
        local manifest = lesson.exercise._manifest
        for _, tool in ipairs((adapters.get(manifest.runner) or {}).tools or {}) do
          if not seen[tool] then
            seen[tool] = true
            table.insert(required, tool)
          end
        end
      end
      table.sort(required)
      for _, tool in ipairs(required) do
        if vim.fn.executable(tool) ~= 1 then table.insert(missing, tool) end
      end
      local detail = #missing == 0 and "disponible" or "opcional · falta " .. table.concat(missing, ", ")
      table.insert(checks, { track.language .. " toolchain", #missing == 0, detail })
    end
  end
  local state, state_err = progress.load()
  table.insert(checks, { "Almacenamiento de progreso", state ~= nil })
  local lines = { "# Salud de Forja", "" }
  for _, check in ipairs(checks) do
    table.insert(lines, (check[2] and "[ok] " or "[missing] ") .. check[1]
      .. (check[3] and " · " .. check[3] or ""))
  end
  if curriculum_err then table.insert(lines, "Detalle del currículo: " .. curriculum_err) end
  if state_err then table.insert(lines, "Detalle del almacenamiento: " .. state_err) end
  table.insert(lines, "")
  table.insert(lines, "Proveedor de IA: " .. (config.get().ai.provider and "configurado" or "opcional / sin configurar"))
  ui.lines("Salud de Forja", lines)
end

function M.export(path)
  local state = load_state()
  if not state then return end
  local function write_export(destination)
    if not destination or destination == "" then return end
    local absolute = vim.fn.fnamemodify(vim.fn.expand(destination), ":p")
    local source = vim.fn.fnamemodify(storage.path(), ":p")
    if absolute == source or absolute == source .. ".bak" then
      ui.notify("elige una ruta distinta al archivo de progreso activo", vim.log.levels.ERROR)
      return
    end
    if not save_state(state) then return end
    local contents, err = require("forja.util.fs").read(storage.path())
    if not contents then ui.notify("no se pudo leer el progreso para exportar: " .. tostring(err), vim.log.levels.ERROR); return end
    local ok, write_err = require("forja.util.fs").atomic_write(absolute, contents)
    if not ok then ui.notify("falló la exportación: " .. tostring(write_err), vim.log.levels.ERROR); return end
    ui.notify("progreso exportado a " .. absolute)
  end
  if path and path ~= "" then write_export(path); return end
  vim.ui.input({ prompt = "Exportar progreso JSON a: " }, write_export)
end

local function register(name, opts, callback)
  vim.api.nvim_create_user_command(name, callback, opts)
end

function M.setup()
  if not registered then
    registered = true
    register("Forja", { desc = "Abrir el panel de aprendizaje" }, M.dashboard)
    register("ForjaClose", { desc = "Cerrar la vista de Forja y volver al código" }, M.close_view)
    register("ForjaResult", { desc = "Mostrar el resultado más reciente" }, ui.show_result)
    register("ForjaStart", { nargs = "?", complete = function() return { "rust-foundations" } end, desc = "Iniciar o continuar una ruta" }, function(args) M.start(args.args ~= "" and args.args or nil) end)
    register("ForjaTracks", { desc = "Explorar rutas de aprendizaje" }, M.tracks)
    register("ForjaLesson", { nargs = "?", desc = "Abrir la lección actual o una indicada" }, function(args) M.lesson(args.args ~= "" and args.args or nil) end)
    register("ForjaNext", { desc = "Abrir la siguiente lección disponible" }, M.next)
    register("ForjaRun", { desc = "Ejecutar tests visibles de forma asíncrona" }, function() test_run(false) end)
    register("ForjaTest", { desc = "Ejecutar la evaluación aislada" }, function() test_run(true) end)
    register("ForjaTrustLocal", { desc = "Aprobar la ejecución local de este ejercicio" }, M.trust_local)
    register("ForjaCancel", { desc = "Cancel a running Forja process" }, function()
      if runner.cancel() then ui.notify("se solicitó cancelar el proceso") else ui.notify("no hay un proceso de Forja en ejecución", vim.log.levels.WARN) end
    end)
    register("ForjaHint", { desc = "Solicitar la siguiente pista gradual" }, M.hint)
    register("ForjaHistory", { desc = "Revisar respuestas y reanudar práctica guardada" }, M.history)
    register("ForjaRecall", { desc = "Responder las preguntas de recuperación" }, M.recall)
    register("ForjaTutor", { desc = "Consultar al tutor socrático" }, M.tutor)
    register("ForjaReview", { nargs = "?", desc = "Practicar de memoria una lección demostrada" }, function(args) M.review(args.args ~= "" and args.args or nil) end)
    register("ForjaPractice", { nargs = "?", desc = "Abrir la variación de transferencia" }, function(args) M.practice(args.args ~= "" and args.args or nil) end)
    register("ForjaExam", { nargs = "?", complete = function() return { "stop" } end, desc = "Iniciar o terminar Exam Mode" }, function(args) M.exam(args.args) end)
    register("ForjaAbandon", { desc = "Abandonar el intento y mostrar la solución" }, M.abandon)
    register("ForjaProgress", { desc = "Mostrar evidencia, intentos y asistencia" }, M.progress)
    register("ForjaHealth", { desc = "Revisar Forja y sus dependencias" }, M.health)
    register("ForjaExport", { nargs = "?", desc = "Exportar el progreso local en JSON" }, function(args) M.export(args.args) end)
  end
  if config.get().keymaps.enabled then
    local prefix = config.get().keymaps.prefix
    vim.keymap.set("n", prefix, M.dashboard, { desc = "Panel de aprendizaje Forja" })
    vim.keymap.set("n", prefix .. "q", M.close_view, { desc = "Cerrar vista Forja" })
    vim.keymap.set("n", prefix .. "o", ui.show_result, { desc = "Mostrar resultado Forja" })
  end
end

return M
