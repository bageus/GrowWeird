# GrowWeird — Testing

This document owns test execution instructions. Architecture requirements remain authoritative in [`ARCHITECTURE.md`](ARCHITECTURE.md). Yandex-specific release checks live in [`YANDEX_GAMES.md`](YANDEX_GAMES.md).

## Required checks
Before merging gameplay or architecture changes:
1. Run the repository line-limit check.
2. Run all headless Godot regression runners.
3. Open the playable slice and complete the manual interaction path below when gameplay/UI changed.
4. Confirm save/load still works when the save schema changed.
5. For Yandex/platform changes, complete the platform checks below.

## CI
GitHub Actions now uses the official Godot 4.6.3 Linux binary and runs the same three regression runners documented below. The downloaded binary is SHA-256 verified before execution.

CI also runs:
```bash
python3 scripts/check_line_limits.py
```
Project-owned authored text files must remain at or below 350 lines.

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

## Headless offline/platform tests
```bash
godot --headless --path . --script res://tests/run_offline_platform_tests.gd
```
The offline/platform runner verifies:
- long absences are capped by the configured offline horizon;
- catch-up never exceeds the configured maximum simulation chunks;
- permanent death can be disabled for offline simulation without creating a second growth formula;
- permanent death can be enabled through the same policy;
- fertilizer-offer time advances during eligible offline catch-up;
- save JSON can round-trip independently from local filesystem I/O;
- native/editor platform resources load and the local adapter provides a clock/fallback path.

The Yandex JavaScript SDK itself cannot be exercised by native headless Godot; Web/Yandex behavior still requires the release verification path in [`YANDEX_GAMES.md`](YANDEX_GAMES.md).

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

## Offline manual path
Use a copied save or a debug-adjusted `last_saved_unix`; do not edit gameplay formulas just to make the test convenient.

Verify:
1. close after a valid save, advance the saved timestamp gap, then reopen;
2. only one catch-up is applied before realtime simulation resumes;
3. the elapsed time is capped when the absence exceeds the configured horizon;
4. soil/growth/health/fruit/offers follow the current offline switches in `GameRules`;
5. with offline death disabled, a critically stressed plant remains barely alive rather than permanently dying;
6. with offline death enabled in a temporary test rules resource, the same stressed state can die;
7. an already-active fertilizer offer survives reload and is not rerolled;
8. background/pause followed by resume uses catch-up rather than double-running foreground delta.

## Platform/Yandex checks
For platform changes, verify native/editor startup still falls back to `LocalPlatformAdapter` and does not require browser SDK objects.

For an actual Yandex Web build, follow [`YANDEX_GAMES.md`](YANDEX_GAMES.md). At minimum verify local/cloud reconciliation, trusted platform time, pause/resume catch-up and readiness reporting. Do not treat a generic local browser run as proof that the Yandex SDK path works.

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
Current schema is **v3**. Offline/platform work adds no persisted fields: it reuses `last_saved_unix`, so no schema bump is required. `v2 → v3` remains the latest migration for branch-local growing-fruit state.
