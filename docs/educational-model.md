# Educational model

Forja uses deterministic exercises as the evidence source. A lesson being read
or opened is not completion. A passing visible test is useful feedback but does
not unlock the next lesson; the assessment command must pass.

## Lesson cycle

Each lesson in the Rust, Python, Java and Go foundations tracks includes an
objective, Spanish explanation, compact code example, retrieval questions,
guided strategy, implementation requirements and a transfer prompt. Python
starts with four short lessons that teach file execution and `print`, numeric
values and expressions, named values and assignment, then function definition,
calling and `return`. Existing Python lessons depend on that sequence so a
track with old progress does not accidentally jump past the new foundations.
Beginner lessons display the objective and three staged explanation steps
before the exercise. Every
lesson also has a separate runnable transfer project. Each base and transfer
exercise has visible tests, separately stored assessment tests and a verified
reference solution. The learner writes code in a persistent workspace.

The workflow is:

1. In the Python beginner sequence, first read the lesson pane and inspect the
   example. The pane is placed to the left of the code on wide terminals. Then
   switch to `1 Reto` and attempt the implementation.
2. Use `:ForjaRecall` to answer the short questions before rereading; answers
   are saved as practice evidence and are not automatically graded.
3. Inspect the requirements and implement the main task.
4. Run `:ForjaRun` for visible compiler/test feedback.
5. Run `:ForjaTest` for the hidden assessment target and next-lesson gate.
6. Review assistance and result history with `:ForjaProgress`.
7. Revisit a completed exercise using `:ForjaReview`, which creates a clean
   starter copy and hides the worked explanation, example, and strategy.
8. Use `:ForjaPractice` to implement a dedicated transfer problem in a separate
   workspace. Its test and assistance evidence is independent from the base
   lesson and does not unlock curriculum progress.
9. Use `:ForjaHistory` to reopen saved recall answers or resume an earlier
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
