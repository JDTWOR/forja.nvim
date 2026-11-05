local fs = require("forja.util.fs")
local graph = require("forja.core.graph")
local M = {}

local function plugin_root()
  local source = debug.getinfo(1, "S").source:sub(2)
  return vim.fn.fnamemodify(source, ":p:h:h:h:h")
end

local function decode(path)
  local contents, err = fs.read(path)
  if not contents then return nil, "cannot read " .. path .. ": " .. tostring(err) end
  local ok, result = pcall(vim.json.decode, contents)
  if not ok then return nil, "invalid curriculum JSON at " .. path .. ": " .. tostring(result) end
  local sorted, validation_err = graph.validate(result)
  if not sorted then return nil, validation_err end
  local track_dir = vim.fn.fnamemodify(path, ":h")
  for _, lesson in ipairs(sorted) do
    local exercise = lesson.exercise
    for _, field in ipairs({ "project_dir", "starter_dir", "assessment_file", "solution_file" }) do
      if not fs.safe_relative(exercise[field]) then
        return nil, "lesson " .. lesson.id .. " has an unsafe " .. field
      end
    end
    local manifest_path = fs.join(track_dir, exercise.project_dir, "exercise.json")
    local manifest_text = fs.read(manifest_path)
    if not manifest_text then return nil, "missing exercise manifest for " .. lesson.id end
    local valid, manifest = pcall(vim.json.decode, manifest_text)
    if not valid or type(manifest) ~= "table" or manifest.schema_version ~= 1 then
      return nil, "invalid exercise manifest for " .. lesson.id
    end
    if manifest.id ~= lesson.id or manifest.runner ~= "cargo-test" then
      return nil, "exercise manifest identity or runner mismatch for " .. lesson.id
    end
    if type(manifest.package) ~= "string" or not manifest.package:match("^[a-z][a-z0-9_]*$") then
      return nil, "exercise manifest has an invalid Cargo package for " .. lesson.id
    end
    if type(manifest.timeout_ms) ~= "number" or manifest.timeout_ms < 1000 or manifest.timeout_ms > 120000 then
      return nil, "exercise manifest has an invalid timeout for " .. lesson.id
    end
    if manifest.assessment_file ~= exercise.assessment_file or manifest.solution_file ~= exercise.solution_file then
      return nil, "exercise manifest paths do not match curriculum for " .. lesson.id
    end
    if not fs.read(fs.join(track_dir, exercise.project_dir, exercise.assessment_file))
      or not fs.read(fs.join(track_dir, exercise.project_dir, exercise.solution_file)) then
      return nil, "exercise assessment or reference solution is missing for " .. lesson.id
    end
    lesson.exercise._manifest = manifest
    lesson.exercise._dir = fs.join(track_dir, exercise.project_dir)
    local starter_ok, starter_err = require("forja.util.cargo").validate_starter(
      fs.join(lesson.exercise._dir, exercise.starter_dir), manifest.package)
    if not starter_ok then return nil, lesson.id .. ": " .. starter_err end
    if exercise.variation_dir then
      local variation_root = fs.join(lesson.exercise._dir, exercise.variation_dir)
      local variation_text = fs.read(fs.join(variation_root, "exercise.json"))
      local variation_ok, variation_manifest = pcall(vim.json.decode, variation_text or "")
      if not variation_ok or type(variation_manifest) ~= "table"
        or variation_manifest.schema_version ~= 1
        or variation_manifest.id ~= lesson.id
        or variation_manifest.runner ~= "cargo-test"
        or type(variation_manifest.package) ~= "string"
        or not variation_manifest.package:match("^[a-z][a-z0-9_]*$")
        or type(variation_manifest.timeout_ms) ~= "number"
        or variation_manifest.timeout_ms < 1000 or variation_manifest.timeout_ms > 120000
        or not fs.safe_relative(variation_manifest.assessment_file)
        or not fs.safe_relative(variation_manifest.solution_file) then
        return nil, "invalid transfer exercise manifest for " .. lesson.id
      end
      if not fs.read(fs.join(variation_root, variation_manifest.assessment_file))
        or not fs.read(fs.join(variation_root, variation_manifest.solution_file))
        or not fs.read(fs.join(variation_root, "starter/Cargo.toml"))
        or not fs.read(fs.join(variation_root, "starter/src/lib.rs")) then
        return nil, "transfer exercise files are missing for " .. lesson.id
      end
      lesson.exercise._variation_dir = variation_root
      lesson.exercise._variation_manifest = variation_manifest
      local transfer_ok, transfer_err = require("forja.util.cargo").validate_starter(
        fs.join(variation_root, "starter"), variation_manifest.package)
      if not transfer_ok then return nil, lesson.id .. " transfer: " .. transfer_err end
    end
  end
  result._ordered_lessons = sorted
  return result
end

function M.root()
  return plugin_root()
end

function M.list()
  local root = plugin_root()
  local files = vim.fn.glob(root .. "/courses/*/foundations.json", false, true)
  local tracks = {}
  for _, path in ipairs(files) do
    local track, err = decode(path)
    if not track then return nil, err end
    track._path = vim.fn.fnamemodify(path, ":h")
    table.insert(tracks, track)
  end
  table.sort(tracks, function(a, b) return a.title < b.title end)
  return tracks
end

function M.get(id)
  for _, track in ipairs(M.list() or {}) do
    if track.id == id then return track end
  end
  return nil, "unknown learning track: " .. tostring(id)
end

function M.lesson(track, id)
  for _, lesson in ipairs(track._ordered_lessons or {}) do
    if lesson.id == id then return lesson end
  end
  return nil, "unknown lesson: " .. tostring(id)
end

return M
