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
- multi-axis synergy mutations require and consume every configured axis;
- pruning, cutting planting and grafting respect slot/inheritance rules;
- mature comfortable branches grow and expose harvest-ready fruit;
- harvesting resets the branch fruit cycle;
- plant valuation returns money and selling frees the occupied pot;
- Shop purchases add fertilizer and additional pots atomically;
- species seed unlocks depend on data-driven pot-count requirements;
- purchased species seeds contain the requested clean species genome;
- save mapping round-trips fertilizer offers, inventory genetics and growing-fruit progress.

## Headless presentation tests
```bash
godot --headless --path . --script res://tests/run_presentation_tests.gd
```
The presentation runner checks:
- the main scene plus Shop/pot/inventory presentation resources load;
- all three branch geometries expand with `growth_ratio` without becoming gameplay rules;
- base traits plus fungal/structural/synergy traits produce visible phenotype instructions;
- species resources expose distinct visual palettes;
- growing fruit exposes unripe/ready state for rendering;
- Harvest interaction mode is available.
Presentation tests validate rendering contracts only. They must not become a second owner of gameplay rules.

## Playable slice manual path
Run the project normally in Godot and verify:
1. Cycle `dark → diffused → bright → direct` by clicking the window; toggle the handle open/closed.
2. Water/spray and confirm soil plus Plant Sense react.
3. Let the plant grow; center/left/right geometry expands continuously.
4. Resolve fertilizer offers and confirm visible mutations without hidden numerical pressure values.
5. Combine fertilizer families and verify synergy phenotypes such as lure blooms, crystal thorns or luminous fungus can appear.
6. Confirm fungal growth, bark armor and synergy traits remain branch-local and survive pruning/grafting snapshots.
7. Prune a branch and confirm the cutting appears with an expanded phenotype preview.
8. Plant a cutting/seed; only empty pots are valid targets.
9. Graft a cutting into a free slot and confirm the graft marker/phenotype remains visible.
10. Grow beyond the species fruiting threshold and harvest a ripe fruit into inventory.
11. Convert one harvested fruit to a seed and sell another fruit; money must update.
12. Open Shop and confirm species seeds are listed separately from fertilizers.
13. With the starting two pots, buy a `shade_fern` seed and plant it; its care preferences and palette must differ from the starter.
14. Confirm `sun_creeper` is locked until a third pot is owned; buy a pot and verify the seed unlocks immediately.
15. Buy and plant `sun_creeper`; confirm it prefers a different light/moisture range and has its own palette/fruit color.
16. Sell the active plant; its pot must immediately become empty and remain selectable for planting.
17. Save/reload while a fruit is partially ripe; progress and hybrid marker must persist.

## Content progression ownership
Exact fertilizer contributions, species care ranges, seed prices, unlock pot counts and visual palettes live in `content/**/*.tres` and are not duplicated in UI code.
`MutationDefinition.axis_requirements` owns single- or multi-axis mutation thresholds. `MutationEngine` only evaluates those definitions.
Species seed availability is calculated by `ShopService` from each `PlantSpeciesDefinition.unlock_pot_count` and current `GameState.pots`.

## Save schema
Any persisted-field change must:
- increment `GameState.SCHEMA_VERSION` when compatibility changes;
- add a sequential migration in `SaveMigrator`;
- keep old migrations intact;
- round-trip all new state through the appropriate mapper.
Current schema is **v3**. This content/progression slice adds no persisted fields, so no schema bump is required. `v2 → v3` remains the latest migration for branch-local growing-fruit state.
