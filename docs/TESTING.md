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
GitHub Actions uses the official Godot 4.6.3 Linux binary, verifies its SHA-256, imports/parses the project, then runs all regression runners documented below.

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
- species seed unlocks combine data-driven milestone and pot-count requirements;
- purchased species seeds contain the requested clean species genome;
- save mapping round-trips fertilizer offers, inventory genetics and growing-fruit progress.

## Headless lifecycle tests
```bash
godot --headless --path . --script res://tests/run_lifecycle_tests.gd
```
The lifecycle runner verifies:
- species-driven `sprout → juvenile → adult` stage boundaries;
- a cared-for adult remains alive long-term instead of dying from age;
- sustained critical neglect causes irreversible foreground death;
- a healthy adult regrows a native branch only in the exact freed slot;
- regrowth does not bank progress before adulthood;
- a graft occupying the free slot cancels pending native regrowth;
- regrown branches use host species/lineage and do not recreate removed branch-local mutations;
- partial regrowth survives save/load;
- old saves still pass through the v4 regrowth migration on the way to current schema;
- species silhouette parameters produce meaningfully different geometry;
- poor vitality creates visible branch/stem droop;
- Presentation receives bud progress while the slot remains mechanically empty until regrowth completes.

## Headless resource-loop tests
```bash
godot --headless --path . --script res://tests/run_resource_loop_tests.gd
```
The resource runner verifies:
- cutting sale uses species/genome valuation, consumes exactly that cutting and credits money;
- seed sale uses species/genome valuation, consumes exactly that seed and credits money;
- seed, cutting and fruit recycling destroy the source item and add the configured `Compost Mix` yield;
- recycled genetics do not remain as another seed/cutting/fruit object;
- a living whole plant cannot be composted;
- a dead whole plant can be composted, produces biomass-based yield and frees its pot;
- `Compost Mix` uses the ordinary inventory fertilizer path and applies its normal care/mutation definition.

## Headless progression tests
```bash
godot --headless --path . --script res://tests/run_progression_tests.gd
```
The progression runner verifies:
- a new game starts with the watering milestone;
- milestone rewards credit once and cannot be farmed by repeating completed actions;
- events performed before a milestone is available do not bank progress for it;
- `shade_fern` requires the lineage milestone plus its pot-count requirement;
- `sun_creeper` requires the graft milestone plus its third-pot requirement;
- targeted strange fertilizers remain Shop-locked until their configured milestone;
- zero-price recycled `Compost Mix` is never listed or purchasable in Shop;
- progression completion/partial progress round-trip through save v5;
- v4 saves migrate with onboarding bypass so existing players keep previously available content.

## Headless presentation tests
```bash
godot --headless --path . --script res://tests/run_presentation_tests.gd
```
The presentation runner checks:
- the main scene plus Shop/pot/inventory/progression presentation resources load;
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

## First-session manual path
Use a new save. Do not mark progression complete manually.

Verify the current goal advances only after a successful matching action:
1. `Wake the sprout` → water/spray the living starter.
2. `Change the room` → change light or window state.
3. `Run an experiment` → apply a fertilizer; hidden effects must remain hidden.
4. `Make it weird` → keep experimenting until a mutation actually resolves; fertilizer use without a mutation must not complete it.
5. `Harvest the result` → harvest a ready fruit.
6. `Keep the lineage` → convert fruit into a seed snapshot.
7. `Take a cutting` → prune an existing branch.
8. `Build a mosaic` → graft a cutting into a free slot.
9. `Choose what survives` → sell or compost a genetic inventory item.

At every milestone confirm:
- the goal card advances immediately;
- the configured money reward is credited exactly once;
- doing future actions early does not auto-complete later goals;
- Shop lock labels update without exposing internal milestone IDs.

Shop progression checks:
- `Mushroom Compost` becomes target-purchasable after the first fertilizer experiment;
- `Dead Mouse` and `Radioactive Sample` become target-purchasable after the first resolved mutation;
- `shade_fern` still needs two pots and also stays locked until the seed milestone;
- `sun_creeper` still needs three pots and also stays locked until the graft milestone;
- random three-choice fertilizer offers remain experimental and may surface unusual material before Shop unlock;
- recycled `Compost Mix` never appears as a free Shop purchase.

