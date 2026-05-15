#!/usr/bin/env python3
"""One-shot: add routes / role_assignments / progression to offense run & pass plays."""
import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
DEFAULT_PROGRESSION = ["WR1", "WR2", "TE1", "RB1", "RB2", "TE2", "WR3"]


def formation_roles(form):
    return [p["role"] for p in form.get("positions", []) if "role" in p]


def pick_carrier(roles):
    for r in roles:
        if r.upper().startswith("RB"):
            return r
    return ""


def filtered_progression(roles):
    out = []
    for want in DEFAULT_PROGRESSION:
        if want in roles:
            out.append(want)
    for r in roles:
        ru = r.upper()
        if (ru.startswith("WR") or ru.startswith("TE") or ru.startswith("RB")) and r not in out:
            out.append(r)
    return out


def chain(steps):
    return [[int(s[0]), int(s[1])] for s in steps]


def wps_run_carrier():
    return chain([[0, -1]] * 3 + [[-1, -1], [0, -1], [0, -1]])


def wps_run_lead_block():
    return chain([[0, -1], [1, 0], [0, -1]])


def wps_run_clear_out(role):
    lat = -1 if "1" in role or role.endswith("3") else 1
    return chain([[0, -1], [lat, -1], [0, -1]])


def wps_pass_flat(role):
    n = 1
    if role.upper().startswith("RB") and len(role) > 2:
        try:
            n = int(role[2:])
        except ValueError:
            n = 1
    lat = -1 if n % 2 == 1 else 1
    return chain([[lat, 0], [lat, -1], [0, -1], [0, -1]])


def wps_pass_receiver(idx, role):
    if role.upper().startswith("TE"):
        return chain([[0, -1], [0, -1], [1, -1], [0, -1]])
    if idx % 3 == 0:
        return chain([[0, -1], [0, -2], [0, -1], [1, -1], [0, -1]])
    if idx % 3 == 1:
        return chain([[0, -1], [1, 0], [0, -1], [0, -2]])
    return chain([[1, -1], [0, -1], [0, -1], [-1, -1]])


def default_role_assignments(ptype, roles):
    ra = {}
    carrier = pick_carrier(roles) if ptype == "run" else ""
    rb_i = wr_i = 0
    for role in roles:
        ru = role.upper()
        if ru.startswith("OL") or ru == "QB":
            ra[role] = {"start_action": "pass_block" if ptype == "pass" else "run_block"}
        elif ru.startswith("RB"):
            rb_i += 1
            if ptype == "run":
                ra[role] = {"start_action": "carry" if role == carrier else "run_block"}
            else:
                ra[role] = {"start_action": "route"}
        elif ru.startswith("WR") or ru.startswith("TE"):
            wr_i += 1
            if ptype == "run":
                ra[role] = {"start_action": "run_block" if wr_i % 2 == 0 else "route"}
            else:
                ra[role] = {"start_action": "route"}
    return ra


def default_routes(ptype, roles):
    routes = {}
    carrier = pick_carrier(roles) if ptype == "run" else ""
    rb_i = wr_i = 0
    ra = default_role_assignments(ptype, roles)
    for role in roles:
        ru = role.upper()
        wps = []
        if ru.startswith("RB"):
            rb_i += 1
            if ptype == "run" and role == carrier:
                wps = wps_run_carrier()
            elif ptype == "run":
                wps = wps_run_lead_block()
            elif ptype == "pass":
                wps = wps_pass_flat(role)
        elif ru.startswith("WR") or ru.startswith("TE"):
            wr_i += 1
            if ptype == "run" and ra[role]["start_action"] == "route":
                wps = wps_run_clear_out(role)
            elif ptype == "pass":
                wps = wps_pass_receiver(wr_i, role)
        if wps:
            routes[role] = {"waypoints": wps}
    return routes


def enrich_play(play, form):
    ptype = play.get("play_type", "")
    if ptype not in ("run", "pass"):
        return play
    roles = formation_roles(form)
    if not roles:
        return play
    play["role_assignments"] = default_role_assignments(ptype, roles)
    play["routes"] = default_routes(ptype, roles)
    if ptype == "run":
        play["ball_carrier_role"] = pick_carrier(roles)
    else:
        order = filtered_progression(roles)
        play["receiver_progression"] = {}
        if len(order) > 0:
            play["receiver_progression"]["primary"] = order[0]
        if len(order) > 1:
            play["receiver_progression"]["secondary"] = order[1]
        if len(order) > 2:
            play["receiver_progression"]["tertiary"] = order[2]
        play["qb_script"] = {
            "mode": "dropback_progression",
            "dropback_ticks": 5,
            "progression": order,
        }
    return play


def main():
    plays_path = ROOT / "data" / "plays.json"
    forms_path = ROOT / "data" / "formations.json"
    plays = json.loads(plays_path.read_text(encoding="utf-8"))
    forms = {f["id"]: f for f in json.loads(forms_path.read_text(encoding="utf-8"))["formations"]}
    n = 0
    for pid, play in plays.items():
        if play.get("side") != "offense":
            continue
        if play.get("play_type") not in ("run", "pass"):
            continue
        fid = play.get("formation_id", "")
        form = forms.get(fid)
        if not form:
            print(f"skip {pid}: unknown formation {fid}")
            continue
        enrich_play(play, form)
        n += 1
    plays_path.write_text(json.dumps(plays, indent="\t") + "\n", encoding="utf-8")
    print(f"migrated {n} offense run/pass plays")


if __name__ == "__main__":
    main()
