# GrowWeird — Game Design
> Living design document. Gameplay/UX/content source of truth. Technical rules live only in `ARCHITECTURE.md`.

## 1. Product thesis
GrowWeird is a mouse-first plant-growing game about care, experimentation and endlessly mutating plants. The player starts with one small sprout and one empty pot, manages water/light/air, uses normal and absurd fertilizers, cuts branches, roots cuttings, grafts other lineages, harvests fruit and creates seeds.

**Core fantasy: Grow something nobody else has grown.**
There is no ideal final specimen. Any living plant can continue mutating indefinitely unless the player pays to skip a fertilizer event.

## 2. Core pillars
1. **Readable care** — understand problems without spreadsheets or visible percentages.
2. **Visible growth** — meaningful actions eventually change the specimen on screen.
3. **Experimental mutation** — fertilizer properties are hidden and learned by use.
4. **Ownership** — naming, pruning, cloning and grafting make plants personal.
5. **Endless variation** — unusual combinations matter more than one linear best build.
6. **Dark humor** — dead mice, insects, radiation, rot and absurd biology are valid content.

## 3. Platforms and input
- Initial target: Yandex Games / Web.
- Future targets: Android and iOS.
- Primary desktop input: mouse only.
- Every gameplay action must map cleanly from pointer click to mobile tap later.

## 4. Main screen
- Center: current pot and plant.
- Background: interactive window, blinds/curtains and lighting.
- Top-right: Shop; money immediately to its left.
- Left-center: Water and Prune; Water exposes Watering Can / Sprayer.
- Right: vertical inventory for fruit, seeds, fertilizer, cuttings and later item types.
- Bottom-center: periodic three-item fertilizer offer.
- Below offers: pot selector; switching pot switches that pot's environment.
- Start: 1 pot with a sprout + 1 empty pot.
- Extra pots come from Shop. Decorative rooms/pots are out of current scope.

## 5. Core loop
1. Inspect plant condition.
2. Adjust water, light and window state.
3. Let the plant grow in real time.
4. Resolve fertilizer offer: choose one item or pay to skip.
5. Observe growth/mutation.
6. Harvest fruit and/or prune branches.
7. Plant, graft, seed, sell or compost acquired genetic material.
8. Spend money on pots, plants, sprouts, seeds and targeted fertilizer.
9. Repeat with increasingly unusual lineages.

## 6. Plant structure and native regrowth
A plant has a persistent root/base and exactly three possible visible branch slots: `left`, `center`, `right`. A mature default silhouette is one central branch/trunk plus one branch on each side.
- Any branch may be cut, including `center`.
- Cutting removes that branch, creates a cutting item and frees that exact slot.
- Cutting a branch does not automatically kill the root/base.
- Grafting is possible only into a free slot; no operation creates a fourth branch.
- Different slots can therefore contain different ancestry.
- A species may enable natural native-branch regrowth for freed slots.
- Native regrowth begins only when that plant is adult, sufficiently healthy and sufficiently comfortable according to its species tuning.
- Regrowth happens in the exact empty slot and appears first as a visible bud while the slot is still mechanically empty.
- The restored branch is a clean native branch of the host species. It does not recreate branch-local traits/mutations that belonged to the removed branch.
- If a graft occupies the slot before native regrowth completes, pending native regrowth for that slot is cancelled.

## 7. Care model
Each species defines internal preferences for:
- soil moisture;
- light intensity/type;
- air/window state;
- optional leaf-moisture preference for sprayer-sensitive species.
Different plants intentionally conflict: one wants lots of water, another little; one direct sun, another diffused light; one open window, another closed. Exact numeric values stay hidden from normal UI.

