vim.opt.runtimepath:prepend(vim.fn.getcwd())

local fs = require("forja.util.fs")
local curriculum = require("forja.core.curriculum")
local runner = require("forja.runner.process")
local adapters = require("forja.runner.adapters")
local ui = require("forja.ui")
local lesson_ui = require("forja.ui.lesson")

local function check(value, message)
  if not value then error("FAIL: " .. message, 2) end
end

local root = vim.fn.tempname()
fs.ensure_dir(root)
local tracks = assert(curriculum.list())
local checked = 0

for _, track_id in ipairs({ "python-foundations", "java-foundations", "go-foundations" }) do
  local track = assert(curriculum.get(track_id))
  local lesson = track._ordered_lessons[1]
  local manifest = lesson.exercise._manifest
  local adapter = assert(adapters.get(manifest.runner))
  local available = true
  for _, tool in ipairs(adapter.tools) do
    if vim.fn.executable(tool) ~= 1 then available = false end
  end
  if available then
    local workspace = fs.join(root, track.language)
    local starter = fs.join(lesson.exercise._dir, lesson.exercise.starter_dir)
    local copied, copy_err = fs.copy_tree(starter, workspace)
    check(copied, copy_err or (track.language .. " starter could not be copied"))

    local function run(assessment)
      local result
      runner.run(track, lesson, workspace, assessment, 120000, function(value) result = value end)
      local done = vim.wait(130000, function() return result ~= nil end, 10)
      check(done, track.language .. " runner did not complete")
      check(not result.error and not result.cancelled and not result.timed_out,
        track.language .. " runner failed to start or exceeded its deadline: " .. vim.inspect(result))
      return result
    end

    local incomplete = run(true)
    check(incomplete.code ~= 0, track.language .. " starter incorrectly passed its hidden assessment")

    local solution = fs.read(fs.join(lesson.exercise._dir, lesson.exercise.solution_file))
    check(solution ~= nil, track.language .. " reference solution is missing")
    check(fs.write(fs.join(workspace, manifest.source_file), solution), track.language .. " solution could not be staged")
    local visible = run(false)
    check(visible.code == 0, track.language .. " reference solution failed visible tests: " .. visible.output)
    local assessment = run(true)
    check(assessment.code == 0, track.language .. " reference solution failed hidden tests: " .. assessment.output)
    check(vim.uv.fs_stat(fs.join(workspace, "ForjaAssessment.java")) == nil,
      "Java hidden assessment must remain outside the learner workspace")
    check(vim.uv.fs_stat(fs.join(workspace, "Solution.class")) == nil,
      "Java class files must not be written into the learner workspace")
    checked = checked + 1
    print("Verified Forja runner integration for " .. track.language .. ".")
  else
    print("Skipped Forja runner integration for " .. track.language .. ": required toolchain is missing.")
  end
end

for _, track_id in ipairs({ "python-foundations", "java-foundations", "go-foundations", "rust-foundations" }) do
  local lesson = assert(curriculum.get(track_id))._ordered_lessons[1]
  lesson_ui.render(lesson, nil, nil, false)
  local lesson_text = table.concat(vim.api.nvim_buf_get_lines(ui.lesson_view.buf, 0, -1, false), "\n")
  local expected_fence = "```" .. lesson.language
  local expected_source = lesson.exercise._manifest.source_file or "src/lib.rs"
  check(lesson_text:find(expected_fence, 1, true) and lesson_text:find(expected_source, 1, true),
    track_id .. " lesson displays its source path and language-specific code fence")
  local has_practice_key = false
  for _, mapping in ipairs(vim.api.nvim_buf_get_keymap(ui.lesson_view.buf, "n")) do
    if mapping.lhs == "p" then has_practice_key = true end
  end
  check(has_practice_key == (lesson.exercise._variation_dir ~= nil),
    track_id .. " advertises transfer practice only when a runnable exercise exists")
  ui.close()
end

fs.remove_tree(root)
check(checked > 0, "at least one non-Rust runner must be available for integration checks")
print("Multilanguage runner integration tests passed for " .. checked .. " available toolchains.")
vim.cmd("qa!")
