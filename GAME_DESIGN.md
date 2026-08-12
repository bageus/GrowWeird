# GrowWeird — Game Design

> Status: living design document.  
> Scope: gameplay, UX, progression, content rules and MVP.  
> Technical implementation rules live only in `ARCHITECTURE.md`.

## 1. Product thesis

GrowWeird is a mouse-first plant-growing game about care, experimentation and endlessly mutating plants.

The player starts with one small sprout and one empty pot. Plants need the right amount of water, light and air. The player grows them in real time, fertilizes them with normal and absurd materials, cuts branches, roots cuttings, grafts branches from other plants, harvests fruit and creates seeds.

The central fantasy is not “build the perfect garden”. It is:

**Grow something nobody else has grown.**

There is no ideal final specimen. Any living plant can continue mutating indefinitely unless the player pays to skip a fertilizer event.

## 2. Core pillars

1. **Readable care** — the player should understand what a plant dislikes without reading spreadsheets or numeric stats.
2. **Visible growth** — every meaningful action should eventually change the plant on screen.
3. **Experimental mutation** — fertilizer properties are hidden; knowledge comes from trying things.
4. **Ownership** — naming, cutting, cloning and grafting make a plant feel authored by the player.
5. **Endless variation** — value comes from unusual combinations, not from one linear “best” build.
6. **Dark humor** — dead mice, insects, radiation, rot and absurd mutations are valid content.

## 3. Target platforms and input

Initial release target: Yandex Games / Web.

Future targets: Android and iOS.

Primary desktop control: mouse only.

All gameplay actions must therefore be expressible as pointer/tap interactions so the same interaction model can later map cleanly to touch.

## 4. Main screen

The main screen is intentionally compact.

- Center: current pot and plant.
- Background: window and lighting controls.
- Top-right: Shop button.
- Immediately left of Shop: money counter.
- Left-center: Water and Prune tools.
- Water tool opens Watering Can / Sprayer choice.
- Right side: vertical inventory for fruit, seeds, fertilizer, cuttings and future item types.
- Bottom-center: periodic choice of three fertilizer offers.
- Below fertilizer offers: pot selector.
- Switching pots switches to that pot's own window/light state.

At game start the player owns:

- 1 pot with a sprout;
- 1 empty pot.

Additional pots are bought in the Shop.

Decorative rooms and decorative pot variants are out of current scope.

## 5. Core loop

1. Inspect plant condition.
2. Adjust water, light and window state.
3. Wait for real-time growth.
4. Resolve fertilizer offers: choose one or pay to skip.
5. Observe mutations and new growth.
6. Harvest fruit and/or prune branches.
7. Sell, recycle, root, seed or graft acquired material.
8. Use money to buy pots, plants, sprouts, seeds, fertilizer and future progression items.
9. Repeat with increasingly unusual lineages.

## 6. Plant structure

A plant has a persistent root/base and up to three visible branch slots:

- `left`
- `center`
- `right`

A mature default silhouette is a central trunk/branch plus one left and one right branch.

Any of the three branches may be cut, including the center branch.

Cutting a branch:

- removes it from the plant;
- creates a cutting item;
- frees that exact branch slot;
- does not automatically kill the root/base.

Grafting is possible only into a free branch slot.

A plant can therefore contain branches with different ancestry.

Whether an empty native slot regrows automatically is an open balance decision; architecture must support both policies without changing saved data.

## 7. Care parameters

Every species has preferences for:

- soil moisture;
- light intensity/type;
- air/window state;
- optional leaf moisture preference for sprayer-sensitive plants.

Different species deliberately conflict:

- some want lots of water, some very little;
- some want direct sun, some diffused light;
- some benefit from an open window, some dislike it;
- some like spraying, some do not.

Exact numeric values are internal. The normal player-facing UI should not expose percentages.

## 8. Plant Sense — condition feedback

The main condition indicator is a semicircular gauge above the plant.

