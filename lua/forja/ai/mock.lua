local M = {}

function M.complete(request, callback)
  local response = {
    kind = request.kind or "question",
    text = "¿Qué comportamiento observas en el caso que falla? ¿Qué concepto de esta lección te ayuda a explicarlo?",
  }
  vim.schedule(function() callback(response) end)
  return { cancel = function() end }
end

return M
