import { readFileSync, writeFileSync } from "fs";
import { fileURLToPath } from "url";
import { dirname, join } from "path";

const ROOT = join(dirname(fileURLToPath(import.meta.url)), "..");
const DEFAULT_PROGRESSION = ["WR1", "WR2", "TE1", "RB1", "RB2", "TE2", "WR3"];

function formationRoles(form) {
  return (form.positions || []).map((p) => p.role).filter(Boolean);
}

function pickCarrier(roles) {
  return roles.find((r) => r.toUpperCase().startsWith("RB")) || "";
}

function filteredProgression(roles) {
  const out = [];
  for (const want of DEFAULT_PROGRESSION) {
    if (roles.includes(want)) out.push(want);
  }
  for (const r of roles) {
    const ru = r.toUpperCase();
    if ((ru.startsWith("WR") || ru.startsWith("TE") || ru.startsWith("RB")) && !out.includes(r)) {
      out.push(r);
    }
  }
  return out;
}

function chain(steps) {
  return steps.map((s) => [s[0], s[1]]);
}

function wpsRunCarrier() {
  return chain([[0, -1], [0, -1], [0, -1], [-1, -1], [0, -1], [0, -1]]);
}

function wpsRunLeadBlock() {
  return chain([[0, -1], [1, 0], [0, -1]]);
}

function wpsRunClearOut(role) {
  const lat = role.includes("1") || role.endsWith("3") ? -1 : 1;
  return chain([[0, -1], [lat, -1], [0, -1]]);
}

function wpsPassFlat(role) {
  let n = 1;
  if (role.toUpperCase().startsWith("RB") && role.length > 2) {
    n = parseInt(role.slice(2), 10) || 1;
  }
  const lat = n % 2 === 1 ? -1 : 1;
  return chain([[lat, 0], [lat, -1], [0, -1], [0, -1]]);
}

function wpsPassReceiver(idx, role) {
  if (role.toUpperCase().startsWith("TE")) {
    return chain([[0, -1], [0, -1], [1, -1], [0, -1]]);
  }
  if (idx % 3 === 0) {
    return chain([[0, -1], [0, -2], [0, -1], [1, -1], [0, -1]]);
  }
  if (idx % 3 === 1) {
    return chain([[0, -1], [1, 0], [0, -1], [0, -2]]);
  }
  return chain([[1, -1], [0, -1], [0, -1], [-1, -1]]);
}

function defaultRoleAssignments(ptype, roles) {
  const ra = {};
  const carrier = ptype === "run" ? pickCarrier(roles) : "";
  let rbI = 0;
  let wrI = 0;
  for (const role of roles) {
    const ru = role.toUpperCase();
    if (ru.startsWith("OL") || ru === "QB") {
      ra[role] = { start_action: ptype === "pass" ? "pass_block" : "run_block" };
    } else if (ru.startsWith("RB")) {
      rbI += 1;
      if (ptype === "run") {
        ra[role] = { start_action: role === carrier ? "carry" : "run_block" };
      } else {
        ra[role] = { start_action: "route" };
      }
    } else if (ru.startsWith("WR") || ru.startsWith("TE")) {
      wrI += 1;
      if (ptype === "run") {
        ra[role] = { start_action: wrI % 2 === 0 ? "run_block" : "route" };
      } else {
        ra[role] = { start_action: "route" };
      }
    }
  }
  return ra;
}

function defaultRoutes(ptype, roles) {
  const routes = {};
  const carrier = ptype === "run" ? pickCarrier(roles) : "";
  let rbI = 0;
  let wrI = 0;
  const ra = defaultRoleAssignments(ptype, roles);
  for (const role of roles) {
    const ru = role.toUpperCase();
    let wps = [];
    if (ru.startsWith("RB")) {
      rbI += 1;
      if (ptype === "run" && role === carrier) wps = wpsRunCarrier();
      else if (ptype === "run") wps = wpsRunLeadBlock();
      else if (ptype === "pass") wps = wpsPassFlat(role);
    } else if (ru.startsWith("WR") || ru.startsWith("TE")) {
      wrI += 1;
      if (ptype === "run" && ra[role]?.start_action === "route") {
        wps = wpsRunClearOut(role);
      } else if (ptype === "pass") {
        wps = wpsPassReceiver(wrI, role);
      }
    }
    if (wps.length) routes[role] = { waypoints: wps };
  }
  return routes;
}

function enrichPlay(play, form) {
  const ptype = play.play_type;
  if (ptype !== "run" && ptype !== "pass") return play;
  const roles = formationRoles(form);
  if (!roles.length) return play;
  play.role_assignments = defaultRoleAssignments(ptype, roles);
  play.routes = defaultRoutes(ptype, roles);
  if (ptype === "run") {
    play.ball_carrier_role = pickCarrier(roles);
  } else {
    const order = filteredProgression(roles);
    play.receiver_progression = {};
    if (order[0]) play.receiver_progression.primary = order[0];
    if (order[1]) play.receiver_progression.secondary = order[1];
    if (order[2]) play.receiver_progression.tertiary = order[2];
    play.qb_script = {
      mode: "dropback_progression",
      dropback_ticks: 5,
      progression: order,
    };
  }
  return play;
}

const playsPath = join(ROOT, "data", "plays.json");
const formsPath = join(ROOT, "data", "formations.json");
const plays = JSON.parse(readFileSync(playsPath, "utf8"));
const formsRaw = JSON.parse(readFileSync(formsPath, "utf8"));
const formsList = Array.isArray(formsRaw) ? formsRaw : formsRaw.formations || [];
const forms = Object.fromEntries(formsList.map((f) => [f.id, f]));
let n = 0;
for (const [pid, play] of Object.entries(plays)) {
  if (play.side !== "offense") continue;
  if (play.play_type !== "run" && play.play_type !== "pass") continue;
  const form = forms[play.formation_id];
  if (!form) {
    console.log(`skip ${pid}: unknown formation ${play.formation_id}`);
    continue;
  }
  enrichPlay(play, form);
  n += 1;
}
writeFileSync(playsPath, JSON.stringify(plays, null, "\t") + "\n", "utf8");
console.log(`migrated ${n} offense run/pass plays`);
