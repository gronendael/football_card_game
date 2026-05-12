#!/usr/bin/env python3
"""Generate plays.json, coaches_catalog.json, playbooks/*.json, teams.json updates."""
import json
import os
import random

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
DATA = os.path.join(ROOT, "data")
PB_DIR = os.path.join(DATA, "playbooks")

OFF_FORMS = ["off_i", "off_shotgun", "off_empty", "off_singleback", "off_pro"]
DEF_RUN_FORMS = ["def_43", "def_34"]
DEF_PASS_FORMS = ["def_nickel", "def_dime", "def_m2m"]

SPE_KICK = "spe_kickoff"
SPE_KRET = "spe_kickoff_return"
SPE_PUNT = "spe_punt"
SPE_PRET = "spe_punt_return"
SPE_FG = "spe_spot_kick"
SPE_BLOCK = "spe_fg_block"


def build_plays():
    plays = {}
    # Scrimmage offense
    for i in range(1, 13):
        fid = OFF_FORMS[(i - 1) % len(OFF_FORMS)]
        plays[f"run_{i:02d}"] = {
            "name": f"Run Concept {i}",
            "formation_id": fid,
            "side": "offense",
            "play_type": "run",
            "tile_delta_min": 0,
            "tile_delta_max": 10,
            "description": "Gap run; blocking determines lane.",
        }
    for i in range(1, 13):
        fid = OFF_FORMS[(i + 3) % len(OFF_FORMS)]
        plays[f"pass_{i:02d}"] = {
            "name": f"Pass Concept {i}",
            "formation_id": fid,
            "side": "offense",
            "play_type": "pass",
            "tile_delta_min": 0,
            "tile_delta_max": 13,
            "description": "Routes: mixed depths; completion vs coverage.",
        }
    # Scrimmage defense
    for i in range(1, 13):
        fid = DEF_RUN_FORMS[(i - 1) % len(DEF_RUN_FORMS)]
        plays[f"run_def_{i:02d}"] = {
            "name": f"Run Defense {i}",
            "formation_id": fid,
            "side": "defense",
            "play_type": "run_def",
            "description": "Fill and spill run fits.",
        }
    for i in range(1, 13):
        fid = DEF_PASS_FORMS[(i - 1) % len(DEF_PASS_FORMS)]
        plays[f"pass_def_{i:02d}"] = {
            "name": f"Pass Defense {i}",
            "formation_id": fid,
            "side": "defense",
            "play_type": "pass_def",
            "description": "Coverage shell vs pass.",
        }
    for i in range(1, 4):
        plays[f"kickoff_{i:02d}"] = {
            "name": f"Kickoff {i}",
            "formation_id": SPE_KICK,
            "side": "special",
            "play_type": "kickoff",
            "description": "Kickoff placement variant.",
        }
    for i in range(1, 4):
        plays[f"kickoff_ret_{i:02d}"] = {
            "name": f"Kickoff Return {i}",
            "formation_id": SPE_KRET,
            "side": "defense",
            "play_type": "kickoff_return",
            "description": "Return lanes and wall.",
        }
    for i in range(1, 4):
        plays[f"punt_{i:02d}"] = {
            "name": f"Punt {i}",
            "formation_id": SPE_PUNT,
            "side": "special",
            "play_type": "punt",
            "description": "Directional punt variant.",
        }
    for i in range(1, 4):
        plays[f"punt_ret_{i:02d}"] = {
            "name": f"Punt Return {i}",
            "formation_id": SPE_PRET,
            "side": "defense",
            "play_type": "punt_return",
            "description": "Return setup variant.",
        }
    # FG / XP attempts (spot kick)
    for i in range(1, 3):
        plays[f"fg_{i:02d}"] = {
            "name": f"Field Goal {i}",
            "formation_id": SPE_FG,
            "side": "special",
            "play_type": "spot_kick",
            "enabled_zones": [4, 5, 6],
            "base_chance": {"4": 35, "5": 55, "6": 75},
            "description": "FG alignment variant.",
        }
    for i in range(1, 3):
        plays[f"fg_xp_def_{i:02d}"] = {
            "name": f"FG/XP Block {i}",
            "formation_id": SPE_BLOCK,
            "side": "defense",
            "play_type": "fg_xp_def",
            "description": "Rush lanes vs FG/XP.",
        }
    return plays


REQ_KEYS = {
    "kickoff": lambda ps: [k for k, v in ps.items() if v.get("play_type") == "kickoff"],
    "kickoff_return": lambda ps: [k for k, v in ps.items() if v.get("play_type") == "kickoff_return"],
    "punt": lambda ps: [k for k, v in ps.items() if v.get("play_type") == "punt"],
    "punt_return": lambda ps: [k for k, v in ps.items() if v.get("play_type") == "punt_return"],
    "spot_kick": lambda ps: [k for k, v in ps.items() if v.get("play_type") == "spot_kick"],
    "fg_xp_def": lambda ps: [k for k, v in ps.items() if v.get("play_type") == "fg_xp_def"],
}


