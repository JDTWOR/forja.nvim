local M = {}

M.defaults = {
  data_dir = nil,
  keymaps = { enabled = false, prefix = "<leader>F" },
  runner = { timeout_ms = 30000 },
  ai = { provider = nil },
}

function M.setup(opts)
  opts = opts or {}
  M.options = vim.tbl_deep_extend("force", vim.deepcopy(M.defaults), opts)
  M.options.data_dir = M.options.data_dir or (vim.fn.stdpath("data") .. "/forja")
  if M.options.ai.provider == nil and require("forja.ai.credentials").status().configured then
    M.options.ai.provider = require("forja.ai.providers.openai").new()
  end
  return M.options
end

function M.get()
  return M.options or M.setup({})
end

return M
