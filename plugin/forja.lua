if vim.g.loaded_forja then return end
vim.g.loaded_forja = true

require("forja").setup(vim.g.forja or {})
