import fs from "fs";
import path from "path";
import { fileURLToPath } from "url";

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const ROOT = path.join(__dirname, "..");
const DATA = path.join(ROOT, "data");
const PB_DIR = path.join(DATA, "playbooks");

const OFF_FORMS = ["off_i", "off_shotgun", "off_empty", "off_singleback", "off_pro"];
const DEF_RUN_FORMS = ["def_43", "def_34"];
const DEF_PASS_FORMS = ["def_nickel", "def_dime", "def_m2m"];

function buildPlays() {
  const plays = {};
  for (let i = 1; i <= 12; i++) {
    const fid = OFF_FORMS[(i - 1) % OFF_FORMS.length];
    plays[`run_${String(i).padStart(2, "0")}`] = {
      name: `Run Concept ${i}`,
      formation_id: fid,
      side: "offense",
      play_type: "run",
      tile_delta_min: 0,
      tile_delta_max: 10,
      description: "Gap run; blocking determines lane.",
    };
  }
  for (let i = 1; i <= 12; i++) {
    const fid = OFF_FORMS[(i + 3) % OFF_FORMS.length];
    plays[`pass_${String(i).padStart(2, "0")}`] = {
      name: `Pass Concept ${i}`,
      formation_id: fid,
      side: "offense",
      play_type: "pass",
      tile_delta_min: 0,
      tile_delta_max: 13,
      description: "Routes: mixed depths; completion vs coverage.",
    };
  }
  for (let i = 1; i <= 12; i++) {
    const fid = DEF_RUN_FORMS[(i - 1) % DEF_RUN_FORMS.length];
    plays[`run_def_${String(i).padStart(2, "0")}`] = {
      name: `Run Defense ${i}`,
      formation_id: fid,
      side: "defense",
      play_type: "run_def",
      description: "Fill and spill run fits.",
    };
  }
  for (let i = 1; i <= 12; i++) {
    const fid = DEF_PASS_FORMS[(i - 1) % DEF_PASS_FORMS.length];
    plays[`pass_def_${String(i).padStart(2, "0")}`] = {
      name: `Pass Defense ${i}`,
      formation_id: fid,
      side: "defense",
      play_type: "pass_def",
      description: "Coverage shell vs pass.",
    };
  }
  for (let i = 1; i <= 3; i++) {
    plays[`kickoff_${String(i).padStart(2, "0")}`] = {
      name: `Kickoff ${i}`,
      formation_id: "spe_kickoff",
      side: "special",
      play_type: "kickoff",
      description: "Kickoff placement variant.",
    };
    plays[`kickoff_ret_${String(i).padStart(2, "0")}`] = {
      name: `Kickoff Return ${i}`,
      formation_id: "spe_kickoff_return",
      side: "defense",
      play_type: "kickoff_return",
      description: "Return lanes and wall.",
    };
    plays[`punt_${String(i).padStart(2, "0")}`] = {
      name: `Punt ${i}`,
      formation_id: "spe_punt",
      side: "special",
      play_type: "punt",
      description: "Directional punt variant.",
    };
    plays[`punt_ret_${String(i).padStart(2, "0")}`] = {
      name: `Punt Return ${i}`,
      formation_id: "spe_punt_return",
      side: "defense",
      play_type: "punt_return",
      description: "Return setup variant.",
    };
  }
  for (let i = 1; i <= 2; i++) {
    plays[`fg_${String(i).padStart(2, "0")}`] = {
      name: `Field Goal ${i}`,
      formation_id: "spe_spot_kick",
      side: "special",
      play_type: "spot_kick",
      enabled_zones: [4, 5, 6],
      base_chance: { 4: 35, 5: 55, 6: 75 },
      description: "FG alignment variant.",
    };
    plays[`fg_xp_def_${String(i).padStart(2, "0")}`] = {
      name: `FG/XP Block ${i}`,
      formation_id: "spe_fg_block",
      side: "defense",
      play_type: "fg_xp_def",
      description: "Rush lanes vs FG/XP.",
    };
  }
  return plays;
}

const REQ_KEYS = {
  kickoff: (ps) => Object.keys(ps).filter((k) => ps[k].play_type === "kickoff"),
  kickoff_return: (ps) => Object.keys(ps).filter((k) => ps[k].play_type === "kickoff_return"),
  punt: (ps) => Object.keys(ps).filter((k) => ps[k].play_type === "punt"),
  punt_return: (ps) => Object.keys(ps).filter((k) => ps[k].play_type === "punt_return"),
  spot_kick: (ps) => Object.keys(ps).filter((k) => ps[k].play_type === "spot_kick"),
  fg_xp_def: (ps) => Object.keys(ps).filter((k) => ps[k].play_type === "fg_xp_def"),
};

