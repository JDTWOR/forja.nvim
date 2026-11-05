-- Run with: nvim --headless -u NONE -l tests/ux_review.lua
vim.opt.runtimepath:prepend(vim.fn.getcwd())
local ui = require('forja.ui')
local lesson_ui = require('forja.ui.lesson')
local curriculum = require('forja.core.curriculum')
local lesson = assert(curriculum.list())[1]._ordered_lessons[1]
local function check(value, message) assert(value, message) end
for _, mode in ipairs({ 'review', 'recall', 'exam' }) do
  lesson_ui.render(lesson, nil, mode, mode == 'exam')
  local text = table.concat(vim.api.nvim_buf_get_lines(ui.lesson_view.buf, 0, -1, false), '\n')
  check(not text:find(lesson.explanation, 1, true), mode .. ' exposed explanation')
  check(not text:find(lesson.guided, 1, true), mode .. ' exposed guided strategy')
  check(not text:find(lesson.example, 1, true), mode .. ' exposed example')
  ui.close()
end
local config = require('forja.config')
local commands = require('forja.commands')
local storage = require('forja.storage.json')
local fs = require('forja.util.fs')
local temporary = vim.fn.tempname()
local provider_calls = 0
config.setup({ data_dir = temporary, ai = { provider = { complete = function() provider_calls = provider_calls + 1 end } } })
commands.setup()
check(vim.fn.exists(':ForjaHistory') == 2, 'ForjaHistory command is registered')
commands.start('rust-foundations')
local base_path = vim.api.nvim_buf_get_name(ui.lesson_view.return_win and vim.api.nvim_win_get_buf(ui.lesson_view.return_win) or 0)
commands.practice()
local practice_path = vim.api.nvim_buf_get_name(ui.lesson_view.return_win and vim.api.nvim_win_get_buf(ui.lesson_view.return_win) or 0)
commands.lesson('missing-lesson')
commands.lesson()
local reopened = vim.api.nvim_buf_get_name(vim.api.nvim_win_get_buf(ui.lesson_view.return_win))
check(reopened == practice_path, 'failed navigation detached the active practice session')
local pending_input
local old_input = vim.ui.input
vim.ui.input = function(_, callback) pending_input = callback end
commands.tutor()
commands.exam()
check(storage.load().exam_active, 'fresh exam did not start')
local exam_path = vim.api.nvim_buf_get_name(vim.api.nvim_win_get_buf(ui.lesson_view.return_win))
check(exam_path ~= practice_path and exam_path ~= base_path, 'exam reused an existing workspace')
local exam_keys = {}
for _, mapping in ipairs(vim.api.nvim_buf_get_keymap(ui.lesson_view.buf, 'n')) do exam_keys[mapping.lhs] = true end
check(exam_keys.e and not exam_keys.h and not exam_keys.a and not exam_keys.p and not exam_keys.b,
  'Exam Mode advertises only independent assessment actions')
commands.recall()
check(vim.api.nvim_buf_get_name(vim.api.nvim_win_get_buf(ui.lesson_view.return_win)) == exam_path,
  'guided recall cannot replace the independent exam view')
package.loaded['forja.commands'] = nil
local restarted = require('forja.commands')
restarted.lesson()
check(vim.api.nvim_buf_get_name(vim.api.nvim_win_get_buf(ui.lesson_view.return_win)) == exam_path, 'restart lost active exam workspace')
pending_input('Please help')
check(provider_calls == 0, 'pending tutor input invoked a provider during exam')
vim.ui.input = old_input
restarted.exam('stop')
check(not storage.load().exam_active, 'exam did not end')
check(vim.api.nvim_buf_get_name(vim.api.nvim_win_get_buf(ui.lesson_view.return_win)) == base_path, 'exam did not return to base')
local recall_state = storage.load()
require('forja.core.progress').record_recall(recall_state, 'rust-foundations', lesson.id, { 'saved answer' })
storage.save(recall_state)
local old_select = vim.ui.select
vim.ui.select = function(items, _, callback)
  for _, item in ipairs(items) do if item.recall then callback(item); return end end
  error('saved recall was not discoverable')
end
restarted.history()
check(table.concat(vim.api.nvim_buf_get_lines(ui.current.buf, 0, -1, false), '\n'):find('saved answer', 1, true), 'saved recall answers cannot be reviewed')
ui.close('float')
vim.ui.select = function(items, _, callback)
  for _, item in ipairs(items) do if item.path == practice_path:gsub('/src/lib.rs$', '') then callback(item); return end end
  error('saved practice was not discoverable')
end
restarted.history()
check(vim.api.nvim_buf_get_name(vim.api.nvim_win_get_buf(ui.lesson_view.return_win)) == practice_path, 'history did not resume saved workspace')
vim.ui.select = old_select
local state = storage.load()
state.practice_session.path = '/tmp/outside-forja'
state.exam_active = true
storage.save(state)
package.loaded['forja.commands'] = nil
require('forja.commands').progress()
check(not storage.load().exam_active and storage.load().practice_session == nil, 'invalid saved exam path was not terminated')
ui.close()
fs.remove_tree(temporary)
print('UX restricted-reading tests passed: review, recall and exam hide study assistance')
vim.cmd('qa!')
