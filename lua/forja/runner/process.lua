local fs = require("forja.util.fs")
local adapters = require("forja.runner.adapters")
local M = { active = nil }

local function result_output(stdout, stderr)
  local parts = {}
  if stdout ~= "" then table.insert(parts, stdout) end
  if stderr ~= "" then table.insert(parts, stderr) end
  return table.concat(parts, "\n"):gsub("\n+$", "")
end

function M.run(track, lesson, workspace, assessment, timeout_ms, callback, variation)
  local function fail(result)
    vim.schedule(function() callback(result) end)
  end
  if M.active then fail({ error = "A Forja process is already running" }); return end
  local exercise = lesson.exercise
  local manifest = variation and exercise._variation_manifest or exercise._manifest
  if not manifest then fail({ error = "exercise runner manifest is missing" }); return end
  local adapter = adapters.get(manifest.runner)
  if not adapter then fail({ error = "unsupported exercise runner: " .. tostring(manifest.runner) }); return end

  for _, tool in ipairs(adapter.tools or {}) do
    if vim.fn.executable(tool) ~= 1 then
      fail({ error = "required toolchain executable is unavailable: " .. tool, missing_tool = true, tool = tool })
      return
    end
  end

  local context = {
    track = track,
    lesson = lesson,
    exercise = exercise,
    manifest = manifest,
    workspace = workspace,
    assessment = assessment == true,
    variation = variation == true,
  }
  local prepared, prepare_err = adapter.prepare(context)
  if not prepared then fail({ error = prepare_err or "could not prepare exercise runner" }); return end
  local commands = prepared.commands
  if type(commands) ~= "table" or #commands == 0 then
    if prepared.temporary then fs.remove_tree(prepared.temporary) end
    fail({ error = "exercise adapter returned no commands" })
    return
  end
  for _, argv in ipairs(commands) do
    if type(argv) ~= "table" or type(argv[1]) ~= "string" or #argv == 0 then
      if prepared.temporary then fs.remove_tree(prepared.temporary) end
      fail({ error = "exercise adapter returned an invalid command" })
      return
    end
  end

  local uv = vim.uv or vim.loop
  local active = {
    temporary = prepared.temporary,
    assessment = assessment == true,
    variation = variation == true,
    cancelled = false,
    deadline = uv.hrtime() + (timeout_ms or manifest.timeout_ms or 30000) * 1000000,
    commands = commands,
    command_index = 1,
    stdout = {},
    stderr = {},
    cwd = prepared.cwd or workspace,
    env = prepared.env,
    after_step = prepared.after_step,
  }
  M.active = active

  local function finish(result)
    if result.stdout and result.stdout ~= "" then table.insert(active.stdout, result.stdout) end
    if result.stderr and result.stderr ~= "" then table.insert(active.stderr, result.stderr) end
    if active.timer then
      active.timer:stop()
      active.timer:close()
      active.timer = nil
    end
    if M.active == active then M.active = nil end
    if active.temporary then fs.remove_tree(active.temporary) end
    result.assessment = active.assessment
    result.variation = active.variation
    result.cancelled = active.cancelled
    result.timed_out = active.timed_out == true
    result.stdout = table.concat(active.stdout, "\n")
    result.stderr = table.concat(active.stderr, "\n")
    if not result.error then result.output = result_output(result.stdout, result.stderr) end
    vim.schedule(function() callback(result) end)
  end

  local spawn_next
  spawn_next = function()
    if active.cancelled then finish({ code = 143, signal = 9 }); return end
    local remaining = math.floor((active.deadline - uv.hrtime()) / 1000000)
    if remaining <= 0 then
      active.timed_out = true
      finish({ code = 124, signal = 9, stderr = "Execution deadline exceeded" })
      return
    end
    local argv = active.commands[active.command_index]
    local ok, process_or_error = pcall(vim.system, argv, {
      cwd = active.cwd,
      env = active.env,
      text = true,
      detach = true,
    }, function(result)
      if active.timer then
        active.timer:stop()
        active.timer:close()
        active.timer = nil
      end
      if result.stdout and result.stdout ~= "" then table.insert(active.stdout, result.stdout) end
      if result.stderr and result.stderr ~= "" then table.insert(active.stderr, result.stderr) end
      if active.cancelled then
        finish({ code = result.code, signal = result.signal })
        return
      end
      if result.code ~= 0 then
        finish({ code = result.code, signal = result.signal })
        return
      end
      if active.after_step then
        local hook_ok, hook_err = pcall(active.after_step, active.command_index)
        if not hook_ok then finish({ error = "runner post-step failed: " .. tostring(hook_err) }); return end
      end
      active.command_index = active.command_index + 1
      if active.command_index > #active.commands then
        finish({ code = result.code, signal = result.signal })
      else
        vim.schedule(spawn_next)
      end
    end)
    if not ok then
      finish({ error = "could not start " .. argv[1] .. ": " .. tostring(process_or_error) })
      return
    end
    active.process = process_or_error
    active.timer = uv.new_timer()
    active.timer:start(remaining, 0, function()
      active.timed_out = true
      if active.process then
        local killed = uv.kill(-active.process.pid, 9)
        if not killed and active.process.kill then pcall(active.process.kill, active.process, 9) end
      end
    end)
  end

  spawn_next()
end

function M.cancel()
  if not M.active then return false end
  M.active.cancelled = true
  local process = M.active.process
  if process then
    local uv = vim.uv or vim.loop
    local killed = uv.kill(-process.pid, 9)
    if not killed and process.kill then pcall(process.kill, process, 9) end
  end
  return true
end

return M
