# AI agent working procedure

These instructions apply throughout this repository. They describe the user's
required collaboration workflow; do not weaken or rewrite these rules without
the user's approval.

## Communication and context

- Start every user-facing answer or progress update with `cesar`.
- Write documentation in English, understandable to the owner, AI agents, and
  potential contributors. Explain concrete behavior using plain language.
- Read `README.md`, `ARCHITECTURE.md`, and the relevant pages under `docs/` before
  planning changes. Inspect the affected implementation; documentation can lag
  behind source, so report discrepancies rather than assuming intended behavior.
- Exclude dependencies, caches, and generated output from project scans unless a
  specific investigation requires them. Preserve unrelated user changes.

## Approval before editing

1. Inspect source, documentation, and repository status without editing files.
2. Ask questions if requirements or permissions remain ambiguous.
3. Present a detailed plan covering the requested outcome, affected files,
   implementation steps, data/architecture/dependency implications, documentation
   updates, and verification. Identify material risks or behavior changes.
4. Wait for the user to approve the plan before modifying files or running
   commands that intentionally change project files.
5. Implement the approved scope autonomously. Do not ask again before each file
   edit or routine implementation decision already covered by approval.
6. If a material scope change is needed, explain it and obtain approval for a
   revised plan before performing that additional work.

Read-only inspection is allowed before approval. Dependencies may be added when
needed within the approved plan; explain their purpose and keep manifests and
lockfiles consistent. Do not add unrelated refactors or features.

## Git belongs to the user

Read-only inspection such as `git status`, `git diff`, `git log`, `git show`, and
`git ls-files` is allowed. All operations that change Git state are reserved for
the user. Do not stage, commit, amend, create/switch/delete branches, create
worktrees, stash, reset, restore/checkout files, clean, merge, rebase, cherry-pick,
tag, fetch, pull, push, or change Git configuration. Do not create or modify pull
requests. Do not edit `.git` directly or use another tool to bypass this rule.

Leave approved file changes in the working tree for the user to review and commit.

## Implementation principles

- Preserve offline operation and the personal Android scope. Do not introduce
  remote services, accounts, telemetry, or sync as incidental implementation work.
- Keep persistence in repositories, database lifecycle/migrations in
  `AppDatabase`, coordination in `AppController`, and interface code in features.
  If an approved change alters those boundaries, update the architecture docs.
- Preserve independent scheduled workout snapshots and existing training history.
  Use transactions for related writes and explicit versioned migrations for
  schema changes, covering both fresh creation and upgrades.
- Never clear user data, reset a database, or uninstall the app to bypass a
  migration issue. Raise any necessary destructive transformation in the plan.
- Follow local Dart/Flutter conventions and format affected Dart files without
  reformatting unrelated code. Avoid modifying generated files or dependencies.

## Documentation is part of every change

Update the relevant documentation whenever behavior, architecture, setup, or
process changes. Evaluate documentation impact even for small changes; do not
leave known discrepancies introduced by your work.

- `README.md`: app overview, supported features, prerequisites, startup, APK build,
  and Wi-Fi debugging. Keep product vision and future gamification plans out.
- `ARCHITECTURE.md`: current implementation only, including responsibilities,
  state flow, persistence, and platform integration.
- `docs/development.md`: workflow and verification commands.
- `docs/database.md`: schema, mappings, transactions, migrations, and data effects.
- `docs/behavior.md`: user-visible rules, calculations, and current limitations.
- `AGENTS.md`: user-approved changes to agent procedure.

Use relative links between documentation files. Keep detailed information in its
owning page and link to it rather than duplicating it throughout the docs.

## Verification and handoff

- Always run `flutter analyze` after changes, including documentation-only tasks.
  Report its actual result. Fix issues introduced by the approved work. If it
  cannot run, explain the blocker; do not claim it passed or silently omit it.
- There are currently no automated tests. Skip nonexistent tests; do not create a
  test suite merely to satisfy a checklist. If tests are introduced in an approved
  task, update the documented validation procedure accordingly.
- Use relevant manual verification for behavior changes when a device is
  available. Clearly distinguish analysis, build checks, and device verification.
- Review the final diff and documentation links. Confirm changes match the
  approved scope and do not overwrite unrelated work.
- Finish with a concise report of what changed, documentation updated, checks
  performed, and any remaining limitations. Do not commit the result.
