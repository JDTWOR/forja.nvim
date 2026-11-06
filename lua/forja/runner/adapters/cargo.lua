local fs = require("forja.util.fs")
local cargo = require("forja.util.cargo")
local util = require("forja.runner.adapters.util")
local M = { tools = { "cargo", "rustc" } }

function M.validate_starter(path, manifest)
  return cargo.validate_starter(path, manifest.package)
end

function M.prepare(ctx)
  local cwd = ctx.workspace
  local assessment_target
  if ctx.assessment then
    local assessment_file = ctx.manifest.assessment_file
    if not fs.safe_relative(assessment_file) then return nil, "unsafe assessment path" end
    local temporary, err = util.new_temp_copy(ctx.workspace)
    if not temporary then return nil, err end
    ctx.temporary = temporary
    assessment_target = "forja_assessment_" .. vim.fn.sha256(tostring((vim.uv or vim.loop).hrtime()) .. temporary):sub(1, 12)
    local staged, stage_err = util.stage_assessment(ctx, assessment_file, "tests/" .. assessment_target .. ".rs")
    if not staged then fs.remove_tree(temporary); return nil, stage_err end
    local cargo_path = fs.join(temporary, "Cargo.toml")
    local manifest_text = fs.read(cargo_path)
    if not manifest_text then fs.remove_tree(temporary); return nil, "missing Cargo.toml" end
    local added, add_err = fs.write(cargo_path, manifest_text .. '\n[[test]]\nname = "' .. assessment_target
      .. '"\npath = "tests/' .. assessment_target .. '.rs"\nharness = true\n')
    if not added then fs.remove_tree(temporary); return nil, add_err end
    cwd = temporary
  end

  local target_args = ctx.assessment and { "--test", assessment_target } or {}
  local prepare = { "cargo", "test", "--offline", "--no-run" }
  local run = { "cargo", "test", "--offline" }
  vim.list_extend(prepare, target_args)
  vim.list_extend(run, target_args)
  return {
    cwd = cwd,
    temporary = ctx.temporary,
    tools = M.tools,
    commands = { prepare, run },
    after_step = function(index)
      if index ~= 1 then return end
      local uv = vim.uv or vim.loop
      local target_dir = fs.join(cwd, "target/debug/deps")
      local scan = uv.fs_scandir(target_dir)
      if not scan then return end
      while true do
        local name = uv.fs_scandir_next(scan)
        if not name then break end
        if not name:find("%.") then
          local path = fs.join(target_dir, name)
          local stat = uv.fs_lstat(path)
          if stat and stat.type == "file" then uv.fs_chmod(path, 448) end
        end
      end
    end,
  }
end

return M
