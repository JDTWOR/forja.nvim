# Educational model

Forja uses deterministic exercises as the evidence source. A lesson being read
or opened is not completion. A passing visible test is useful feedback but does
not unlock the next lesson; the assessment command must pass.

## Lesson cycle

Each of the first five lessons includes an objective, Spanish explanation,
compact code example, retrieval questions, guided strategy, implementation
requirements, and a transfer prompt. Rust includes separate runnable transfer
contracts; Python, Java, and Go currently use written variations pending
dedicated transfer workspaces. Every language exercise has visible tests,
separately stored assessment tests, and a verified reference solution. The
learner writes code in a persistent workspace.

The workflow is:

1. Use `:ForjaRecall` to answer the short questions before rereading; answers
   are saved as practice evidence and are not automatically graded.
2. Inspect the requirements and implement the main task.
3. Run `:ForjaRun` for visible compiler/test feedback.
4. Run `:ForjaTest` for the hidden assessment target and next-lesson gate.
5. Review assistance and result history with `:ForjaProgress`.
6. Revisit a completed exercise using `:ForjaReview`, which creates a clean
   starter copy and hides the worked explanation, example, and strategy.
7. Use `:ForjaPractice` to implement a dedicated Rust transfer problem in a
   separate workspace. Its test and assistance evidence is independent from the
   base lesson and does not unlock curriculum progress.
8. Use `:ForjaHistory` to reopen saved recall answers or resume an earlier
   review/transfer workspace without overwriting it.

## Assistance and outcomes

Hints are ordered from requirement clarification toward a conceptual example.
Lifetime totals and active-workspace exposure are recorded separately. Visible
tests, retries, Exam Mode counters, and reference-solution disclosure do not
erase assistance. A newly created clean retrieval or exam workspace starts a
separate evidence session; reopening an old workspace is explicitly marked
uncertified and cannot establish new independent evidence. `:ForjaTutor` is
Socratic; in the default offline configuration it uses a fixed mock question. A
configured provider is optional and remains advisory. Hints and tutor responses
are recorded separately from correctness.

Passing an assessment after assistance is recorded as `reproduced`. A passing
assessment from a fresh starter workspace with no hints, tutor use, or solution
disclosure is recorded as `independently_demonstrated`. Mistakes remain in
attempt history and do not reduce a score. Learners can establish new
independent evidence later through a clean retrieval or exam workspace.
Later assisted successes are recorded as the latest result without replacing a
stronger independent mastery record.

Exam Mode creates a fresh starter workspace and hides lesson explanations,
examples, guided strategies, hints, tutor requests, and guided recall. It does
not block external editors, shell commands, browser searches, or other
operating-system tools. A valid active exam workspace is restored after a
Neovim restart; an invalid or missing path terminates the exam explicitly.

## What Phase 1 does not claim

- There is no validated FSRS scheduler yet. `:ForjaReview` is explicit practice,
  not a due-date recommendation.
- The current mastery vocabulary is deliberately small: no evidence, reproduced,
  or independently demonstrated. It does not pretend that one test score proves
  a six-level competence model.
- Time, explanation quality, conceptual error taxonomies and transfer across
  unrelated domains are not yet scored.
- An assessment is repeatable on a local machine. A learner who reads the source
  can inspect the hidden tests and reference solution.

These items are in the roadmap; the plugin will not label them as measured
outcomes before their evidence and algorithms exist.