## 8. Plant Sense — readable condition UI
The main indicator is a semicircle above the plant:
`too little <- bad / warning / good / warning / bad -> too much`
The center is the comfort zone. The gauge shows the **single worst current need**, not generic health.
Examples:
- 💧 + needle left = too dry;
- 💧 + needle right = too wet;
- ☀ + needle right = too much light;
- air icon + needle left = too little air.
Three small status icons show water/light/air as only `good`, `warning`, `bad`. Hover/tap may show short text such as “Too much light”; percentages remain hidden.
Plant Sense is for living plants. A dead plant no longer has an actionable care reading.

## 9. Watering
### Watering can
Each click adds a meaningful water portion. Soil is primary feedback: pale/sandy → dry → normal → dark/wet → saturated. Moisture decays continuously in real time.
### Sprayer
The sprayer adds a small amount of soil moisture plus temporary leaf moisture. Species may like, tolerate or dislike spraying; it is not just a slower watering can.

## 10. Light and window
Window controls are manipulated directly in the scene, not through a settings panel. Initial light states:
1. closed blinds/curtains — minimal light;
2. translucent blinds — diffused light;
3. blinds open — bright light;
4. direct-sun condition — strongest/direct light when available.
Window itself is open/closed and affects air preference. Temperature is excluded from the first version. Each pot owns its own environment so incompatible species can coexist.

## 11. Real-time growth and life stages
Plants grow in real time. Small plants grow faster; growth progressively slows as size increases. Care modifies speed:
- comfortable: normal/full progression;
- moderate mismatch: slower growth;
- severe mismatch: growth nearly stops;
- prolonged critical stress: health declines and death becomes possible.

Every species moves continuously through three derived life stages:
1. **Sprout** — small, fastest growth and limited silhouette.
2. **Juvenile** — established plant, expanding branch geometry.
3. **Adult** — mature specimen capable of species-configured native regrowth and normal mature systems.

Stage boundaries are species-specific and are derived from growth progress; they are not separate collectible objects and do not reset genetics. An adult can live indefinitely under adequate care. Adulthood is not an ending: mutation, fruiting, pruning, grafting and future generations continue forever.

Species should differ in silhouette as well as color/care. Height, side spread/lift and leaf scale may vary by species while branch-slot legality remains identical.

## 12. Health, wilting and permanent death
Health changes gradually from care quality rather than from age. Player-facing condition is qualitative:
`Healthy → Stressed → Wilted → Critical → Dead`.
Normal UI does not expose raw health percentages.

Loss of vitality must be visible before death: leaves become fewer/smaller, colors dry/desaturate, branches sag, glow/flowers/fungi lose vitality and fruit looks less healthy. These visuals communicate state; they do not own the underlying thresholds.

Plants can die permanently after sustained critical conditions. On death:
- growth, native regrowth, fruiting and mutation stop;
- prune/graft/harvest care interactions stop;
- Plant Sense hides because the condition is no longer recoverable;
- the dead specimen remains in the pot until sold for reduced salvage value or composted;
- either final processing action frees the pot.

A mature plant has no natural lifespan limit. Good care can keep it alive indefinitely.
Offline death is a balance policy separate from foreground death. Current default allows offline progression but prevents a living specimen from crossing into permanent death while the game is closed; this policy can be tuned without changing the lifecycle model.

## 13. Fertilizer events
Periodically three choices appear. Examples: banana peel, salt, dead mouse, insects, worms, humus, rotten fruit, mushrooms, nitrate/mineral fertilizer, radioactive material, unknown chemicals.
Player must either choose exactly one offer or pay money to skip the whole event. Without skips, continued play keeps applying mutation pressure.
Fertilizer properties are **not shown**. There is currently no encyclopedia; learning comes from repeated experiments and visual outcomes.

`Compost Mix` is the common fertilizer output of recycling genetic material. It uses the same inventory/fertilizer application path as purchased or offered fertilizer; recycling is not a separate care mechanic.

