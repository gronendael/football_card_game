# Data architecture

## Principles

- **Data-driven**: catalogs in JSON; runtime instances generated or loaded per franchise/save.
- **Unique `player_id`** per generated athlete (UUID or franchise-scoped id).
- **Templates ≠ instances**: species, archetype, and trait definitions are shared; stats and history are per player.

## Stat scale

All player core stats are **integers 1–10**. See [Balancing.md](Balancing.md) for tuning philosophy.

## Static catalogs (target)

| File | Contents |
|------|----------|
| `data/species.json` | Templates: roll weights, training affinities, synergy tags, visual keys |
| `data/archetypes.json` | Per-position archetypes, stat biases, tags |
| `data/traits.json` | Trait effects (small), acquisition weights |
| `data/coaches.json` | Coordinators (existing) |
| `data/plays.json`, `data/formations.json` | Play/formation catalogs (existing) |
| `data/synergy_rules.json` (optional) | Rule definitions with caps |

## Player instance schema (target)

```
player_id, franchise_id, species_id,
archetype_ids[], trait_ids[],
first_name, last_name, age, jersey_number,
homeworld, origin_region, academy_id (optional),
stats: { speed..kick_accuracy }   // all 1-10 ints
development: { training_affinities, growth_log[] },
visual_profile: { silhouette_id, palette_id },
career: { games_played, awards[] }
```

## Generation pipeline

1. Roll species template → apply **weight maps** (not flat bonuses).
2. Roll primary archetype (+ rare secondary/hybrid chance).
3. Roll traits from species-weighted pools.
4. Roll stats within archetype + species weights; clamp **1–10**.
5. Assign name/visual from species + franchise locale tables.
6. Persist instance to franchise roster store.

Detail: [Player_Generation.md](Player_Generation.md).

## Prototype state

- **`data/species.json`** — four species templates (`sp_velox`, `sp_gravik`, `sp_cerebron`, `sp_durant`) with roll/training weight metadata (not applied in sim yet). Loaded by `SpeciesCatalog`.
- **`data/players.json`** — static legacy roster (placeholder human names, franchise `team`, **`species_id`**, **1–10** stats). `PlayerData` assigns a default species if `species_id` is missing. Migration: procedural generation per franchise when generation ships.

## Synergy rules (optional)

Rule types: `species_count`, `archetype_pair`, `coordinator_tag`, `position_group`, `team_culture`. Each rule: `cap`, `effect` (small modifier id). Enforcement: [Balancing.md](Balancing.md).

## Resolver integration

`PlayerStatView` reads final **1–10** stats; species/trait/synergy modifiers apply as **small deltas or probability shifts**, logged in play calc when relevant.

## Related docs

- [Properties.md](Properties.md) — field dictionary
- [Systems.md](Systems.md)
