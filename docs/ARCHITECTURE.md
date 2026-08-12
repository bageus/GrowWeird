# GrowWeird — Architecture
> Architectural source of truth for the Godot 4.x project. Goal: ship a small Web MVP without creating a dead end for larger Web/Android/iOS versions.

## 1. Non-negotiable rules
1. **One source of truth:** every gameplay rule, formula, balance value and mutable fact has one authoritative owner.
2. **No project-owned text file over 350 lines.** Split by responsibility before crossing the limit.
3. **No gameplay logic in UI or visual plant nodes.** UI sends intent and renders state/events.
4. **No duplicated formulas.** Growth, comfort, valuation, mutation and inheritance each have one domain owner.
5. **Definitions are immutable at runtime.** Species/fertilizer/trait resources are content, not save state.
6. **Save data stores stable IDs + primitive/serializable state, never NodePaths/scenes.**
7. **Gameplay randomness is deterministic when it matters.** Use owned RNG seeds/streams.
8. **Platform APIs sit behind adapters.** Yandex/Android/iOS code never enters Domain.
9. **Scenes compose/present; Domain decides.**
10. **Expected invalid actions return explicit failures, not ad-hoc exceptions.**

## 2. 350-line enforcement
Limit applies to tracked project text files such as `.gd`, `.md`, `.json`, `.cfg`, `.tscn`, `.tres`; generated/imported `.godot/` files are excluded. Large scenes/resources must be decomposed. Add `tools/check_file_length.py` and run it in CI/pre-commit; the checker also obeys the same limit.

## 3. Layer model
```text
Presentation -> Application -> Domain <- Data Definitions
                      |
               Infrastructure
                      |
                  Platform
```
Dependencies point inward.
- **Presentation:** input, views, animations, VFX/audio.
- **Application:** player-action use cases, transactions, session orchestration.
- **Domain:** rules/calculations/state invariants; no Godot scene/SDK dependency.
- **Data Definitions:** authored immutable Resources and registries.
- **Infrastructure:** persistence, clock, RNG implementation, analytics transport.
- **Platform:** Yandex/Android/iOS adapters.

## 4. Suggested layout
```text
res://
  app/{boot,session,commands,events}/
  domain/{plant,care,growth,mutation,genetics,grafting,harvest,inventory,economy,offers}/
  data/definitions/{species,fertilizers,traits,mutation_rules,balance}/
  data/registries/
  presentation/{main,plant,hud,inventory,shop,common}/
  infrastructure/{persistence,time,rng,analytics}/
  platform/{common,yandex,android,ios}/
  assets/{art,audio,fonts}/
  tests/{unit,integration}/
  tools/
```
Create folders only when the first real type needs them; do not build empty architecture for appearance.

## 5. Composition root and globals
Recommended entry scene: `res://app/boot/boot.tscn`. A `GameApplication` constructs/wires services and owns the active `GameSession`. Avoid many Autoload singletons. Gameplay state lives in `GameSession`, not a global dictionary. Autoload is reserved for truly process-wide SDK/bootstrap needs.

## 6. Definitions vs runtime state
### Immutable authored definitions
- `PlantSpeciesDefinition`
- `FertilizerDefinition`
- `TraitDefinition`
- `MutationRuleDefinition`
- `GrowthCurveDefinition`
- `EconomyBalanceDefinition`
- `OfferBalanceDefinition`
Godot custom `Resource` files are appropriate.
### Mutable runtime/save state
- `GameState`, `PlayerState`, `PotState`, `PlantState`, `BranchState`
- `MutationState`, `GenomeSnapshot`
- `SeedState`, `CuttingState`, `FruitState`
- `InventoryState`, `FertilizerOfferState`
Runtime state must remain serializable and scene-independent.

## 7. Stable IDs
Every definition gets a permanent string ID, e.g. `species.apple_basic`, `fertilizer.dead_mouse`, `trait.carnivore.thorns`.
Rules:
- released IDs never change if saves may contain them;
- display names are localization keys, never IDs;
- asset paths are not gameplay IDs;
- migrations translate deprecated IDs when required.

## 8. Registries as content source of truth
Use explicit `SpeciesRegistry`, `FertilizerRegistry`, `TraitRegistry`, `MutationRuleRegistry`. No subsystem independently scans the same folders or keeps its own copy. Registries validate duplicate IDs, missing references, invalid ranges, impossible rules and missing required visual descriptors.

