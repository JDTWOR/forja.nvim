# Forja usability audit and remediation record

Date: 2026-11-05

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
| U07 | P1 | Result views replaced lessons and asynchronous completion could interrupt editing. | Results are cached separately, open only on request, and completion reports a short notification. | Test verifies focus remains in the learner buffer and closing results preserves instructions. |
| U08 | P1 | Navigation could persist a new lesson before opening it and risked hiding modified code. | Progress is saved only after the target buffer opens. Navigation refuses to proceed while any buffer in the current exercise workspace is modified. | Regression test attempts navigation from the lesson pane with a dirty code buffer and verifies the lesson and file remain current. |
| U09 | P1 | Infrastructure failures could look like incorrect learner answers. | Cargo missing, compile errors, failed assertions, timeouts, cancellation, and process startup errors receive distinct diagnostics. Missing Cargo is not counted as a learner attempt. | Integration test removes Cargo from `PATH`, checks guidance, and confirms attempt history does not change. Runner tests cover timeout and cancellation. |
| U10 | P1 | Actions were difficult to discover and appeared at the bottom of a long lesson. | A top-of-lesson action line and window-local mappings expose close, visible tests, assessment, recall, hints, results, and transfer practice. | Tests cover dashboard and lesson action mappings; README documents the keyboard walkthrough. |
| U11 | P2 | Navigation mixed languages and exposed raw concept IDs/workspace paths. | Learner-facing navigation and feedback use Spanish; concept IDs map to readable labels; lesson text no longer prints workspace paths. Rust identifiers and compiler messages remain in English. | Source review and visible lesson/dashboard assertions. |
| U12 | P2 | Recall questions had no way to capture retrieval. | `:ForjaRecall` and dashboard `a` collect answers and save them as ungraded evidence, then ask the learner to compare with the explanation. | Command test verifies answer capture and separate recall history. |
| U13 | P2 | `:ForjaPractice` repeated the whole base project. | Every Rust lesson now has a distinct transfer crate with its own starter, visible tests, hidden assessment, reference solution, approval, and progress history. Transfer success does not unlock the base lesson. | Transfer integration test passes a dedicated assessment and checks the base attempt/completion records stay unchanged; all ten reference solutions are tested. |
| U14 | P1 | Prior checks covered registration and cleanup, not reading/editing behavior. | Regression coverage now exercises focus, split/float choice, wrapping, resize, close/reopen, dirty navigation, stale-buffer protection, asynchronous result focus, Exam Mode, recall, and transfer evidence. | `bash tests/run.sh` passes. |
| U15 | P2 | Starter `todo!()` implementations left every parameter unused, producing Rust warnings before the learner changed the code. | TODO messages now reference their inputs for diagnostic context. This removes starter-only warnings while normal compiler warnings remain visible after implementation. | `tests/verify_solutions.py` runs `cargo check --offline` on all ten starters and fails if it finds any warning. |

## Interaction contract now implemented

- `:Forja` opens a focused dashboard; `q` or `<Esc>` returns to the editor.
- Starting a lesson opens code and instructions side by side on wide screens. At
  narrow widths the reading float takes focus and has explicit close controls.
- Lesson actions use buffer-local mappings, so normal editing keys are untouched
  in source buffers.
- Tests never start while modified exercise buffers are unresolved. Completion
  does not steal focus; `:ForjaResult` opens the latest diagnostic on demand.
- Transfer practice uses a separate exercise workspace and records separate
  evidence. It cannot unlock the curriculum lesson.
- Exam Mode blocks Forja hints, tutor calls, and solution disclosure. It does
  not claim to control applications or tools outside the plugin.

## Verification and remaining check

`bash tests/run.sh` passed on Neovim 0.12.6 with Cargo available. It runs the
headless Neovim workflow suite, timeout/cancellation checks, and authentic
offline Cargo tests for the five lesson solutions plus five transfer solutions.
The UI suite exercises 80x24 and 120x40 layouts, transitions between float and
split on resize, and warning-free compilation of all ten starters.

The implementation has not been visually inspected inside the user's actual
LazyVim colorscheme or terminal. The remaining release check is a keyboard-only
walkthrough in that environment, especially to confirm local `winbar` rendering
and that the configured terminal font leaves enough code width beside the lesson
pane. No functional test currently indicates a blocker.
