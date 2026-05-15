# Balancing — 1–10 stat scale

## Scale philosophy

All core player stats are **integers 1–10**. One point matters; +2 is a large upgrade. Progression and species effects must stay **small** (typically ±1 effective over many sessions, not per single training click).

Prototype code and `data/players.json` already use **1–10**. There is no 1–100 migration.

## Resolver expectations

Formulas blend stats with coefficients and noise (`balance_constants`, `ScrimmageSimCalculators`, tackle/pass helpers). Tuning target: meaningful spread between **4 vs 7**, not legacy high-scale deltas.

Worked examples: [Simulated_Play_Resolution.md](Simulated_Play_Resolution.md).

## Species balance

| Allowed | Avoid |
|---------|--------|
| Weight shifts on roll tables | +2 flat to all Speed |
| Training XP multipliers ~1.05–1.15 | 1.5× growth |
| Trait/archetype frequency nudges | Mandatory meta species |
| Small synergy caps | Position locks |

**Identity from growth:** fast/agile species train Speed and Agility faster; durable species train Strength and Stamina faster; tactical species train Awareness faster. Starting stats stay close within archetype bands.

## Synergy caps (design defaults — tune in data)

- Single synergy line: **≤ ~3%** effective on relevant resolver input (or ~0.1–0.2 stat-equivalent).
- Stacking: diminishing returns after two tags; global cap per play.

## Progression pacing (1–10)

- Training session: chance to raise **one** stat by **+1** if below cap.
- Season-long: most starters reach **6–8** in primaries; **9–10** is elite/rare.

See [Progression.md](Progression.md).

## Cards and momentum

In-match only; not tied to global player ownership.

## Monetization guardrails

Paid content may unlock **cosmetics**, **scout regions**, **coordinator licenses**, **training slots**—not direct permanent +stat purchases.

## Playtest checklist

- Same archetype, different species: recognizable but not identical
- No species >55% optimal rate on a single position (target)
- Elite roster without duplicate species still viable
