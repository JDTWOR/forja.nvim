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
  ["python.print"] = "print y salida", ["python.expressions"] = "expresiones",
  ["python.arithmetic"] = "aritmética", ["python.identifiers"] = "nombres",
  ["python.def"] = "definir una función", ["python.calling"] = "llamar una función",
  ["python.arguments"] = "argumentos", ["python.return-values"] = "valores de retorno",
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

local sections = {
  { id = "challenge", label = "Reto" },
  { id = "concept", label = "Concepto" },
  { id = "example", label = "Ejemplo" },
  { id = "recall", label = "Recuperación" },
  { id = "guide", label = "Guía" },
}
local selected = {}

local function header(lesson, active, source_file)
  local tabs = {}
  for index, section in ipairs(sections) do
    local label = ({ "Reto", "Idea", "Ejemplo", "Recall", "Guía" })[index]
    table.insert(tabs, (active == index and "[" or "") .. index .. " " .. label .. (active == index and "]" or ""))
  end
  return {
    string.format("FORJA  /  %s  /  %s", (lesson.language or "rust"):upper(), lesson.title),
    table.concat(tabs, "  ·  "),
    string.rep("─", 42),
    "Archivo: " .. source_file .. "    ·    r tests visibles    t evaluación",
    "",
  }
end

local function normal_content(lesson, active, source_file)
  local lines = header(lesson, active, source_file)
  if active == 1 then
    vim.list_extend(lines, { "# Reto", "", "## Objetivo", lesson.objective, "", "## Requisitos" })
    for _, requirement in ipairs(lesson.requirements) do table.insert(lines, "- " .. requirement) end
    vim.list_extend(lines, { "", "Completa el reto en el editor. Ejecuta `:ForjaRun` para los casos visibles." })
  elseif active == 2 then
    vim.list_extend(lines, { "# La idea", "", "## Qué vas a aprender", lesson.objective, "",
      "## Ideas clave", concepts(lesson.concepts), "" })
    if lesson.teaching_steps then
      for index, step in ipairs(lesson.teaching_steps) do
        table.insert(lines, string.format("### Paso %d", index))
        table.insert(lines, step)
        table.insert(lines, "")
      end
      table.insert(lines, "Resumen: " .. lesson.explanation)
    else
      table.insert(lines, lesson.explanation)
    end
  elseif active == 3 then
    vim.list_extend(lines, { "# Ejemplo orientativo", "",
      lesson.example_explanation or "Este ejemplo ilustra el concepto con un caso distinto al ejercicio.", "", "```" .. (lesson.language or "rust") })
    vim.list_extend(lines, vim.split(lesson.example, "\n", { plain = true }))
    vim.list_extend(lines, { "```", "", "Vuelve al reto e implementa la solución de memoria." })
  elseif active == 4 then
    vim.list_extend(lines, { "# Recuperación activa", "", "Intenta responder antes de volver a consultar la explicación." })
    for _, question in ipairs(lesson.questions) do table.insert(lines, "- " .. question) end
    vim.list_extend(lines, { "", "Usa `:ForjaRecall` para guardar tus respuestas." })
  else
    vim.list_extend(lines, { "# Estrategia", "", lesson.guided, "", "## Ayuda gradual", "`h` revela una pista cada vez. Las pistas cuentan como asistencia para este intento." })
  end
  vim.list_extend(lines, { "", "1–5 sección    ·    r tests    ·    t evaluar    ·    q código" })
  return lines
end

function M.render(lesson, workspace, mode, exam_active)
  local practice_available = lesson.exercise and lesson.exercise._variation_dir ~= nil
  local manifest = lesson.exercise and lesson.exercise._manifest or {}
  local source_file = manifest.source_file or "src/lib.rs"
  local restricted = exam_active or mode == "review" or mode == "exam" or mode == "practice"
  local lines

  if mode == "recall" then
    lines = { "# Recuperación activa · " .. lesson.title, "", "Responde de memoria. La explicación y los ejemplos están ocultos." }
    for _, question in ipairs(lesson.questions) do table.insert(lines, "- " .. question) end
  elseif restricted then
    lines = { mode == "practice" and "# Variación independiente · " .. lesson.title or "# Intento independiente · " .. lesson.title,
      "", "## Objetivo", lesson.objective, "", "## Requisitos" }
    if mode == "practice" then
      table.insert(lines, lesson.variation)
    else
      for _, requirement in ipairs(lesson.requirements) do table.insert(lines, "- " .. requirement) end
    end
    vim.list_extend(lines, { "", "Explicación, ejemplos, guía y pistas ocultos durante este intento.",
      "", "Archivo: " .. source_file .. "    ·    r tests visibles    t evaluación" })
  else
    local key = (lesson.language or "rust") .. "." .. lesson.id
    local index = selected[key] or lesson.start_section or 1
    lines = normal_content(lesson, index, source_file)
  end

  if mode == "practice" and not exam_active then
    vim.list_extend(lines, { "", "b vuelve al ejercicio base. Este resultado no desbloquea lecciones." })
  elseif exam_active then
    vim.list_extend(lines, { "", "EXAM MODE ACTIVO · tutor y pistas deshabilitados · :ForjaExam stop termina el intento." })
  end

  local title = mode == "practice" and "Transferencia · " .. lesson.title or lesson.title
  local view = ui.open_lesson(lines, title, nil, mode, exam_active, practice_available,
    selected[(lesson.language or "rust") .. "." .. lesson.id] or lesson.start_section or 1)
  if not restricted and mode ~= "recall" then
    local key = (lesson.language or "rust") .. "." .. lesson.id
    for index = 1, #sections do
      vim.keymap.set("n", tostring(index), function()
        selected[key] = index
        ui.update_lesson(normal_content(lesson, index, source_file), sections[index].label, index)
      end, { buffer = view.buf, silent = true, desc = "Show " .. sections[index].label })
    end
  end
  return view
end

return M
