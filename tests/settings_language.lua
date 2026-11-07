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
local original_columns = vim.o.columns
vim.o.columns = 58
commands.lang()
local compact_text = current_text()
check(compact_text:find("FORJA  /  RUTAS DE APRENDIZAJE", 1, true)
  and compact_text:find("Fundamentos de", 1, true), "narrow terminals get a compact, readable route picker")
ui.close()
vim.o.columns = original_columns
commands.lang()
local picker = ui.current.buf
local picker_text = current_text()
check(picker_text:find("RUTAS DE APRENDIZAJE", 1, true), "language picker has a clear heading")
check(picker_text:find("RUST", 1, true) and picker_text:find("PYTHON", 1, true)
  and picker_text:find("JAVA", 1, true) and picker_text:find("GO", 1, true), "picker shows all supported languages")
check(picker_text:find("Mostrando 4 de 4 rutas", 1, true), "picker count matches the visible entries")
check(not picker_text:find("python-foundations", 1, true), "picker hides internal curriculum IDs")
local pending_search
local original_input = vim.ui.input
vim.ui.input = function(_, callback) pending_search = callback end
invoke_mapping(picker, "/")
check(pending_search ~= nil, "language picker exposes keyboard search")
pending_search("python")
vim.ui.input = original_input
picker_text = current_text()
check(picker_text:find("PYTHON", 1, true) and not picker_text:find("RUST", 1, true),
  "language picker filters the visible routes")
check(picker_text:find("Mostrando 1 de 4 rutas", 1, true), "search updates the picker result count")
invoke_mapping(picker, "x")
invoke_mapping(picker, "2")
check(require("forja.storage.json").load().active_track == "python-foundations",
  "number selection starts the chosen language track")
local python_lesson = assert(require("forja.core.curriculum").get("python-foundations"))._ordered_lessons[1]
check(ui.lesson_view and ui.lesson_view.section_index == 2,
  "a new Python lesson opens on its explanation instead of the challenge")
local lesson_text = table.concat(vim.api.nvim_buf_get_lines(ui.lesson_view.buf, 0, -1, false), "\n")
check(lesson_text:find("Qué vas a aprender", 1, true) and lesson_text:find(python_lesson.objective, 1, true)
  and lesson_text:find("Paso 1", 1, true), "beginner lesson explains its goal and first concept step")

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
