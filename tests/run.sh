#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/.."
nvim --headless -u NONE --cmd 'set runtimepath^=.' -c 'lua local ok, err = pcall(dofile, "tests/run.lua"); if not ok then print(err); vim.cmd("cquit 1") end'
nvim --headless -u NONE -c 'lua local ok, err = pcall(dofile, "tests/progress_sessions.lua"); if not ok then print(err); vim.cmd("cquit 1") end'
nvim --headless -u NONE -c 'lua local ok, err = pcall(dofile, "tests/ux_review.lua"); if not ok then print(err); vim.cmd("cquit 1") end'
nvim --headless -u NONE -c 'lua local ok, err = pcall(dofile, "tests/runner_regression.lua"); if not ok then print(err); vim.cmd("cquit 1") end'
nvim --headless -u NONE -c 'lua local ok, err = pcall(dofile, "tests/multilang_runner.lua"); if not ok then print(err); vim.cmd("cquit 1") end'
python3 tests/verify_solutions.py
python3 courses/python/verify_solutions.py
python3 courses/java/verify_solutions.py
python3 courses/go/verify_solutions.py
