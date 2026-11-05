local fs = require("forja.util.fs")
local M = {}

-- Course packages intentionally use literal metadata: no executable curriculum
-- or workspace inheritance is needed to identify the starter being executed.
function M.validate_starter(path, expected_package)
  local text = fs.read(fs.join(path, "Cargo.toml"))
  if not text then return nil, "starter Cargo.toml is missing" end
  if not fs.read(fs.join(path, "src/lib.rs")) and not fs.read(fs.join(path, "src/main.rs")) then
    return nil, "starter src/lib.rs or src/main.rs is missing"
  end
  local in_package, name = false, nil
  for line in text:gmatch("[^\r\n]+") do
    local section = line:match("^%s*%[([^%]]+)%]%s*#?.*$")
    if section then in_package = section == "package" end
    if in_package then name = line:match('^%s*name%s*=%s*"([^"]+)"') or line:match("^%s*name%s*=%s*'([^']+)'") or name end
  end
  if name ~= expected_package then return nil, "starter Cargo package does not match exercise manifest" end
  return true
end

return M
