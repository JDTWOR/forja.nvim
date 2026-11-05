local ui = require("forja.ui")
local M = {}

function M.render(lesson, workspace, mode)
  local lines = {
    "# " .. lesson.title,
    "",
    "## Objetivo",
    lesson.objective,
    "",
    "## Conceptos",
    table.concat(lesson.concepts, " · "),
    "",
    "## Explicación",
    lesson.explanation,
    "",
    "## Ejemplo",
    "```rust",
  }
  vim.list_extend(lines, vim.split(lesson.example, "\n", { plain = true }))
  vim.list_extend(lines, { "```", "", "## Preguntas de recuperación" })
  for _, question in ipairs(lesson.questions) do table.insert(lines, "- " .. question) end
  vim.list_extend(lines, { "", "## Estrategia guiada", lesson.guided, "", "## Ejercicio", "" })
  for _, requirement in ipairs(lesson.requirements) do table.insert(lines, "- " .. requirement) end
  if mode == "practice" or mode == "review" then
    vim.list_extend(lines, { "", "## Variación de transferencia", lesson.variation })
  end
  vim.list_extend(lines, {
    "",
    "Escribe tu solución en `src/lib.rs` y ejecuta `:ForjaRun` para los tests visibles.",
    "`:ForjaTest` ejecuta la evaluación local aislada. Se requiere `:ForjaTrustLocal` una vez.",
    "",
    "Workspace: " .. workspace,
    "",
    "Cierra esta ventana con `q` o `<Esc>`. El buffer de código queda abierto.",
  })
  ui.open(lines, mode == "practice" and "Variación · " .. lesson.title or lesson.title, { focus = false })
end

return M
