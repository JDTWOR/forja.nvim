local fs = require("forja.util.fs")
local util = require("forja.runner.adapters.util")
local M = { tools = { "go" } }

function M.validate_starter(path, manifest)
  if manifest.package ~= "exercise" then return nil, "Go exercise package must be `exercise`" end
  local module_path, module_err = util.validate_file(path, "go.mod", "Go module file")
  if not module_path then return nil, module_err end
  local module_text = fs.read(module_path)
  if not module_text or not module_text:match("\n?module%s+[%w._/%-]+") then return nil, "Go module file is missing a valid module declaration" end
  local source, source_err = util.validate_file(path, manifest.source_file, "Go source file")
  if not source then return nil, source_err end
  local public, public_err = util.validate_file(path, manifest.public_test_file, "Go visible tests")
  if not public then return nil, public_err end
  local source_text = fs.read(source) or ""
  if not source_text:match("\n?package%s+exercise[%s\r\n]") then return nil, "Go source must declare package exercise" end
  return true
end

function M.prepare(ctx)
  local cwd = ctx.workspace
  if ctx.assessment then
    local temporary, err = util.new_temp_copy(ctx.workspace)
    if not temporary then return nil, err end
    ctx.temporary = temporary
    local staged, stage_err = util.stage_assessment(ctx, ctx.manifest.assessment_file, "forja_assessment_test.go")
    if not staged then fs.remove_tree(temporary); return nil, stage_err end
    cwd = temporary
  end
  local command = ctx.assessment
      and { "go", "test", "-run", "^TestForjaAssessment", "./..." }
      or { "go", "test", "./..." }
  return {
    cwd = cwd,
    temporary = ctx.temporary,
    tools = M.tools,
    env = { GOPROXY = "off", GOSUMDB = "off", GOTOOLCHAIN = "local" },
    commands = { command },
  }
end

return M
