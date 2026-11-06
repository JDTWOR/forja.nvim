# Upstream research notes

Reviewed on 2026-11-05. The repository snapshots below were shallow-cloned from
their default branches on that date; short commit IDs identify the inspected
source. No source code, prompts, exercises, or lesson text from these projects is
included in Forja. This is a design review, not a security audit.

## `qtsone/learning` — `db9a13b`

Source: [repository](https://github.com/qtsone/learning/tree/db9a13b), [design document](https://github.com/qtsone/learning/blob/db9a13b/docs/DESIGN.md), [license](https://github.com/qtsone/learning/blob/db9a13b/LICENSE).

1. **Relevant features:** pre-authored lessons and exercises, tested solutions,
   progress gates, safe curriculum synchronization, custom tutor guidance.
2. **Architecture:** a deterministic Python standard-library curriculum/state
   engine is separated from a Claude Code skill that supplies adaptive dialogue.
   A registry describes stable IDs and track composition; content lives in
   language/shared pools. State is schema-versioned and engine-owned.
3. **Dependencies and compatibility:** the curriculum engine itself has no
   runtime dependencies beyond Python 3; the conversational layer targets Claude
   Code. The inspected curriculum is Go-first and CLI/repository based, not a
   Neovim plugin.
4. **Conceptual reuse:** pre-authored versioned content; stable identifiers;
   deterministic gates; explicit ownership of progress; never overwriting learner
   edits during content updates; one deterministic boundary around AI behavior.
5. **Independent implementation:** Forja uses JSON curriculum manifests, Lua
   graph validation, Neovim buffers and local Rust workspaces. Its course text and
   exercises are newly authored.
6. **Integration/licensing risks:** the project is AGPL-3.0 with an additional
   learner exception. Do not copy its code or course content into this MIT
   project without a deliberate licensing review. The Claude-specific skill is
   not a portable provider contract.

## `kawre/leetcode.nvim` — `4e8b368`

Source: [repository](https://github.com/kawre/leetcode.nvim/tree/4e8b368), [README](https://github.com/kawre/leetcode.nvim/blob/4e8b368/README.md), [license](https://github.com/kawre/leetcode.nvim/blob/4e8b368/LICENSE).

1. **Relevant features:** in-editor problem browsing, descriptions, code
   templates, test-case UI, local submission/test workflow, caching.
2. **Architecture:** Lua modules separate API/data handling, parsing and
   normalization, question models, and UI split/popup components. It supplies a
   vertical-slice example of a problem workflow inside Neovim.
3. **Dependencies and compatibility:** README says Neovim 0.9+ and lists
   `plenary.nvim` and `nui.nvim`; Telescope is an optional picker. The project
   communicates with the LeetCode service, so it is not an offline curriculum.
4. **Conceptual reuse:** keep exercise selection, description, code workspace and
   test feedback close together; represent exercises independently from the
   display layer.
5. **Independent implementation:** Forja uses native buffers/windows, bundled
   declarative course files, and local Cargo tests; it has no LeetCode API or
   third-party UI dependency.
6. **Integration risks:** upstream service/session behavior can change, and
   network-backed problem APIs are not suitable as a required dependency for
   local-first lessons.

## `olimorris/codecompanion.nvim` — `9cc3c13`

Source: [repository](https://github.com/olimorris/codecompanion.nvim/tree/9cc3c13), [adapter resolver](https://github.com/olimorris/codecompanion.nvim/blob/9cc3c13/lua/codecompanion/adapters/init.lua), [README](https://github.com/olimorris/codecompanion.nvim/blob/9cc3c13/README.md), [license](https://github.com/olimorris/codecompanion.nvim/blob/9cc3c13/LICENSE).

1. **Relevant features:** multi-provider LLM requests, chat/actions, HTTP
   adapters, ACP agents, structured extension points and test coverage.
2. **Architecture:** adapters resolve by transport (HTTP or ACP); provider
   specifics are kept behind adapter methods. The inspected source has explicit
   adapter resolution and provider configuration rather than baking one model
   into UI code.
3. **Dependencies and compatibility:** the current checkout's plugin entry point
   requires Neovim 0.12+ and its README lists `plenary.nvim`. Adapters may also
   depend on external CLIs or credentials.
4. **Conceptual reuse:** provider boundary, request cancellation, explicit
   provider configuration and testing malformed/error responses.
5. **Independent implementation:** Forja defines a much smaller callback
   interface for advisory tutoring and will keep AI output away from exercise
   execution or file-writing tools.
6. **Integration risks:** CodeCompanion is an AI coding/agent integration, not an
   educational policy engine. ACP agents can have capabilities outside the
   Socratic tutor's intended scope. Any future adapter must disable tools and
   respect Exam Mode.

## `avante-corp/avante.nvim` — `2afffaf`

Source: [repository](https://github.com/avante-corp/avante.nvim/tree/2afffaf), [README](https://github.com/avante-corp/avante.nvim/blob/2afffaf/README.md), [provider configuration](https://github.com/avante-corp/avante.nvim/tree/2afffaf/lua/avante/providers), [Cargo workspace](https://github.com/avante-corp/avante.nvim/blob/2afffaf/Cargo.toml), [license](https://github.com/avante-corp/avante.nvim/blob/2afffaf/LICENSE).

1. **Relevant features:** multiple hosted/local providers, editing UI, tool
   integration, repository context, ACP sessions and cancellation.
2. **Architecture:** Lua UI/provider modules are paired with Rust crates for
   selected native functionality. Provider, UI and agent/tool features are
   independently configured.
3. **Dependencies and compatibility:** the current plugin gate and README badge
   require Neovim 0.12+. The source build uses Cargo and includes additional
   Neovim/plugin dependencies such as `plenary.nvim` and `nui.nvim`. Its README
   also contains an older compatibility sentence saying 0.11, so the current
   runtime gate is the safer reading.
4. **Conceptual reuse:** keep provider details behind an adapter; expose
   cancellation; include only selected context.
5. **Independent implementation:** Forja does not embed its agent UI, Rust
   native module or provider code. The initial tutor context contains objectives
   and assistance history, not repository files.
6. **Integration risks:** agent tools and file editing can solve the learner's
   active task. That behavior conflicts with Forja's default educational policy;
   any future use must be advisory, scoped, and disabled in Exam Mode.

## `nvim-neotest/neotest` — `27bf921`

Source: [repository](https://github.com/nvim-neotest/neotest/tree/27bf921), [architecture and public API](https://github.com/nvim-neotest/neotest/blob/27bf921/lua/neotest/init.lua), [README](https://github.com/nvim-neotest/neotest/blob/27bf921/README.md), [MIT license](https://github.com/nvim-neotest/neotest/blob/27bf921/LICENCE.md).

1. **Relevant features:** language-specific test adapters, test discovery,
   subprocess strategies, result state, diagnostics and summary consumers.
2. **Architecture:** adapters discover/build/parse language tests; a client runs
   tests and records events; consumers present results. The core requires an
   adapter for each test framework.
3. **Dependencies and compatibility:** the README requires `nvim-nio`; language
   adapters can add Tree-sitter/runtime dependencies. The inspected README does
   not state one definitive Neovim minimum. Forja's language adapters use the
   built-in `vim.system` API and have no Neotest dependency.
4. **Conceptual reuse:** isolate runner behavior from lesson logic; use async
   process results as evidence; keep language-specific test protocols in
   adapters.
5. **Independent implementation:** Forja keeps a small runner coordinator and
   reviewed Rust, Python, Java, and Go adapters. They use argument arrays and
   own bounded temporary assessment copies; Neotest is not required.
6. **Integration risks:** adopting Neotest would add a required dependency and
   adapter maintenance before Forja needs multi-runner support. Its adapters and
   parser outputs must not be treated as authoritative mastery by themselves.

## `Yeijon/mnemonic.nvim` — `58dd954`

Source: [repository](https://github.com/Yeijon/mnemonic.nvim/tree/58dd954), [README and stated license](https://github.com/Yeijon/mnemonic.nvim/blob/58dd954/README.md), [FSRS module](https://github.com/Yeijon/mnemonic.nvim/blob/58dd954/lua/mnemonic/fsrs.lua).

1. **Relevant features:** in-editor question/answer cards, topic links, local JSON
   persistence, spaced recall and an FSRS-inspired scheduler.
2. **Architecture:** configuration, card database, UI and FSRS calculations are
   separate Lua modules. The README says it implements a simplified FSRS v4 model
   and describes card state such as stability, difficulty and due time.
3. **Dependencies and compatibility:** README lists Neovim 0.9+, Telescope for
   backlink selection, and Dressing as recommended. It states MIT in the README;
   the inspected root has no standalone `LICENSE` file.
4. **Conceptual reuse:** conceptual recall is a different activity from coding
   drills; keep review history and due work local; separate scheduler math from
   card UI.
5. **Independent implementation:** Phase 1 does not schedule reviews. Forja will
   select a maintained FSRS implementation and validate version/parameters
   before adopting one; it will not present the README's simplified interval
   equation as validated FSRS.
6. **Integration risks:** FSRS version/weights and review ratings matter. A
   hand-written approximation would create misleading due dates. Coding
   reimplementation tasks also need a scheduler policy distinct from short recall
   cards.

## `open-spaced-repetition/awesome-fsrs` — `1b1eade`

Source: [repository](https://github.com/open-spaced-repetition/awesome-fsrs/tree/1b1eade), [implementation/resource catalog](https://github.com/open-spaced-repetition/awesome-fsrs/blob/1b1eade/README.md), [CC0 license](https://github.com/open-spaced-repetition/awesome-fsrs/blob/1b1eade/LICENSE).

1. **Relevant features:** curated implementations, research and products that
   use FSRS, with implementation/version references.
2. **Architecture:** it is a catalog, not an executable scheduler or a single
   canonical implementation.
3. **Dependencies and compatibility:** none for the catalog. Its entries span
   language implementations and different FSRS generations; the README observed
   FSRS-5 and FSRS-6 implementations in its current list.
4. **Conceptual reuse:** choose a maintained implementation with an explicit
   algorithm version, known test vectors, documented parameters and an adapter
   boundary.
5. **Independent implementation:** Forja has not copied an algorithm from the
   list and will pin neither parameters nor version until Phase 3 chooses and
   validates an implementation.
6. **Integration risks:** product-level claims in a curated README do not prove
   that a particular scheduler implementation is compatible with Forja's review
   events. Version drift must be tested.

## `szymonwilczek/vim-be-better` — `60e0214`

Source: [repository](https://github.com/szymonwilczek/vim-be-better/tree/60e0214), [README](https://github.com/szymonwilczek/vim-be-better/blob/60e0214/README.md), [game runner](https://github.com/szymonwilczek/vim-be-better/blob/60e0214/lua/vim-be-better/game-runner.lua).

1. **Relevant features:** small keyboard-driven training rounds, challenge
   families, focused buffers/windows, statistics and restartable games.
2. **Architecture:** Lua owns plugin setup, menus, windows, statistics and game
   execution; some game definitions are TypeScript source under `src/game`.
3. **Dependencies and compatibility:** README says Neovim 0.8+. The inspected
   root has no `LICENSE` file even though some source comments mention MIT; no
   code is reused.
4. **Conceptual reuse:** practice should be a short action in the editor, with a
   clear objective and immediate feedback rather than a passive dashboard.
5. **Independent implementation:** Forja lessons use declarative per-language
   exercise projects with explicit contracts and deterministic tests, not
   movement mini-games.
6. **Integration risks:** a missing root license makes code reuse ambiguous; its
   game/statistics model does not prove programming-language mastery.

## `neovim/neovim` and its documentation — `893d90f`

Source: [repository](https://github.com/neovim/neovim/tree/893d90f), [Lua guide](https://neovim.io/doc/user/lua.html), [API documentation](https://neovim.io/doc/user/api.html), [license](https://github.com/neovim/neovim/blob/893d90f/LICENSE.txt).

1. **Relevant features:** Lua modules, API-created commands, buffers/windows,
   notifications, user input, process execution and health reporting.
2. **Architecture:** the public API is the supported plugin boundary; runtime Lua
   libraries are available from `vim.*`, and native UI state is managed through
   API functions.
3. **Dependencies and compatibility:** Forja uses Lua APIs and `vim.system`,
   introduced in Neovim 0.10 ([0.10 release notes](https://neovim.io/doc/user/news-0.10.html));
   the current development environment is Neovim 0.12.6. `vim.system` takes an
   argument list and runs asynchronously.
4. **Conceptual reuse:** use `nvim_create_user_command`, native scratch buffers,
   floating windows and asynchronous process callbacks rather than an embedded
   web UI or shell command assembled from strings.
5. **Independent implementation:** Forja uses only documented public APIs and
   no Neovim source code.
6. **Integration risks:** APIs and plugin-manager docs can change. Compatibility
   is checked by `:ForjaHealth` and headless tests; older Neovim versions are not
   supported by this initial runner.

## Lazy.nvim and LazyVim integration

The current [lazy.nvim plugin spec](https://lazy.folke.io/spec) supports local
`dir` specs, a `main` module, `opts`, `cmd`, and `keys`; its docs recommend `opts`
over custom `config` where possible. [LazyVim plugin docs](https://www.lazyvim.org/configuration/plugins)
say to add a spec under `lua/plugins/*.lua`. Forja provides a local `dir` spec
and declares commands for lazy loading. It does not need to add a global mapping.

## Resulting design choices

- Deterministic curriculum, validation, tests and progress are independent of AI.
- Exercises are reviewed files rather than generated at lesson-open time.
- Learner workspaces are created once and never overwritten by course updates.
- Assessment tests are copied to a temporary project for the run and removed
  afterward; this is separation from normal workspace browsing, not a security
  boundary against the machine owner.
- No FSRS algorithm is shipped in Phase 1.
- Provider adapters may explain and question, but do not receive filesystem or
  shell tools from Forja.
