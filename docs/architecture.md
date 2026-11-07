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
prerequisites, references, and cycles before a track is exposed. Four language
tracks currently provide five sequential lessons each for Rust, Python, Java,
and Go. Shared concepts and language-specific lessons can be composed by adding
manifests; progress storage does not depend on a language.

Each exercise directory contains:

```text
exercise.json       # schema version and reviewed runner metadata
starter/            # copied once into the learner workspace
assessment.*        # hidden from the normal workspace
solution.*          # only revealed after :ForjaAbandon
transfer/           # optional independent variation project and assessment
```

`runner/adapters/` maps each manifest runner to a reviewed implementation. The
Rust adapter explicitly registers a hidden Cargo test target, even when
`autotests = false`, and excludes `.git` and `target` while staging. Python
stages the hidden module under `tests/` and disables bytecode writes. Java
compiles into a temporary classes directory and removes it after the run. Go
uses `go test` with module downloads disabled. All process calls use fixed
argument arrays and a shared deadline; no manifest content becomes a shell
command. Assessment staging is limited to 2000 filesystem entries and 16 MiB.
The reference solution is never copied into the learner workspace. The local
machine owner can inspect course files and alter tests; this is not a
cryptographic assessment boundary.

## Storage

Progress lives in `stdpath("data")/forja/progress.json` unless `data_dir` is
configured. Writes use a temporary file followed by rename; the prior version is
kept as `progress.json.bak`. Malformed JSON is preserved and reported instead of
being replaced. `storage/migrations.lua` owns schema upgrades. Exercise workspaces
are under `workspaces/<track>/<lesson>/` and are not overwritten if they already
exist. Review, exam, and focused practice attempts use distinct timestamped
directories. Active session metadata is saved so a validated workspace under
`reviews/<track>/<lesson>/` can be restored after restart. Historical workspaces
can be resumed without overwriting them, but resumption is marked uncertified
and cannot produce fresh independent evidence. Saved recall answers can also be
browsed from the history command.

The single-user JSON adapter is the initial repository implementation. A future
SQLite adapter can implement the same progress repository operations, with a
one-time importer from schema version 1 JSON. No credentials are stored in the
progress file. Recall answers are saved as ungraded evidence. Transfer attempts,
hints, and tutor use are stored separately from the base lesson record and do
not change prerequisite completion.

## Process and execution boundary

The process coordinator starts adapter-supplied argument arrays through
`vim.system` with an explicit working directory and one shared deadline. On
Linux/macOS the detached process group is killed for cancellation or timeout.
Assessment writes are restricted to generated temporary copies; workspaces are
copied without following symlinks. Staging is synchronous but bounded by the
file and byte caps above. These controls reduce hangs and runaway copies; they
are not a sandbox, and a child that deliberately escapes its process group is
outside the termination guarantee. Each toolchain can execute learner code with
the current user's permissions, so local execution is blocked until
`:ForjaTrustLocal` is confirmed. Go modules and Rust crates run offline; offline
mode is not a sandbox. Phase 1 does not claim isolation from the operating
system.

## AI boundary

`ai/interface.lua` accepts a provider with `complete(request, callback)` and
checks for a non-empty text response. `ai/context.lua` sends the lesson objective,
concept tags, assistance level, attempt count, mode and learner question; it does
not collect repository files. The built-in mock gives one fixed Socratic question
and is not an AI model. `ai/prompts.lua` contains the educational system prompt.
The opt-in `ai/providers/openai.lua` adapter calls the Responses API asynchronously
through `curl`, resolves its key through `ai/credentials.lua`, sends no files, sets
`store = false`, and supports timeout, cancellation, and session token accounting.
The mock remains the default when no key is available. `ai/credentials.lua`
supports a local key file outside progress data with `0600` permissions; the
Neovim settings panel masks key entry, and the environment remains available as
a fallback. The file is plaintext for the current OS user and is not encrypted.

`:ForjaLang` opens a native keyboard picker showing friendly course names and
per-track completion, without exposing curriculum IDs. `:ForjaSettings` groups
language switching, tutor status, masked key entry and local key removal.

## Lazy.nvim

The plugin has no external Lua dependency. Its runtime file sets up commands, and
the module's `setup(opts)` accepts configuration from lazy.nvim. See the working
local-development spec in the README.
