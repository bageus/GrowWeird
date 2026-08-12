# GrowWeird — Architecture

> Status: architectural source of truth.  
> Engine: Godot 4.x.  
> Goal: support a small MVP without creating a dead end when the project grows to Web, Android and iOS.

## 1. Non-negotiable rules

1. **One source of truth.** A gameplay rule, formula, balance value or runtime state has exactly one authoritative owner.
2. **No handwritten text file may exceed 350 lines.** Split by responsibility before crossing the limit.
3. **No gameplay logic in UI scenes.** UI sends commands and renders read models/events.
4. **No gameplay logic in visual plant nodes.** Visuals reflect phenotype/state; they do not decide genetics, prices, growth or death.
5. **No duplicated formulas.** Growth, comfort, valuation, inheritance and mutation resolution each have one domain service.
6. **Definitions are immutable at runtime.** Species/fertilizer/trait/rule resources are content definitions, not save state.
7. **Save data contains stable IDs and primitive state, never NodePaths or scene references.**
8. **Randomness is deterministic when gameplay-relevant.** Mutation/genetics use owned RNG seeds so saves and tests are reproducible.
9. **Platform APIs are behind adapters.** Yandex, Android and iOS code must not leak into domain logic.
10. **Scenes are composition/presentation.** Business rules live in plain GDScript domain classes/services.

## 2. File-size rule

The 350-line limit applies to project-owned text files, including:

- `.gd`
- `.md`
- `.json`
- `.cfg`
- `.tscn`
- `.tres`

If a scene/resource approaches the limit, split it into child scenes/resources.

Generated/imported files under `.godot/` are excluded.

A CI/pre-commit check should fail when a tracked project text file exceeds 350 lines.

Recommended checker location:

`tools/check_file_length.py`

The checker itself must also stay under 350 lines.

## 3. Architectural shape

Use a layered, data-driven architecture:

```text
Presentation -> Application -> Domain <- Data Definitions
                      |
                 Infrastructure
                      |
                   Platform
```

Dependencies point inward.

- Presentation may call Application.
- Application orchestrates Domain services.
- Domain knows nothing about scenes, SDKs or save files.
- Infrastructure implements persistence/time/platform boundaries.
- Data Definitions describe content but do not own mutable player state.

## 4. Suggested repository layout

```text
res://
  app/
    boot/
    session/
    commands/
    events/
  domain/
    plant/
    care/
    growth/
    mutation/
    genetics/
    grafting/
    harvest/
    inventory/
    economy/
    offers/
  data/
    definitions/
      species/
      fertilizers/
      traits/
      mutation_rules/
      balance/
    registries/
  presentation/
    main/
    plant/
    hud/
    inventory/
    shop/
    common/
  infrastructure/
    persistence/
    time/
    rng/
    analytics/
  platform/
    common/
    yandex/
    android/
    ios/
  assets/
    art/
    audio/
    fonts/
  tests/
    unit/
    integration/
  tools/
```

Do not create folders merely to match this document. Create them when the first real type for that responsibility exists.

## 5. Composition root

The project should have one composition root responsible for constructing and wiring services.

Recommended entry scene:

`res://app/boot/boot.tscn`

Recommended coordinator:

`GameApplication`

It owns references to application services and the active `GameSession`.

Avoid a large collection of global Autoload singletons.

Acceptable Autoload candidates are only truly process-wide infrastructure such as a minimal platform bootstrap if required by an SDK.

Gameplay state itself must live in `GameSession`, not in an Autoload global dictionary.

## 6. Content definitions vs runtime state

This separation is critical.

### Content definitions

Authored once and treated as immutable:

- `PlantSpeciesDefinition`
- `FertilizerDefinition`
- `TraitDefinition`
- `MutationRuleDefinition`
- `GrowthCurveDefinition`
- `EconomyBalanceDefinition`
- `OfferBalanceDefinition`

Godot custom `Resource` files are suitable for these definitions.

### Runtime state

Created per save/player/specimen:

- `GameState`
- `PlayerState`
- `PotState`
- `PlantState`
- `BranchState`
- `MutationState`
- `GenomeSnapshot`
- `SeedState`
- `CuttingState`
- `FruitState`
- `InventoryState`
- `FertilizerOfferState`

Runtime state is serializable data and must not depend on scene nodes.

## 7. Stable identifiers

Every content definition must have a permanent string ID.

Examples:

```text
species.apple_basic
fertilizer.dead_mouse
trait.carnivore.thorns
mutation.glow.radioactive
```

