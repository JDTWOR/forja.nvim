local ui = require("forja.ui")
local M = {}

local concept_labels = {
  ["rust.binding"] = "bindings", ["rust.mutability"] = "mutability", ["rust.shadowing"] = "shadowing",
  ["rust.scalar-types"] = "tipos escalares", ["rust.integer-types"] = "tipos enteros",
  ["rust.floating-point"] = "punto flotante", ["rust.bool"] = "booleanos",
  ["rust.if"] = "expresiones if", ["rust.matching-ranges"] = "rangos y match", ["rust.branch-coverage"] = "cobertura de ramas",
  ["rust.functions"] = "funciones", ["rust.parameters"] = "parámetros", ["rust.return-values"] = "valores de retorno",
  ["rust.decomposition"] = "descomposición", ["rust.ownership"] = "ownership", ["rust.borrowing"] = "borrowing",
  ["rust.string-slice"] = "string slices", ["rust.lifetimes-intro"] = "lifetimes",
}

local function concepts(items)
  local result = {}
  for _, item in ipairs(items or {}) do table.insert(result, concept_labels[item] or item) end
  return table.concat(result, " · ")
end

function M.render(lesson, workspace, mode, exam_active)
  local lines
  if mode == "recall" then
    lines = { "# Recuperación activa · " .. lesson.title, "", "Responde de memoria. La explicación y los ejemplos están ocultos durante esta práctica." }
    for _, question in ipairs(lesson.questions) do table.insert(lines, "- " .. question) end
  elseif exam_active or mode == "review" or mode == "exam" then
    lines = { "# Intento independiente · " .. lesson.title, "", "## Objetivo", lesson.objective, "", "## Requisitos" }
    if mode == "practice" then
      table.insert(lines, lesson.variation)
    else
      for _, requirement in ipairs(lesson.requirements) do table.insert(lines, "- " .. requirement) end
    end
    table.insert(lines, "La explicación, los ejemplos y la estrategia guiada están ocultos durante este intento.")
  elseif mode == "practice" then
    lines = {
      "# Variación de transferencia · " .. lesson.title,
      "",
      "## Propósito",
      "Aplica el concepto en una tarea distinta. Esta práctica tiene workspace y evaluación propios.",
      "",
      "## Reto",
      lesson.variation,
      "",
      "## Evidencia",
      "Los resultados de transferencia se guardan por separado y no desbloquean lecciones.",
    }
  else
    lines = {
      "# " .. lesson.title,
      "",
      "## Objetivo",
      lesson.objective,
      "",
      "## Conceptos",
      concepts(lesson.concepts),
      "",
      "## Explicación",
      lesson.explanation,
      "",
      "## Ejemplo",
      "```rust",
    }
    vim.list_extend(lines, vim.split(lesson.example, "\n", { plain = true }))
    vim.list_extend(lines, { "```", "", "## Recuperación activa", "Antes de releer la explicación, responde de memoria con `:ForjaRecall`." })
    for _, question in ipairs(lesson.questions) do table.insert(lines, "- " .. question) end
    vim.list_extend(lines, { "", "## Estrategia guiada", lesson.guided, "", "## Ejercicio", "" })
    for _, requirement in ipairs(lesson.requirements) do table.insert(lines, "- " .. requirement) end
    if mode == "review" then
      vim.list_extend(lines, { "", "## Práctica de recuperación", "Este workspace empieza limpio. Implementa la lección sin consultar tu solución guardada." })
    end
  end
  if exam_active then
    vim.list_extend(lines, {
      "",
      "Workspace limpio · `r` tests visibles · `t` evaluación · `o` resultados.",
      "Las pistas, el tutor, la recuperación guiada y la transferencia están deshabilitados.",
      "Termina con `e` o `:ForjaExam stop`; el workspace se conserva.",
    })
  else
    vim.list_extend(lines, {
      "",
      "Código abierto en `src/lib.rs` · `r` tests visibles · `t` evaluación · `o` resultados.",
      "`h` pista · `a` recuperación activa · `p` variación de transferencia.",
      "",
      "Cierra con `q`, `<Esc>` o `:ForjaClose`. El código queda abierto.",
    })
  end
  local action_line = exam_active
    and "Exam Mode: e terminar · r tests · t evaluar · o resultados · :ForjaExam stop"
    or "Acciones: q cerrar · r tests · t evaluar · a recordar · h pista · o resultados · p variación · :ForjaClose"
  if not exam_active and (mode == "practice" or mode == "review") then
    action_line = action_line .. " · b volver al ejercicio base"
    vim.list_extend(lines, { "", "`b` o `:ForjaReview stop` guarda esta copia y vuelve al workspace original." })
  end
  table.insert(lines, 2, action_line)
  table.insert(lines, 3, "")
  if exam_active then
    table.insert(lines, 1, "⚠ EXAM MODE ACTIVO · tutor y pistas deshabilitados · :ForjaExam stop para terminar")
    table.insert(lines, 2, "")
  end
  ui.open_lesson(lines, mode == "practice" and "Variación · " .. lesson.title or lesson.title, nil, mode, exam_active)
end

return M
