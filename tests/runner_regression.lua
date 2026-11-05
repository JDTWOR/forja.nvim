vim.opt.runtimepath:prepend(vim.fn.getcwd())
local fs = require("forja.util.fs")
local runner = require("forja.runner.process")
local function check(value, message) if not value then error(message) end end
local root = vim.fn.tempname()
fs.ensure_dir(root)
local track = assert(require("forja.core.curriculum").list())[1]
local lesson = track._ordered_lessons[1]
local workspace = fs.join(root, "exercise")
fs.ensure_dir(fs.join(workspace, "src"))
fs.write(fs.join(workspace, "Cargo.toml"), '[package]\nname="forja_variables_mutability"\nversion="0.1.0"\nedition="2021"\nautotests=false\n\n[[test]]\nname="forja_assessment"\npath="tests/old_assessment.rs"\n')
fs.ensure_dir(fs.join(workspace, "tests"))
fs.write(fs.join(workspace, "tests/old_assessment.rs"), "#[test] fn old_target() {}\n")
fs.write(fs.join(workspace, "src/lib.rs"), "pub fn add_fee(_:u32,_:u32)->u32 {0}\npub fn final_price(_:u32,_:u8,_:u8)->u32 {0}\npub fn final_price_tax_first(_:u32,_:u8,_:u8)->u32 {0}\n")
local function run(assessment, timeout, started)
  local result
  runner.run(track, lesson, workspace, assessment, timeout, function(value) result = value end)
  if started then started() end
  check(vim.wait(10000, function() return result ~= nil end, 10), "runner never completed")
  return result
end
local hidden = run(true, 5000)
check(hidden.code ~= 0 and hidden.output:find("assessment_", 1, true), "autotests=false bypassed hidden assertions")
local cargo = require("forja.util.cargo")
check(cargo.validate_starter(workspace, "forja_variables_mutability"), "valid starter rejected")
check(not cargo.validate_starter(workspace, "different"), "package mismatch accepted")
vim.uv.fs_unlink(fs.join(workspace, "src/lib.rs"))
check(not cargo.validate_starter(workspace, "forja_variables_mutability"), "missing source accepted")
fs.write(fs.join(workspace, "src/lib.rs"), "pub fn value() {}\n")
local copied, copy_error = fs.copy_tree(workspace, fs.join(root, "bounded"), {}, "",
  { entries = 0, bytes = 0, max_entries = 1, max_bytes = 10 })
check(not copied and copy_error:find("limit"), "staging limits were ignored")
-- A test child survives killing Cargo alone. Require termination of its group.
fs.write(fs.join(workspace, "Cargo.toml"), '[package]\nname="forja_variables_mutability"\nversion="0.1.0"\nedition="2021"\n')
fs.ensure_dir(fs.join(workspace, "tests"))
fs.write(fs.join(workspace, "tests/child.rs"), [[#[test] fn child() {
let child = std::process::Command::new("sleep").arg("20").spawn().unwrap();
std::fs::write("child.pid", child.id().to_string()).unwrap();
std::thread::sleep(std::time::Duration::from_secs(20));
}]])
local child_pid
local cancelled = run(false, 5000, function()
  check(vim.wait(4000, function()
    local pid = fs.read(fs.join(workspace, "child.pid"))
    if pid then child_pid = tonumber(pid); return true end
  end, 10), "child never started")
  check(runner.cancel(), "cancel rejected")
end)
check(cancelled.cancelled, "cancel status missing")
local status = fs.read("/proc/" .. child_pid .. "/stat")
check(not status or status:match("%) Z"), "cancel left the test child running")
vim.uv.fs_unlink(fs.join(workspace, "child.pid"))
local began = vim.uv.hrtime()
local timed = run(false, 500)
check(timed.timed_out and (vim.uv.hrtime() - began) / 1e6 < 1500, "total deadline not enforced")
fs.remove_tree(root)
print("Runner regressions passed: mandatory hidden target, Cargo validation, staging bounds, child cancellation, total deadline")
vim.cmd("qa!")