Rules:

- IDs never change after release if they may exist in saves.
- Display names are localization keys, not IDs.
- Asset paths are not IDs.
- Save migrations translate deprecated IDs when necessary.

## 8. Registries are the content source of truth

Definitions are loaded through explicit registries, for example:

- `SpeciesRegistry`
- `FertilizerRegistry`
- `TraitRegistry`
- `MutationRuleRegistry`

No system should scan arbitrary folders independently for the same definitions.

The registry validates:

- duplicate IDs;
- missing referenced IDs;
- invalid ranges;
- impossible mutation requirements;
- missing visual descriptors where required.

## 9. GameState ownership

`GameState` is the authoritative mutable snapshot of the current game.

It contains references/state for:

- player money;
- owned pots;
- plants per pot;
- inventory;
- active fertilizer offers;
- save/version metadata;
- authoritative last simulation timestamp.

UI must never keep a competing writable copy of these values.

Temporary UI selection state, such as “currently hovered branch”, is presentation state and does not belong in `GameState`.

## 10. PotState

Each pot owns its own local environment.

Recommended state:

```text
pot_id
plant_id|null
light_mode
window_open
last_environment_change_at
```

This guarantees that switching pots can also switch the visible background/window condition without forcing all plants to share one environment.

## 11. PlantState

A plant instance should contain only specimen state, not authored species rules.

Recommended fields:

```text
plant_id
custom_name
species_id
created_at
age_seconds
size
health
soil_moisture
leaf_moisture
root_genome
mutation_state
branch_slots
fruit_state
rng_seed
status
```

`status` should use a small domain enum such as alive/dead.

Derived values such as current price, comfort or growth speed are calculated, not persisted unless profiling proves caching necessary.

## 12. Three branch slots

The root/base owns exactly three structural slots:

- left
- center
- right

Represent them by slot ID, not array position assumptions spread across code.

Each slot contains either `null` or a `BranchState`.

A `BranchState` should include:

```text
branch_id
slot_id
origin_type
source_plant_id|null
genome
mutation_state
visual_seed
created_at
```

`origin_type` may distinguish native/grafted/cutting-derived lineage.

Cutting any branch sets its slot to `null` and creates a `CuttingState` snapshot.

Grafting requires a `null` slot.

The center slot is not a special exception in pruning logic.

## 13. Infinite mutation without infinite class explosion

Never create a class/resource for every possible complete plant combination.

Use two concepts:

1. **Mutation state** — compact gameplay/genetic values.
2. **Phenotype descriptor** — deterministic visual expression derived from state.

Mutation state can store maps such as:

```text
trait_id -> level/expression/seed
```

Repeated acquisition of the same mutation increases or modifies its expression instead of appending duplicate event records forever.

This gives unbounded progression while keeping saves compact.

If unique procedural variants are needed, store a deterministic seed/parameters, not a copied full asset composition.

“Unlimited mutation” therefore means no artificial gameplay cap on levels/combinations, not an ever-growing duplicate history log.

## 14. Mutation ownership

Mutations must explicitly declare scope:

- root/whole-plant;
- branch-local;
- fruit-expression;
- inherited-genome-only if a future mechanic requires it.

Do not infer scope from asset names.

`MutationEngine` is the only service allowed to resolve new mutations from fertilizer/genetic inputs.

Other systems may request mutation resolution but must not duplicate mutation rules.

## 15. Fertilizer definitions

`FertilizerDefinition` is the single source for a fertilizer's hidden mechanical effects.

Recommended authored data:

```text
id
localization_key
shop_price
mutation_contributions
care_effects
growth_effects
visual/icon reference
offer_weight
tags
```

UI receives only player-visible fields.

Hidden mutation contributions must never be exposed merely because the definition contains them.

## 16. Mutation rules

`MutationRuleDefinition` describes thresholds/combinations in data.

Examples of rule inputs:

- trait pressure thresholds;
- existing mutation levels;
- species tags;
- branch ancestry;
- environmental state;
- deterministic random roll.

Examples of outputs:

- add trait;
- increase trait level;
- modify expression seed;
- enable visual organ;
- add fruit-expression modifier.

Rules belong in data; rule evaluation belongs only in `MutationEngine`.

## 17. Genetics and inheritance

`GeneticsService` is the only source of truth for copying/combining genomes.

It owns:

- seed snapshots;
- cutting snapshots;
- graft ancestry;
- hybrid fruit inheritance.

