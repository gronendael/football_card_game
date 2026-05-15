# Player generation

## Goals

- Every player feels like an **individual**, not a species clone.
- Species shapes **development probability**, not guaranteed outcomes.
- Rare builds (fast heavy-world lineman, tactical deep threat) are possible at low rates.

## Inputs

Species template, archetype template, trait pools, franchise homeworld/region, generation seed, prospect tier (draft/scout quality).

## Stat rolls (1–10)

- Start from archetype **center** + small species **weight shift** on roll tables (not +2 flat to Speed).
- Per-stat variance so two athletes of the same archetype and species differ.
- Hard cap: no starting stat above design max without explicit **elite prospect** flag.

## Archetype and trait likelihood

- Species tables: `archetype_weights`, `trait_weights` by position bucket.
- Coordinator/franchise culture (future): nudge weights only.

## Individuality levers

| Lever | Effect |
|-------|--------|
| Roll variance | Same archetype, different stat spread |
| Hybrid archetype | Low chance second tendency tag |
| Outlier trait | Rare trait outside species norm |
| Name/visual | Unique presentation |

## Anti-patterns

- Species that always spawn 9–10 in a primary stat at a position
- Position-forbidden species
- “Must have” species per meta lineup

## Persistent history

Append-only `career` events: games, awards, injury stubs (future). Used for UI lore and franchise trades—not shared global collectibles.

## Related docs

- [Data_Architecture.md](Data_Architecture.md)
- [Balancing.md](Balancing.md)
- [Systems.md](Systems.md)
