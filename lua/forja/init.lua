local M = {}

function M.setup(opts)
  require("forja.config").setup(opts)
  require("forja.commands").setup()
  return M
end

return M
