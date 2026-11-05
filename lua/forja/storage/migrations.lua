local M = {}
M.current_version = 1

function M.upgrade(state)
  state = state or {}
  local version = state.schema_version or 0
  if version > M.current_version then
    return nil, "progress data was created by a newer Forja version"
  end
  if version == 0 then
    state.schema_version = 1
    state.active_track = state.active_track or nil
    state.tracks = state.tracks or {}
    state.trusted_exercises = state.trusted_exercises or {}
    state.exam_active = state.exam_active or false
    state.history = state.history or {}
  end
  if type(state.tracks) ~= "table" or type(state.trusted_exercises) ~= "table" or type(state.history) ~= "table" then
    return nil, "progress data has invalid fields for schema version " .. tostring(version)
  end
  if state.exam_active ~= nil and type(state.exam_active) ~= "boolean" then
    return nil, "progress exam_active must be a boolean"
  end
  return state
end

return M
