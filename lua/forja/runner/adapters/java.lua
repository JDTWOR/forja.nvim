local fs = require("forja.util.fs")
local util = require("forja.runner.adapters.util")
local M = { tools = { "javac", "java" } }

function M.validate_starter(path, manifest)
  local slug_ok, slug_err = util.validate_slug(manifest.package, "Java exercise package")
  if not slug_ok then return nil, slug_err end
  local source, source_err = util.validate_file(path, manifest.source_file, "Java source file")
  if not source then return nil, source_err end
  local public, public_err = util.validate_file(path, manifest.public_test_file, "Java visible tests")
  if not public then return nil, public_err end
  if vim.fn.fnamemodify(source, ":t") ~= "Solution.java" or vim.fn.fnamemodify(public, ":t") ~= "PublicTests.java" then
    return nil, "Java starter must use Solution.java and PublicTests.java"
  end
  return true
end

function M.prepare(ctx)
  local cwd = ctx.workspace
  local temporary
  if ctx.assessment then
    local err
    temporary, err = util.new_temp_copy(ctx.workspace)
    if not temporary then return nil, err end
    ctx.temporary = temporary
    local staged, stage_err = util.stage_assessment(ctx, ctx.manifest.assessment_file, "ForjaAssessment.java")
    if not staged then fs.remove_tree(temporary); return nil, stage_err end
    cwd = temporary
  else
    local err
    temporary, err = util.new_temp_dir()
    if not temporary then return nil, err end
  end
  local classes = fs.join(temporary, "classes")
  fs.ensure_dir(classes)
  local test_class = ctx.assessment and "ForjaAssessment" or "PublicTests"
  return {
    cwd = cwd,
    temporary = temporary,
    tools = M.tools,
    commands = {
      { "javac", "-encoding", "UTF-8", "-d", classes, "Solution.java", test_class .. ".java" },
      { "java", "-ea", "-cp", classes, test_class },
    },
  }
end

return M
