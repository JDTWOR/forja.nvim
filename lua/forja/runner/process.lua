local fs = require("forja.util.fs")
local M = { active = nil }

local function result_output(result)
  local parts = {}
  if result.stdout and result.stdout ~= "" then table.insert(parts, result.stdout) end
  if result.stderr and result.stderr ~= "" then table.insert(parts, result.stderr) end
  return table.concat(parts, "\n"):gsub("\n+$", "")
end

function M.run(track, lesson, workspace, assessment, timeout_ms, callback)
  if M.active then callback({ error = "A Forja process is already running" }); return end
  local exercise = lesson.exercise
  local manifest = exercise._manifest
  local temporary = nil
  local cwd = workspace

  if assessment then
    if not fs.safe_relative(exercise.assessment_file) then
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
    local test_dir = fs.join(temporary, "tests")
    fs.ensure_dir(test_dir)
    local assessment_source = fs.join(exercise._dir, exercise.assessment_file)
    local assessment_code, read_err = fs.read(assessment_source)
    if not assessment_code then
      fs.remove_tree(temporary)
      callback({ error = "could not read assessment: " .. tostring(read_err) }); return
    end
    local wrote, write_err = fs.write(fs.join(test_dir, "forja_assessment.rs"), assessment_code)
    if not wrote then
      fs.remove_tree(temporary)
      callback({ error = "could not stage assessment: " .. tostring(write_err) }); return
    end
    cwd = temporary
  end

  local active = { temporary = temporary, assessment = assessment, cancelled = false }
  M.active = active
  -- The fixed wrapper sets a private umask. Compile test binaries first, then
  -- restore the owner execute bit in case the host umask removed it.
  local prepare_argv = { "/bin/sh", "-c", "umask 077; exec cargo test --offline --no-run" }
  local test_argv = { "/bin/sh", "-c", "umask 077; exec cargo test --offline" }
  local function finish(result)
    if M.active == active then M.active = nil end
    if active.temporary then fs.remove_tree(active.temporary) end
    result.assessment = assessment
    result.cancelled = active.cancelled
    if not result.error then result.output = result_output(result) end
    vim.schedule(function() callback(result) end)
  end

  local function spawn()
    if active.cancelled then finish({ code = 143, signal = 15, stdout = "", stderr = "" }); return end
    local argv = active.phase == "prepare" and prepare_argv or test_argv
    local ok, process_or_error = pcall(vim.system, argv, {
      cwd = cwd,
      text = true,
      timeout = timeout_ms or manifest.timeout_ms or 30000,
    }, function(result)
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
  end
  active.phase = "prepare"
  spawn()
end

function M.cancel()
  if not M.active then return false end
  M.active.cancelled = true
  if M.active.process then M.active.process:kill(15) end
  return true
end

return M
