# Tools (editor / dev)

The **Tools** menu on the live game screen (`GameScene` / `TopRightBar`) hosts utilities that edit `res://` data. Intended for **editor and dev builds**; exported games may have read-only packaged resources.

**Convention:** tool-created entities use **auto-generated ids**; the formation editor shows **Id** as **read-only** (new `fmt_*` on create, existing id when editing). Future tools should follow the same pattern.

## Formation tool

- **Open:** **Tools → Formation tool…** → [`scenes/formation_tool.tscn`](scenes/formation_tool.tscn) (`FormationTool`).
- **Data:** reads/writes [`data/formations.json`](../data/formations.json). **Save** reloads the formations catalog in the running game. Does **not** rewrite `formation_id` references in [`data/plays.json`](../data/plays.json).
- **Add flow:** pick **formation_shell** (context) from the list, then the **Add/Edit** layout: **column 1** — Id (read-only), Name, Description, Tags; **column 2** — draggable roles **not currently on the grid** (each role at most one token on the field; dragging from the list places it and hides that row; dragging a chip from the grid back onto column 2 returns it to the list); **column 3** — **7×20** grid (LOS row uses pale empty-cell tint).
- **Edit:** same layout; id stays read-only for that formation.
- **UI:** **scrollable** opaque panel with screen margins for shorter viewports; editor row is wider than the formation list screen; grid column uses a **taller minimum height** so all **20** tile rows fit without clipping.
