# Systems — IFL meta + in-match

## Design pillars

1. **Football strategy first** — play calls, downs, zones, matchups unchanged in spirit.
2. **Unique instances, shared templates** — archetypes, traits, species templates, coordinators are global catalogs; each `player_id` is one franchise’s athlete.
3. **Readable builds** — opponents infer threats from position, archetype, traits, species silhouette, and behavior.
4. **Soft synergies** — bonuses stay small; no mandatory “exact six” meta teams.

## Player identity stack

Position → Archetype(s) → Trait(s) → Species → Visual profile → In-game behavior → Franchise reputation.

## Species (summary)

Full balance numbers: [Balancing.md](Balancing.md). Generation rules: [Player_Generation.md](Player_Generation.md).

Species influence:

- Stat **roll weights** (small starting tendencies)
- **Training efficiency** (primary long-term identity)
- Trait and archetype **likelihood**
- Visual silhouette and synergy tags

Species do **not**: hard-lock positions, large flat starting stat bonuses, magic, or non-football mechanics.

## Archetypes and traits (shared catalogs)

Examples: Deep Threat WR, Ball Hawk CB, Power Back RB, Gunslinger QB. Traits are readable keywords with small resolver/UI effects (see [Properties.md](Properties.md)).

## Coordinators and play style

OC/DC schemes modify play weights, card access, and synergy tags. Fit between archetype, coordinator, and species culture is **soft**, not required.

## Synergy types (all capped — see Balancing.md)

| Type | Example |
|------|---------|
| Species | Multiple Velox-type athletes in secondary → tiny coverage synergy |
| Archetype | Deep Threat + Gunslinger → small vertical bias |
| Coordinator | Blitz DC + Pass Rush DL traits |
| Position group | Multiple Power archetypes on OL/RB → run crease nudge |
| Team identity | Homeworld culture tag + roster composition |

Avoid hero-collector “exact lineup” meta requirements.

## In-match systems

Momentum, cards, play selection, whole-play and tick sim — see [Implementation_Plan.md](Implementation_Plan.md). Cards modify **this match**; they do not imply shared global player ownership.

## Scouting and recruitment

Pre-game reports highlight archetype/species/outlier threats. Recruitment pulls from **regional pools** — see [Progression.md](Progression.md).

## Related docs

- [Data_Architecture.md](Data_Architecture.md)
- [Gameplay_Summary.md](Gameplay_Summary.md)
