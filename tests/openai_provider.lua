vim.opt.runtimepath:prepend(vim.fn.getcwd())

local provider_module = require("forja.ai.providers.openai")
local check = function(value, message) assert(value, message) end
local original_system = vim.system
local original_key = vim.env.OPENAI_API_KEY
local api_key = "sk-forja-test-secret"
vim.env.OPENAI_API_KEY = api_key

local request = {
  system = "You are Forja, a supportive tutor.",
  context = { question = "How should I begin?", objective = "Use mutable bindings." },
}
local valid_body = vim.json.encode({
  id = "resp_test",
  status = "completed",
  output = {
    { type = "reasoning", summary = { { type = "summary_text", text = "hidden reasoning" } } },
    { type = "message", role = "assistant", content = {
      { type = "output_text", text = "Think about the value after the first update." },
      { type = "output_text", text = "Then write a small example." },
    } },
  },
  usage = { input_tokens = 83, output_tokens = 19 },
})

local captured, callback_result
vim.system = function(argv, options, callback)
  captured = { argv = argv, options = options }
  vim.schedule(function() callback({ code = 0, signal = 0, stdout = valid_body .. "FORJA_HTTP_STATUS:200", stderr = "" }) end)
  return { kill = function() end }
end

local provider = provider_module.new({ model = "test-model", timeout_ms = 5000 })
provider.complete(request, function(response) callback_result = response end)
check(vim.wait(1000, function() return callback_result ~= nil end, 10), "OpenAI response callback completes")
check(callback_result.text == "Think about the value after the first update.\nThen write a small example.",
  "OpenAI adapter gathers assistant output text and ignores reasoning items")
check(callback_result.usage.input_tokens == 83 and callback_result.usage.output_tokens == 19,
  "OpenAI token usage is returned to Forja")
check(provider.usage().requests == 1 and provider.usage().input_tokens == 83,
  "OpenAI provider tracks session request and token totals")
check(captured.argv[1] == "curl" and captured.argv[2] == "--disable"
  and captured.argv[3] == "--config" and captured.argv[4] == "-",
  "OpenAI requests use curl argument arrays without a shell or implicit curl config")
check(not table.concat(captured.argv, " "):find(api_key, 1, true), "API key never appears in curl process arguments")
check(captured.options.stdin:find(api_key, 1, true) and captured.options.stdin:find("test-model", 1, true),
  "API credentials and model configuration are sent over curl stdin")
check(captured.options.stdin:find("https://api.openai.com/v1/responses", 1, true), "adapter targets the OpenAI Responses API")
check(captured.options.stdin:find('\\"store\\":false', 1, true), "request disables API response storage")
local healthy, health_message = provider.health()
check(healthy and health_message:find("test-model", 1, true), "provider health reports readiness without exposing the key")

local function response_from(stdout, code)
  local response
  vim.system = function(_, _, callback)
    vim.schedule(function() callback({ code = code or 0, signal = 0, stdout = stdout, stderr = "" }) end)
    return { kill = function() end }
  end
  provider.complete(request, function(value) response = value end)
  check(vim.wait(1000, function() return response ~= nil end, 10), "provider error callback completes")
  return response
end

local unauthorized = response_from(vim.json.encode({ error = { message = "Incorrect API key provided." } }) .. "FORJA_HTTP_STATUS:401")
check(unauthorized.error:find("HTTP 401", 1, true) and unauthorized.error:find("Incorrect API key", 1, true),
  "HTTP errors produce actionable provider feedback")
local malformed = response_from("not-jsonFORJA_HTTP_STATUS:200")
check(malformed.error and malformed.error:find("JSON inválida", 1, true), "malformed Responses API payload is rejected")
local empty = response_from(vim.json.encode({ status = "completed", output = {} }) .. "FORJA_HTTP_STATUS:200")
check(empty.error and empty.error:find("sin devolver texto", 1, true), "empty model output is not treated as tutor feedback")

local calls = 0
vim.system = function() calls = calls + 1; error("curl must not start without a key") end
vim.env.OPENAI_API_KEY = nil
local no_key
provider.complete(request, function(response) no_key = response end)
check(no_key and no_key.error:find("OPENAI_API_KEY", 1, true) and calls == 0,
  "missing API key fails before starting a process")
vim.env.OPENAI_API_KEY = api_key

local pending_callback, killed, cancelled_callback
vim.system = function(_, _, callback)
  pending_callback = callback
  return { kill = function() killed = true end }
end
local cancel_handle = provider.complete(request, function() cancelled_callback = true end)
check(cancel_handle.cancel() and killed, "OpenAI request supports process cancellation")
pending_callback({ code = 137, signal = 9, stdout = "", stderr = "" })
vim.wait(50, function() return false end, 10)
check(not cancelled_callback, "cancelled OpenAI request does not deliver a late response")

local timeout_callback, timeout_killed
vim.system = function(_, _, callback)
  return { kill = function()
    timeout_killed = true
    vim.schedule(function() callback({ code = 137, signal = 9, stdout = "", stderr = "" }) end)
  end }
end
local short_provider = provider_module.new({ model = "test-model", timeout_ms = 1000 })
short_provider.complete(request, function(response) timeout_callback = response end)
check(vim.wait(2500, function() return timeout_callback ~= nil end, 10), "OpenAI request timeout completes")
check(timeout_killed and timeout_callback.error:find("timeout", 1, true), "OpenAI timeout kills curl and reports the limit")

vim.system = original_system
vim.env.OPENAI_API_KEY = original_key
print("OpenAI provider tests passed: request transport, response parsing, errors, usage, key handling, timeout and cancellation")
vim.cmd("qa!")
