# Forja usability audit and remediation record

Date: 2026-11-07

## Scope

The audit began with the supplied Neovim screenshot and a source review of the
lesson UI, commands, workspace runner, curriculum, and progress storage. The
screenshot showed the lesson covering the code, paragraphs clipped to one
screen line, and compiler warnings competing with the exercise. Source review
confirmed the navigation, execution, and learning-cycle gaps listed below.

## Findings and remediation

| ID | Priority | Finding | Correction | Evidence |
| --- | --- | --- | --- | --- |
| U01 | P0 | Lesson close keys were bound only in a float that did not own focus. | Lesson views now own focus when floating; `q` and `<Esc>` close them. `:ForjaClose` works from code, instructions, and results and restores the learner buffer. | Headless navigation and close tests. |
| U02 | P0 | Cargo could test stale disk contents while an exercise buffer had unsaved edits. | `:ForjaRun` and `:ForjaTest` detect modified workspace buffers and offer save-and-run or cancel. | Regression test cancels without changing edits, then saves exact buffer contents before running. |
| U03 | P0 | `:ForjaAbandon` disclosed the reference solution during Exam Mode. | Solution review is blocked until `:ForjaExam stop`; the active lesson displays an Exam Mode banner. | Tests verify the banner appears/disappears and solution disclosure remains blocked. |
| U04 | P1 | A centered lesson float covered the exercise. | Wide terminals use a side split while keeping code focused. Narrow terminals use a bounded, focused reading float. | Headless layout checks at 120x40 and 80x24. |
| U05 | P1 | Long prose and requirements did not wrap. | Reading windows set local `wrap`, `linebreak`, `breakindent`, and reading-oriented number/sign options. | UI regression checks inspect the lesson window options. |
| U06 | P1 | Window dimensions could exceed small terminals. | Float sizes and positions are clamped to available editor dimensions; borders are omitted when they cannot fit. | 80x24 bounds test and a 12x6 minimum-size smoke check. |
| U07 | P1 | Result views replaced lessons and asynchronous completion could interrupt editing. | Results are cached and shown in a persistent bottom pane on wide terminals; subsequent runs update the same pane and preserve code focus. Narrow terminals use a bounded float. | Headless checks verify pane reuse, output retention, close behavior and focus preservation. |
| U08 | P1 | Navigation could persist a new lesson before opening it and risked hiding modified code. | Progress is saved only after the target buffer opens. Navigation refuses to proceed while any buffer in the current exercise workspace is modified. | Regression test attempts navigation from the lesson pane with a dirty code buffer and verifies the lesson and file remain current. |
| U09 | P1 | Infrastructure failures could look like incorrect learner answers. | Cargo missing, compile errors, failed assertions, timeouts, cancellation, and process startup errors receive distinct diagnostics. Missing Cargo is not counted as a learner attempt. | Integration test removes Cargo from `PATH`, checks guidance, and confirms attempt history does not change. Runner tests cover timeout and cancellation. |
| U10 | P1 | Actions were difficult to discover and appeared at the bottom of a long lesson. | A top-of-lesson action line and window-local mappings expose close, visible tests, assessment, recall, hints, results, and transfer practice. | Tests cover dashboard and lesson action mappings; README documents the keyboard walkthrough. |
| U11 | P2 | Navigation mixed languages and exposed raw concept IDs/workspace paths. | Learner-facing navigation and feedback use Spanish; concept IDs map to readable labels; lesson text no longer prints workspace paths. Rust identifiers and compiler messages remain in English. | Source review and visible lesson/dashboard assertions. |
| U12 | P2 | Recall questions had no way to capture retrieval. | `:ForjaRecall` and dashboard `a` collect answers and save them as ungraded evidence, then ask the learner to compare with the explanation. | Command test verifies answer capture and separate recall history. |
| U13 | P2 | `:ForjaPractice` repeated the whole base project. | Every lesson in Rust, Python, Java and Go now has a distinct transfer project with its own starter, visible tests, hidden assessment, reference solution, approval and progress history. Transfer success does not unlock the base lesson. | Each language verifier requires all five starters to fail by assertion and all ten reference solutions to pass their public and hidden suites. |
| U14 | P1 | Prior checks covered registration and cleanup, not reading/editing behavior. | Regression coverage now exercises focus, split/float choice, wrapping, resize, close/reopen, dirty navigation, stale-buffer protection, asynchronous result focus, Exam Mode, recall, and transfer evidence. | `bash tests/run.sh` passes. |
| U15 | P2 | Starter `todo!()` implementations left every parameter unused, producing Rust warnings before the learner changed the code. | TODO messages now reference their inputs for diagnostic context. This removes starter-only warnings while normal compiler warnings remain visible after implementation. | `tests/verify_solutions.py` runs `cargo check --offline` on all ten starters and fails if it finds any warning. |
| U16 | P1 | A visible test or retry cleared hint/tutor counters, so later code in the same workspace could be mislabeled independent. | Assistance exposure is sticky for a workspace session. Only a newly created clean review/exam workspace starts fresh independent evidence; resuming old workspaces is explicitly uncertified. | Dedicated base/transfer tests cover hint → visible test → exam counters, AI exposure, fresh retrieval, resume, and JSON persistence. |
| U17 | P1 | Showing the reference solution did not taint the active attempt. | `:ForjaAbandon` records solution disclosure as assistance for the active workspace, including transfer practice. | Progress regression verifies disclosure blocks independence until a newly created clean attempt. |
| U18 | P1 | Exam Mode reused assisted code and still showed explanations and worked examples. | Exam Mode opens a fresh starter copy, hides explanations/examples/guided strategy, disables Forja hints, tutor, and guided recall, and restores the same valid workspace after restart. | UX regression checks restricted views, new workspace identity, restart restoration, and invalid saved-path handling. |
| U19 | P1 | A failed lesson navigation detached the editor from its active practice workspace. | Practice context changes only after the destination opens successfully; `:ForjaLesson` without an argument reopens the current session/lesson. Exam sessions block unrelated navigation until stopped. | UX regression exercises an unknown lesson request during transfer practice and verifies commands stay attached to that copy. |
| U20 | P2 | Recall answers and earlier practice copies were stored but unavailable to review after restart. | `:ForjaHistory` displays saved recall answers and safely lists prior review/transfer workspaces for resume without overwriting files. | UX regression reviews a saved response, resumes a transfer workspace, and verifies resumed evidence is uncertified. |
| U21 | P1 | Cargo could return success without running the hidden assessment when `autotests = false`. | Assessment staging appends an explicit hidden test target and invokes it by name; visible tests remain a separate `:ForjaRun` action. | Runner regression uses `autotests = false` and confirms hidden assertions run and fail on the incomplete solution. |
| U22 | P1 | Timeout covered each Cargo stage separately, cancellation could leave child tests alive, and large workspace staging could freeze Neovim. | One deadline spans compile and test; cancellation/timeouts kill the detached process group on Linux/macOS; synchronous staging rejects workspaces over 2000 entries or 16 MiB. | Runner regressions check child termination, one total deadline, and rejection beyond staging limits. Staging remains synchronous within those bounds. |
| U23 | P2 | Invalid base starter manifests were accepted until the learner attempted execution. | Curriculum loading validates base and transfer Cargo package names and requires a starter source file. | Regression checks reject package mismatches and missing source files before a track is offered. |
| U24 | P1 | Tutor input could be submitted before Exam Mode and still invoke a provider after the exam began. | The async input callback checks current Exam Mode immediately before contacting a provider. | UX regression holds the input callback, starts an exam, then verifies the configured provider is never called. |
| U25 | P1 | A fresh installation silently chose the alphabetically first course, so the dashboard could display an unrelated language and progress state. | With no active course, the dashboard offers a keyboard language picker; `:ForjaLang` reopens it at any time. | Headless test verifies the picker presents friendly course names and starts the selected route. |
| U26 | P1 | A lesson presented its explanation, example, questions, strategy and exercise in one long pane. | The reading pane now has numbered sections for challenge, concept, example, recall and strategy; switching sections keeps the same source buffer open. | UI tests navigate the tabs for all four course languages and verify the displayed example fence. |
| U27 | P1 | Changing tracks required internal IDs or an unstyled `vim.ui.select`; the dashboard did not expose a clear language switch. | `:ForjaLang`, dashboard `l`, and first-run start use a native picker with language names, completion counts, `j`/`k`, arrows, Enter, and number shortcuts. | Headless UX test selects Python by number and verifies the selected track and workspace. |
| U28 | P1 | The dashboard was plain Markdown text in a fixed-height window, leaving large empty areas and weak visual hierarchy. | Rebuild the dashboard as a compact native panel with highlighted section headings, a clear next action, language/AI setup shortcuts, recent activity, a fitted height, and a local shortcut bar. | Headless tests verify action mappings, picker/settings navigation, buffer cleanup, and responsive bounds. |
| U29 | P1 | Configuring an API key required editing shell state and Lazy configuration; there was no visible settings area or masked input. | `:ForjaSettings` groups language and tutor controls. `k` uses Neovim's hidden secret prompt and stores the key outside progress in a file with `0600` permissions; `d` removes it. | Settings tests verify the key is absent from the UI/progress, permissions are restricted, the provider activates, and removal returns to offline mode. |

