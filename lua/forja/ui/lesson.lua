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
  ["python.assignment"] = "asignación", ["python.numeric-types"] = "tipos numéricos",
  ["python.booleans"] = "booleanos", ["python.f-strings"] = "f-strings",
  ["python.boolean-expressions"] = "expresiones booleanas", ["python.boundaries"] = "casos límite",
  ["python.conditionals"] = "condicionales", ["python.functions"] = "functions",
  ["python.parameters"] = "parámetros", ["python.return-values"] = "valores de retorno",
  ["python.composition"] = "composición", ["python.dict"] = "dicts", ["python.list"] = "listas",
  ["python.iteration"] = "iteración", ["python.max"] = "max", ["python.sorting"] = "ordenamiento",
  ["python.copy-semantics"] = "copia de datos", ["python.decimal"] = "decimales",
  ["python.exceptions"] = "exceptions", ["python.input-validation"] = "validación de entradas",
  ["python.string-parsing"] = "parsing de strings",
  ["java.variables"] = "variables", ["java.primitive-types"] = "primitive types",
  ["java.integer-arithmetic"] = "aritmética entera", ["java.boundaries"] = "casos límite",
  ["java.if-else"] = "if/else", ["java.switch"] = "switch", ["java.functions"] = "métodos",
  ["java.methods"] = "métodos", ["java.parameters"] = "parámetros",
  ["java.return-values"] = "valores de retorno", ["java.method-composition"] = "composición de métodos",
  ["java.classes"] = "classes", ["java.constructors"] = "constructors",
  ["java.encapsulation"] = "encapsulation", ["java.invariants"] = "invariantes",
  ["java.final"] = "final", ["java.arrays"] = "arrays", ["java.list"] = "List",
  ["java.map"] = "Map", ["java.set"] = "Set", ["java.generics"] = "generics",
  ["java.validation"] = "validación",
  ["go.variables"] = "variables", ["go.short-declaration"] = "short declaration",
  ["go.zero-values"] = "zero values", ["go.boolean-logic"] = "lógica booleana",
  ["go.boundaries"] = "casos límite", ["go.if"] = "if", ["go.switch"] = "switch",
  ["go.branch-coverage"] = "cobertura de ramas", ["go.functions"] = "functions",
  ["go.contracts"] = "contratos", ["go.composition"] = "composición",
  ["go.multiple-returns"] = "multiple return values", ["go.slices"] = "slices",
  ["go.maps"] = "maps", ["go.collections"] = "collections", ["go.range"] = "range",
  ["go.error-values"] = "error values", ["go.error-propagation"] = "propagación de errores",
  ["go.interfaces"] = "interfaces", ["go.error-interface"] = "error interface",
}

local function concepts(items)
  local result = {}
  for _, item in ipairs(items or {}) do table.insert(result, concept_labels[item] or item) end
  return table.concat(result, " · ")
end

function M.render(lesson, workspace, mode, exam_active)
  local lines
  local practice_available = lesson.exercise and lesson.exercise._variation_dir ~= nil
  local source_file = lesson.exercise and lesson.exercise._manifest and lesson.exercise._manifest.source_file
    or "src/lib.rs"
  local language = lesson.language or "rust"
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
      "```" .. language,
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
    vim.list_extend(lines, { "", "Código abierto en `" .. source_file
      .. "` · `r` tests visibles · `t` evaluación · `o` resultados." })
    local assistance_actions = "`h` pista · `a` recuperación activa"
    if practice_available then assistance_actions = assistance_actions .. " · `p` variación de transferencia" end
    vim.list_extend(lines, { assistance_actions, "", "Cierra con `q`, `<Esc>` o `:ForjaClose`. El código queda abierto." })
  end
  local action_line = exam_active
    and "Exam Mode: e terminar · r tests · t evaluar · o resultados · :ForjaExam stop"
    or "Acciones: q cerrar · r tests · t evaluar · a recordar · h pista · o resultados"
  if not exam_active and practice_available then action_line = action_line .. " · p variación" end
  if not exam_active then action_line = action_line .. " · :ForjaClose" end
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
  ui.open_lesson(lines, mode == "practice" and "Variación · " .. lesson.title or lesson.title,
    nil, mode, exam_active, practice_available)
end

return M
