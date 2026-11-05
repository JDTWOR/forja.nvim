local uv = vim.uv or vim.loop
local M = {}

function M.join(...)
  return (table.concat({ ... }, "/"):gsub("/+$", ""))
end

function M.read(path)
  local fd, err = uv.fs_open(path, "r", 438)
  if not fd then return nil, err end
  local stat = uv.fs_fstat(fd)
  local data = uv.fs_read(fd, stat.size, 0)
  uv.fs_close(fd)
  return data
end

function M.write(path, data)
  local fd, err = uv.fs_open(path, "w", 384)
  if not fd then return nil, err end
  local ok, write_err = uv.fs_write(fd, data, 0)
  uv.fs_close(fd)
  if not ok then return nil, write_err end
  return true
end

function M.ensure_dir(path)
  vim.fn.mkdir(path, "p")
  return path
end

function M.safe_relative(path)
  if type(path) ~= "string" or path == "" or path:match("[%z\r\n]") then return false end
  if path:match("^[/\\]") or path:match("^[A-Za-z]:") then return false end
  for segment in path:gmatch("[^/\\]+") do
    if segment == ".." or segment == "." then return false end
  end
  return true
end

function M.copy_tree(source, destination, exclude, relative)
  exclude = exclude or {}
  relative = relative or ""
  local source_stat = uv.fs_lstat(source)
  if not source_stat or source_stat.type ~= "directory" then
    return nil, "source is not a directory"
  end
  M.ensure_dir(destination)
  local scan, scan_err = uv.fs_scandir(source)
  if not scan then return nil, scan_err end
  while true do
    local name, kind = uv.fs_scandir_next(scan)
    if not name then break end
    local relative_path = relative == "" and name or (relative .. "/" .. name)
    if not exclude[relative_path] then
      local src, dst = M.join(source, name), M.join(destination, name)
      local stat = uv.fs_lstat(src)
      if not stat or stat.type == "link" then
        return nil, "symlinks and unreadable files are not allowed in exercise workspaces"
      elseif stat.type == "directory" then
        local ok, err = M.copy_tree(src, dst, exclude, relative_path)
        if not ok then return nil, err end
      elseif stat.type == "file" then
        local data, err = M.read(src)
        if not data then return nil, err end
        local ok, write_err = M.write(dst, data)
        if not ok then return nil, write_err end
      else
        return nil, "unsupported filesystem entry in exercise workspaces: " .. tostring(kind)
      end
    end
  end
  return true
end

function M.remove_tree(path)
  local stat = uv.fs_lstat(path)
  if not stat then return true end
  if stat.type ~= "directory" then
    return uv.fs_unlink(path)
  end
  local scan = uv.fs_scandir(path)
  if scan then
    while true do
      local name = uv.fs_scandir_next(scan)
      if not name then break end
      local ok, err = M.remove_tree(M.join(path, name))
      if not ok then return nil, err end
    end
  end
  return uv.fs_rmdir(path)
end

function M.atomic_write(path, data)
  local dir = vim.fn.fnamemodify(path, ":h")
  M.ensure_dir(dir)
  local temporary = path .. ".tmp-" .. tostring(uv.hrtime())
  local ok, err = M.write(temporary, data)
  if not ok then return nil, err end
  if uv.fs_stat(path) then
    local previous = M.read(path)
    if previous then M.write(path .. ".bak", previous) end
  end
  local renamed, rename_err = uv.fs_rename(temporary, path)
  if not renamed then
    uv.fs_unlink(temporary)
    return nil, rename_err
  end
  return true
end

return M
