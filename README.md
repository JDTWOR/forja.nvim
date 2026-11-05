# forja.nvim

`forja.nvim` is a local-first programming practice plugin. It gives you a
structured curriculum, editable starter projects, deterministic Rust tests, and
progress evidence inside Neovim. It is designed to make the learner do the
implementation. AI is optional and the first slice works offline.

## Phase 1 status

The current working track is **Rust Fundamentals**. It contains five Spanish
lessons: variables and mutability, scalar types, control flow, functions, and
ownership/borrowing. Each lesson includes a transfer variation, visible tests,
assessment tests, and a verified reference solution. Lessons unlock only after
the assessment passes. Hints and tutor use are recorded separately from test
correctness.

There is no shipped HTTP AI provider or spaced-repetition scheduler yet. The
offline tutor uses a fixed Socratic question; `:ForjaReview` creates a clean
workspace for explicit retrieval practice. See [the roadmap](docs/roadmap.md)
for the next phases and [research notes](docs/research.md) for the upstream
review and licensing decisions.

## Requirements

- Neovim 0.10 or newer on Linux/macOS, with `/bin/sh` for the fixed runner
  wrapper. The development environment used Neovim 0.12.6.
- `rustc` and `cargo` for the Rust track. Tests run with `cargo test --offline`.
- Python 3 only to run the optional reference-solution verification script.
- lazy.nvim is recommended; there are no required Neovim plugin dependencies.

On Arch Linux/CachyOS:

```sh
sudo pacman -S neovim rust
```

The Arch `rust` package includes `rustc` and Cargo. A language server is not
required by Forja; install `rust-analyzer` separately if you want Rust LSP
features in your editor.

## Install with LazyVim

Add `lua/plugins/forja.lua` to your Neovim configuration. This local `dir` spec
uses the repository location from this workspace; change it if you clone Forja
elsewhere:

```lua
return {
  {
    dir = vim.fn.expand("~/Documents/Personal/forja"),
    name = "forja.nvim",
    main = "forja",
    cmd = {
      "Forja", "ForjaStart", "ForjaTracks", "ForjaLesson", "ForjaNext",
      "ForjaRun", "ForjaTest", "ForjaTrustLocal", "ForjaCancel", "ForjaHint",
      "ForjaTutor", "ForjaReview", "ForjaPractice", "ForjaExam", "ForjaAbandon",
      "ForjaProgress", "ForjaHealth", "ForjaExport",
    },
    opts = {
      runner = { timeout_ms = 30000 },
      keymaps = { enabled = false, prefix = "<leader>F" },
    },
  },
}
```

LazyVim loads specs from `lua/plugins/*.lua`. For a generic Lazy setup, add
the same spec table to `require("lazy").setup({ ... })`. The plugin can also be
put directly on Neovim's `runtimepath`; its `plugin/forja.lua` file registers the
commands.

Optional mappings are disabled by default. To enable the dashboard mapping:

```lua
opts = { keymaps = { enabled = true, prefix = "<leader>F" } }
```

## First lesson walkthrough

1. Run `:Forja` and press `s`, or run `:ForjaStart rust-foundations`.
2. Read the lesson panel and work in the opened `src/lib.rs` buffer. The starter
   workspace is under `stdpath("data")/forja/workspaces/`.
3. Run `:ForjaTrustLocal` once for this exercise and confirm the prompt. Rust
   builds and tests execute local code with your user permissions.
4. Run `:ForjaRun` for visible tests and compiler output. Fix your implementation
   and run it again as needed.
5. Run `:ForjaTest` for the assessment. A failure is saved as evidence but does
   not unlock the next lesson. A passing assessment unlocks it.
6. Run `:ForjaNext` to continue, `:ForjaHint` for the next graduated hint, or
   `:ForjaAbandon` if you want to stop and reveal the reference solution.

If you have already completed a lesson, `:ForjaReview` lets you choose it and
creates a separate clean starter workspace. It will not overwrite your original
solution. `:ForjaPractice` opens the lesson's transfer variation in its own
clean workspace, where the variation is checked by the same public and hidden
tests. Run `:ForjaReview stop` to return to your persistent learner workspace;
the practice copy stays under `forja/reviews/`.

## Commands