function shuffle(arr, rng) {
  const a = [...arr];
  for (let i = a.length - 1; i > 0; i--) {
    const j = Math.floor(rng() * (i + 1));
    [a[i], a[j]] = [a[j], a[i]];
  }
  return a;
}

function main() {
  const rng = () => {
    let s = 42;
    return () => {
      s = (s * 1103515245 + 12345) & 0x7fffffff;
      return s / 0x7fffffff;
    };
  };
  const rand = rng();

  fs.mkdirSync(PB_DIR, { recursive: true });
  const plays = buildPlays();
  fs.writeFileSync(path.join(DATA, "plays.json"), JSON.stringify(plays, null, 2) + "\n");

  const coachNames = [
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
  ];

  const run_o = Object.keys(plays).filter((k) => k.startsWith("run_"));
  const pass_o = Object.keys(plays).filter((k) => k.startsWith("pass_"));
  const rd = Object.keys(plays).filter((k) => k.startsWith("run_def_"));
  const pd = Object.keys(plays).filter((k) => k.startsWith("pass_def_"));

  const coaches = [];
  for (let i = 0; i < 12; i++) {
    const req_ids = [];
    const used = new Set();
    for (const fn of Object.values(REQ_KEYS)) {
      let pool = fn(plays).filter((p) => !used.has(p));
      const pick = pool[Math.floor(rand() * pool.length)];
      req_ids.push(pick);
      used.add(pick);
    }
    const off_cand = shuffle([...run_o.slice(0, 4), ...pass_o.slice(0, 4)], rand);
    const def_cand = shuffle([...rd.slice(0, 4), ...pd.slice(0, 4)], rand);
    coaches.push({
      id: `coach_${String(i + 1).padStart(2, "0")}`,
      name: coachNames[i],
      bonus_offense: { standard_zone_bonus: Math.floor(rand() * 3) },
      bonus_defense: { defense_mod: Math.floor(rand() * 3) },
      max_playbook_offense_slots: 4,
      max_playbook_defense_slots: 4,
      attached_required_candidates: req_ids,
      attached_offense_candidates: off_cand,
      attached_defense_candidates: def_cand,
    });
  }

  fs.writeFileSync(path.join(DATA, "coaches_catalog.json"), JSON.stringify({ coaches }, null, 2) + "\n");

  const teamIds = ["bees", "cavs", "hawks", "wolves", "tigers", "sharks", "knights", "pirates", "storm", "falcons"];
  const teamOc = teamIds.map((_, i) => `coach_${String((i % 12) + 1).padStart(2, "0")}`);
  const teamDc = teamIds.map((_, i) => `coach_${String(((i + 5) % 12) + 1).padStart(2, "0")}`);

  const playbookDocs = [];
  for (let ti = 0; ti < teamIds.length; ti++) {
    const tid = teamIds[ti];
    const oc = coaches.find((c) => c.id === teamOc[ti]);
    const dc = coaches.find((c) => c.id === teamDc[ti]);
    const pb_max = 6 + oc.max_playbook_offense_slots + dc.max_playbook_defense_slots;
    const req_sources = [...new Set([...oc.attached_required_candidates, ...dc.attached_required_candidates])];
    shuffle(req_sources, rand);
    const required = [];
    const usedR = new Set();
    for (const fn of Object.values(REQ_KEYS)) {
      let pool = fn(plays).filter((p) => req_sources.includes(p) && !usedR.has(p));
      if (pool.length === 0) pool = fn(plays).filter((p) => !usedR.has(p));
      const pick = pool[Math.floor(rand() * pool.length)];
      required.push(pick);
      usedR.add(pick);
    }
    const off_ids = shuffle([...oc.attached_offense_candidates], rand).slice(0, 4);
    const def_ids = shuffle([...dc.attached_defense_candidates], rand).slice(0, 4);
    const play_ids = [...required, ...off_ids, ...def_ids];
    const pid = `pb_${tid}`;
    const doc = { id: pid, team_id: tid, max_slots: pb_max, play_ids };
    playbookDocs.push(doc);
    fs.writeFileSync(path.join(PB_DIR, `${pid}.json`), JSON.stringify(doc, null, 2) + "\n");
  }

  const teamsPath = path.join(DATA, "teams.json");
  const teams = JSON.parse(fs.readFileSync(teamsPath, "utf8"));
  for (let i = 0; i < teams.length; i++) {
    const tid = teams[i].id;
    const doc = playbookDocs.find((d) => d.team_id === tid);
    teams[i].off_coord_id = teamOc[i];
    teams[i].def_coord_id = teamDc[i];
    teams[i].playbook_id = doc.id;
  }
  fs.writeFileSync(teamsPath, JSON.stringify(teams, null, 2) + "\n");

  fs.writeFileSync(
    path.join(PB_DIR, "index.json"),
    JSON.stringify({ playbooks: playbookDocs.map((d) => d.id) }, null, 2) + "\n"
  );

  console.log("OK");
}

main();
