# Curriculum and exercise authoring

Forja separates curriculum text from its engine. Add a track using JSON and
static exercise projects; do not add executable Lua curriculum configuration.

## Track layout

```text
courses/<language>/<track>.json
courses/<language>/exercises/<exercise-id>/
  exercise.json
  starter/
    Cargo.toml
    src/lib.rs
    tests/public.rs
  assessment.rs
  solution.rs
  transfer/
    exercise.json
    starter/
      Cargo.toml
      src/lib.rs
      tests/public.rs
    assessment.rs
    solution.rs
```

The current loader discovers `courses/*/foundations.json`. New built-in track
files should use that filename until discovery is generalized.

## Curriculum schema version 1

The top-level object includes:

```json
{
  "schema_version": 1,
  "id": "rust-foundations",
  "version": "1.0.0",
  "title": "Fundamentos de Rust",
  "description": "...",
  "language": "rust",
  "modules": [{ "id": "rust-basics", "title": "Fundamentos" }],
  "lessons": []
}
```

Each lesson has a stable `id`, `module`, Spanish `title`, `objective`, stable
concept tags, a list of prerequisite lesson IDs, `explanation`, `example`,
retrieval `questions`, `guided` strategy, `requirements`, `variation`, six
base `hints`, optional six `variation_hints` (the base ladder is reused when
omitted), and an `exercise` reference. IDs accept lowercase letters,
numbers, dots, underscores and hyphens. Prefix IDs by language or domain to
avoid collisions as tracks grow. A prerequisite graph must be acyclic.

Example exercise reference:

```json
"exercise": {
  "project_dir": "exercises/variables-mutability",
  "starter_dir": "starter",
  "assessment_file": "assessment.rs",
  "solution_file": "solution.rs",
  "variation_dir": "transfer"
}
```

All paths must be relative to the course directory and cannot contain `.` or
`..` path components. The `exercise.json` file has `schema_version: 1`, matching
exercise ID, supported runner `cargo-test`, Cargo package name, assessment and
solution filenames, and a timeout between 1 and 120 seconds.

## Exercise quality and safety

- Write the Spanish explanation and keep Rust identifiers/compiler messages in
  English.
- Give every task a learning objective, explicit constraints, examples, and
  boundary cases.
- A transfer variation has a dedicated project under `variation_dir` with its
  own visible tests, hidden assessment, and reference solution. Its progress is
  recorded separately and does not unlock the base curriculum.
- A variation must change what the learner reasons about, not just names.
- Keep visible tests in `starter/tests/public.rs` so learners can inspect and run
  them. Put assessment tests in `assessment.rs`; the runner stages that file only
  in a temporary project copy.
- Keep the reference solution in `solution.rs`. It is never copied into the
  ordinary workspace and is shown only after `:ForjaAbandon`.
- Use a dependency-free Cargo package where practical. Tests run with
  `cargo test --offline`.
- Never put shell commands, Lua callbacks, or arbitrary runner arguments in a
  curriculum manifest. A new execution backend requires reviewed engine code.
- Do not assume hidden tests are inaccessible to the local machine owner.

Verify content before accepting it:

```sh
bash tests/run.sh
```

`tests/verify_solutions.py` copies each starter to a temporary directory, swaps
in its reference solution, stages assessment tests, and runs Cargo. This verifies
the solution but does not test assessment fairness; review tests and rubrics too.

## Adding a language

Keep language-specific runner behavior behind a runner adapter. Reuse the
curriculum concepts and progress contract where appropriate; do not assume a
Rust implementation proves mastery of an equivalent Java/Python/framework
implementation. Diagnostic assessments can establish transfer separately. The
current first phase supports only `cargo-test`; adding another runner changes
engine code and tests, not the curriculum JSON interface.
