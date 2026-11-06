local fs = require("forja.util.fs")
local util = require("forja.runner.adapters.util")
local M = { tools = { "python3" } }

function M.validate_starter(path, manifest)
  local slug_ok, slug_err = util.validate_slug(manifest.package, "Python module name")
  if not slug_ok then return nil, slug_err end
  local source, source_err = util.validate_file(path, manifest.source_file, "Python source file")
  if not source then return nil, source_err end
  local public, public_err = util.validate_file(path, manifest.public_test_file, "Python visible tests")
  if not public then return nil, public_err end
  if fs.join(source, "") == public then return nil, "source and visible tests cannot be the same file" end
  return true
end

function M.prepare(ctx)
  local cwd = ctx.workspace
  if ctx.assessment then
    local temporary, err = util.new_temp_copy(ctx.workspace)
    if not temporary then return nil, err end
    ctx.temporary = temporary
    local staged, stage_err = util.stage_assessment(ctx, ctx.manifest.assessment_file, "tests/test_forja_assessment.py")
    if not staged then fs.remove_tree(temporary); return nil, stage_err end
    cwd = temporary
  end
  local pattern = ctx.assessment and "test_forja_assessment.py" or vim.fn.fnamemodify(ctx.manifest.public_test_file, ":t")
  return {
    cwd = cwd,
    temporary = ctx.temporary,
    tools = M.tools,
    env = { PYTHONDONTWRITEBYTECODE = "1" },
    commands = {{ "python3", "-B", "-m", "unittest", "discover", "-s", "tests", "-p", pattern, "-v" }},
  }
end

return M
