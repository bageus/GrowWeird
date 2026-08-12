# GrowWeird — Testing

This document owns test execution instructions. Architecture requirements remain authoritative in [`ARCHITECTURE.md`](ARCHITECTURE.md).

## Required checks

Before merging gameplay or architecture changes:

1. Run the repository line-limit check.
2. Run headless domain tests with the project Godot version.
3. Run headless presentation tests when UI/rendering wiring changed.
4. Open the playable slice and complete the manual interaction path below.
5. Confirm save/load still works when the save schema changed.

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

The domain runner verifies these core invariants:

- a seed genome snapshot does not change when its parent mutates later;
- fruit from a grafted branch is marked hybrid and contains host + donor traits;
- a fertilizer event contains three unique choices;
- pruning, planting a cutting and grafting respect branch-slot/inheritance rules;
- save mapping round-trips fertilizer offers, inventory stacks and cutting genomes.

## Headless presentation tests

```bash
godot --headless --path . --script res://tests/run_presentation_tests.gd
```

The presentation runner checks that:

- the main scene and presentation scripts load;
- the visual growth assembler reveals center/left/right branches by stage;
- `thorns`, `bloom` and `glow` produce visible phenotype instructions.

Presentation tests validate rendering contracts only. They must not become a second owner of gameplay rules.

## Playable slice manual path

Run the project normally in Godot. The former smoke screen has been replaced by the playable plant-care screen.

Verify this sequence:

1. Click the window background to cycle `dark → diffused → bright → direct` light.
2. Click the window handle to open/close the window.
3. Water and spray; confirm soil visibly darkens and Plant Sense changes.
4. Observe the plant start as a sprout and progressively reveal center, left and right branches.
5. Wait for the three-item fertilizer offer; choose radiation if available to get a fast visible `glow` mutation, or repeat relevant fertilizers until a mutation resolves.
6. Confirm `thorns`, `bloom` or `glow` appear on the mutated branch without exposing hidden mutation numbers in normal UI.
7. Enter Prune mode, hover a visible branch and click it; confirm a cutting appears in inventory.
8. Click `Plant` on the cutting; only empty pots should be valid targets.
9. Create another cutting, click `Graft`, then choose a glowing free branch slot on a living plant.
10. Switch between pots; each pot must retain its own light/window/soil state.

## Save schema

Any change to persisted fields must:

- increment `GameState.SCHEMA_VERSION` when compatibility changes;
- add a sequential migration in `SaveMigrator`;
- keep old migrations intact;
- round-trip all new state through the appropriate mapper.

Genetic item serialization belongs to `SaveItemMapper`; Game/Pot/Plant/Branch serialization belongs to `SaveMapper`.
