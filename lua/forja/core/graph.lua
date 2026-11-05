local M = {}

local function valid_id(value)
  return type(value) == "string" and value:match("^[a-z0-9][a-z0-9._-]*$") ~= nil
end

local function string_list(value, minimum)
  if type(value) ~= "table" or #value < minimum then return false end
  for index = 1, #value do
    if type(value[index]) ~= "string" or value[index] == "" then return false end
  end
  return true
end

function M.validate(curriculum)
  if type(curriculum) ~= "table" then return nil, "curriculum must be an object" end
  if curriculum.schema_version ~= 1 then return nil, "unsupported curriculum schema_version" end
  if not valid_id(curriculum.id) then return nil, "curriculum has an invalid id" end
  if type(curriculum.version) ~= "string" then return nil, "curriculum version must be a string" end
  if type(curriculum.title) ~= "string" then return nil, "curriculum title must be a string" end
  if type(curriculum.modules) ~= "table" or #curriculum.modules == 0 then
    return nil, "curriculum must contain at least one module"
  end
  local modules = {}
  for _, module in ipairs(curriculum.modules) do
    if type(module) ~= "table" or not valid_id(module.id) then return nil, "module has an invalid id" end
    if modules[module.id] then return nil, "duplicate module id: " .. module.id end
    if type(module.title) ~= "string" or module.title == "" then return nil, "module " .. module.id .. " must have a title" end
    modules[module.id] = true
  end
  if type(curriculum.lessons) ~= "table" or #curriculum.lessons == 0 then
    return nil, "curriculum must contain at least one lesson"
  end

  local ids = {}
  for _, lesson in ipairs(curriculum.lessons) do
    if type(lesson) ~= "table" or not valid_id(lesson.id) then
      return nil, "lesson has an invalid id"
    end
    if ids[lesson.id] then return nil, "duplicate lesson id: " .. lesson.id end
    if type(lesson.title) ~= "string" or lesson.title == ""
      or type(lesson.objective) ~= "string" or lesson.objective == "" then
      return nil, "lesson " .. lesson.id .. " must have a title and objective"
    end
    if not modules[lesson.module] then return nil, "lesson " .. lesson.id .. " references missing module " .. tostring(lesson.module) end
    if not string_list(lesson.concepts, 1) or type(lesson.exercise) ~= "table" then
      return nil, "lesson " .. lesson.id .. " must declare concepts and an exercise"
    end
    if type(lesson.prerequisites) ~= "table" then return nil, "lesson " .. lesson.id .. " prerequisites must be a list" end
    for _, field in ipairs({ "explanation", "example", "guided", "variation" }) do
      if type(lesson[field]) ~= "string" or lesson[field] == "" then
        return nil, "lesson " .. lesson.id .. " must provide " .. field
      end
    end
    for _, field in ipairs({ "questions", "requirements" }) do
      if not string_list(lesson[field], 1) then return nil, "lesson " .. lesson.id .. " must provide " .. field end
    end
    if not string_list(lesson.hints, 6) then
      return nil, "lesson " .. lesson.id .. " must provide the six hint levels"
    end
    if lesson.variation_hints ~= nil and not string_list(lesson.variation_hints, 6) then
      return nil, "lesson " .. lesson.id .. " must provide the six transfer hint levels"
    end
    if lesson.exercise.variation_dir ~= nil and not valid_id(lesson.exercise.variation_dir) then
      return nil, "lesson " .. lesson.id .. " has an invalid variation_dir"
    end
    ids[lesson.id] = lesson
  end

  local indegree, dependents = {}, {}
  for id in pairs(ids) do indegree[id], dependents[id] = 0, {} end
  for _, lesson in ipairs(curriculum.lessons) do
    local seen_prerequisites = {}
    for _, prerequisite in ipairs(lesson.prerequisites or {}) do
      if not valid_id(prerequisite) then return nil, "lesson " .. lesson.id .. " has an invalid prerequisite id" end
      if not ids[prerequisite] then
        return nil, "lesson " .. lesson.id .. " references missing prerequisite " .. prerequisite
      end
      if seen_prerequisites[prerequisite] then return nil, "lesson " .. lesson.id .. " repeats prerequisite " .. prerequisite end
      seen_prerequisites[prerequisite] = true
      indegree[lesson.id] = indegree[lesson.id] + 1
      table.insert(dependents[prerequisite], lesson.id)
    end
  end

  local queue, sorted = {}, {}
  for _, lesson in ipairs(curriculum.lessons) do
    if indegree[lesson.id] == 0 then table.insert(queue, lesson.id) end
  end
  local cursor = 1
  while queue[cursor] do
    local id = queue[cursor]
    cursor = cursor + 1
    table.insert(sorted, ids[id])
    for _, child in ipairs(dependents[id]) do
      indegree[child] = indegree[child] - 1
      if indegree[child] == 0 then table.insert(queue, child) end
    end
  end
  if #sorted ~= #curriculum.lessons then return nil, "prerequisite graph contains a cycle" end
  return sorted
end

return M
