# Item balance and nutrition v5

This document is the gameplay source of truth for found items, fertilizer economy, nutrition capacity and journal discovery. The complete per-item values for both 8x8 atlases are stored in `content/config/item_balance_v5.json` and are loaded by `ItemBalanceCatalog`.

## Canonical mutation families

Fruit: green and normal ripe are base states. Mutations are spiked, carnivorous, poisonous, cybernetic, crystal, energetic, cosmic, magical, golden, unique dragon and unique lunar.

Flowers: normal, spiked, carnivorous, poisonous, cybernetic, magical, cosmic, golden, crystal.

Leaves: normal, spiked, carnivorous, poisonous, cybernetic, magical, cosmic, golden, dragon.

Bark: normal, spiked, stone, metallic, magical, dragon scale, golden.

Old ice-flower effects are represented by the crystal family. Old honeycomb-fruit effects are represented by the energetic family.

## Missing bark and unique lunar sources

- Stone bark: Eggshell and Walnut.
- Metallic bark: Tin Can and Scrap Metal.
- Magical bark: Spirit in a Bottle and Spellbook.
- Dragon-scale bark: Plastic Dinosaur and Dragon Egg.
- Golden bark: Golden Treasure and Golden Slime.
- Unique lunar fruit: Moonstones (50%) and Meteorite (35%; on failure a separate 35% cosmic-fruit check).

## Rarity normalization

Direct mutation items use these design targets. Multi-organ items use the lower drop target for the same rarity.

| Rarity | Drop, one organ | Drop, multi organ | Proc | Base sell |
| --- | ---: | ---: | ---: | ---: |
| Common | 50% | 45% | 10% | 5 |
| Uncommon | 25% | 20% | 25% | 10 |
| Rare | 8% | 6% | 35% | 25 |
| Epic | 3% | 2% | 50% | 50 |
| Legendary | 1% | 1% | 100% | 100 |

Special exceptions are kept in the canonical JSON: Golden Slime 0.5%/120, Dragon Egg 0.5%/120, Magic Portal 0.3%/150. Fertile Soil Bag and Processed Fertilizer do not randomly drop and cannot be sold.

`drop_chance_percent` is used as the relative weight in random item offers. Zero-drop entries are excluded from random offers.

## Dynamic nutrition capacity

| Plant state | Base maximum nutrition |
| --- | ---: |
| Seed | 20 |
| Sprout | 40 |
| Tree immediately after sprout | 60 |
| Formed tree with central branch | 70 |
| One additional branch | 80 |
| Two additional branches | 90 |

Each grown side branch adds 10 capacity. Removing that branch removes 10 capacity.

Flowering temporarily adds 15 to the current capacity. The bonus is removed when flowering ends. Fruiting temporarily adds 25 regardless of fruit count. The fruit bonus is removed after fruits are harvested or converted into seeds.

Whenever capacity decreases, current nutrition must be clamped to the new maximum; nutrition cannot remain hidden above capacity.

## Store fertilizers

A stage-matched store fertilizer restores 50% of the current dynamic maximum nutrition. The integer gain is rounded upward.

A store fertilizer used on the wrong stage behaves exactly like ordinary processed fertilizer for the current stage.

Processed fertilizer base gains:

| Stage | Gain |
| --- | ---: |
| Seed | 10 |
| Sprout | 9 |
| Tree after sprout | 8 |
| Branch/tree formation | 7 |
| Flowering | 6 |
| Fruiting | 5 |

Decoration upgrades may add extra processed-fertilizer nutrition, for example +1. The same bonus applies to a wrong-stage store fertilizer because it is treated as processed fertilizer.

Legacy ordinary misc items that predate the v5 balance table and do not define an explicit Food value retain their old +2 nutrition fallback. Atlas v5 items always use their explicit balance value, including zero.

### Initial store fertilizer prices

| Stage fertilizer | Price |
| --- | ---: |
| Seed | 12 |
| Sprout | 20 |
| Tree growth | 30 |
| Branch formation | 40 |
| Flowering | 50 |
| Fruiting | 60 |

## Planting shop prices

Base genetic-item prices are not stored as 24 separate values. Runtime uses one formula:

`price = base_price_by_type × rarity_multiplier`

Base prices:

| Product | Base price |
| --- | ---: |
| Seed | 20 |
| Sprout | 60 |
| Plantable cutting | 110 |
| Empty normal pot | 130 |

Rarity multipliers:

| Rarity | UI color | Multiplier | Seed | Sprout | Cutting |
| --- | --- | ---: | ---: | ---: | ---: |
| Common | green | ×1.0 | 20 | 60 | 110 |
| Uncommon | turquoise | ×1.5 | 30 | 90 | 165 |
| Rare | blue | ×2.0 | 40 | 120 | 220 |
| Epic | purple | ×3.0 | 60 | 180 | 330 |
| Legendary | orange | ×4.5 | 90 | 270 | 495 |
| Golden | gold | ×6.0 | 120 | 360 | 660 |
| Lunar | pink | ×7.5 | 150 | 450 | 825 |
| Unique | red | ×9.0 | 180 | 540 | 990 |

Rarity order is `common < uncommon < rare < epic < legendary < golden < lunar < unique`. When genetic material is combined, the highest inherited rarity wins. Rarity is stored on genome snapshots and plants so fruit -> seed, seed -> plant and plant -> cutting keep the same rarity tier.

A sprout supplied together with its own normal pot therefore costs its rarity-adjusted sprout price plus 130 for the pot. Pot price itself is not multiplied by plant rarity.

Sale values for seeds and cuttings derive from the same rarity-adjusted full price and then apply the existing sale multiplier from `GameRules`; the 24 rarity/type prices are never duplicated in code.

## Per-item canonical data

Every atlas position has a row in `content/config/item_balance_v5.json` containing:

- stable runtime ID and atlas item ID;
- Russian display name;
- direct nutrition amount;
- processed-fertilizer yield from grinding;
- configured drop percentage;
- sell price;
- rarity;
- effect target;
- final mutation/passive/effect description.

Runtime systems must read those values instead of maintaining duplicate hard-coded economy tables.

## Journal discovery

An item is considered studied only after it has been successfully applied/used at least once. Owning, selling or merely seeing an item does not make it studied.

Before first use it belongs to the unknown group and its properties are hidden. After first use its journal card shows the canonical item name, rarity, direct nutrition, grinding yield, drop percentage, sale price, mutation/passive effect and use count.

Journal data is derived from the same canonical balance JSON used by economy and nutrition systems, so displayed values must match gameplay values.