## 9. Authoritative GameState
`GameState` is the only mutable gameplay snapshot. It owns player money, pots, plants, inventory, active fertilizer offers, schema/version metadata, RNG state and authoritative simulation timestamp. UI never owns competing writable copies. Hover/selection state is presentation-only.

## 10. PotState
Each pot owns its own environment so incompatible species can coexist.
Recommended fields: `pot_id`, `plant_id|null`, `light_mode`, `window_open`, `last_environment_change_at`.
Switching selected pot changes the presented environment; it does not rewrite another pot's state.

## 11. PlantState
A specimen stores instance data, not species definitions:
```text
plant_id, custom_name, species_id, created_at, age_seconds
size, health, soil_moisture, leaf_moisture, status
root_genome, mutation_state, branch_slots, fruit_state, rng_seed
```
Derived values such as comfort, growth speed and sale price are calculated, not persisted unless profiling later justifies a cache.

## 12. Three branch slots
Root/base owns exactly `left`, `center`, `right`. Address slots by stable slot ID, not duplicated array-index assumptions.
Each slot is `null` or a `BranchState` containing roughly:
```text
branch_id, slot_id, origin_type, source_plant_id|null
genome, mutation_state, visual_seed, created_at
```
`origin_type` may be native/grafted/cutting-derived. Cutting any branch, including center, sets the slot to `null` and creates `CuttingState`. Grafting requires `null`. The center branch is not a pruning exception.

## 13. Infinite mutation without class/save explosion
Never create a class/resource for every complete plant combination. Store compact **MutationState** and derive a deterministic **PhenotypeDescriptor**.
Recommended representation: `trait_id -> {level, expression, seed}`. Repeated acquisition changes level/expression instead of appending duplicate history events forever. Unique procedural variants store deterministic seeds/parameters rather than copied full visual trees.
Thus “unlimited mutation” means no gameplay cap on levels/combinations, while save growth remains controlled.

## 14. Mutation scope
Every mutation definition explicitly declares scope: root/whole-plant, branch-local, fruit-expression, or future inheritance-only. Never infer scope from sprite names. `MutationEngine` is the sole resolver of new mutations; callers request resolution rather than reimplementing rules.

## 15. Fertilizer source of truth
`FertilizerDefinition` contains hidden mechanics once:
```text
id, localization_key, shop_price, mutation_contributions
care_effects, growth_effects, icon_ref, offer_weight, tags
```
UI receives only player-visible fields. Hidden contribution values remain hidden even though they exist in data.

## 16. Mutation rules
`MutationRuleDefinition` is data; `MutationEngine` evaluates it. Inputs may include trait pressure, existing levels, species tags, ancestry, environment and deterministic RNG. Outputs may add/increase traits, alter expression seeds, enable organs or fruit modifiers. No rule formula is duplicated in visuals or fertilizer code.

## 17. GeneticsService
`GeneticsService` is the only owner of genome copy/combine rules: seeds, cuttings, graft ancestry and hybrid fruit.
### Seed
When a seed item is created, capture an immutable `GenomeSnapshot` of all inheritable mutations relevant at that exact moment. Later parent mutation never changes existing seed snapshots.
### Cutting
At prune time, snapshot the cut branch's inheritable state. Once planted, the new specimen evolves independently under future fertilizers.
### Graft
A graft retains donor branch ancestry while attached to host root.
### Hybrid fruit
Resolve genetics only through `GeneticsService` using host/root + bearing-branch ancestry. Exact resolution moment stays configurable pending design choice.

## 18. ComfortEvaluator
One pure `ComfortEvaluator` calculates care quality from species preferences, pot light/window, soil/leaf moisture and applicable mutation modifiers.
Output value object:
```text
water_deviation, light_deviation, air_deviation, leaf_deviation
overall_comfort, worst_need
```
Plant Sense renders this result. UI never duplicates comfort thresholds.

## 19. PlantSimulationService
Single owner of time-based plant simulation. It coordinates moisture decay, leaf-moisture decay, comfort, health damage/recovery, growth, maturity, death and later fruit progression.
Design invariant: **smaller plants grow faster; larger plants progressively slower.** The curve lives in `GrowthCurveDefinition`, not hard-coded in scenes.

## 20. Real-time/offline time model
Use injected `GameClock`; domain files must not independently read system wall time. Production clock returns UTC; tests use fake clock. Save `last_simulated_at`.
Resume algorithm:
1. compute elapsed real time;
2. apply configured offline policy;
3. simulate by bounded steps or analytical integration;
4. update authoritative timestamp.
Never run one tick per missed second for long absences. Offline growth/death are policy switches, not architecture changes.

