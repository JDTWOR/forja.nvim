vim.opt.runtimepath:prepend(vim.fn.getcwd())

local config = require("forja.config")
local commands = require("forja.commands")
local ui = require("forja.ui")
local credentials = require("forja.ai.credentials")
local fs = require("forja.util.fs")
local temporary = vim.fn.tempname()
local original_key = vim.env.OPENAI_API_KEY
vim.env.OPENAI_API_KEY = nil
config.setup({ data_dir = temporary })
commands.setup()

local function check(value, message) assert(value, message) end
local function current_text()
  return table.concat(vim.api.nvim_buf_get_lines(ui.current.buf, 0, -1, false), "\n")
end
local function invoke_mapping(buf, lhs)
  for _, mapping in ipairs(vim.api.nvim_buf_get_keymap(buf, "n")) do
    if mapping.lhs == lhs and mapping.callback then return mapping.callback() end
  end
  error("missing Forja mapping: " .. lhs)
end
local function has_mapping(buf, lhs)
  for _, mapping in ipairs(vim.api.nvim_buf_get_keymap(buf, "n")) do
    if mapping.lhs == lhs then return true end
  end
  return false
end

check(vim.fn.exists(":ForjaLang") == 2 and vim.fn.exists(":ForjaSettings") == 2,
  "language and settings commands are registered")
commands.lang()
local picker = ui.current.buf
local picker_text = current_text()
check(picker_text:find("ELIGE TU LENGUAJE", 1, true), "language picker has a clear heading")
check(picker_text:find("RUST", 1, true) and picker_text:find("PYTHON", 1, true)
  and picker_text:find("JAVA", 1, true) and picker_text:find("GO", 1, true), "picker shows all supported languages")
check(not picker_text:find("python-foundations", 1, true), "picker hides internal curriculum IDs")
invoke_mapping(picker, "2")
check(require("forja.storage.json").load().active_track == "python-foundations",
  "number selection starts the chosen language track")

commands.settings()
local settings_buf = ui.current.buf
local settings_text = current_text()
check(settings_text:find("TUTOR IA", 1, true) and settings_text:find("API key", 1, true),
  "settings screen includes a dedicated tutor/API key section")
check(not settings_text:find("sk-forja-ui-test-key", 1, true), "settings screen never displays the API key")
check(not has_mapping(settings_buf, "d") and not vim.wo[ui.current.win].winbar:find("borrar key local", 1, true),
  "settings hides the delete action until a local key exists")

local inputsecret = vim.fn.inputsecret
vim.fn.inputsecret = function() return "sk-forja-ui-test-key" end
invoke_mapping(settings_buf, "k")
vim.fn.inputsecret = inputsecret
local credential_status = credentials.status()
check(credential_status.configured and credential_status.source == "local", "settings stores the key locally")
local key_path = temporary .. "/secrets/openai.key"
local stat = assert((vim.uv or vim.loop).fs_stat(key_path))
check(stat.mode % 64 == 0, "saved API key has no group or other permissions")
local progress_json = fs.read(temporary .. "/progress.json")
check(progress_json and not progress_json:find("sk-forja-ui-test-key", 1, true), "API key is stored outside progress data")
check(config.get().ai.provider and config.get().ai.provider.name == "OpenAI", "saving the key enables the tutor immediately")
check(has_mapping(ui.current.buf, "d"), "settings exposes key removal after saving a local key")
config.setup({ data_dir = temporary })
check(config.get().ai.provider and config.get().ai.provider.name == "OpenAI", "saved credential enables the tutor after restart")

local custom_provider = { name = "Custom", complete = function() end }
config.get().ai.provider = custom_provider
commands.settings()
local custom_key_input = vim.fn.inputsecret
vim.fn.inputsecret = function() return "sk-forja-custom-test-key" end
invoke_mapping(ui.current.buf, "k")
vim.fn.inputsecret = custom_key_input
check(config.get().ai.provider == custom_provider, "saving a key does not replace a configured custom provider")
commands.settings()
invoke_mapping(ui.current.buf, "d")
check(not credentials.status().configured and config.get().ai.provider == custom_provider,
  "deleting the key preserves a configured custom provider")
config.setup({ data_dir = temporary })
check(config.get().ai.provider == nil, "deleting the key returns to offline mode after provider resolution")

ui.close()
vim.env.OPENAI_API_KEY = original_key
fs.remove_tree(temporary)
print("Settings and language UX tests passed: picker, hidden key entry, local permissions, persistence, and removal")
vim.cmd("qa!")