### Seed rule

When the seed item is created, create an immutable `GenomeSnapshot` containing all inheritable mutations present at that exact moment.

Existing seed snapshots never change when the parent mutates later.

### Cutting rule

A cutting receives a snapshot of the cut branch's inheritable state at cut time.

After planting, the new plant is independent and can mutate indefinitely from future fertilizer events.

### Graft rule

A graft keeps donor branch ancestry while attached to the host root.

### Hybrid fruit rule

Hybrid fruit genetics must be resolved only through `GeneticsService`, using host/root and bearing-branch lineage.

The exact resolution moment is configurable pending design decision.

## 18. Care evaluation

Use one `ComfortEvaluator`.

Inputs:

- species preferences;
- pot light state;
- window state;
- soil moisture;
- leaf moisture;
- applicable mutation modifiers.

Output should be a pure value object such as:

```text
water_deviation
light_deviation
air_deviation
leaf_deviation
overall_comfort
worst_need
```

The Plant Sense UI renders this output.

The UI must not calculate comfort thresholds itself.

## 19. Growth simulation

`PlantSimulationService` is the only owner of time-based plant simulation.

It coordinates pure calculations for:

- moisture decay;
- leaf-moisture decay;
- comfort;
- health damage/recovery;
- growth;
- maturity;
- death;
- fruit progression when implemented.

Growth must support the design rule:

**smaller plants grow faster; larger plants grow progressively slower.**

The growth curve itself belongs in a balance definition, not hard-coded into UI or plant scenes.

## 20. Real-time and offline simulation

Use an injected `GameClock` interface.

Domain logic must not call `Time.get_unix_time_from_system()` in many unrelated files.

The production clock returns authoritative UTC timestamps.

Tests can inject a fake clock.

Store `last_simulated_at` in save state.

When resuming:

1. compute elapsed real time;
2. apply configured offline-progress policy;
3. simulate using bounded steps or analytical integration;
4. persist the new authoritative timestamp.

Never run one frame/tick per missed second for long absences.

Whether plants can die while the game is closed is a policy value, not an architectural rewrite.

## 21. Commands and domain events

Presentation sends intent as commands, for example:

- `WaterPlantCommand`
- `SprayPlantCommand`
- `SetLightModeCommand`
- `SetWindowStateCommand`
- `ChooseFertilizerCommand`
- `SkipFertilizerOfferCommand`
- `PruneBranchCommand`
- `PlantCuttingCommand`
- `GraftBranchCommand`
- `HarvestFruitCommand`
- `CreateSeedCommand`
- `SellPlantCommand`
- `RenamePlantCommand`

Application handlers validate the command, call domain services, mutate `GameState`, then emit domain/application events.

Example events:

- `PlantWatered`
- `PlantMutated`
- `BranchPruned`
- `BranchGrafted`
- `FruitHarvested`
- `PlantDied`
- `PlantSold`
- `MoneyChanged`

Visuals and audio react to events; they do not determine whether the action was legal.

## 22. Application transaction boundary

A player action should be atomic from the application's perspective.

Example: selling a plant must not independently:

1. add money in UI code;
2. clear the pot elsewhere;
3. delete the plant in a third callback.

Instead `SellPlantCommand` invokes one use case that:

- validates plant exists;
- calculates value through `PlantValuationService`;
- adds money;
- clears pot ownership;
- removes/moves specimen state as required;
- emits events;
- schedules save.

This prevents partial state and duplicated rules.

## 23. Economy source of truth

Use dedicated services:

- `PlantValuationService`
- `ShopService`
- `EconomyService`

`PlantValuationService` owns the sale formula.

UI never estimates price independently.

Balance coefficients live in `EconomyBalanceDefinition`.

The service may consider species, age, health, mutation expression, synergy, graft complexity and future market modifiers.

## 24. Fertilizer offer system

`FertilizerOfferService` owns:

- when an offer becomes due;
- weighted generation of three choices;
- deterministic random seed/state;
- paid skip price;
- resolving choose/skip;
- scheduling the next offer.

The three offered item IDs and offer deadline/state are saved so reloading cannot reroll choices for free.

The Shop and random offer system may both reference the same `FertilizerDefinition`; they must not duplicate fertilizer mechanics.

## 25. Inventory

`InventoryService` is the only writer for inventory operations.

Prefer typed item-state records rather than a generic unvalidated dictionary when an item carries lineage/genetics.

Simple stackable items may use counts.

