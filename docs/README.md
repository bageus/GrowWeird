# GrowWeird Documentation

This directory is the single home for project documentation and development rules.

## Documentation policy

- Store all project documentation under `docs/`.
- Store architecture rules, coding rules, design rules, workflows and technical decisions under `docs/`.
- Keep the repository root focused on entry-point files such as `README.md`, project configuration and source directories.
- Do not create new project documentation files in the repository root.
- Every project-owned text file, including documentation, must stay under 350 lines.
- When a document grows too large, split it by responsibility and link the new documents from this index.
- Avoid duplicating rules between documents. Each rule must have one authoritative document.

## Current documents

- [`GAME_DESIGN.md`](GAME_DESIGN.md) — gameplay, UX, progression, economy and content rules.
- [`ARCHITECTURE.md`](ARCHITECTURE.md) — code boundaries, ownership, persistence, platform and technical rules.
- [`TESTING.md`](TESTING.md) — test execution, smoke checks and save-schema verification workflow.

## Source-of-truth rule

Gameplay intent belongs in `GAME_DESIGN.md`.
Technical ownership and implementation constraints belong in `ARCHITECTURE.md`.
Test execution instructions belong in `TESTING.md`.
Future specialized rules should be extracted into a dedicated file in this directory only when they have a distinct responsibility and a clear source-of-truth owner.
