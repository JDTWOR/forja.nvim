# Educational model

Forja uses deterministic exercises as the evidence source. A lesson being read
or opened is not completion. A passing visible test is useful feedback but does
not unlock the next lesson; the assessment command must pass.

## Lesson cycle

Each of the first five lessons includes an objective, Spanish explanation,
compact code example, retrieval questions, guided strategy, implementation
requirements, and a transfer variation with an additional executable contract.
Each Rust exercise includes visible
examples, separately stored assessment assertions, and a verified reference
solution. The learner writes code in a persistent workspace.

The workflow is:

1. Recall the concept and answer the short questions.
2. Inspect the requirements and implement both the main task and variation.
3. Run `:ForjaRun` for visible compiler/test feedback.
4. Run `:ForjaTest` for the assessment and next-lesson gate.
5. Review assistance and result history with `:ForjaProgress`.
6. Revisit a completed exercise using `:ForjaReview`, which creates a clean
   starter copy for retrieval practice.

## Assistance and outcomes

Hints are ordered from requirement clarification toward a conceptual example.
Lifetime totals remain visible, while each test attempt records assistance since
the prior test; this lets a later unaided assessment establish independent
evidence. `:ForjaTutor` is Socratic; in the default offline configuration it
uses a fixed mock question. A configured provider is optional and remains
advisory. Hints and tutor responses are recorded separately from correctness.

Passing an assessment after assistance is recorded as `reproduced`. A passing
assessment with no hints or tutor use is recorded as
`independently_demonstrated`. Mistakes remain in attempt history and do not
reduce a score. A later unaided assessment can still establish independent
evidence.

Exam Mode disables Forja hints and tutor requests. It does not block external
editors, shell commands, browser searches, or other operating-system tools.

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
