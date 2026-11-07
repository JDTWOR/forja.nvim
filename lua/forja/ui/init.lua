local M = { current = nil, lesson_view = nil, output_view = nil, last_result = nil, views = {}, resize_group = nil }

local function clamp(value, low, high)
  if high < low then return high end
  return math.max(low, math.min(value, high))
end

local function layout()
  local columns, lines = vim.o.columns, vim.o.lines
  local width = math.max(1, math.min(92, columns - 4))
  local height = math.max(1, math.min(30, lines - 4))
  return width, height, columns, lines
end

local function set_reading_options(win)
  vim.wo[win].wrap = true
  vim.wo[win].linebreak = true
  vim.wo[win].breakindent = true
  vim.wo[win].scrolloff = 2
  vim.wo[win].number = false
  vim.wo[win].relativenumber = false
  vim.wo[win].signcolumn = "no"
  vim.wo[win].foldcolumn = "0"
end

local function float_config(title, requested_height)
  local width, height, columns, lines = layout()
  if requested_height then height = clamp(requested_height, 1, math.max(1, lines - 4)) end
  local border = columns >= 8 and lines >= 6 and "rounded" or "none"
  local config = {
    relative = "editor", width = width, height = height,
    row = math.max(0, math.floor((lines - height - (border == "none" and 0 or 2)) / 2)),
    col = math.max(0, math.floor((columns - width - (border == "none" and 0 or 2)) / 2)),
    style = "minimal", border = border,
  }
  if border ~= "none" then
    config.title = " " .. (title or "Forja") .. " "
    config.title_pos = "center"
  end
  return config
end

local function set_lesson_bar(win, view)
  if view.exam_active or view.mode == "review" or view.mode == "exam" or view.mode == "practice" then
    vim.wo[win].winbar = " Forja · intento independiente · r tests · t evaluar · q código"
      .. ((view.mode == "practice" or view.mode == "review") and " · b volver" or "")
    return
  end
  local labels = { "Reto", "Idea", "Ejemplo", "Recall", "Guía" }
  local tabs = {}
  for index, label in ipairs(labels) do
    table.insert(tabs, (view.section_index == index and "[" or "") .. index .. " " .. label
      .. (view.section_index == index and "]" or ""))
  end
  vim.wo[win].winbar = " Forja · " .. table.concat(tabs, " · ") .. " · q código"
end

local function remove_view(role, restore_focus)
  local view = M.views[role]
  if not view then return end
  M.views[role] = nil
  if role == "float" then M.current = nil end
  if role == "lesson" then M.lesson_view = nil end
  if role == "output" then M.output_view = nil end
  if view.win and vim.api.nvim_win_is_valid(view.win) then
    pcall(vim.api.nvim_win_close, view.win, true)
  end
  if view.buf and vim.api.nvim_buf_is_valid(view.buf) then
    pcall(vim.api.nvim_buf_delete, view.buf, { force = true })
  end
  if restore_focus and view.return_win and vim.api.nvim_win_is_valid(view.return_win) then
    pcall(vim.api.nvim_set_current_win, view.return_win)
  end
end

function M.close(role)
  if role then remove_view(role, true); return end
  remove_view("float", false)
  remove_view("output", false)
  remove_view("lesson", true)
end