Genetic items must be instances:

- seeds;
- cuttings;
- hybrid fruit if its genetics matter.

Two visually identical seeds may not be stackable if their genomes differ.

## 26. Presentation architecture

Presentation scenes should be split into small controllers/views.

Suggested major views:

- `MainGameView`
- `PlantView`
- `WindowView`
- `PlantSenseView`
- `ToolPanelView`
- `FertilizerOfferView`
- `PotSelectorView`
- `InventoryView`
- `ShopView`

Each view receives read-only presentation data and emits user intent.

Avoid a 1,000-line `main.gd` coordinator. If a controller approaches 250–300 lines, split responsibility before the 350-line hard limit.

## 27. Plant visual generation

Use a deterministic `PlantVisualAssembler` in Presentation.

Inputs:

- species visual definition;
- three branch states;
- phenotype descriptor;
- plant size/health;
- visual seeds.

It selects/places reusable modules such as:

- trunk/branch sprites;
- leaves;
- flowers;
- fruit;
- thorns;
- hooks;
- traps;
- fungi;
- glow/effect overlays.

The assembler does not decide which mutation exists. It only renders the descriptor produced from domain state.

## 28. Phenotype derivation

Use one `PhenotypeResolver` to translate mutation/genome state into a renderable descriptor.

This prevents three separate systems from interpreting “Carnivore level 4” differently.

A descriptor can contain normalized visual instructions such as:

```text
leaf_shape_id
leaf_scale
leaf_color_params
thorn_density
thorn_scale
flower_variant_id
fruit_variant_id
fungal_density
glow_amount
branch_deformation_seed
```

The resolver should be deterministic for the same specimen state and seeds.

## 29. Persistence

Use a versioned save DTO/schema separate from domain classes.

Recommended root fields:

```text
schema_version
saved_at_utc
player
pots
plants
inventory
offers
rng_state
```

Persistence flow:

`GameState -> SaveMapper -> SaveDTO -> SaveRepository`

Load flow:

`SaveRepository -> migrations -> SaveDTO -> SaveMapper -> GameState`

Do not serialize Godot scene trees as the primary save format.

## 30. Save migrations

Every released schema change that can break old saves requires a migration.

Example:

```text
v1 -> v2 -> v3 -> current
```

Never maintain parallel loading branches throughout gameplay code.

Migration code owns historical compatibility; current domain code sees only current state.

Keep each migration in its own small file if necessary to respect the 350-line rule.

## 31. Save safety

Infrastructure should support:

- atomic write via temporary file + replace where platform permits;
- last-known-good backup;
- schema validation;
- corruption fallback;
- explicit save after economy/genetic milestones;
- debounced save after frequent low-risk state changes.

Web/platform adapters may implement storage differently, but `SaveRepository` interface remains stable.

## 32. Platform abstraction

Domain and Application must not import Yandex SDK code.

Define small interfaces for platform capabilities, for example:

- `IPlatformStorage`
- `IAdsService`
- `IAnalyticsService`
- `ILeaderboardService` if later needed;
- `IPlatformLifecycle`

Adapters:

- `YandexPlatformAdapter`
- `AndroidPlatformAdapter`
- `IOSPlatformAdapter`
- local/dev adapter.

This makes mobile expansion an adapter task rather than a gameplay rewrite.

## 33. Analytics boundary

Analytics observes application/domain events.

Do not sprinkle vendor analytics calls inside mutation, economy or plant classes.

Example event mapping:

`PlantMutated -> analytics.track("plant_mutated", sanitized_payload)`

Analytics failures must never block gameplay transactions.

## 34. Testing strategy

Domain logic should be testable without loading scenes.

Priority unit tests:

- comfort boundaries;
- growth slows with size;
- prolonged critical state can kill;
- adult plant can continue living;
- fertilizer hidden effects resolve deterministically;
- mutation stacking has no artificial cap;
- cutting any of three slots works;
- graft requires a free slot;
- seed snapshot is immutable after creation;
- cutting preserves donor snapshot then evolves independently;
- hybrid fruit uses host + branch ancestry;
- selling clears pot and credits exactly once;
- offer reload does not reroll choices.

Integration tests should cover save/load and migration round trips.

## 35. Deterministic RNG

Gameplay randomness must be owned by an injectable RNG service/stream.

Use separate named streams/seeds when useful, for example:

- fertilizer offers;
- mutation resolution;
- genetics;
- phenotype cosmetics.

