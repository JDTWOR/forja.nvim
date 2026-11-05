local fs = require("forja.util.fs")
local migrations = require("forja.storage.migrations")
local M = {}

local function state_path()
  return fs.join(require("forja.config").get().data_dir, "progress.json")
end

local function empty_state()
  return {
    schema_version = migrations.current_version,
    active_track = nil,
    tracks = {},
    trusted_exercises = {},
    exam_active = false,
    history = {},
  }
end

function M.load()
  local path = state_path()
  local raw = fs.read(path)
  if not raw then return empty_state() end
  local ok, decoded = pcall(vim.json.decode, raw)
  if not ok or type(decoded) ~= "table" then
    return nil, "progress file is malformed; it has been preserved at " .. path
  end
  local upgraded, err = migrations.upgrade(decoded)
  if not upgraded then return nil, err end
  return upgraded
end

function M.save(state)
  local upgraded, err = migrations.upgrade(state)
  if not upgraded then return nil, err end
  local ok, encoded = pcall(vim.json.encode, upgraded)
  if not ok then return nil, "could not encode progress: " .. tostring(encoded) end
  return fs.atomic_write(state_path(), encoded .. "\n")
end

function M.default()
  return empty_state()
end

function M.path()
  return state_path()
end

return M