Concept:

`too little <- bad / warning / good / warning / bad -> too much`

The center is the comfort zone.

The gauge shows the **single most important current problem**, not a generic health score.

Examples:

- water icon + needle left = too dry;
- water icon + needle right = too wet;
- sun icon + needle right = too much light;
- air icon + needle left = too little air for this species.

Below or near the main gauge are three small status icons:

- water;
- light;
- air.

Each icon has only three readable states: good, warning, bad.

Hover/tap may show a short text such as “Too much light”, but numbers remain hidden.

This produces two information layers:

- beginner: fix the icon currently shown on the big gauge;
- experienced player: monitor all three compact indicators.

## 9. Watering

### Watering can

Each click applies a meaningful portion of water to soil.

The soil itself is the primary visual feedback:

- very dry: pale/sandy;
- dry: light;
- comfortable: normal;
- wet: dark;
- saturated: very dark/wet.

Moisture decays continuously in real time.

### Sprayer

The sprayer is not merely a slower watering can.

It applies:

- a small amount of soil moisture;
- a temporary leaf-moisture effect.

Species can like, tolerate or dislike spraying.

## 10. Light and window

The window is manipulated directly rather than through a separate settings panel.

Lighting states should be visually obvious. Initial target states:

1. curtains/blinds closed — minimal light;
2. translucent blinds — diffused light;
3. blinds open — bright light;
4. direct sun condition — strongest/direct light when available.

The window itself can be open or closed.

Window state affects the plant's air preference. A separate temperature simulation is intentionally excluded from the first version to avoid overloading the player.

Each pot owns its own environment state so incompatible species can coexist.

## 11. Real-time growth

Plants grow in real time.

Growth is faster while a plant is small and progressively slower as it becomes large.

Growth speed is modified by care quality:

- comfortable conditions: normal/full progression;
- moderate mismatch: slower progression;
- severe mismatch: growth may nearly stop;
- critical prolonged stress: health declines and death becomes possible.

A mature plant can live indefinitely if it remains alive.

Maturity is not an ending; it is a platform for more mutations, fruit, pruning and grafting.

## 12. Death

Plants can die permanently.

Death should be a consequence of sustained critical conditions, not a surprise caused by a single missed click.

On death:

- growth stops;
- fruit production stops;
- the specimen can no longer mutate;
- the pot remains occupied until the dead plant is cleared or processed by a future rule.

The exact offline-death policy is still an open product decision.

## 13. Fertilizer events

Periodically, three fertilizer choices appear below the plant.

Examples:

- banana peel;
- salt;
- dead mouse;
- insects;
- worms;
- humus;
- rotten fruit;
- mushrooms;
- nitrate/mineral fertilizer;
- radioactive material;
- unknown chemicals.

The player may:

- choose exactly one offered fertilizer; or
- pay money to skip the entire fertilizer event.

Skipping exists because there is no “finished” plant: without skips, continued play keeps applying mutation pressure.

Fertilizer properties are **not shown** to the player.

There is currently no encyclopedia. The player learns through repeated experimentation and visual results.

## 14. Mutation philosophy

Mutation is effectively unbounded.

Do not model the game as a finite list such as “Normal Apple Tree”, “Spiky Apple Tree”, “Spiky Red Apple Tree”. A specimen is a combination of inherited and acquired traits.

Fertilizers contribute hidden mutation tendencies. Initial conceptual families include:

- predatory / animal-organic;
- floral / fruiting / plant-organic;
- fungal / decay;
- chemical / radioactive;
- structural / mineral;
- stabilizing / conventional growth.

Typical outcomes:

### Predatory direction

- thorns;
- hooks;
- serrated leaves;
- sticky leaves;
- traps;
- toxic fruit;
- foul smell;
- carnivorous flowers.

### Floral direction

- increased flowering;
- unusual petals;
- larger or stranger fruit;
- bright coloration;
- stronger fruiting behavior.

