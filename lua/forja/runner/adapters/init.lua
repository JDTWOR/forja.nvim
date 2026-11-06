local M = {}
local modules = {
  ["cargo-test"] = require("forja.runner.adapters.cargo"),
  ["python-unittest"] = require("forja.runner.adapters.python"),
  ["java-main"] = require("forja.runner.adapters.java"),
  ["go-test"] = require("forja.runner.adapters.go"),
}

function M.get(name)
  return modules[name]
end

function M.names()
  local names = {}
  for name in pairs(modules) do table.insert(names, name) end
  table.sort(names)
  return names
end

function M.validate_starter(name, path, manifest)
  local adapter = M.get(name)
  if not adapter then return nil, "unsupported exercise runner: " .. tostring(name) end
  return adapter.validate_starter(path, manifest)
end

function M.required_tools()
  local tools, seen = {}, {}
  for _, name in ipairs(M.names()) do
    for _, tool in ipairs(modules[name].tools or {}) do
      if not seen[tool] then
        seen[tool] = true
        table.insert(tools, { executable = tool, label = tool })
      end
    end
  end
  return tools
end

return M
