# Roadmap

## Phase 1 — complete in this repository

- Native dashboard and commands; Lazy.nvim setup.
- Validated JSON curriculum graph and twenty Spanish foundation lessons across
  Rust, Python, Java, and Go, backed by reviewed language runner adapters.
- Persistent learner workspaces, visible tests, isolated local assessment copy,
  verified reference solutions and progress gates.
- JSON progress persistence, backups, migrations, hints, local Exam Mode,
  cancellation, health checks, ungraded active-recall capture and dedicated
  transfer projects for each Rust lesson. Clean review/exam sessions preserve
  assistance evidence, old workspaces are resumable but uncertified, and saved
  recall answers are available through `:ForjaHistory`.
- Mandatory hidden assessments, bounded staging, process-group cancellation,
  and one total deadline across the Rust, Python, Java, and Go execution backends.
- Headless domain/end-to-end tests and solution verification.

## Phase 2 — provider-backed tutor

- Add one first-party HTTP provider and a mock provider test suite.
- Structured schemas for explanations, questions, hints and reviews.
- Request timeout/cancellation, context limits, usage accounting and safe error
  reporting. Keep tools disabled and avoid learner file uploads by default.
- Add selectable Professor, Socratic, Coach, Debugging, Code Review, Interviewer
  and Reflection behaviors. Exam Mode remains offline and refuses AI fallback.

## Phase 3 — adaptive learning

- Select and validate a maintained FSRS implementation/version with official
  vectors before scheduling concept recall cards.
- Keep short recall cards distinct from coding reimplementation tasks.
- Store scheduled review events, diagnose repeated failures, identify weak
  concepts, and generate additional validated practice variations. The initial
  Rust transfer exercises are static, independently tested curriculum content.
- Track first attempt, hints, AI use, delayed recall and transfer evidence.

## Phase 4 — independent assessments

- Timed sessions, score reports, attempt history and a broader practical
  interview simulator.
- Projects with milestones and deterministic test/evaluation gates.
- Assess code quality and explanations separately; label subjective AI review as
  subjective.

## Phase 5 — broader curricula

- Additional language runners for PHP, JavaScript, and TypeScript; the initial
  Java, Python, and Go runners are implemented.
- Shared concept DAGs and framework-specific tracks for backend, databases,
  frontend, architecture, testing, security, performance and deployment.
- Diagnostic placement that requires deterministic prerequisite evidence.

## Next concrete tasks

1. Add a maintained AI HTTP adapter behind the current interface and test malformed
   JSON, missing credentials, timeouts and cancellation.
2. Choose a vetted FSRS library and write an adapter test suite before shipping
   scheduled reviews.
3. Add independent assessments for module projects and concept transfer.
4. Add runnable transfer projects to the Python, Java, and Go tracks without
   changing the curriculum/progress contract.
