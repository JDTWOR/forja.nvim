local M = { current = nil, resize_group = nil }

local function dimensions()
  local columns, lines = vim.o.columns, vim.o.lines
  local width = math.max(24, math.min(92, columns - 4))
  local height = math.max(5, math.min(30, lines - 6))
  return width, height
end

function M.close()
  local view = M.current
  M.current = nil
  if not view then return end
  if view.win and vim.api.nvim_win_is_valid(view.win) then vim.api.nvim_win_close(view.win, true) end
  if view.buf and vim.api.nvim_buf_is_valid(view.buf) then vim.api.nvim_buf_delete(view.buf, { force = true }) end
end

local function resize()
  local view = M.current
  if not view or not vim.api.nvim_win_is_valid(view.win) then return end
  local width, height = dimensions()
  vim.api.nvim_win_set_config(view.win, {
    relative = "editor",
    width = width,
    height = height,
    row = math.max(0, math.floor((vim.o.lines - height) / 2) - 1),
    col = math.max(0, math.floor((vim.o.columns - width) / 2)),
  })
end

function M.open(lines, title, opts)
  opts = opts or {}
  M.close()
  local width, height = dimensions()
  local buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  vim.bo[buf].buftype = "nofile"
  vim.bo[buf].bufhidden = "wipe"
  vim.bo[buf].swapfile = false
  vim.bo[buf].filetype = "markdown"
  vim.bo[buf].modifiable = false
  local win = vim.api.nvim_open_win(buf, opts.focus ~= false, {
    relative = "editor",
    width = width,
    height = height,
    row = math.max(0, math.floor((vim.o.lines - height) / 2) - 1),
    col = math.max(0, math.floor((vim.o.columns - width) / 2)),
    style = "minimal",
    border = "rounded",
    title = " " .. (title or "Forja") .. " ",
    title_pos = "center",
  })
  M.current = { buf = buf, win = win }
  vim.keymap.set("n", "q", M.close, { buffer = buf, silent = true, desc = "Close Forja view" })
  vim.keymap.set("n", "<Esc>", M.close, { buffer = buf, silent = true, desc = "Close Forja view" })
  if not M.resize_group then
    M.resize_group = vim.api.nvim_create_augroup("ForjaUI", { clear = true })
    vim.api.nvim_create_autocmd("VimResized", { group = M.resize_group, callback = resize })
    vim.api.nvim_create_autocmd("WinClosed", {
      group = M.resize_group,
      callback = function(event)
        if M.current and tostring(M.current.win) == event.match then M.current = nil end
      end,
    })
  end
  return buf, win
end

function M.notify(message, level)
  vim.notify("Forja: " .. message, level or vim.log.levels.INFO)
end

function M.lines(title, lines)
  return M.open(lines, title)
end

function M.dashboard(lines, actions)
  local buf = M.open(lines, "Forja · aprendizaje")
  local mappings = {
    ["s"] = { actions.start, "Start or resume" },
    ["t"] = { actions.tracks, "Browse tracks" },
    ["l"] = { actions.lesson, "Open lesson" },
    ["n"] = { actions.next, "Next eligible lesson" },
    ["p"] = { actions.progress, "Show progress" },
    ["r"] = { actions.review, "Review" },
  }
  for key, mapping in pairs(mappings) do
    vim.keymap.set("n", key, mapping[1], { buffer = buf, silent = true, desc = mapping[2] })
  end
  return buf
end

return M