def coach_play_pools(plays):
    """Each coach: pools for attachment (not duplicated across coaches by generation)."""
    run_o = [f"run_{i:02d}" for i in range(1, 13)]
    pass_o = [f"pass_{i:02d}" for i in range(1, 13)]
    rd = [f"run_def_{i:02d}" for i in range(1, 13)]
    pd = [f"pass_def_{i:02d}" for i in range(1, 13)]
    kk = REQ_KEYS["kickoff"](plays)
    kr = REQ_KEYS["kickoff_return"](plays)
    pt = REQ_KEYS["punt"](plays)
    pr = REQ_KEYS["punt_return"](plays)
    sk = REQ_KEYS["spot_kick"](plays)
    fx = REQ_KEYS["fg_xp_def"](plays)
    return run_o, pass_o, rd, pd, kk, kr, pt, pr, sk, fx


def main():
    random.seed(42)
    os.makedirs(PB_DIR, exist_ok=True)
    plays = build_plays()
    with open(os.path.join(DATA, "plays.json"), "w", encoding="utf-8") as f:
        json.dump(plays, f, indent=2)
        f.write("\n")

    run_o, pass_o, rd, pd, kk, kr, pt, pr, sk, fx = coach_play_pools(plays)

    coach_names = [
        "Jordan Blake",
        "Riley Carter",
        "Sam Ortiz",
        "Taylor Morgan",
        "Casey Nguyen",
        "Jamie Foster",
        "Alex Rivera",
        "Morgan Ellis",
        "Drew Patterson",
        "Chris Vaughn",
        "Pat Kim",
        "Robin Hayes",
    ]

    coaches = []
    for i in range(12):
        oc_slots = 4
        dc_slots = 4
        req_ids = []
        used_req = set()
        for _cat, fn in REQ_KEYS.items():
            pool = [p for p in fn(plays) if p not in used_req]
            pick = random.choice(pool)
            req_ids.append(pick)
            used_req.add(pick)
        coaches.append(
            {
                "id": f"coach_{i+1:02d}",
                "name": coach_names[i],
                "bonus_offense": {"standard_zone_bonus": random.randint(0, 2)},
                "bonus_defense": {"defense_mod": random.randint(0, 2)},
                "max_playbook_offense_slots": oc_slots,
                "max_playbook_defense_slots": dc_slots,
                "attached_required_candidates": req_ids,
                "attached_offense_candidates": random.sample(run_o, 4) + random.sample(pass_o, 4),
                "attached_defense_candidates": random.sample(rd, 4) + random.sample(pd, 4),
            }
        )

    with open(os.path.join(DATA, "coaches_catalog.json"), "w", encoding="utf-8") as f:
        json.dump({"coaches": coaches}, f, indent=2)
        f.write("\n")

    team_ids = [
        "bees",
        "cavs",
        "hawks",
        "wolves",
        "tigers",
        "sharks",
        "knights",
        "pirates",
        "storm",
        "falcons",
    ]

    # Assign disjoint OC/DC from 12 coaches (10 teams -> use first 10 as OC, next 10 as DC with wrap)
    oc_ids = [f"coach_{i+1:02d}" for i in range(12)]
    team_oc = [oc_ids[i % 12] for i in range(10)]
    team_dc = [oc_ids[(i + 5) % 12] for i in range(10)]

    playbook_docs = []
    for ti, tid in enumerate(team_ids):
        oc = next(c for c in coaches if c["id"] == team_oc[ti])
        dc = next(c for c in coaches if c["id"] == team_dc[ti])
        pb_max = 6 + oc["max_playbook_offense_slots"] + dc["max_playbook_defense_slots"]
        req_sources = list(
            dict.fromkeys(oc["attached_required_candidates"] + dc["attached_required_candidates"])
        )
        random.shuffle(req_sources)
        required = []
        used_r = set()
        for _cat, fn in REQ_KEYS.items():
            pool = [p for p in fn(plays) if p in req_sources and p not in used_r]
            if not pool:
                pool = [p for p in fn(plays) if p not in used_r]
            pick = random.choice(pool)
            required.append(pick)
            used_r.add(pick)
        off_ids = random.sample(oc["attached_offense_candidates"], 4)
        def_ids = random.sample(dc["attached_defense_candidates"], 4)
        play_ids = required + off_ids + def_ids
        assert len(play_ids) == 14
        assert len(set(play_ids)) == len(play_ids), "duplicate in playbook"
        pid = f"pb_{tid}"
        doc = {"id": pid, "team_id": tid, "max_slots": pb_max, "play_ids": play_ids}
        playbook_docs.append(doc)
        with open(os.path.join(PB_DIR, f"{pid}.json"), "w", encoding="utf-8") as f:
            json.dump(doc, f, indent=2)
            f.write("\n")

    # teams.json with oc, dc, playbook
    teams_path = os.path.join(DATA, "teams.json")
    with open(teams_path, encoding="utf-8") as f:
        teams = json.load(f)
    for i, t in enumerate(teams):
        tid = t["id"]
        doc = next(d for d in playbook_docs if d["team_id"] == tid)
        t["off_coord_id"] = team_oc[i]
        t["def_coord_id"] = team_dc[i]
        t["playbook_id"] = doc["id"]
    with open(teams_path, "w", encoding="utf-8") as f:
        json.dump(teams, f, indent=2)
        f.write("\n")

    index = {"playbooks": [d["id"] for d in playbook_docs]}
    with open(os.path.join(PB_DIR, "index.json"), "w", encoding="utf-8") as f:
        json.dump(index, f, indent=2)
        f.write("\n")

    print("Wrote plays.json, coaches_catalog.json, playbooks/*.json, updated teams.json")


if __name__ == "__main__":
    main()
