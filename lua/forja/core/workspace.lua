local config = require("forja.config")
local curriculum = require("forja.core.curriculum")
local fs = require("forja.util.fs")
local M = {}

function M.path(track, lesson)
  return fs.join(config.get().data_dir, "workspaces", track.id, lesson.id)
end

function M.ensure(track, lesson)
  local project = lesson.exercise.project_dir
  local starter = lesson.exercise.starter_dir
  if not fs.safe_relative(project) or not fs.safe_relative(starter) then
    return nil, "curriculum contains an unsafe exercise path"
  end
  local source_root = fs.join(track._path, project, starter)
  local target = M.path(track, lesson)
  if vim.uv.fs_stat(target) then return target end
  local ok, err = fs.copy_tree(source_root, target)
  if not ok then return nil, "could not create exercise workspace: " .. tostring(err) end
  return target
end

function M.new_review(track, lesson)
  local project = lesson.exercise.project_dir
  local starter = lesson.exercise.starter_dir
  local stamp = tostring(os.time()) .. "-" .. tostring((vim.uv or vim.loop).hrtime()):sub(-6)
  local target = fs.join(config.get().data_dir, "reviews", track.id, lesson.id, stamp)
  local ok, err = fs.copy_tree(fs.join(track._path, project, starter), target)
  if not ok then return nil, "could not create a clean review workspace: " .. tostring(err) end
  return target
end

function M.new_practice(track, lesson)
  local source = lesson.exercise._variation_dir
  if not source then return nil, "this lesson has no dedicated transfer exercise" end
  local stamp = tostring(os.time()) .. "-" .. tostring((vim.uv or vim.loop).hrtime()):sub(-6)
  local target = fs.join(config.get().data_dir, "reviews", track.id, lesson.id, "transfer-" .. stamp)
  local ok, err = fs.copy_tree(fs.join(source, "starter"), target)
  if not ok then return nil, "could not create a clean transfer workspace: " .. tostring(err) end
  return target
end

function M.trusted(state, track, lesson, variation)
  local key = track.id .. "/" .. lesson.id .. (variation and "/transfer" or "")
  return state.trusted_exercises[key] == true
end

function M.trust(state, track, lesson, variation)
  local key = track.id .. "/" .. lesson.id .. (variation and "/transfer" or "")
  state.trusted_exercises[key] = true
end

function M.source_file(path)
  local candidates = { "src/lib.rs", "src/main.rs" }
  for _, relative in ipairs(candidates) do
    local candidate = fs.join(path, relative)
    if vim.uv.fs_stat(candidate) then return candidate end
  end
  return nil
end

function M.curriculum_root()
  return curriculum.root()
end

return M