## 21. Commands and events
Presentation sends commands such as `WaterPlant`, `SprayPlant`, `SetLightMode`, `SetWindowState`, `ChooseFertilizer`, `SkipFertilizerOffer`, `PruneBranch`, `PlantCutting`, `GraftBranch`, `HarvestFruit`, `CreateSeed`, `SellPlant`, `RenamePlant`.
Application validates, invokes Domain, changes `GameState`, then publishes events such as `PlantWatered`, `PlantMutated`, `BranchPruned`, `BranchGrafted`, `FruitHarvested`, `PlantDied`, `PlantSold`, `MoneyChanged`.
Visual/audio code reacts to events; it never decides legality.

## 22. Atomic application actions
A player action is one application transaction. Example `SellPlant` must validate existence, calculate price, credit money, clear pot, remove/move specimen state, emit events and schedule save through one use case. Never add money in UI, clear pot elsewhere and delete plant in a third callback.

## 23. Economy ownership
- `PlantValuationService` owns plant sale formula.
- `ShopService` owns purchases/catalog transactions.
- `EconomyService` owns money transfer/invariants.
Coefficients live in `EconomyBalanceDefinition`. UI asks the owner for price; it does not estimate. Valuation may consider species, age, health, mutation expression/synergy, graft complexity, fruiting and future market modifiers.

## 24. FertilizerOfferService
Sole owner of offer cadence, weighted three-choice generation, deterministic offer RNG, skip price, choose/skip resolution and next scheduling. Save offered IDs and offer state so reload cannot reroll for free. Shop and random offers both reference the same `FertilizerDefinition`.

## 25. InventoryService
Only writer for inventory operations. Simple identical items may stack. Genetic items are instances: seeds, cuttings and any fruit whose genetics matter. Two visually identical seeds are not stackable if `GenomeSnapshot` differs.

## 26. Presentation modules
Suggested views: `MainGameView`, `PlantView`, `WindowView`, `PlantSenseView`, `ToolPanelView`, `FertilizerOfferView`, `PotSelectorView`, `InventoryView`, `ShopView`.
Views receive read-only presentation models and emit intent. Avoid a giant `main.gd`; split controllers around 250–300 lines before the 350-line hard limit.

## 27. Plant visuals
`PlantVisualAssembler` receives species visual definition + three branches + phenotype descriptor + size/health + visual seeds. It places reusable trunk/branch sprites, leaves, flowers, fruit, thorns, hooks, traps, fungi and effects.
It does **not** decide what mutations exist.

## 28. PhenotypeResolver
One deterministic `PhenotypeResolver` converts genome/mutation state into renderable instructions so systems cannot interpret the same mutation differently.
Descriptor may contain: `leaf_shape_id`, scale/color params, thorn density/scale, flower/fruit variant IDs, fungal density, glow, deformation seed and other normalized expression values. Same state + seeds must reconstruct the same appearance after load.

## 29. Persistence
Use versioned DTO/schema separate from scenes/domain objects.
Recommended root:
```text
schema_version, saved_at_utc, player, pots, plants
inventory, offers, rng_state
```
Write: `GameState -> SaveMapper -> SaveDTO -> SaveRepository`.
Load: `SaveRepository -> migrations -> SaveDTO -> SaveMapper -> GameState`.
Do not serialize scene trees as primary save format.

## 30. Save migrations and safety
Released breaking schema changes require chained migrations such as `v1 -> v2 -> v3 -> current`; current gameplay code only sees current state. Keep migrations isolated/small.
Persistence should support atomic temp-write/replace where possible, last-known-good backup, validation, corruption fallback, milestone saves and debounced routine saves. Platform storage may differ while `SaveRepository` interface stays stable.

## 31. Platform adapters
Application/Domain never import Yandex SDK. Define small capabilities such as `IPlatformStorage`, `IAdsService`, `IAnalyticsService`, optional `ILeaderboardService`, `IPlatformLifecycle`.
Implement `YandexPlatformAdapter`, `AndroidPlatformAdapter`, `IOSPlatformAdapter`, local/dev adapter. Mobile expansion then replaces adapters rather than gameplay architecture.

## 32. Analytics boundary
Analytics observes domain/application events. Never sprinkle vendor calls inside plant/mutation/economy classes. Analytics failure must never block a gameplay transaction.