local function resize_view(view)
  if not view or not view.win or not vim.api.nvim_win_is_valid(view.win) then return end
  if view.is_output and view.kind == "split" then
    local max_height = math.max(1, vim.o.lines - 5)
    local min_height = math.min(4, max_height)
    vim.api.nvim_win_set_height(view.win, clamp(math.floor(vim.o.lines * 0.28), min_height, math.min(12, max_height)))
    return
  end
  local columns = vim.o.columns
  if view.is_lesson and view.kind == "split" and columns < 90 then
    local old_win = view.win
    local keep_focus = vim.api.nvim_get_current_win() == old_win
    local win = vim.api.nvim_open_win(view.buf, keep_focus, float_config(view.title))
    set_reading_options(win)
    set_lesson_bar(win, view)
    view.win, view.kind = win, "float"
    pcall(vim.api.nvim_win_close, old_win, true)
    return
  end
  if view.is_lesson and view.kind == "float" and columns >= 90 then
    local old_win = view.win
    local keep_focus = vim.api.nvim_get_current_win() == old_win
    if view.return_win and vim.api.nvim_win_is_valid(view.return_win) then
      vim.api.nvim_set_current_win(view.return_win)
    end
    vim.cmd("leftabove vsplit")
    local win = vim.api.nvim_get_current_win()
    vim.api.nvim_win_set_buf(win, view.buf)
    vim.api.nvim_win_set_width(win, clamp(math.floor(columns * 0.4), 32, 64))
    set_reading_options(win)
    set_lesson_bar(win, view)
    view.win, view.kind = win, "split"
    pcall(vim.api.nvim_win_close, old_win, true)
    if not keep_focus and view.return_win and vim.api.nvim_win_is_valid(view.return_win) then
      vim.api.nvim_set_current_win(view.return_win)
    end
    return
  end
  if view.kind == "split" then
    vim.api.nvim_win_set_width(view.win, clamp(math.floor(columns * 0.4), 32, 64))
  else
    local lines = vim.api.nvim_buf_get_lines(view.buf, 0, -1, false)
    vim.api.nvim_win_set_config(view.win, float_config(view.title, #lines))
  end
end

local function install_lifecycle()
  if M.resize_group then return end
  M.resize_group = vim.api.nvim_create_augroup("ForjaUI", { clear = true })
  vim.api.nvim_create_autocmd("VimResized", {
    group = M.resize_group,
    callback = function()
      for _, view in pairs(M.views) do resize_view(view) end
    end,
  })
  vim.api.nvim_create_autocmd("WinClosed", {
    group = M.resize_group,
    callback = function(event)
      for role, view in pairs(M.views) do
        if tostring(view.win) == event.match then
          M.views[role] = nil
          if role == "float" then M.current = nil end
          if role == "lesson" then M.lesson_view = nil end
          if role == "output" then M.output_view = nil end
        end
      end
    end,
  })
end

local function make_buffer(lines, name)
  local buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  vim.bo[buf].buftype = "nofile"
  vim.bo[buf].bufhidden = "wipe"
  vim.bo[buf].swapfile = false
  vim.bo[buf].filetype = "markdown"
  vim.bo[buf].modifiable = false
  if name then pcall(vim.api.nvim_buf_set_name, buf, name) end
  return buf
end

local function bind_close(buf, role)
  vim.keymap.set("n", "q", function() remove_view(role, true) end,
    { buffer = buf, silent = true, desc = "Close Forja view" })
  vim.keymap.set("n", "<Esc>", function() remove_view(role, true) end,
    { buffer = buf, silent = true, desc = "Close Forja view" })
end

function M.open(lines, title, opts)
  opts = opts or {}
  remove_view("float", false)
  local return_win = vim.api.nvim_get_current_win()
  local buf = make_buffer(lines)
  local win = vim.api.nvim_open_win(buf, opts.focus ~= false, float_config(title, opts.fit and #lines or opts.height))
  set_reading_options(win)
  local view = { buf = buf, win = win, kind = "float", return_win = opts.return_win or return_win }
  M.views.float, M.current = view, view
  bind_close(buf, "float")
  install_lifecycle()
  return buf, win
end

function M.open_lesson(lines, title, code_win, mode, exam_active, practice_available, section_index)
  remove_view("lesson", false)
  code_win = code_win or vim.api.nvim_get_current_win()
  local buf = make_buffer(lines, "Forja " .. title)
  local view
  if vim.o.columns >= 90 then
    if vim.api.nvim_win_is_valid(code_win) then vim.api.nvim_set_current_win(code_win) end
    vim.cmd("leftabove vsplit")
    local win = vim.api.nvim_get_current_win()
    vim.api.nvim_win_set_buf(win, buf)
    vim.api.nvim_win_set_width(win, clamp(math.floor(vim.o.columns * 0.4), 32, 64))
    set_reading_options(win)
    view = { buf = buf, win = win, kind = "split", return_win = code_win, is_lesson = true, title = title, mode = mode, exam_active = exam_active, section_index = section_index or 1 }
    set_lesson_bar(win, view)
    vim.api.nvim_set_current_win(code_win)
  else
    local win = vim.api.nvim_open_win(buf, true, float_config(title, #lines))
    set_reading_options(win)
    view = { buf = buf, win = win, kind = "float", return_win = code_win, is_lesson = true, title = title, mode = mode, exam_active = exam_active, section_index = section_index or 1 }
    set_lesson_bar(win, view)
  end
  M.views.lesson, M.lesson_view = view, view
  bind_close(buf, "lesson")
  local actions = {
    r = { "ForjaRun", "Ejecutar tests visibles" },
    t = { "ForjaTest", "Ejecutar evaluación" },
    o = { "ForjaResult", "Ver último resultado" },
  }
  if exam_active then
    actions.e = { "ForjaExam stop", "Terminar Exam Mode" }
  else
    actions.a = { "ForjaRecall", "Practicar recuperación activa" }
    actions.h = { "ForjaHint", "Solicitar pista" }
    if practice_available then actions.p = { "ForjaPractice", "Abrir variación de transferencia" } end
  end
  if not exam_active and (mode == "practice" or mode == "review") then
    actions.b = { "ForjaReview stop", "Volver al workspace original" }
  end
  for key, action in pairs(actions) do
    vim.keymap.set("n", key, function() vim.cmd(action[1]) end,
      { buffer = buf, silent = true, desc = action[2] })
  end
  install_lifecycle()
  return view
end

function M.update_lesson(lines, title, section_index)
  local view = M.lesson_view
  if not view or not vim.api.nvim_buf_is_valid(view.buf) then return false end
  vim.bo[view.buf].modifiable = true
  vim.api.nvim_buf_set_lines(view.buf, 0, -1, false, lines)
  vim.bo[view.buf].modified = false
  vim.bo[view.buf].modifiable = false
  if title then
    view.section = title
    view.section_index = section_index or view.section_index
    if view.win and vim.api.nvim_win_is_valid(view.win) then
      set_lesson_bar(view.win, view)
    end
  end
  if view.kind == "float" and view.win and vim.api.nvim_win_is_valid(view.win) then
    vim.api.nvim_win_set_config(view.win, float_config(view.title, #lines))
  end
  if view.win and vim.api.nvim_win_is_valid(view.win) then
    vim.api.nvim_win_set_cursor(view.win, { 1, 0 })
  end
  return true
end

function M.open_output(title, lines)
  local previous = vim.api.nvim_get_current_win()
  local view = M.output_view
  if view and view.win and vim.api.nvim_win_is_valid(view.win) and view.kind == "split" then
    vim.bo[view.buf].modifiable = true
    vim.api.nvim_buf_set_lines(view.buf, 0, -1, false, lines)
    vim.bo[view.buf].modifiable = false
    view.title = title
    if vim.api.nvim_win_is_valid(view.win) then
      vim.wo[view.win].winbar = " Forja · " .. title .. " · q cerrar · r tests · t evaluación"
    end
    if previous ~= view.win and vim.api.nvim_win_is_valid(previous) then vim.api.nvim_set_current_win(previous) end
    return view
  end

  if vim.o.columns < 90 or vim.o.lines < 22 then
    M.open(lines, title, { focus = true, return_win = previous })
    M.current.is_output = true
    M.current.title = title
    return M.current
  end

  local source_win = M.lesson_view and M.lesson_view.return_win
  if not source_win or not vim.api.nvim_win_is_valid(source_win) then source_win = previous end
  if vim.api.nvim_win_is_valid(source_win) then vim.api.nvim_set_current_win(source_win) end
  vim.cmd("botright 10split")
  local win = vim.api.nvim_get_current_win()
  local buf = make_buffer(lines, "Forja Resultados")
  vim.api.nvim_win_set_buf(win, buf)
  local max_height = math.max(1, vim.o.lines - 5)
  local min_height = math.min(4, max_height)
  vim.api.nvim_win_set_height(win, clamp(math.floor(vim.o.lines * 0.28), min_height, math.min(12, max_height)))
  set_reading_options(win)
  vim.wo[win].winbar = " Forja · " .. title .. " · q cerrar · r tests · t evaluación"
  local output = { buf = buf, win = win, kind = "split", return_win = previous, title = title, is_output = true }
  M.views.output, M.output_view = output, output
  bind_close(buf, "output")
  vim.keymap.set("n", "r", function() vim.cmd("ForjaRun") end,
    { buffer = buf, silent = true, desc = "Run visible tests" })
  vim.keymap.set("n", "t", function() vim.cmd("ForjaTest") end,
    { buffer = buf, silent = true, desc = "Run assessment" })
  install_lifecycle()
  if vim.api.nvim_win_is_valid(previous) then vim.api.nvim_set_current_win(previous) end
  return output
end

function M.result(title, lines)
  M.last_result = { title = title, lines = lines }
  M.open_output(title, lines)
end

function M.show_result()
  if not M.last_result then
    M.notify("todavía no hay resultados; ejecuta :ForjaRun o :ForjaTest primero", vim.log.levels.WARN)
    return
  end
  return M.open_output(M.last_result.title, M.last_result.lines)
end

function M.notify(message, level)
  vim.notify("Forja: " .. message, level or vim.log.levels.INFO)
end

function M.lines(title, lines)
  return M.open(lines, title)
end

function M.dashboard(lines, actions)
  local buf, win = M.open(lines, "FORJA · APRENDIZAJE", { fit = true })
  vim.wo[win].winbar = "  FORJA   ·   [s] empezar/continuar   [e] lección   [l] lenguaje   [c] tutor IA   [q] cerrar"
  local ns = vim.api.nvim_create_namespace("forja-dashboard")
  for index, line in ipairs(lines) do
    local group = line:match("^FORJA") and "Title"
      or line:match("^━") and "Comment"
      or line:match("^PRÓXIMO PASO") and "DiagnosticInfo"
      or line:match("^TU RUTA") and "Special"
      or line:match("^CAMBIAR LENGUAJE") and "DiagnosticInfo"
      or line:match("^TUTOR IA") and "Special"
      or line:match("^RECORRIDO") and "Special"
      or line:match("^ACTIVIDAD") and "Special"
      or line:match("^  Progreso") and "DiagnosticInfo"
      or line:match("^%s*%[[slc]%]") and "DiagnosticInfo"
    if group then pcall(vim.api.nvim_buf_add_highlight, buf, ns, group, index - 1, 0, -1) end
  end
  local mappings = {}
  local function add(key, action, description)
    if type(action) == "function" then mappings[key] = { action, description } end
  end
  add("s", actions.start, "Empezar o continuar")
  add("l", actions.language or actions.tracks, "Cambiar lenguaje o ruta")
  add("c", actions.settings, "Configurar el tutor IA")
  add("n", actions.next, "Siguiente lección")
  add("p", actions.progress, "Ver progreso")
  add("r", actions.review, "Repasar")
  add("a", actions.recall, "Recuperación activa")
  if actions.lesson then mappings["e"] = { actions.lesson, "Abrir lección actual" } end
  for key, mapping in pairs(mappings) do
    vim.keymap.set("n", key, mapping[1], { buffer = buf, silent = true, desc = mapping[2] })
  end
  install_lifecycle()
  return buf
end

function M.track_picker(entries, selected, on_select)
  local buf, win = M.open({ "Cargando rutas..." }, "FORJA · RUTAS", { fit = true })
  vim.wo[win].cursorline = true
  vim.wo[win].cursorlineopt = "line"
  local ns = vim.api.nvim_create_namespace("forja-track-picker")
  local filter = ""
  local filtered, selectable_rows = {}, {}
  local current = math.max(1, math.min(selected or 1, #entries))

  local function matches(entry)
    if filter == "" then return true end
    local track = entry.track
    local haystack = table.concat({ track.language or "", track.title or "", track.description or "" }, " "):lower()
    return haystack:find(filter:lower(), 1, true) ~= nil
  end

  local function render()
    filtered, selectable_rows = {}, {}
    for index, entry in ipairs(entries) do
      if matches(entry) then table.insert(filtered, index) end
    end
    local lines = {
      "FORJA  /  RUTAS DE APRENDIZAJE",
      "Elige un lenguaje. Cada ruta conserva sus lecciones y su progreso.",
      "",
      "Buscar: " .. (filter == "" and "(sin filtro)" or filter),
      string.format("Mostrando %d de %d rutas", #filtered, #entries),
      "",
    }
    local current_visible = false
    local row_width = vim.api.nvim_win_get_width(win)
    local compact = row_width < 62
    local title_width = math.max(10, row_width - (compact and 10 or 38))
    for visible, index in ipairs(filtered) do
      local entry, track = entries[index], entries[index].track
      local language = tostring(track.language or ""):upper()
      local progress = entry.progress or ("0/" .. tostring(#(track.lessons or {})))
      local marker = compact and (entry.active and "●" or "○")
        or (entry.active and "● ACTIVA" or "○ disponible")
      local title = track.title or language
      if vim.fn.strdisplaywidth(title) > title_width then
        title = vim.fn.strcharpart(title, 0, title_width - 1) .. "…"
      end
      local title_column = string.format("%-" .. title_width .. "s", title)
      selectable_rows[visible] = #lines + 1
      if compact then
        table.insert(lines, string.format("  %d  %-8s  %s  %s", visible, language, progress, marker))
        table.insert(lines, "      " .. title_column)
      else
        table.insert(lines, string.format("  %d   %-8s  %s  %s   %s", visible, language,
          title_column, progress, marker))
      end
      local description = tostring(track.description or ""):gsub("%s+", " ")
      local description_width = math.max(16, row_width - 10)
      if vim.fn.strdisplaywidth(description) > description_width then
        description = vim.fn.strcharpart(description, 0, description_width - 3) .. "..."
      end
      table.insert(lines, "      " .. description)
      table.insert(lines, "")
      if index == current then current_visible = visible end
    end
    if #filtered == 0 then table.insert(lines, "  No hay rutas que coincidan. Pulsa x para limpiar el filtro.") end
    table.insert(lines, "  / buscar   ·   x limpiar   ·   j/k mover   ·   Enter abrir   ·   q volver")
    vim.bo[buf].modifiable = true
    vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
    vim.bo[buf].modified = false
    vim.bo[buf].modifiable = false
    if vim.api.nvim_win_is_valid(win) then
      vim.api.nvim_win_set_config(win, float_config("FORJA · RUTAS", #lines))
    end
    vim.api.nvim_buf_clear_namespace(buf, ns, 0, -1)
    vim.api.nvim_buf_add_highlight(buf, ns, "Title", 0, 0, -1)
    vim.api.nvim_buf_add_highlight(buf, ns, "Comment", 1, 0, -1)
    vim.api.nvim_buf_add_highlight(buf, ns, "DiagnosticInfo", 3, 0, -1)
    for visible, row in ipairs(selectable_rows) do
      vim.api.nvim_buf_add_highlight(buf, ns, entries[filtered[visible]].active and "DiagnosticOk" or "Identifier", row - 1, 0, -1)
      vim.api.nvim_buf_add_highlight(buf, ns, "Comment", row, 0, -1)
    end
    if vim.api.nvim_win_is_valid(win) then
      local target = current_visible and selectable_rows[current_visible] or math.min(1, #lines)
      if target and target > 0 then vim.api.nvim_win_set_cursor(win, { target, 0 }) end
    end
  end

  local function move(delta)
    if #filtered == 0 then return end
    local visible = 1
    for index, original in ipairs(filtered) do if original == current then visible = index; break end end
    visible = ((visible - 1 + delta) % #filtered) + 1
    current = filtered[visible]
    if vim.api.nvim_win_is_valid(win) then vim.api.nvim_win_set_cursor(win, { selectable_rows[visible], 0 }) end
  end
  local function choose(index)
    local entry = entries[index]
    if not entry then return end
    remove_view("float", true)
    on_select(entry.track)
  end
  local function choose_current()
    for _, index in ipairs(filtered) do if index == current then choose(index); return end end
  end
  local function search()
    vim.ui.input({ prompt = "Buscar lenguaje o ruta: ", default = filter }, function(value)
      if value == nil then return end
      local old = current
      filter = value
      local was_visible, first_match = false, nil
      for index, entry in ipairs(entries) do
        if matches(entry) then
          first_match = first_match or index
          if index == old then was_visible = true end
        end
      end
      if not was_visible then current = first_match or 1 end
      render()
    end)
  end
  render()
  vim.keymap.set("n", "j", function() move(1) end, { buffer = buf, silent = true, desc = "Siguiente lenguaje" })
  vim.keymap.set("n", "k", function() move(-1) end, { buffer = buf, silent = true, desc = "Lenguaje anterior" })
  vim.keymap.set("n", "<Down>", function() move(1) end, { buffer = buf, silent = true })
  vim.keymap.set("n", "<Up>", function() move(-1) end, { buffer = buf, silent = true })
  vim.keymap.set("n", "/", search, { buffer = buf, silent = true, desc = "Buscar ruta" })
  vim.keymap.set("n", "x", function() filter = ""; render() end,
    { buffer = buf, silent = true, desc = "Limpiar filtro" })
  vim.keymap.set("n", "<CR>", choose_current, { buffer = buf, silent = true, desc = "Abrir ruta" })
  for visible = 1, math.min(9, #filtered) do
    vim.keymap.set("n", tostring(visible), function()
      if filtered[visible] then choose(filtered[visible]) end
    end, { buffer = buf, silent = true, desc = "Elegir " .. entries[filtered[visible]].track.title })
  end
  return buf, win
end

function M.settings(lines, actions)
  local buf, win = M.open(lines, "FORJA · AJUSTES", { fit = true })
  vim.wo[win].winbar = "  FORJA   ·   [l] lenguaje   [k] API key"
    .. (actions.delete_key and "   [d] borrar key local" or "") .. "   [q] cerrar"
  local ns = vim.api.nvim_create_namespace("forja-settings")
  for index, line in ipairs(lines) do
    local group = line:match("^FORJA") and "Title"
      or line:match("^━") and "Comment"
      or line:match("^LENGUAJE") and "Special"
      or line:match("^TUTOR IA") and "Special"
      or line:match("^SEGURIDAD") and "DiagnosticWarn"
      or line:match("^%s*%[[lkd]%]") and "DiagnosticInfo"
    if group then pcall(vim.api.nvim_buf_add_highlight, buf, ns, group, index - 1, 0, -1) end
  end
  local mappings = {
    ["l"] = { actions.language, "Cambiar lenguaje" },
    ["k"] = { actions.set_key, "Guardar API key de forma local" },
    ["d"] = { actions.delete_key, "Borrar API key local" },
  }
  for key, mapping in pairs(mappings) do
    if mapping[1] then vim.keymap.set("n", key, mapping[1], { buffer = buf, silent = true, desc = mapping[2] }) end
  end
  install_lifecycle()
  return buf, win
end

return M
