# forja.nvim

`forja.nvim` is a local-first programming practice plugin. It gives you a
structured curriculum, editable starter projects, deterministic language tests,
and progress evidence inside Neovim. It is designed to make the learner do the
implementation. AI is optional and the courses work offline.

## Phase 1 status

Forja currently includes four foundations tracks with five Spanish lessons
each: Rust, Python, Java, and Go. All twenty lessons have editable starter code,
visible tests, a separate assessment, and a reference solution verified against
the tests. Each lesson in all four tracks also has a separate runnable transfer
project with its own starter, visible tests, hidden assessment and reference
solution. Lessons unlock only after their assessment passes. Hints and tutor use
are recorded separately from test correctness.

The study view keeps the source editor beside a focused lesson pane on wide
terminals. Its numbered sections separate the challenge, concept, example,
active recall and strategy; `1`–`5` switch sections without leaving the code.
Test output remains in a bottom pane that updates on later runs and can be
closed with `q`. On a fresh install the dashboard asks which track to start
instead of choosing one implicitly.

The OpenAI Responses API provider is optional; when no key is configured, the
tutor uses a fixed offline Socratic question. Set up the provider directly in
Neovim with `:ForjaSettings`. A spaced-repetition scheduler is not shipped yet;
`:ForjaReview` creates a clean workspace for explicit recall practice. See [the roadmap](docs/roadmap.md) for the next phases and
[research notes](docs/research.md) for upstream review and licensing decisions.

## Requirements

- Neovim 0.10 or newer on Linux/macOS. The development environment used Neovim 0.12.6.
- Install the toolchain for each track you want to use:
  - Rust: `rustc` and `cargo` (`cargo test --offline`).
  - Python: `python3` (standard-library `unittest`).
  - Java: JDK 11+ (`javac` and `java`; standard library only).
  - Go: Go 1.21+ (standard library only; module network access is disabled).
- `curl` is needed only for the optional OpenAI provider.
- Python 3 is also used by the optional solution verification scripts.
- lazy.nvim is recommended; there are no required Neovim plugin dependencies.

On Arch Linux/CachyOS:

