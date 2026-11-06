# Curriculum and exercise authoring

Forja separates curriculum text from its engine. Add a track using JSON and
static exercise projects; do not add executable Lua curriculum configuration.

## Track layout

```text
courses/<language>/foundations.json
courses/<language>/exercises/<exercise-id>/
  exercise.json
  starter/                 # language-specific source and public tests
  assessment.*             # staged only into a temporary assessment copy
  solution.*               # revealed only after explicit abandonment
```

The loader discovers `courses/*/foundations.json` and selects a reviewed runner
adapter from the exercise manifest.

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
`..` path components. Every `exercise.json` has `schema_version: 1`, the lesson
ID, a supported runner, a package slug, source and public-test paths, assessment
and solution filenames, and a timeout between 1 and 120 seconds. Current
runner IDs and starter layouts are:

| Language | Runner | Starter files | Manifest package |
| --- | --- | --- | --- |
| Rust | `cargo-test` | `Cargo.toml`, `src/lib.rs`, `tests/public.rs` | Cargo package name |
| Python | `python-unittest` | `solution.py`, `tests/test_public.py` | module name `solution` |
| Java | `java-main` | `Solution.java`, `PublicTests.java` | stable manifest slug; default Java package |
| Go | `go-test` | `go.mod`, `solution.go`, `solution_test.go` | Go package `exercise` |

## Exercise quality and safety

- Write learner explanations in Spanish and keep identifiers, programming
  terminology, and compiler messages in their original English names.
- Give every task a learning objective, explicit constraints, examples, and
  boundary cases.
- A transfer variation has a dedicated project under `variation_dir` with its
  own visible tests, hidden assessment, and reference solution. Its progress is
  recorded separately and does not unlock the base curriculum.
- A variation must change what the learner reasons about, not just names.
- Keep public tests in the starter so learners can inspect and run them with
  `:ForjaRun`. Put assessment tests and the reference solution beside
  `exercise.json`; `:ForjaTest` stages only the assessment into a bounded,
  temporary copy. The reference solution is not copied into the normal
  workspace and is shown only after `:ForjaAbandon`.
- Prefer standard-library-only exercises. Rust uses `cargo test --offline`,
  Python uses `unittest`, Java compiles with `javac` and runs assertions with
  `java -ea`, and Go runs `go test` with module downloads disabled.
- Never put shell commands, Lua callbacks, or arbitrary runner arguments in a
  curriculum manifest. A new execution backend requires reviewed engine code.
- Do not assume hidden tests are inaccessible to the local machine owner.

Verify content before accepting it:

```sh
bash tests/run.sh
```

The curriculum loader delegates starter validation to its reviewed adapter.
Run `bash tests/run.sh`: each language verifier checks that a starter fails and
its reference solution passes both public and assessment tests. This does not
prove assessment fairness; review the tests and requirements too. Runtime
assessment copies are bounded to 2000 filesystem entries and 16 MiB.

## Adding a language

Keep language-specific runner behavior behind a reviewed adapter that returns
argument arrays, never shell strings. Reuse concepts and progress evidence where
appropriate, but do not assume a Rust implementation proves mastery of an
equivalent Java, Python, Go, or framework implementation. Diagnostic
assessments can establish transfer separately. New runners require adapter
code, manifest validation, and tests; the curriculum and progress contracts
remain language-neutral.
