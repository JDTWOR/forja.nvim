local fs = require("forja.util.fs")
local M = { active = nil }

local function result_output(result)
  local parts = {}
  if result.stdout and result.stdout ~= "" then table.insert(parts, result.stdout) end
  if result.stderr and result.stderr ~= "" then table.insert(parts, result.stderr) end
  return table.concat(parts, "\n"):gsub("\n+$", "")
end

function M.run(track, lesson, workspace, assessment, timeout_ms, callback, variation)
  if M.active then callback({ error = "A Forja process is already running" }); return end
  local exercise = lesson.exercise
  local manifest = variation and exercise._variation_manifest or exercise._manifest
  if variation and not manifest then callback({ error = "this lesson has no dedicated transfer assessment" }); return end
  local assessment_file = variation and manifest.assessment_file or exercise.assessment_file
  local assessment_target
  local temporary = nil
  local cwd = workspace

  if assessment then
    if not fs.safe_relative(assessment_file) then
      callback({ error = "unsafe assessment path" }); return
    end
    local uv = vim.uv or vim.loop
    local system = uv.os_uname().sysname
    local temp_root
    if system == "Windows_NT" then
      temp_root = os.getenv("TEMP") or os.getenv("TMP") or vim.fn.stdpath("cache")
    else
      temp_root = os.getenv("TMPDIR") or "/tmp"
    end
    if not temp_root:match("^[/\\]") or temp_root:match("[%z\r\n]") then
      callback({ error = "temporary directory must be an absolute path" }); return
    end
    temporary = fs.join(temp_root, string.format("forja-%s-%s", tostring(uv.os_getpid()), tostring(uv.hrtime())))
    local created, mkdir_err = (vim.uv or vim.loop).fs_mkdir(temporary, 448)
    if not created then callback({ error = "could not create a private assessment directory: " .. tostring(mkdir_err) }); return end
    -- Cargo's cache must not cross the isolation boundary: copied fingerprints
    -- can make Cargo accept a binary built from an older learner source file.
    local copied, copy_err = fs.copy_tree(workspace, temporary, { target = true, [".git"] = true })
    if not copied then
      fs.remove_tree(temporary)
      callback({ error = "could not prepare an isolated assessment copy: " .. tostring(copy_err) })
      return
    end
    assessment_target = "forja_assessment_" .. vim.fn.sha256(tostring(uv.hrtime()) .. temporary):sub(1, 12)
    local test_dir = fs.join(temporary, "tests")
    fs.ensure_dir(test_dir)
    local assessment_source = fs.join(variation and exercise._variation_dir or exercise._dir, assessment_file)
    local assessment_code, read_err = fs.read(assessment_source)
    if not assessment_code then
      fs.remove_tree(temporary)
      callback({ error = "could not read assessment: " .. tostring(read_err) }); return
    end
    local wrote, write_err = fs.write(fs.join(test_dir, assessment_target .. ".rs"), assessment_code)
    if not wrote then
      fs.remove_tree(temporary)
      callback({ error = "could not stage assessment: " .. tostring(write_err) }); return
    end
    -- Explicit targets survive autotests=false. Never accept a successful Cargo
    -- invocation which did not run the assessment target.
    local cargo_path = fs.join(temporary, "Cargo.toml")
    local cargo = fs.read(cargo_path)
    if not cargo then fs.remove_tree(temporary); callback({ error = "missing Cargo.toml" }); return end
    local target_added, target_err = fs.write(cargo_path, cargo .. '\n[[test]]\nname = "' .. assessment_target
      .. '"\npath = "tests/' .. assessment_target .. '.rs"\nharness = true\n')
    if not target_added then fs.remove_tree(temporary); callback({ error = target_err }); return end
    cwd = temporary
  end

  local uv = vim.uv or vim.loop
  local active = { temporary = temporary, assessment = assessment, cancelled = false,
    deadline = uv.hrtime() + (timeout_ms or manifest.timeout_ms or 30000) * 1000000 }
  M.active = active
  -- The fixed wrapper sets a private umask. Compile test binaries first, then
  -- restore the owner execute bit in case the host umask removed it.
  local target_args = assessment and " --test " .. assessment_target or ""
  local prepare_argv = { "/bin/sh", "-c", "umask 077; exec cargo test --offline --no-run" .. target_args }
  local test_argv = { "/bin/sh", "-c", "umask 077; exec cargo test --offline" .. target_args }
  local function finish(result)
    if active.timer then active.timer:stop(); active.timer:close(); active.timer = nil end
    if M.active == active then M.active = nil end
    if active.temporary then fs.remove_tree(active.temporary) end
    result.assessment = assessment
    result.variation = variation == true
    result.cancelled = active.cancelled
    result.timed_out = active.timed_out == true
    if not result.error then result.output = result_output(result) end
    vim.schedule(function() callback(result) end)
  end

  local function spawn()
    if active.cancelled then finish({ code = 143, signal = 15, stdout = "", stderr = "" }); return end
    local remaining = math.floor((active.deadline - uv.hrtime()) / 1000000)
    if remaining <= 0 then active.timed_out = true; finish({ code = 124, signal = 9, stdout = "", stderr = "Execution deadline exceeded" }); return end
    local argv = active.phase == "prepare" and prepare_argv or test_argv
    local ok, process_or_error = pcall(vim.system, argv, {
      cwd = cwd,
      text = true,
      detach = true,
    }, function(result)
      if active.timer then active.timer:stop(); active.timer:close(); active.timer = nil end
      if active.phase == "prepare" and result.code == 0 then
        local uv = vim.uv or vim.loop
        local target_dir = fs.join(cwd, "target/debug/deps")
        local scan = uv.fs_scandir(target_dir)
        if scan then
          while true do
            local name = uv.fs_scandir_next(scan)
            if not name then break end
            -- Rust test executables in deps have no extension; metadata, rlibs,
            -- and shared objects do. Keep generated executables private.
            if not name:find("%.") then
              local path = fs.join(target_dir, name)
              local stat = uv.fs_lstat(path)
              if stat and stat.type == "file" then uv.fs_chmod(path, 448) end
            end
          end
        end
        active.phase = "test"
        active.process = nil
        vim.schedule(spawn)
        return
      end
      finish(result)
    end)
    if not ok then finish({ error = "could not start Cargo: " .. tostring(process_or_error) }); return end
    active.process = process_or_error
    active.timer = uv.new_timer()
    active.timer:start(remaining, 0, function()
      active.timed_out = true
      uv.kill(-active.process.pid, 9)
    end)
  end
  active.phase = "prepare"
  spawn()
end

function M.cancel()
  if not M.active then return false end
  M.active.cancelled = true
  if M.active.process then (vim.uv or vim.loop).kill(-M.active.process.pid, 9) end
  return true
end

return M