## 33. Deterministic RNG
Use injectable named streams when useful: fertilizer offers, mutation resolution, genetics, phenotype cosmetics. Cosmetic randomness may be less strict, but a saved specimen's visible phenotype must remain stable after reload.

## 34. Tests
Domain tests must run without scenes. Priority cases:
- comfort boundaries;
- growth slows as size rises;
- prolonged critical care can kill;
- mature plant can live indefinitely;
- fertilizer effects resolve deterministically;
- mutation stacking has no artificial cap;
- all three branch slots can be cut;
- graft requires free slot;
- seed snapshot is immutable after creation;
- cutting preserves snapshot then evolves independently;
- hybrid fruit uses host + branch ancestry;
- selling clears pot and credits exactly once;
- reload does not reroll fertilizer offers;
- save/load + migrations round-trip.

## 35. Duplication-prevention map
Before writing a function, identify its owner:
- “Is plant comfortable?” → `ComfortEvaluator`
- “How fast does it grow/die?” → `PlantSimulationService`
- “What mutation occurs?” → `MutationEngine`
- “What does seed/cutting inherit?” → `GeneticsService`
- “Can graft happen here?” → `GraftingService`
- “What is plant worth?” → `PlantValuationService`
- “What offer/skip price applies?” → `FertilizerOfferService`
If another caller needs the answer, call that owner; never copy the formula.

## 36. Rule-placement hierarchy
1. Authored content value → Definition/Resource.
2. Universal gameplay calculation → Domain service.
3. One player-action orchestration → Application use case/handler.
4. Persisted mutable fact → Runtime state.
5. File/SDK/storage concern → Infrastructure/Platform.
6. Rendering/input/animation → Presentation.
If the same rule appears in two layers, the outer layer delegates to the inner owner.

## 37. Expected failures
Commands return explicit failure codes/results for normal invalid states: occupied pot/slot, insufficient money, dead plant, missing branch/item, invalid target. Expected rejection is not an exception. Broken invariants should fail loudly in development and be captured by diagnostics in production where possible.

## 38. Performance rules for Web/mobile
- Avoid `_process()` on every plant part.
- Simulate plants centrally at controlled cadence.
- Presentation may animate every frame; gameplay simulation need not.
- Background/offline plants use batched or analytical updates.
- Keep mutation state compact and reconstruct visuals deterministically.
- Load registries once and reuse definitions.
- Pool transient VFX only if profiling shows benefit.
- Profile browser memory before raising simultaneous pot count.
Foreground/background/offline paths must use the same formulas to avoid divergent results.

## 39. Localization
All player-visible authored text uses localization keys from the start. IDs are language-independent. Custom plant names are raw player content stored separately. This keeps RU/EN Web and future mobile localization out of Domain.

## 40. Client authority
Initial GrowWeird saves are client-controlled and therefore not secure competitive state. Do not pretend otherwise. If trading/leaderboards/competitive economy later require server authority, add validation behind backend/platform services rather than ad-hoc anti-cheat checks throughout Domain.

## 41. First implementation slice
1. `PlantSpeciesDefinition` + registry.
2. `GameState`, `PotState`, `PlantState` + three branch slots.
3. `GameClock` + `PlantSimulationService`.
4. `ComfortEvaluator`.
5. Water/light/window command path.
6. Minimal `PlantView` + Plant Sense read model.
7. `FertilizerDefinition` + `MutationEngine`.
8. One visible mutation through `PhenotypeResolver`.
9. Versioned save round-trip.
Do not prebuild every future interface; preserve boundaries and add implementations when first used.

## 42. Definition of done for new features
A feature is complete only when:
- source-of-truth owner is clear;
- formulas/rules are not duplicated;
- persisted data uses stable IDs;
- save migration impact is considered;
- domain behavior is testable without UI;
- platform calls are isolated;
- all text files remain below 350 lines;
- UI only renders/dispatches intent;
- gameplay RNG is deterministic where required;
- new content schemas are registry-validated.

## 43. Decisions intentionally configurable
Architecture must support without rewrite:
- offline growth enabled/disabled/capped;
- offline permanent death enabled/disabled;
- native branch regrowth policy;
- fertilizer offer cadence;
- skip-price curve;
- mutation thresholds;
- hybrid-fruit genetics timing;
- branch-local vs root-wide mutation definitions;
- market-demand modifiers;
- max owned pots due to balance/device limits.
These are product/balance settings, not structural assumptions.