## 14. Mutation model
Mutation is effectively unbounded. Do not model complete plants as a finite catalog like “Spiky Red Apple Tree”. A specimen is a combination of inherited/acquired traits and expression parameters.
Initial conceptual mutation families:
- **predatory/animal-organic** — thorns, hooks, serrated/sticky leaves, traps, toxic fruit, foul smell, carnivorous flowers;
- **floral/plant-organic** — more flowers, unusual petals, larger/stranger fruit, bright coloration;
- **fungal/decay** — mushrooms, spores, mold-like surfaces, dark tissue, fungal structures;
- **chemical/radiation** — glow, pigmentation shifts, asymmetry, split structures, oversized organs;
- **structural/mineral** — dense wood, heavy structures, reinforced thorns, growth changes;
- **stabilizing/conventional** — humus/minerals mainly improve growth/stability with lower mutation pressure.
Repeated exposure may deepen an existing trait instead of only adding binary traits.

## 15. Mutation synergies
The most valuable outcomes should often be combinations:
- floral + predatory = lure flowers/traps;
- radioactive + floral = glowing flowers/fruit;
- fungal + predatory = spore-based traps;
- structural + predatory = heavy woody thorns;
- radioactive + fungal = bioluminescent fungal growth.
“Infinite mutation” means no gameplay cap on trait level/combination depth, while implementation remains compact.

## 16. Pruning and cuttings
Prune mode highlights the three cuttable existing branches. Clicking one removes that exact branch and produces a cutting.
A cutting has three meaningful uses:
- plant it in an empty pot;
- graft it into another living plant's free slot;
- sell it for a value derived from species, inherited trait depth and lineage;
- compost it into `Compost Mix`.

Planting/grafting consumes the cutting only after the operation succeeds. Selling or composting is irreversible and destroys that item snapshot. A planted cutting starts from donor inherited state but future fertilizer events mutate it independently.

On an adult plant whose species supports native regrowth, pruning also starts a potential new-growth cycle for that empty slot. Regrowth is not a free clone: the cutting preserves the removed branch snapshot, while the new host branch starts as native host tissue without that removed branch's local traits.

## 17. Grafting
A graft occupies one free branch slot and retains donor ancestry/visible identity while living on the host. No graft creates a fourth slot.
A grafted branch produces **hybrid fruit** using host/root and donor-branch ancestry. The plant may therefore become a mosaic of lineages.
Grafting into a slot takes priority over pending native regrowth and cancels that regrowth progress.

## 18. Fruit and seeds
Harvested fruit has three competing uses:
- sell for money;
- convert into a seed snapshot;
- compost into `Compost Mix`.

When a seed item appears, it receives a snapshot of **all inheritable mutations relevant to its source lineage at that moment**. Later parent mutations never change an existing seed. Seeds have no rarity tier; their value comes from species, inherited state and ancestry.

A seed can be planted, sold or composted. Selling/composting consumes the exact item. Composting intentionally destroys its genome and never creates another genetic object.

## 19. Selling and processing plants
Selling a living plant is the primary cash-out path that frees an occupied pot. Price must not equal simple fruit output. Candidate influences: base species, age/size, health, mutation depth, rare synergies, graft complexity, fruiting value and later market demand.
A non-fruiting thorn-covered monster may be worth more than a productive conventional tree if its combination is unusual enough.

A dead specimen has two final processing choices:
- sell it for reduced salvage value;
- compost the remains into `Compost Mix` based on specimen size and remaining branch biomass.

Both choices remove the specimen and free the pot. Only dead plants may use the whole-plant compost action; living plants must be sold or kept alive.

## 20. Naming
Players may give every specimen a custom name. The name belongs to the individual, not the species, and persists through save/load and future specimen-summary/sale UI.

## 21. Shop and economy
Initial shop categories: fertilizer, plants, sprouts, seeds, pots. Later: tools, automation, laboratory items.
Primary money sinks:
- additional pots;
- targeted fertilizer;
- plants/sprouts/seeds;
- fertilizer-offer skips;
- future progression/tools.

Primary material choices create opportunity cost:
- sell genetic items for immediate money;
- preserve them for planting/grafting/seeding;
- destroy them for fertilizer through composting.

