#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/.."
nvim --headless -u NONE --cmd 'set runtimepath^=.' -c 'lua local ok, err = pcall(dofile, "tests/run.lua"); if not ok then print(err); vim.cmd("cquit 1") end'
python3 tests/verify_solutions.py
