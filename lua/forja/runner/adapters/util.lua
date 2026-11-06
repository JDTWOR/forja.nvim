local fs = require("forja.util.fs")
local M = {}

local function uv()
  return vim.uv or vim.loop
end

function M.new_temp_dir()
  local runtime = uv()
  local system = runtime.os_uname().sysname
  local temp_root = system == "Windows_NT"
      and (os.getenv("TEMP") or os.getenv("TMP") or vim.fn.stdpath("cache"))
      or (os.getenv("TMPDIR") or "/tmp")
  local absolute = temp_root:sub(1, 1) == "/" or (system == "Windows_NT" and temp_root:match("^[A-Za-z]:"))
  if not absolute or temp_root:match("[%z\r\n]") then
    return nil, "temporary directory must be absolute"
  end
  local temporary = fs.join(temp_root, string.format("forja-%s-%s", tostring(runtime.os_getpid()), tostring(runtime.hrtime())))
  local created, err = runtime.fs_mkdir(temporary, 448)
  if not created then return nil, "could not create private temporary directory: " .. tostring(err) end
  return temporary
end

function M.validate_file(root, relative, label)
  if not fs.safe_relative(relative) then return nil, "unsafe " .. label .. " path" end
  local path = fs.join(root, relative)
  local stat = uv().fs_lstat(path)
  if not stat or stat.type ~= "file" then return nil, label .. " is missing or is not a regular file" end
  return path
end

function M.validate_slug(value, label)
  if type(value) ~= "string" or not value:match("^[a-z][a-z0-9_]*$") then
    return nil, "invalid " .. label
  end
  return true
end

function M.new_temp_copy(workspace)
  local runtime = uv()
  local system = runtime.os_uname().sysname
  local temp_root = system == "Windows_NT"
      and (os.getenv("TEMP") or os.getenv("TMP") or vim.fn.stdpath("cache"))
      or (os.getenv("TMPDIR") or "/tmp")
  if not temp_root:match("^[/\\]") or temp_root:match("[%z\r\n]") then
    return nil, "temporary directory must be absolute"
  end
  local temporary = fs.join(temp_root, string.format("forja-%s-%s", tostring(runtime.os_getpid()), tostring(runtime.hrtime())))
  local created, err = runtime.fs_mkdir(temporary, 448)
  if not created then return nil, "could not create private assessment directory: " .. tostring(err) end
  local copied, copy_err = fs.copy_tree(workspace, temporary, { target = true, [".git"] = true })
  if not copied then
    fs.remove_tree(temporary)
    return nil, "could not prepare isolated assessment copy: " .. tostring(copy_err)
  end
  return temporary
end

function M.stage_assessment(ctx, relative, destination)
  if not fs.safe_relative(relative) or not fs.safe_relative(destination) then
    return nil, "unsafe assessment path"
  end
  local source_root = ctx.variation and ctx.exercise._variation_dir or ctx.exercise._dir
  local source = fs.join(source_root, relative)
  local stat = uv().fs_lstat(source)
  if not stat or stat.type ~= "file" then return nil, "assessment is missing or is not a regular file" end
  local code, err = fs.read(source)
  if not code then return nil, "could not read assessment: " .. tostring(err) end
  local dest = fs.join(ctx.temporary, destination)
  local parent = vim.fn.fnamemodify(dest, ":h")
  fs.ensure_dir(parent)
  local ok, write_err = fs.write(dest, code)
  if not ok then return nil, "could not stage assessment: " .. tostring(write_err) end
  return true
end

return M