### Fungal/decay direction

- mushrooms on trunk;
- spores;
- mold-like surfaces;
- darkened tissue;
- fungal fruit structures.

### Chemical/radiation direction

- glow;
- unusual pigmentation;
- asymmetry;
- split structures;
- oversized organs;
- bizarre combinations.

### Conventional fertilizer

Humus, normal minerals and similar inputs mostly improve growth/stability and should mutate a plant less aggressively.

## 15. Mutation combinations

The most valuable mutations should often be combinations rather than isolated traits.

Examples:

- floral + predatory = beautiful lure flowers that trap prey;
- radioactive + floral = glowing flowers or fruit;
- fungal + predatory = spore-based traps;
- structural + predatory = heavy woody thorns;
- radioactive + fungal = bioluminescent fungal growth.

Repeated exposure may deepen an existing trait rather than only adding new binary traits.

“Mutation can continue forever” means there is no gameplay cap on trait growth or combination depth.

## 16. Pruning and cuttings

Prune mode highlights cuttable branches.

Clicking a branch cuts that exact left/center/right branch and produces a cutting item.

A cutting may be:

- planted in an empty pot;
- grafted onto another plant if that plant has a free branch slot;
- processed into fertilizer;
- discarded;
- potentially sold if later balancing requires it.

A planted cutting begins from the donor's inherited state, but it is not permanently identical: future fertilizer events continue mutating it independently.

## 17. Grafting

A graft uses a free branch slot.

The grafted branch retains donor ancestry and visible identity, while continuing to live inside the host plant's environment and mutation history.

A plant may therefore be a mosaic of lineages.

A grafted branch produces **hybrid fruit**, combining host and branch ancestry according to genetics rules.

No fourth branch may be added simply because a graft exists; the three-slot structure remains the hard spatial rule.

## 18. Fruit and seeds

Fruit can be:

- sold;
- processed into fertilizer;
- converted into/generated as seeds according to the species' fruit rules.

When a seed item appears, it receives a snapshot of **all mutations relevant to its source lineage at that moment**.

Later mutations to the parent do not retroactively change existing seeds.

Seeds have no rarity tier of their own.

Their value comes from the inherited specimen state, ancestry and resulting plant potential.

A seed can be:

- planted in an empty pot;
- sold;
- processed into fertilizer.

## 19. Selling plants

The primary way to free an occupied pot is to sell the plant itself.

Plant price must not be a simple “more fruit = more money” rule.

Value is influenced by concepts such as:

- base species value;
- age/size;
- current health;
- unusual mutation depth;
- rare combinations/synergies;
- graft ancestry complexity;
- fruiting value;
- market demand if dynamic buyers are added later.

A non-fruiting thorn-covered monster may be worth far more than a productive conventional tree if its combination is sufficiently unusual.

## 20. Naming

The player may give each plant a custom name.

The name belongs to the individual specimen, not the species.

Names must persist through save/load and remain attached to the plant when it is sold/shown in any future summary UI.

## 21. Shop

Initial shop categories:

- fertilizer;
- plants;
- sprouts;
- seeds;
- pots.

Possible later categories:

- tools;
- automation;
- special laboratory items.

Decorative pots and room decoration are not planned for the current stage.

## 22. Economy goals

Money must create meaningful choices rather than only count upward.

Primary sinks:

- additional pots;
- targeted fertilizer purchases;
- plants/sprouts/seeds;
- fertilizer-offer skips;
- future tool/progression unlocks.

Free random fertilizer offers create experimentation. The Shop creates control.

## 23. Content generation strategy

The game should create variety by combining reusable visual and gameplay traits rather than drawing a unique full plant for every combination.

A specimen may combine:

- species body style;
- branch shapes;
- leaf shapes;
- colors;
- flowers;
- fruit;
- thorns/hooks;
- fungal parts;
- glow/effects;
- graft-specific branch visuals;
- procedural scale/placement parameters.