| Command | Behavior |
| --- | --- |
| `:Forja` | Open the dashboard with current objective, progress, weak lessons, and recent results. |
| `:ForjaStart [track-id]` | Start/resume the first eligible lesson in a track. |
| `:ForjaTracks` | Browse installed tracks. |
| `:ForjaLesson [lesson-id]` | Open the current or a prerequisite-eligible lesson. |
| `:ForjaNext` | Open the next lesson after assessment completion. |
| `:ForjaRun` | Run visible Cargo tests asynchronously. |
| `:ForjaTest` | Run public and hidden assessment tests in a temporary copy. |
| `:ForjaTrustLocal` | Explicitly approve local code execution for this exercise. |
| `:ForjaCancel` | Request cancellation of the active Forja process. |
| `:ForjaHint` | Reveal and record the next hint in the six-step ladder. |
| `:ForjaTutor` | Ask a Socratic question (fixed offline mock unless a provider is configured). |
| `:ForjaReview [lesson-id\|stop]` | Start clean retrieval practice for a completed lesson, or detach the review workspace. |
| `:ForjaPractice [lesson-id]` | Open the transfer variation. |
| `:ForjaExam [stop]` | Toggle plugin-controlled independent mode; hints and tutor are disabled. |
| `:ForjaAbandon` | Explicitly abandon and display the reference solution without changing learner code. |
| `:ForjaProgress` | Show lesson evidence, attempts, hints, and tutor assistance. |
| `:ForjaHealth` | Check Neovim APIs, Cargo, curriculum parsing, and progress storage. |
| `:ForjaExport [path]` | Export the versioned progress JSON. With no path, prompts for one. |

## AI provider configuration

AI is optional and no network provider ships in Phase 1. The tutor accepts a
configured Lua provider object through `opts.ai.provider`. Its interface is:

```lua
{
  complete = function(request, callback)
    -- request.system and request.context contain educational context only.
    -- Call callback({ text = "..." }) or callback({ error = "..." }).
    -- Return an optional handle with a cancel method.
  end,
}
```

The context intentionally excludes learner files and source buffers. Do not put
API keys in Forja progress data or source files; a future built-in provider will
read secrets from the environment or a secret store. Provider output is tutoring
advice, not a test result. Exam Mode does not call the provider and never falls
back to one.

## Data, backup, and migration

By default Forja stores progress at `stdpath("data")/forja/progress.json`.
Each successful write keeps the previous file at `progress.json.bak`; writes are
made through a temporary file and rename. To export a portable copy, run
`:ForjaExport /path/to/forja-progress.json`. Workspaces live in
`forja/workspaces/`; clean review copies live in `forja/reviews/`.

You can choose a different data directory in plugin options:

```lua
opts = { data_dir = vim.fn.stdpath("state") .. "/forja" }
```

The progress file has a `schema_version`. Migrations are in
`lua/forja/storage/migrations.lua`. A malformed file is preserved and reported;
Forja does not silently replace it. Keep a copy of both `progress.json` and
`progress.json.bak` before manually editing or moving data. Never copy API
credentials into this file.

## Curriculum and exercise authoring

Courses are declarative JSON plus ordinary source/test files under `courses/`.
Curriculum Lua is never executed. Read
[the authoring guide](docs/curriculum-authoring.md) before adding a track or
exercise. The validator rejects unsupported schema versions, duplicate IDs,
missing module/prerequisite references, cycles, unsafe exercise paths, and
invalid runner manifests.

## Testing the plugin

Run the headless Neovim domain/end-to-end tests and verify every reference
solution with authentic Cargo tests:

```sh
bash tests/run.sh
```

The suite uses no Plenary or other Neovim test dependency. It covers graph
validation, migrations, persistence, assistance accounting, command loading,
UI cleanup, assessment gating, local execution, timeout, and cancellation.

## Security limits

Forja asks before running local Rust code. After approval, Cargo can run build
scripts, procedural macros, and learner tests with your account's permissions.
`--offline` avoids dependency downloads; it does not sandbox the process. The
assessment temp copy prevents hidden assertions from appearing in the ordinary
exercise workspace, but the machine owner can inspect repository files or change
tests. Exam Mode only disables assistance controlled by Forja; it cannot block
external apps, search engines, shell commands, or other AI tools.

## Documentation

- [Architecture](docs/architecture.md)
- [Educational model and evidence](docs/educational-model.md)
- [Research and upstream compatibility/licensing notes](docs/research.md)
- [Curriculum authoring](docs/curriculum-authoring.md)
- [Roadmap](docs/roadmap.md)
