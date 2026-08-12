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
GitHub Actions runs this automatically. Project-owned authored text files must remain at or below 350 lines.

## Headless domain tests
```bash
godot --headless --path . --script res://tests/run_domain_tests.gd
```
The domain runner verifies:
- seed snapshots stay immutable after later parent mutations;
- grafted branches create hybrid genomes with host + donor traits;
- fertilizer offers contain three unique choices;
- pruning, cutting planting and grafting respect slot/inheritance rules;
- mature comfortable branches grow and expose harvest-ready fruit;
- harvesting resets the branch fruit cycle;
- plant valuation returns money and selling frees the occupied pot;
- Shop purchases add fertilizer and additional pots atomically;
- save mapping round-trips fertilizer offers, inventory genetics and growing-fruit progress.

## Headless presentation tests
```bash
godot --headless --path . --script res://tests/run_presentation_tests.gd
```
The presentation runner checks:
- the main scene plus Shop/pot/inventory presentation resources load;
- all three branch geometries expand with `growth_ratio` without becoming gameplay rules;
- `thorns`, `bloom` and `glow` produce visible phenotype instructions;
- growing fruit exposes unripe/ready state for rendering;
- Harvest interaction mode is available.
Presentation tests validate rendering contracts only. They must not become a second owner of gameplay rules.

## Playable slice manual path
Run the project normally in Godot and verify:
1. Cycle `dark → diffused → bright → direct` by clicking the window; toggle the handle open/closed.
2. Water/spray and confirm soil plus Plant Sense react.
3. Let the plant grow; center/left/right geometry expands continuously.
4. Resolve fertilizer offers and confirm visible `thorns`, `bloom` or `glow` without hidden numbers.
5. Prune a branch and confirm the cutting appears with phenotype preview.
6. Plant a cutting/seed; only empty pots are valid targets.
7. Graft a cutting into a free slot and confirm the graft marker/phenotype remains visible.
8. Grow beyond the species fruiting threshold; each living branch should begin a visible fruit cycle.
9. Confirm fruit progresses from tiny blossom/bud to colored fruit; hybrid fruit is visually distinct.
10. When the gold ready ring appears, enter Harvest mode and click that branch; the fruit must move to inventory.
11. In inventory, convert one harvested fruit to a seed and sell another fruit; money must update.
12. Sell the active plant; its pot must immediately become empty and remain selectable for planting.
13. Open Shop, buy a fertilizer, use it from inventory, and verify money/inventory update exactly once.
14. Buy a new pot; it must appear automatically in the dynamic bottom selector and accept planting.
15. Save/reload while a fruit is partially ripe; progress and hybrid marker must persist.

## Save schema
Any persisted-field change must:
- increment `GameState.SCHEMA_VERSION` when compatibility changes;
- add a sequential migration in `SaveMigrator`;
- keep old migrations intact;
- round-trip all new state through the appropriate mapper.
Current schema is **v3**. `v2 → v3` adds branch-local growing-fruit state. Genetic inventory serialization belongs to `SaveItemMapper`; Game/Pot/Plant/Branch/fruit-growth serialization belongs to `SaveMapper`.
