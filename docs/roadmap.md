# Roadmap

## Phase 1 — complete in this repository

- Native dashboard and commands; Lazy.nvim setup.
- Validated JSON curriculum graph and twenty Spanish foundation lessons across
  Rust, Python, Java, and Go, backed by reviewed language runner adapters.
- Persistent learner workspaces, visible tests, isolated local assessment copy,
  verified reference solutions and progress gates; all twenty lessons have a
  separate executable transfer project.
- Tabbed lesson reader and a persistent bottom test-output pane on wide
  terminals, with first-run track selection instead of an implicit default.
- JSON progress persistence, backups, migrations, hints, local Exam Mode,
  cancellation, health checks, ungraded active-recall capture and dedicated
  transfer projects for every lesson in all four tracks. Clean review/exam sessions preserve
  assistance evidence, old workspaces are resumable but uncertified, and saved
  recall answers are available through `:ForjaHistory`.
- Mandatory hidden assessments, bounded staging, process-group cancellation,
  and one total deadline across the Rust, Python, Java, and Go execution backends.
- Headless domain/end-to-end tests and solution verification.

## Phase 2 — broader tutor behaviors

- Initial OpenAI Responses API adapter is implemented with mock-based protocol
  tests, a required environment key, disabled server-side response storage,
  request timeout/cancellation, context caps, usage accounting and safe errors.
- Add structured schemas for explanations, questions, hints and reviews.
- Add selectable Professor, Socratic, Coach, Debugging, Code Review, Interviewer
  and Reflection behaviors. Exam Mode remains offline and refuses AI fallback.
- The native `:ForjaLang` picker and `:ForjaSettings` panel provide readable
  track selection and masked, permission-restricted local API-key setup.

## Phase 3 — adaptive learning

- Select and validate a maintained FSRS implementation/version with official
  vectors before scheduling concept recall cards.
- Keep short recall cards distinct from coding reimplementation tasks.
- Store scheduled review events, diagnose repeated failures, identify weak
  concepts, and generate additional validated practice variations. Current
  transfer exercises are static, independently tested curriculum content.
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

1. Add structured tutor response types and selectable tutor modes behind the
   existing provider interface.
2. Choose a vetted FSRS library and write an adapter test suite before shipping
   scheduled reviews.
3. Add independent assessments for module projects and concept transfer.