## Interaction contract now implemented

- `:Forja` opens a focused dashboard; `q` or `<Esc>` returns to the editor.
- Starting a lesson opens code and instructions side by side on wide screens. At
  narrow widths the reading float takes focus and has explicit close controls.
- The lesson pane opens on the challenge. Use `1`–`5` to show the concept,
  worked example, active-recall questions or strategy without hiding the code.
- Lesson actions use buffer-local mappings, so normal editing keys are untouched
  in source buffers.
- Tests never start while modified exercise buffers are unresolved. Completion
  does not steal code focus; diagnostics stay in a reusable bottom pane on wide
  screens and `:ForjaResult` reopens the latest result.
- Transfer practice uses a separate exercise workspace and records separate
  evidence. It cannot unlock the curriculum lesson.
- Exam Mode starts from a clean starter, hides study materials, and blocks Forja
  hints, tutor calls, guided recall, navigation, and solution disclosure. It
  does not claim to control applications or tools outside the plugin.
- `:ForjaHistory` reopens saved recall answers and practice copies; reopening an
  old copy never counts as fresh independent evidence.
- `:ForjaLang` opens the language/track picker. `:ForjaSettings` configures the
  tutor without exposing the API key in the panel.

## Verification and remaining check

`bash tests/run.sh` passed on Neovim 0.12.6 with Cargo available. It runs the
headless Neovim workflow, progress-session, UX, and runner regression suites,
then authentic offline Cargo checks for the five lesson solutions plus five
transfer solutions. The UI suite exercises 80x24 and 120x40 layouts, transitions
between float and split on resize, and warning-free compilation of all ten
starters.

The implementation has not been visually inspected inside the user's actual
LazyVim colorscheme or terminal. A keyboard-only walkthrough remains useful to
confirm local `winbar` rendering and that the configured terminal font leaves
enough code width beside the lesson pane. Headless tests cover supported sizes;
they cannot verify terminal font rendering.