## Playable slice manual path
Run the project normally in Godot and verify:
1. Cycle `dark → diffused → bright → direct` by clicking the window; toggle the handle open/closed.
2. Water/spray and confirm soil plus Plant Sense react without displaying raw care percentages.
3. Watch a new specimen transition through `Sprout → Juvenile → Adult`; geometry must expand continuously rather than jump between separate plant objects.
4. Keep care good and confirm an adult remains stable indefinitely while fruit/mutations continue.
5. Deliberately create prolonged critical care and observe color loss, fewer/smaller leaves and branch droop before permanent death.
6. After death, confirm Plant Sense hides and prune/graft/harvest actions no longer work.
7. Resolve fertilizer offers and confirm visible mutations without hidden numerical pressure values.
8. Combine fertilizer families and verify synergy phenotypes such as lure blooms, crystal thorns or luminous fungus can appear.
9. Confirm fungal growth, bark armor and synergy traits remain branch-local and survive pruning/grafting snapshots.
10. Prune an adult healthy plant and keep care comfortable; confirm a small bud appears and eventually restores the exact freed slot as a clean native branch.
11. Repeat pruning, then graft into the free slot before regrowth completes; native bud progress must disappear and the graft must remain.
12. Save/reload during partial native regrowth and confirm the same bud progress resumes instead of restarting.
13. In inventory, verify every cutting exposes `Plant`, `Graft`, `Sell` and `Compost` choices.
14. Sell one cutting and confirm only that item disappears and money increases.
15. Compost another cutting and confirm it disappears while the `Compost Mix` fertilizer stack increases.
16. For a seed, verify `Plant`, `Sell` and `Compost`; selling/composting must consume the exact seed.
17. Harvest fruit and verify the three competing actions: convert to seed, sell, or compost.
18. Use recycled `Compost Mix` on a living plant and confirm it behaves like an ordinary fertilizer item and is consumed from inventory.
19. Kill a test plant, then verify both final processing choices remain: reduced-value `Sell plant` and `Compost remains`.
20. Compost the dead plant and confirm biomass yield enters inventory and the pot becomes immediately empty/selectable.
21. Save/reload while a fruit is partially ripe; progress and hybrid marker must persist.

## Offline manual path
Use a copied save or a debug-adjusted `last_saved_unix`; do not edit gameplay formulas just to make the test convenient.

Verify:
1. close after a valid save, advance the saved timestamp gap, then reopen;
2. only one catch-up is applied before realtime simulation resumes;
3. the elapsed time is capped when the absence exceeds the configured horizon;
4. soil/growth/health/fruit/offers and native branch regrowth follow the current offline switches in `GameRules`;
5. with offline death disabled, a critically stressed plant remains barely alive rather than permanently dying;
6. with offline death enabled in a temporary test rules resource, the same stressed state can die;
7. an already-active fertilizer offer survives reload and is not rerolled;
8. background/pause followed by resume uses catch-up rather than double-running foreground delta.

## Platform/Yandex checks
For platform changes, verify native/editor startup still falls back to `LocalPlatformAdapter` and does not require browser SDK objects.

For an actual Yandex Web build, follow [`YANDEX_GAMES.md`](YANDEX_GAMES.md). At minimum verify local/cloud reconciliation, trusted platform time, pause/resume catch-up and readiness reporting. Do not treat a generic local browser run as proof that the Yandex SDK path works.

## Content/progression ownership
Exact fertilizer contributions, species care ranges, lifecycle thresholds, branch-regrowth tuning, seed prices, unlock pot counts and visual palettes/silhouette parameters live in `content/**/*.tres` and are not duplicated in UI code.
`MutationDefinition.axis_requirements` owns single- or multi-axis mutation thresholds. `MutationEngine` only evaluates those definitions.
`ProgressionDefinition` resources own onboarding order, event targets, prerequisite IDs, copy and milestone money rewards. `ProgressionService` owns completion rules; Presentation receives only a current-goal descriptor.
Species and targeted-fertilizer Shop availability is calculated by `ShopService` from definition-owned requirements plus `ProgressionState`/current pots.
Item sale multipliers and compost yields live in `GameRules`; genetic item value is calculated by `GeneticItemValuationService`, and recycling yield/compost identity by `RecyclingService`.

## Save schema
Any persisted-field change must:
- increment `GameState.SCHEMA_VERSION` when compatibility changes;
- add a sequential migration in `SaveMigrator`;
- keep old migrations intact;
- round-trip all new state through the appropriate mapper.
Current schema is **v5**. `v4 → v5` adds persisted milestone progress/completions and an onboarding-bypass flag. Existing v4 players migrate with the bypass enabled; new games start the milestone path normally.