```sh
sudo pacman -S neovim python rust jdk-openjdk go curl
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
      "Forja", "ForjaClose", "ForjaResult", "ForjaStart", "ForjaLang", "ForjaSettings", "ForjaTracks", "ForjaLesson", "ForjaNext",
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

1. Run `:Forja` and press `l` to choose a language, or start one directly:
   `:ForjaStart rust-foundations`, `:ForjaStart python-foundations`,
   `:ForjaStart java-foundations`, or `:ForjaStart go-foundations`.
   Later, use `:ForjaLang` or dashboard key `l` to switch tracks. Each track
   keeps its own progress and workspace.
2. Read the challenge beside the opened source buffer on wide terminals. Press
   `1`–`5` in the lesson pane to switch between the challenge, concept, example,
   recall and strategy. On narrow terminals, the focused lesson view has
   `q`/`Esc` to return to code.
   `:ForjaClose` works from either pane. The workspace is under
   `stdpath("data")/forja/workspaces/`.
3. Run `:ForjaTrustLocal` once for this exercise and confirm the prompt. The
   selected language toolchain executes local code with your user permissions.
4. Run `:ForjaRun` for visible tests and compiler output. On wide terminals,
   feedback stays in a bottom result pane and refreshes on later runs; use
   `:ForjaResult` to reopen it. If the buffer has unsaved changes, Forja asks
   whether to save and run or cancel. Fix your implementation and run it again.
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
`:ForjaTrustLocal`. Transfer results do not unlock lessons. All four tracks have
a dedicated runnable transfer workspace per lesson. Run `:ForjaReview stop` to
return to your persistent learner workspace; practice copies stay under
`forja/reviews/`. Use `:ForjaHistory` to review saved answers or resume one of
those workspaces. Resumed workspaces preserve their files but cannot establish
new independent mastery; start a newly created review or exam workspace for that.

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
| `:ForjaLang` | Open the keyboard language/track picker. |
| `:ForjaSettings` | Open language and AI settings; add a masked API key with `k`. |
| `:ForjaTracks` | Open the language/track picker. |
| `:ForjaLesson [lesson-id]` | Open the current or a prerequisite-eligible lesson. |
| `:ForjaNext` | Open the next lesson after assessment completion. |
| `:ForjaRun` | Run visible tests with the selected language toolchain asynchronously. |
| `:ForjaTest` | Run the hidden assessment target in a temporary copy; `:ForjaRun` runs visible tests. |
| `:ForjaTrustLocal` | Explicitly approve local code execution for this exercise. |
| `:ForjaCancel` | Cancel the pending tutor request or active Forja process. |
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

## OpenAI tutor configuration

Forja includes an optional adapter for OpenAI's [Responses API](https://developers.openai.com/api/docs/guides/text).
Without a key, `:ForjaTutor` uses the offline mock. Run `:ForjaSettings`, press
`k`, then paste the key at the masked prompt. Forja saves it outside progress
data at `stdpath("data")/forja/secrets/openai.key` with `0600` file permissions,
enables OpenAI immediately, and never displays the saved value. The local key
takes priority over the environment; `d` removes the saved key and falls back
to `OPENAI_API_KEY` if present. The adapter requires `curl`.

Create an API key in the [OpenAI API platform](https://platform.openai.com/api-keys)
If you prefer not to save a local key, provide `OPENAI_API_KEY` in Neovim's
environment. For a single Zsh terminal session, enter it without echoing it or
putting it in shell history:

```zsh
read -rs 'OPENAI_API_KEY?OpenAI API key: '
export OPENAI_API_KEY
nvim
```

Open a lesson and run `:ForjaTutor`. Use `:ForjaHealth` to check `curl`, the
key's presence, the selected model, and this session's token totals.
`:ForjaCancel` cancels a pending tutor request or a running exercise. The model
defaults to `gpt-6-luna`; set `FORJA_OPENAI_MODEL` or configure `opts.ai.provider`
if you need another model. A model response is guidance, not a test result.
OpenAI API usage is billed separately from a ChatGPT subscription; see the
[OpenAI billing explanation](https://help.openai.com/en/articles/9039756-managing-billing-for-chatgpt-and-the-api-platform).

Custom providers remain supported through `opts.ai.provider` and the same
small interface:

```lua
{
  complete = function(request, callback)
    -- request.system and request.context contain educational context only.
    -- Call callback({ text = "..." }) or callback({ error = "..." }).
    -- Return an optional handle with a cancel method.
  end,
}
```

The context intentionally excludes learner files and source buffers. Keep API
keys out of Forja progress data, source files, and public Git repositories. A
locally saved key is unencrypted and readable by the same OS user (and root);
the `0600` permissions prevent access by other ordinary users. Use the
environment-variable option when you prefer to manage the key elsewhere.
Provider output is tutoring advice, not a test result. Exam Mode does not call
the provider and never falls back to one.

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

The complete suite requires Rust/Cargo, Python 3, a JDK, and Go. The optional
OpenAI provider also uses `curl`. To use Forja without one of those toolchains,
install only the runtimes for tracks you plan to study; the plugin itself does
not require the other compilers.

The suite uses no Plenary or other Neovim test dependency. It covers graph
validation, migrations, persistence, sticky assistance accounting, clean
retrieval and exam gating, saved history and session restoration, restricted
recall/review views, tabbed lessons, first-run track selection, persistent test
results, responsive UI cleanup and resize, language-picker navigation, secure
masked API-key setup/removal, assessment gating, unsaved-buffer safety, separate
transfer workspaces, mandatory hidden assessments, workspace staging limits,
process-group cancellation, OpenAI protocol parsing, missing-key handling, token
usage, timeout and cancellation. It checks that ten Rust starters
compile without warnings and verifies all twenty foundation exercises and all
twenty transfer variations against visible and hidden tests.

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
