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
- Left-center: Water and Prune; Water opens Watering Can / Sprayer.
- Right: vertical inventory for fruit, seeds, fertilizer, cuttings and later item types.
- Bottom-center: periodic three-item fertilizer offer.
- Below offers: pot selector; switching pot switches that pot's window/light state.
- Start: 1 pot with a sprout + 1 empty pot.
- Extra pots come from Shop. Decorative rooms/pots are out of current scope.

## 5. Core loop
1. Inspect plant condition.
2. Adjust water, light and window state.
3. Let the plant grow in real time.
4. Resolve fertilizer offer: choose one item or pay to skip.
5. Observe growth/mutation.
6. Harvest fruit and/or prune branches.
7. Sell, recycle, root, seed or graft acquired material.
8. Spend money on pots, plants, sprouts, seeds and targeted fertilizer.
9. Repeat with increasingly unusual lineages.

## 6. Plant structure
A plant has a persistent root/base and exactly three possible visible branch slots: `left`, `center`, `right`. A mature default silhouette is one central branch/trunk plus one branch on each side.
- Any branch may be cut, including `center`.
- Cutting removes that branch, creates a cutting item and frees that exact slot.
- Cutting a branch does not automatically kill the root/base.
- Grafting is possible only into a free slot.
- Different slots can therefore contain different ancestry.
- Native regrowth of a freed slot is an open balance decision; the system must support either policy.

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
This gives two layers: beginners fix the large current problem; experienced players scan all three icons.

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

## 11. Real-time growth
Plants grow in real time. Small plants grow faster; growth progressively slows as size increases. Care modifies speed:
- comfortable: normal/full progression;
- moderate mismatch: slower growth;
- severe mismatch: growth nearly stops;
- prolonged critical stress: health declines and death becomes possible.
A mature living plant can live indefinitely. Maturity is not an ending; it enables continued mutations, fruit, pruning and grafting.

## 12. Death
Plants can die permanently. Death should require sustained critical conditions rather than one missed click. On death: growth, fruiting and mutation stop. The pot remains occupied until the dead plant is cleared/processed by the chosen rule. Offline-death behavior is still an open product decision.

## 13. Fertilizer events
Periodically three choices appear. Examples: banana peel, salt, dead mouse, insects, worms, humus, rotten fruit, mushrooms, nitrate/mineral fertilizer, radioactive material, unknown chemicals.
Player must either choose exactly one offer or pay money to skip the whole event. Without skips, continued play keeps applying mutation pressure.
Fertilizer properties are **not shown**. There is currently no encyclopedia; learning comes from repeated experiments and visual outcomes.

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
Prune mode highlights the three cuttable branches. Clicking one removes that exact branch and produces a cutting.
A cutting can be planted in an empty pot, grafted into another plant's free slot, processed into fertilizer or discarded; selling can be added later if balance needs it.
A planted cutting starts from donor inherited state but is not permanently identical: future fertilizer events mutate it independently.

## 17. Grafting
A graft occupies one free branch slot and retains donor ancestry/visible identity while living on the host. No graft creates a fourth slot.
A grafted branch produces **hybrid fruit** using host/root and donor-branch ancestry. The plant may therefore become a mosaic of lineages.

## 18. Fruit and seeds
Fruit can be sold, processed into fertilizer, or produce/convert into seeds according to species rules.
When a seed item appears, it receives a snapshot of **all inheritable mutations relevant to its source lineage at that moment**. Later parent mutations never change an existing seed.
Seeds have no rarity tier. Their value comes from inherited state/ancestry. A seed can be planted, sold or processed into fertilizer.

## 19. Selling plants
Selling the plant itself is the primary way to free an occupied pot. Price must not equal simple fruit output. Candidate influences: base species, age/size, health, mutation depth, rare synergies, graft complexity, fruiting value and later market demand.
A non-fruiting thorn-covered monster may be worth more than a productive conventional tree if its combination is unusual enough.

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
Free random offers create experimentation; Shop purchases create control.

## 22. Content generation strategy
Practically endless variety comes from combining reusable gameplay/visual traits, not drawing every full plant variant. A specimen may combine species body style, branch shapes, leaf shapes/colors, flowers, fruit, thorns/hooks, fungi, glow/effects, graft visuals and procedural placement/scale parameters.

## 23. Asset plan — MVP
### Environment
Room/table background; window frame/glass; open/closed window; blinds/curtains; sunlight and shadow overlays.
### Pot and soil
One functional base pot; separate soil layer; 5+ moisture states.
### Plant modules
Seed/sprout stages; root/base; center/left/right branch modules; several leaf shapes; flowers; fruit anchors/sprites.
### Mutation modules
Small/large thorns; hooks; serrated/sticky/trap leaves; carnivorous flower/trap parts; fungi/spores; glow; mutated fruit; color/pattern masks.
### Tools/UI
Watering can; sprayer; pruning shears; Shop/money; water/light/air indicators; fertilizer cards; pot selector; inventory frames; sell/recycle/plant/graft actions.
### VFX/audio
Water drops, mist, soil transition, growth, pruning particles, mutation reveal, fruit pickup, coins, spores/glow; sounds for watering, spraying, pruning, window/blinds, planting, harvest, mutation, selling and room ambience.

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
17. Shop/content expansion.
18. Save/load, balancing, analytics and platform integration.
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
- Does growth/health continue while closed, and for how long?
- Can a freed native branch slot regrow naturally?
- How often do fertilizer offers appear by life stage?
- Does repeated paid skip become more expensive?
- Exact irreversible-death thresholds and dead-plant salvage value?
- When are hybrid-fruit genetics resolved: flower, fruit creation or harvest?
- How strongly does ancestry affect sale price without enabling exploits?
- Which mutations are branch-local versus whole-plant/root-level?
- Target time to the first major visible mutation in a new session?
