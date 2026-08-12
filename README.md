# GrowWeird

GrowWeird is a Godot game about growing, pruning, grafting and endlessly mutating strange plants.

## Documents

- [`GAME_DESIGN.md`](GAME_DESIGN.md) — gameplay rules, UX, progression and MVP scope.
- [`ARCHITECTURE.md`](ARCHITECTURE.md) — code boundaries, ownership rules and technical constraints.

Those two documents intentionally cover different concerns. Gameplay rules belong in the design document; implementation ownership belongs in the architecture document.

## Project principles

- One source of truth for every gameplay rule.
- Data-driven species, fertilizer and mutation definitions.
- Runtime state is separate from authored content.
- Presentation code never owns gameplay rules.
- Platform integrations are adapters, not domain dependencies.
- Every authored text/code file stays under 350 lines.

## Run

Open the repository with Godot 4.6+ and run the project. The initial scene is a foundation/smoke screen while gameplay presentation is built on top of the domain model.

## Current foundation scope

The initial codebase provides:

- versioned game state;
- pot and three-branch plant runtime state;
- species/fertilizer/mutation definitions;
- content registry;
- care/comfort evaluation;
- real-time plant simulation;
- repeatable mutation resolution;
- save/load boundary;
- application-level commands;
- line-limit validation in CI.
