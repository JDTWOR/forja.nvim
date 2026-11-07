local fs = require("forja.util.fs")
local uv = vim.uv or vim.loop
local M = {}

local function directory()
  return fs.join(require("forja.config").get().data_dir, "secrets")
end

local function key_path()
  return fs.join(directory(), "openai.key")
end

local function saved_key()
  local path = key_path()
  local stat = uv.fs_lstat(path)
  if not stat then return nil end
  if stat.type ~= "file" then return nil, "La credencial local no es un archivo regular." end
  if stat.mode % 64 ~= 0 then
    return nil, "Los permisos de la credencial son demasiado abiertos; vuelve a guardarla desde :ForjaSettings."
  end
  local value, err = fs.read(path)
  if not value then return nil, "No se pudo leer la credencial local: " .. tostring(err) end
  value = value:gsub("\r?\n$", "")
  if value == "" then return nil end
  return value
end

function M.resolve(env_name)
  env_name = env_name or "OPENAI_API_KEY"
  if env_name == "OPENAI_API_KEY" then
    local value, err = saved_key()
    if value or err then return value, value and "local" or nil, err end
  end
  local value = vim.env[env_name]
  if type(value) == "string" and value ~= "" then return value, "environment" end
  return nil
end

function M.status(env_name)
  env_name = env_name or "OPENAI_API_KEY"
  if env_name == "OPENAI_API_KEY" then
    local value, err = saved_key()
    if err then return { configured = false, source = "error", detail = err } end
    if value then return { configured = true, source = "local", detail = "guardada localmente con permisos 0600" } end
  end
  local value = vim.env[env_name]
  if type(value) == "string" and value ~= "" then
    return { configured = true, source = "environment", detail = "disponible desde " .. env_name }
  end
  return { configured = false, source = "missing", detail = "sin configurar" }
end

function M.set(value)
  if type(value) ~= "string" then return nil, "La API key debe ser texto." end
  value = vim.trim(value)
  if #value < 10 or #value > 4096 or value:find("%s") then
    return nil, "La API key debe tener entre 10 y 4096 caracteres, sin espacios ni saltos de línea."
  end

  local dir = directory()
  fs.ensure_dir(dir)
  local dir_stat = uv.fs_lstat(dir)
  if not dir_stat or dir_stat.type ~= "directory" then return nil, "La carpeta local de credenciales no es segura." end
  local chmod_dir, chmod_dir_err = uv.fs_chmod(dir, 448) -- 0700
  if not chmod_dir then return nil, "No se pudieron proteger las credenciales: " .. tostring(chmod_dir_err) end

  local path = key_path()
  local existing = uv.fs_lstat(path)
  if existing and existing.type ~= "file" then return nil, "La ruta de la credencial no es un archivo regular." end

  local temporary = path .. ".tmp-" .. tostring(uv.hrtime())
  local fd, open_err = uv.fs_open(temporary, "wx", 384) -- 0600
  if not fd then return nil, "No se pudo crear el archivo protegido: " .. tostring(open_err) end
  local written, write_err = uv.fs_write(fd, value .. "\n", 0)
  uv.fs_close(fd)
  if not written then uv.fs_unlink(temporary); return nil, "No se pudo escribir la credencial: " .. tostring(write_err) end
  local chmod_ok, chmod_err = uv.fs_chmod(temporary, 384)
  if not chmod_ok then uv.fs_unlink(temporary); return nil, "No se pudieron proteger los permisos: " .. tostring(chmod_err) end
  local renamed, rename_err = uv.fs_rename(temporary, path)
  if not renamed then uv.fs_unlink(temporary); return nil, "No se pudo guardar la credencial: " .. tostring(rename_err) end
  return true
end

function M.delete()
  local path = key_path()
  local stat = uv.fs_lstat(path)
  if not stat then return true end
  if stat.type ~= "file" then return nil, "La ruta de la credencial no es un archivo regular." end
  return uv.fs_unlink(path)
end

return M
