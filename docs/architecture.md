# Architecture

Forja's first vertical slice is a deterministic Lua plugin with static,
versioned curriculum JSON. It runs without a network connection or AI provider.

## Runtime path

```text
plugin/forja.lua
  -> lua/forja/init.lua
     -> commands.lua -> curriculum.lua -> graph.lua
                    -> progress.lua -> storage/json.lua -> migrations.lua
                    -> workspace.lua -> runner/process.lua -> vim.system
                    -> ui/* native Neovim buffers and windows
                    -> ai/interface.lua (optional, advisory only)
```

Curriculum JSON and exercise manifests are declarative data. The engine never
loads curriculum Lua. `core.graph` validates schema version, identifiers,
prerequisites, references, and cycles before a track is exposed. The current
course has one Rust track with five lessons and a sequential prerequisite DAG.
Shared concepts and language-specific lessons can be composed by adding manifests;
no language-specific logic is part of progress storage.

Each exercise directory contains:

```text
exercise.json       # schema version and runner metadata
starter/            # copied once into the learner workspace
assessment.rs       # hidden from the normal workspace
solution.rs         # only revealed after :ForjaAbandon
transfer/           # optional independent variation project and assessment
```

Visible Rust tests live in `starter/tests/public.rs`. The assessment runner makes
a temporary copy of source files (excluding `.git` and Cargo's `target/` cache),
adds `assessment.rs` as an integration test, runs `cargo test --offline`, and
removes the temporary copy. Excluding `target/` ensures Cargo recompiles the
current learner source instead of reusing cached binaries from an earlier
attempt. It never copies the reference solution into a learner workspace. The
local machine owner can still inspect course files and modify tests; this is not
a cryptographic assessment boundary.

## Storage

Progress lives in `stdpath("data")/forja/progress.json` unless `data_dir` is
configured. Writes use a temporary file followed by rename; the prior version is
kept as `progress.json.bak`. Malformed JSON is preserved and reported instead of
being replaced. `storage/migrations.lua` owns schema upgrades. Exercise workspaces
are under `workspaces/<track>/<lesson>/` and are not overwritten if they already
exist. Review and focused practice attempts use distinct timestamped directories.

The single-user JSON adapter is the initial repository implementation. A future
SQLite adapter can implement the same progress repository operations, with a
one-time importer from schema version 1 JSON. No credentials are stored in the
progress file. Recall answers are saved as ungraded evidence. Transfer attempts,
hints, and tutor use are stored separately from the base lesson record and do
not change prerequisite completion.

## Process and execution boundary

The runner starts a fixed `/bin/sh` argument array whose constant script sets a
private `077` umask and invokes `cargo test --offline --no-run`. It restores the
owner execute bit on generated test binaries, then launches `cargo test
--offline`. This handles environments where Neovim inherited a restrictive
umask; no curriculum or learner text is interpolated into the script. Both
stages use `vim.system`, an explicit working directory and timeout, and can be
cancelled with `:ForjaCancel`. Assessment writes are restricted to a generated
temporary copy; learner workspaces are copied without following symlinks.
Cargo can run `build.rs`, procedural macros, compiler plugins, and learner test
code with the current user's permissions. For that reason, local execution is
blocked until the user confirms `:ForjaTrustLocal` for the exercise. The approval
is saved per base exercise or transfer exercise. `--offline` prevents dependency
downloads but is not a sandbox. Phase 1 does not claim isolation from the
operating system.

## AI boundary

`ai/interface.lua` accepts a provider with `complete(request, callback)` and
checks for a non-empty text response. `ai/context.lua` sends the lesson objective,
concept tags, assistance level, attempt count, mode and learner question; it does
not collect repository files. The built-in mock gives one fixed Socratic question
and is not an AI model. `ai/prompts.lua` contains the educational system prompt.
No AI provider is included in Phase 1.

## Lazy.nvim

The plugin has no external Lua dependency. Its runtime file sets up commands, and
the module's `setup(opts)` accepts configuration from lazy.nvim. See the working
local-development spec in the README.
