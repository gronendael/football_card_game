# Tools (editor / dev)

The **Tools** menu on the live game screen (`GameScene` / `TopRightBar`) hosts utilities that edit `res://` data. Intended for **editor and dev builds**; exported games may have read-only packaged resources.

## Tools Hub (no full game)

Open [`scenes/tools_hub.tscn`](../scenes/tools_hub.tscn) and press **Play** (F6 / “Run Current Scene”) to launch **only** the tools shell — same **Tools** menu as the game (Formation tool, Test Play, Play Creator) without loading the match HUD, cards, or clocks.

- **Open full game** switches to [`scenes/game_scene.tscn`](../scenes/game_scene.tscn).
- Optional: set **Project → Project Settings → Application → Run → Main Scene** to `res://scenes/tools_hub.tscn` while authoring data files.

## Full game launch pause

When the main game scene starts, **play clock** and **game clock** stay idle until you press **▶** (unpause) or **Sim**. Restart behaves the same way.

**Convention:** tool-created entities use **auto-generated ids**; the formation editor shows **Id** as **read-only** (new `fmt_*` on create, existing id when editing). Future tools should follow the same pattern.

## Formation tool

- **Open:** **Tools → Formation tool…** → [`scenes/formation_tool.tscn`](scenes/formation_tool.tscn) (`FormationTool`).
- **Data:** reads/writes [`data/formations.json`](../data/formations.json). **Save** reloads the formations catalog in the running game. Does **not** rewrite `formation_id` references in [`data/plays.json`](../data/plays.json).
- **Add flow:** pick **formation_shell** (context) from the list, then the **Add/Edit** layout: **column 1** — Id (read-only), Name, Description, Tags; **column 2** — draggable roles **not currently on the grid** (each role at most one token on the field; dragging from the list places it and hides that row; dragging a chip from the grid back onto column 2 returns it to the list); **column 3** — **7×20** grid (LOS row uses pale empty-cell tint).
- **Edit:** same layout; id stays read-only for that formation.
- **UI:** **scrollable** opaque panel with screen margins for shorter viewports; editor row is wider than the formation list screen; grid column uses a **taller minimum height** so all **20** tile rows fit without clipping.
- **List screen:** filter by **Type** (All / Offense / Defense / Special, from formation `side`) and **Tags** (comma-separated; formation matches if **any** term matches a tag). Table columns **ID**, **Name**, **Type** — click a column header to sort (click again to reverse). Double-click a row to edit.

## Play Creator

- **Open:** **Tools → Play Creator…** (`PlayCreatorTool` overlay).
- **Data:** reads/writes [`data/plays.json`](../data/plays.json). **Save** reloads `PlaysCatalog` in the running game. Does not change playbooks until those rows reference new ids.
- **List:** search by play name; filter **Type** (offense/defense/special), **Sub-type** (`play_type`, e.g. offense Run/Pass), and **Formation**; sortable columns **ID**, **Name**, **Type**, **Formation**; double-click to edit.
- **Editor:** Id (read-only, auto `play_off_*` / `play_def_*` / `play_sp_*` on create), Name, Description, Side, Play type, Formation picker. Offense **run/pass** adds per-role **start_action**, **routes** (step list + field overlay on the 7×20 grid), **ball_carrier_role** (run), **QB script** + receiver **primary/secondary/tertiary** (pass). **Save** writes and stays in the editor; **Close** prompts Save / Discard / Cancel if changed. **Test play** opens Test Play with the saved offense id.
- **Sim:** [scripts/play_authoring.gd](../scripts/play_authoring.gd) reads optional `routes`, `role_assignments`, `ball_carrier_role`, `qb_script`, `receiver_progression` on the offense play row. **Tick sim** (`PlayTickEngine`) and **pass targeting** (`PassTargetSelector` via `PassSimResolver`) use them when present; tick sim also calls `PlayRouteTemplates.enrich_play_row` for any still-incomplete row.

## Test Play

- **Open:** **Tools → Test Play…** on the live game screen (`TestPlayScreen` overlay).
- **Purpose:** Run a single scrimmage play in isolation — no game clock, play clock, cards, or scoreboard.
- **Setup:** Full-screen layout: **field left** (scaled up), **log panel right**. Midfield LOS (`current_zone` 4); flat **5** stats ([scripts/test_play_stat_factory.gd](../scripts/test_play_stat_factory.gd)). Enables **Tick sim authority** and **full dropback** (no early throw) for the session only.
- **Plays:** Offense `run` / `pass`; defense **Solo** (`run_def_01` / `pass_def_01`) or **Opponent play**.
- **Controls:** **Reseed**, **Snap**, **Step** / **◀ Prev** / **Next ▶** (one **beat** per sim tick), **Play** (auto-advance beats; pauses on throw / tackle / TD), **Close**.
- **Focus roles:** Multi-select formation roles to show **only those markers** on the field and matching narrative sections. **Ball** and **Play events** (pressure/throw) toggles apply while focused.
- **Presets:** Save/load named focus sets to `user://test_play_presets.json` — **Save as…**, **Apply**, **Update**, **Delete** ([scripts/test_play_presets.gd](../scripts/test_play_presets.gd)).
- **Log:** One narrative **beat** per tick ([scripts/test_play_narrative_builder.gd](../scripts/test_play_narrative_builder.gd)) — per-role movement, **target** (role name or `None`; man cover or engage), engage/block attempts (including failed rolls when verbose sim is on), coverage separation, and sim events; optional throw-resolution beat. Tick-authoritative throws use grid-based separation at throw time. **Changes only** hides “stays on” lines.
- **Ball:** Gold ring + **🏈** on carrier when visible in focus.
