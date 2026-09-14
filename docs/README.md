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
- [`ITEM_BALANCE.md`](ITEM_BALANCE.md) — canonical item economy, mutations, nutrition, fertilizer prices and journal discovery rules.
- [`ARCHITECTURE.md`](ARCHITECTURE.md) — code boundaries, ownership, persistence, platform and technical rules.
- [`TESTING.md`](TESTING.md) — test execution, smoke checks and save-schema verification workflow.
- [`YANDEX_GAMES.md`](YANDEX_GAMES.md) — Yandex SDK bootstrap, cloud saves, lifecycle and release verification.

## Source-of-truth rule

Gameplay intent belongs in `GAME_DESIGN.md`. Detailed item/economy values and nutrition rules belong in `ITEM_BALANCE.md` and the runtime data file it references.
Technical ownership and implementation constraints belong in `ARCHITECTURE.md`.
Test execution instructions belong in `TESTING.md`.
Yandex-specific integration and release behavior belongs in `YANDEX_GAMES.md`.
Future specialized rules should be extracted into a dedicated file in this directory only when they have a distinct responsibility and a clear source-of-truth owner.
