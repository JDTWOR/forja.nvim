# forja.nvim

`forja.nvim` is a local-first programming practice plugin. It gives you a
structured curriculum, editable starter projects, deterministic language tests,
and progress evidence inside Neovim. It is designed to make the learner do the
implementation. AI is optional and the courses work offline.

## Phase 1 status

Forja currently includes four foundations tracks with five Spanish lessons
each: Rust, Python, Java, and Go. All twenty lessons have editable starter code,
visible tests, a separate assessment, and a reference solution verified against
the tests. Rust also has runnable transfer projects for all five lessons; the
other tracks include written variations, with separate runnable transfer
projects planned. Lessons unlock only after their assessment passes. Hints and
tutor use are recorded separately from test correctness.

There is no shipped HTTP AI provider or spaced-repetition scheduler yet. The
offline tutor uses a fixed Socratic question; `:ForjaReview` creates a clean
workspace for explicit retrieval practice. See [the roadmap](docs/roadmap.md)
for the next phases and [research notes](docs/research.md) for the upstream
review and licensing decisions.

## Requirements

- Neovim 0.10 or newer on Linux/macOS. The development environment used Neovim 0.12.6.
- Install the toolchain for each track you want to use:
  - Rust: `rustc` and `cargo` (`cargo test --offline`).
  - Python: `python3` (standard-library `unittest`).
  - Java: JDK 11+ (`javac` and `java`; standard library only).
  - Go: Go 1.21+ (standard library only; module network access is disabled).
- Python 3 is also used by the optional solution verification scripts.
- lazy.nvim is recommended; there are no required Neovim plugin dependencies.

On Arch Linux/CachyOS:

```sh
sudo pacman -S neovim python rust jdk-openjdk go
```

The Arch `rust` package includes `rustc` and Cargo. The JDK provides both
`javac` and `java`. Language servers are not required by Forja; install
`rust-analyzer`, `pyright`, `jdtls`, or `gopls` separately if you want LSP
features in your editor.

## Install with LazyVim

Add `lua/plugins/forja.lua` to your Neovim configuration:

```lua
return {
  {
    "JDTWOR/forja.nvim",
    main = "forja",
    cmd = {
      "Forja", "ForjaClose", "ForjaResult", "ForjaStart", "ForjaTracks", "ForjaLesson", "ForjaNext",
      "ForjaRun", "ForjaTest", "ForjaTrustLocal", "ForjaCancel", "ForjaHint",
      "ForjaTutor", "ForjaRecall", "ForjaHistory", "ForjaReview", "ForjaPractice", "ForjaExam", "ForjaAbandon",
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

1. Run `:Forja` and press `s`, or start a track directly:
   `:ForjaStart rust-foundations`, `:ForjaStart python-foundations`,
   `:ForjaStart java-foundations`, or `:ForjaStart go-foundations`.
2. Read the lesson beside the opened source buffer on wide terminals. On
   narrow terminals, the focused lesson view has `q`/`Esc` to return to code.
   `:ForjaClose` works from either pane. The workspace is under
   `stdpath("data")/forja/workspaces/`.
3. Run `:ForjaTrustLocal` once for this exercise and confirm the prompt. The
   selected language toolchain executes local code with your user permissions.
4. Run `:ForjaRun` for visible tests and compiler output. If the buffer has
   unsaved changes, Forja asks whether to save and run or cancel. Fix your
   implementation and run it again as needed.
5. Run `:ForjaTest` for the hidden assessment in a temporary copy. A failure is
   saved as evidence but does not unlock the next lesson. A passing assessment
   unlocks it. The local machine owner can inspect course files; this is not a
   cryptographic boundary.
6. Run `:ForjaNext` to continue, `:ForjaHint` for the next graduated hint, or
   `:ForjaAbandon` if you want to stop and reveal the reference solution.

Use `:ForjaRecall` (or `a` in the dashboard) to answer each retrieval question
from memory. Forja hides the explanation and example while you answer, then
stores your ungraded responses. From a normal lesson workspace, run
`:ForjaLesson` to reopen the explanation and compare your answer. `:ForjaHistory`
lets you read saved responses later.

If you have already completed a lesson, `:ForjaReview` lets you choose it and
creates a separate clean starter workspace with study explanations hidden. It
will not overwrite your original solution. `:ForjaPractice` opens a dedicated
transfer exercise with its own starter, visible tests, hidden assessment and
saved evidence. Approve its local Cargo run separately with
`:ForjaTrustLocal`. Transfer results do not unlock lessons. Run
`:ForjaReview stop` to return to your persistent learner workspace; practice
copies stay under `forja/reviews/`. Use `:ForjaHistory` to review saved answers
or resume one of those workspaces. Resumed workspaces preserve their files but
cannot establish new independent mastery; start a newly created review or exam
workspace for that. Dedicated runnable transfer workspaces currently exist for
the Rust lessons; Python, Java, and Go have written variation prompts.

`:ForjaExam` starts a fresh workspace and hides the worked explanation, example,
and guided strategy. Forja disables its hints and tutor until `:ForjaExam stop`,
which saves the exam workspace and returns to your normal lesson. An active exam
workspace can be restored after restarting Neovim when its saved path is valid.
Exam Mode only controls features inside Forja.

## Commands

| Command | Behavior |
| --- | --- |
| `:Forja` | Open the dashboard with current objective, progress, weak lessons, and recent results. |
| `:ForjaClose` | Close the lesson or focused Forja view and return to code. |
| `:ForjaResult` | Open the latest test output without replacing the lesson. |
| `:ForjaStart [track-id]` | Start/resume the first eligible lesson in a track. |
| `:ForjaTracks` | Browse installed tracks. |
| `:ForjaLesson [lesson-id]` | Open the current or a prerequisite-eligible lesson. |
| `:ForjaNext` | Open the next lesson after assessment completion. |
| `:ForjaRun` | Run visible tests with the selected language toolchain asynchronously. |
| `:ForjaTest` | Run the hidden assessment target in a temporary copy; `:ForjaRun` runs visible tests. |
| `:ForjaTrustLocal` | Explicitly approve local code execution for this exercise. |
| `:ForjaCancel` | Request cancellation of the active Forja process. |
| `:ForjaHint` | Reveal and record the next hint in the six-step ladder. |
| `:ForjaRecall` | Capture short answers to the lesson's retrieval questions. |
| `:ForjaHistory` | Review saved recall answers or resume a saved review/transfer workspace. |
| `:ForjaTutor` | Ask a Socratic question (fixed offline mock unless a provider is configured). |
| `:ForjaReview [lesson-id\|stop]` | Start clean retrieval practice for a completed lesson, or detach the review workspace. |
| `:ForjaPractice [lesson-id]` | Open the transfer variation. |
| `:ForjaExam [stop]` | Start/stop a clean independent attempt; Forja hints and tutor are disabled while active. |
| `:ForjaAbandon` | Explicitly abandon and display the reference solution without changing learner code. |
| `:ForjaProgress` | Show lesson evidence, attempts, hints, and tutor assistance. |
| `:ForjaHealth` | Check Neovim APIs, installed course toolchains, curriculum parsing, and progress storage. |
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
`forja/workspaces/`; clean review copies live in `forja/reviews/`. Active review,
practice, and exam metadata is persisted so Forja can restore a valid workspace
after restart. Existing workspaces are never overwritten.

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

Run the headless Neovim domain/end-to-end tests and verify reference solutions
with the corresponding language toolchains:

```sh
bash tests/run.sh
```

The complete suite requires Rust/Cargo, Python 3, a JDK, and Go. To use Forja
without one of those toolchains, install only the runtimes for tracks you plan
to study; the plugin itself does not require the other compilers.

The suite uses no Plenary or other Neovim test dependency. It covers graph
validation, migrations, persistence, sticky assistance accounting, clean
retrieval and exam gating, saved history and session restoration, restricted
recall/review views, responsive UI cleanup and resize, assessment gating,
unsaved-buffer safety, separate transfer workspaces, mandatory hidden assessments,
workspace staging limits, process-group cancellation, and a total execution
deadline. It checks that ten Rust starters compile without warnings and verifies
all twenty foundation reference solutions against visible and assessment tests.

## Security limits

Forja asks before running local code. After approval, compilers and test
runners execute with your account's permissions. The assessment copy excludes
`.git` and Rust's `target`, is limited to 2000 filesystem entries and 16 MiB,
and runs hidden tests in a temporary copy under one deadline. Java class files
are written to a temporary directory and removed after the run. Go module
downloads are disabled for Forja exercises.
`--offline` avoids Rust dependency downloads; it does not sandbox the process.
Cancellation and timeout kill the child process group on Linux/macOS. A process
that deliberately escapes that group is outside this control. The machine owner
can inspect repository files or change tests. Exam Mode only disables assistance
controlled by Forja; it cannot block external apps, search engines, shell
commands, or other AI tools.

## Documentation

- [Architecture](docs/architecture.md)
- [Educational model and evidence](docs/educational-model.md)
- [Research and upstream compatibility/licensing notes](docs/research.md)
- [Curriculum authoring](docs/curriculum-authoring.md)
- [Roadmap](docs/roadmap.md)