This is required for practically endless generation.

## 24. Asset plan — MVP

### Environment

- room/table background;
- window frame and glass;
- open/closed window states;
- blind/curtain layers;
- sunlight and shadow overlays.

### Pots and soil

- functional base pot;
- separate soil layer;
- 5+ soil moisture visuals.

### Plant base modules

- seed/sprout stages;
- root/base transition;
- center branch modules;
- left branch modules;
- right branch modules;
- multiple leaf shapes;
- flowers;
- fruit anchors and fruit sprites.

### Mutation modules

- small/large thorns;
- hooks;
- serrated leaves;
- sticky/trap leaves;
- carnivorous flower/trap parts;
- fungal growths;
- spores;
- glow overlays;
- mutated fruit variants;
- color/pattern masks.

### Tools and UI

- watering can;
- sprayer;
- pruning shears;
- shop/money icons;
- water/light/air indicators;
- fertilizer cards/items;
- pot selector;
- inventory item frames;
- sell/recycle/plant/graft actions.

### Feedback/VFX

- water drops;
- spray mist;
- wet-soil transition;
- leaf/branch growth;
- pruning particles;
- mutation reveal;
- fruit pickup;
- coins;
- spores/glow as needed.

### Audio

- watering;
- spraying;
- pruning;
- window/blinds;
- planting;
- fruit pickup;
- mutation event;
- selling/coins;
- light room ambience.

## 25. MVP production order

1. One plant, one pot, real-time moisture decay.
2. Watering can and visible soil moisture.
3. Window/light states.
4. Plant Sense condition UI.
5. Growth curve: small fast, large slow.
6. Health, stress and permanent death.
7. Three-choice fertilizer event + paid skip.
8. First mutation family and visible mutation.
9. Fruit, inventory and money.
10. Second pot and per-pot environment.
11. Plant selling and pot freeing.
12. Seeds with mutation snapshot inheritance.
13. Pruning all three branch slots.
14. Cuttings and planting cuttings.
15. Grafting into free slots.
16. Hybrid fruit.
17. Shop/content expansion.
18. Save/load, balancing, analytics and platform integration.

A useful vertical slice exists once steps 1–8 are fun without the rest.

## 26. Reference games

References are for studying interaction/progression, not feature copying.

- **Plant Tycoon** — plant genetics and rare specimen discovery.
- **Viridi** — calm plant-care feedback and readable visual condition.
- **Botany Manor** — learning species-specific environmental needs.
- **My Tiny Garden** — compact pot/water/fertilize/prune loop.
- **Strange Horticulture** — strange-botany tone and presentation.
- **Grow a Garden** — extremely readable seed → grow → harvest → sell loop.

GrowWeird's intended differentiation is the combination of hidden fertilizer experimentation, unbounded visible mutation, three-slot pruning/grafting and lineage inheritance.

## 27. Explicit non-goals for the current stage

- no plant encyclopedia;
- no seed rarity tiers;
- no decorative room system;
- no decorative pot collection;
- no fixed “perfect specimen” end state;
- no requirement to expose hidden mutation numbers to the player;
- no multiplayer dependency for the core game.

## 28. Open design decisions

These do not block architecture but require balancing decisions before release:

- Does growth/health continue while the game is closed, and for how long?
- Can an empty native branch slot regrow on its own, or only via explicit grafting/new growth action?
- How often do fertilizer offers appear at each life stage?
- Can paid skip cost escalate with repeated skips?
- What exact conditions cause irreversible death?
- Does a dead plant have salvage value?
- When exactly is hybrid-fruit genetics resolved: at flower creation, fruit creation or harvest?
- How much ancestry should affect plant sale price before it becomes exploitable?
- Which mutations are branch-local versus whole-plant/root-level?
- What is the first-session target duration before the first visible major mutation?