Free random offers create experimentation; Shop purchases create control; recycling provides a material recovery path without preserving genetics.

## 22. Content generation strategy
Practically endless variety comes from combining reusable gameplay/visual traits, not drawing every full plant variant. A specimen may combine species body style, branch shapes, leaf shapes/colors, flowers, fruit, thorns/hooks, fungi, glow/effects, graft visuals and procedural placement/scale parameters.

## 23. Asset plan — MVP
### Environment
Room/table background; window frame/glass; open/closed window; blinds/curtains; sunlight and shadow overlays.
### Pot and soil
One functional base pot; separate soil layer; 5+ moisture states.
### Plant modules
Seed/sprout stages; root/base; center/left/right branch modules; several leaf shapes; flowers; fruit anchors/sprites; wilted/dead variants or procedural equivalents; native-regrowth buds.
### Mutation modules
Small/large thorns; hooks; serrated/sticky/trap leaves; carnivorous flower/trap parts; fungi/spores; glow; mutated fruit; color/pattern masks.
### Tools/UI
Watering can; sprayer; pruning shears; Shop/money; water/light/air indicators; fertilizer cards; pot selector; inventory frames; sell/compost/plant/graft actions.
### VFX/audio
Water drops, mist, soil transition, growth, pruning particles, mutation reveal, fruit pickup, coins, spores/glow; sounds for watering, spraying, pruning, window/blinds, planting, harvest, mutation, selling, composting and room ambience.

## 24. MVP production order
1. One plant/pot + real-time moisture decay.
2. Watering + visible soil moisture.
3. Window/light states.
4. Plant Sense.
5. Growth curve: small fast, large slow.
6. Health, stress and permanent death.
7. Three-choice fertilizer event + paid skip.
8. First mutation family + visible mutation.
9. Fruit, inventory and money.
10. Second pot + per-pot environment.
11. Plant selling + pot freeing.
12. Seeds + mutation snapshot inheritance.
13. Pruning all three slots.
14. Cuttings and planting cuttings.
15. Grafting into free slots.
16. Hybrid fruit.
17. Species lifecycle/regrowth and stronger species silhouettes.
18. Complete item sell/compost/resource loop.
19. Shop/content/progression expansion.
20. Save/load, balancing, onboarding and game-feel pass.
21. Platform-specific production integration and release work.
A useful vertical slice exists once steps 1–8 are fun without the rest.

## 25. Reference games
References are for studying interaction/progression, not copying features:
- **Plant Tycoon** — genetics and rare specimen discovery.
- **Viridi** — calm care feedback and readable condition.
- **Botany Manor** — species-specific environmental needs.
- **My Tiny Garden** — compact pot/water/fertilize/prune loop.
- **Strange Horticulture** — strange-botany tone/presentation.
- **Grow a Garden** — readable seed → grow → harvest → sell loop.
GrowWeird differentiates through hidden fertilizer experimentation, unbounded visible mutation, three-slot pruning/grafting and lineage inheritance.

## 26. Explicit non-goals now
- no plant encyclopedia;
- no seed rarity tiers;
- no decorative room system;
- no decorative pot collection;
- no fixed “perfect specimen” end state;
- no visible hidden mutation numbers by default;
- no multiplayer dependency for core gameplay.

## 27. Open design decisions
These are balance/product questions, not reasons to redesign architecture:
- exact offline catch-up horizon and whether offline permanent death should remain disabled for release;
- exact native-regrowth timings/health/comfort requirements per species;
- how often fertilizer offers should vary by life stage, if at all;
- whether repeated paid skip becomes more expensive;
- exact sale-vs-compost balance and recycling yields after economy playtesting;
- how strongly ancestry affects sale price without enabling exploits;
- which future mutations are branch-local versus whole-plant/root-level;
- target time to the first major visible mutation in a new session;
- whether regrown native branches may later inherit root-wide mutations beyond current branch-local rules.
