# GrowWeird — Testing

This document owns test execution instructions. Architecture requirements remain authoritative in [`ARCHITECTURE.md`](ARCHITECTURE.md).

## Required checks

Before merging gameplay or architecture changes:

1. Run the repository line-limit check.
2. Run headless domain tests with the project Godot version.
3. Open the smoke screen when presentation/application wiring changed.
4. Confirm save/load still works when the save schema changed.

## Line-limit check

```bash
python3 scripts/check_line_limits.py
```

GitHub Actions runs this check automatically. Project-owned authored text files must remain at or below 350 lines.

## Headless domain tests

With Godot available on `PATH`:

```bash
godot --headless --path . --script res://tests/run_domain_tests.gd
```

The current runner verifies these core invariants:

- a seed genome snapshot does not change when its parent mutates later;
- fruit from a grafted branch is marked hybrid and contains host + donor traits;
- a fertilizer event contains three unique choices;
- pruning, planting a cutting and grafting respect branch-slot/inheritance rules;
- save mapping round-trips fertilizer offers, inventory stacks and cutting genomes.

Add a regression test here whenever a domain invariant is fixed or introduced.

## Smoke screen

Run the project normally in Godot. The temporary smoke screen is for architecture verification, not final game UX.

Current smoke paths include:

- water/spray/light/window controls;
- timed fertilizer offers and paid skip;
- pruning `left`, `center`, or `right`;
- cutting inventory creation;
- planting the first cutting into Pot 2;
- grafting the first cutting into the first free branch slot.

## Save schema

Any change to persisted fields must:

- increment `GameState.SCHEMA_VERSION` when compatibility changes;
- add a sequential migration in `SaveMigrator`;
- keep old migrations intact;
- round-trip all new state through the appropriate mapper.

Genetic item serialization belongs to `SaveItemMapper`; Game/Pot/Plant/Branch serialization belongs to `SaveMapper`.