Cosmetic randomness that does not affect gameplay may be freer, but a saved specimen's appearance should remain stable after reload.

## 36. Duplication prevention rules

Before adding a function, ask which service owns that rule.

Examples:

- “Is plant comfortable?” -> `ComfortEvaluator`
- “How fast does it grow?” -> `PlantSimulationService` + growth definition
- “What mutation occurs?” -> `MutationEngine`
- “What does this seed inherit?” -> `GeneticsService`
- “Can I graft here?” -> `GraftingService`
- “What is this plant worth?” -> `PlantValuationService`
- “How much does skip cost?” -> `FertilizerOfferService` + offer balance

If another caller needs the same answer, call the owner; do not copy the formula.

## 37. Rule placement hierarchy

Use this hierarchy when deciding where code/data belongs:

1. authored content value -> Definition/Resource;
2. universal gameplay calculation -> Domain service;
3. orchestration of one player action -> Application use case/command handler;
4. persisted mutable fact -> Runtime state;
5. storage/SDK/file concern -> Infrastructure/Platform;
6. rendering/input/animation -> Presentation.

If a rule appears in two layers, the outer layer should delegate to the inner owner instead of reproducing it.

## 38. Error handling

Domain commands should return explicit success/failure results for expected invalid actions.

Examples:

- pot occupied;
- graft slot occupied;
- insufficient money;
- plant dead;
- branch missing;
- inventory item missing.

Expected gameplay rejection is not an exception.

Unexpected invariant violations should fail loudly in development and be captured by diagnostics in production where possible.

## 39. Performance rules for Web/mobile

- Avoid per-node `_process()` on every plant part.
- Simulate active plants centrally at controlled intervals.
- Visual animation can run per frame; gameplay simulation does not need to.
- Pool frequent transient VFX if profiling shows allocation pressure.
- Keep mutation state compact.
- Use deterministic reconstruction for visuals rather than serializing large generated trees.
- Load content registries once and reuse definitions.
- Profile browser memory before increasing simultaneous pot count.

## 40. Update cadence

Prefer a central simulation scheduler.

Example responsibilities:

- active visible plant can receive frequent presentation updates;
- domain moisture/growth may update at a lower fixed cadence;
- background pots may update less frequently or analytically;
- offline elapsed time is applied in batches.

All paths must use the same formulas so foreground and offline results do not diverge materially.

## 41. Localization

All player-visible text uses localization keys from the start.

Do not use localized display strings as gameplay IDs.

Custom player plant names are raw user content and are stored separately from localization.

This keeps Web RU/EN and future mobile localization independent from domain rules.

## 42. Security and client authority

GrowWeird is initially a client game, so local state is not inherently trustworthy for competitive systems.

Do not architect core gameplay around a fake assumption that client saves are secure.

If leaderboards, trading or competitive economy are added later, isolate server-authoritative validation behind platform/backend services rather than infecting current domain rules with ad-hoc anti-cheat checks.

## 43. Recommended first implementation slice

Build only enough architecture to prove the boundaries:

1. `PlantSpeciesDefinition` + registry.
2. `GameState`, `PotState`, `PlantState`, three branch slots.
3. `GameClock` + `PlantSimulationService`.
4. `ComfortEvaluator`.
5. one `WaterPlantCommand` and one light/window command path.
6. minimal `PlantView` + Plant Sense read model.
7. `FertilizerDefinition` + `MutationEngine`.
8. one visible mutation through `PhenotypeResolver`.
9. versioned save round trip.

Do not implement every future interface before it is used. Preserve the boundaries, then add concrete services incrementally.

## 44. Architecture definition of done for new features

A feature is not complete until:

- its source-of-truth owner is clear;
- no formula/rule is duplicated;
- persisted data has stable IDs;
- save migration impact is considered;
- domain behavior is testable without UI;
- platform-specific calls are isolated;
- files remain below 350 lines;
- UI only renders/dispatches intent;
- deterministic gameplay randomness is seeded;
- any new content schema is validated by its registry.

## 45. Decisions intentionally left configurable

Architecture must support these without a rewrite:

- offline growth enabled/disabled/capped;
- offline permanent death enabled/disabled;
- native branch regrowth policy;
- fertilizer offer cadence;
- skip-price curve;
- mutation trigger thresholds;
- hybrid-fruit genetics timing;
- branch-local vs root-wide mutation definitions;
- market demand modifiers;
- maximum number of owned pots imposed by balance/device limits.

These are balance/product rules, not structural assumptions.
