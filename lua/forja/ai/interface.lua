local M = {}

function M.validate(provider)
  if provider == nil then return nil, "No AI provider is configured. Forja works offline; the AI tutor is optional." end
  if type(provider) ~= "table" or type(provider.complete) ~= "function" then
    return nil, "AI provider must expose complete(request, callback)"
  end
  return provider
end

function M.request(provider, request, callback)
  local valid, err = M.validate(provider)
  if not valid then callback({ error = err }); return nil end
  local completed = false
  local function finish(response)
    if completed then return end
    completed = true
    if type(response) ~= "table" or type(response.text) ~= "string" or response.text == "" then
      callback({ error = "AI provider returned a malformed response; expected a non-empty text field" })
      return
    end
    callback(response)
  end
  local ok, handle = pcall(valid.complete, request, finish)
  if not ok then finish({ error = "AI provider failed: " .. tostring(handle) }); return nil end
  return handle
end

return M
