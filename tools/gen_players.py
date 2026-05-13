"""Generate data/players.json and patch data/teams.json roster_player_ids.
Run from repo root: python tools/gen_players.py"""
import json
import random
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
PLAYERS_PATH = ROOT / "data" / "players.json"
TEAMS_PATH = ROOT / "data" / "teams.json"

FIRST = [
    "James", "Michael", "Robert", "David", "William", "Joseph", "Thomas", "Charles",
    "Daniel", "Matthew", "Anthony", "Mark", "Donald", "Steven", "Paul", "Andrew",
    "Joshua", "Kenneth", "Kevin", "Brian", "George", "Timothy", "Ronald", "Jason",
    "Edward", "Jeffrey", "Ryan", "Jacob", "Gary", "Nicholas", "Eric", "Jonathan",
    "Stephen", "Larry", "Justin", "Scott", "Brandon", "Benjamin", "Samuel", "Gregory",
    "Alexander", "Patrick", "Frank", "Raymond", "Jack", "Dennis", "Jerry", "Tyler",
    "Aaron", "Jose", "Adam", "Nathan", "Henry", "Douglas", "Zachary", "Peter",
    "Kyle", "Noah", "Ethan", "Jeremy", "Walter", "Christian", "Keith", "Roger",
    "Terry", "Austin", "Sean", "Gerald", "Carl", "Harold", "Dylan", "Arthur",
    "Lawrence", "Jordan", "Wayne", "Alan", "Juan", "Willie", "Elijah", "Randy",
    "Roy", "Vincent", "Ralph", "Eugene", "Russell", "Bobby", "Mason", "Philip",
    "Louis", "Mary", "Patricia", "Jennifer", "Linda", "Elizabeth", "Barbara",
    "Susan", "Jessica", "Sarah", "Karen", "Lisa", "Nancy", "Betty", "Margaret",
    "Sandra", "Ashley", "Kimberly", "Emily", "Donna", "Michelle", "Carol", "Amanda",
    "Melissa", "Deborah", "Stephanie", "Rebecca", "Laura", "Sharon", "Cynthia",
    "Kathleen", "Amy", "Shirley", "Angela", "Helen", "Anna", "Brenda", "Pamela",
    "Nicole", "Samantha", "Katherine", "Christine", "Debra", "Rachel", "Carolyn",
    "Janet", "Virginia", "Maria", "Heather", "Diane", "Julie", "Joyce", "Victoria",
    "Kelly", "Christina", "Lauren", "Joan", "Evelyn", "Olivia", "Judith", "Megan",
    "Cheryl", "Martha", "Andrea", "Frances", "Hannah", "Jacqueline", "Ann", "Gloria",
    "Jean", "Kathryn", "Alice", "Teresa", "Sara", "Janice", "Doris", "Madison",
    "Julia", "Grace", "Judy", "Abigail", "Marie", "Denise", "Beverly", "Amber",
    "Theresa", "Marilyn", "Danielle", "Diana", "Brittany", "Natalie", "Sophia",
    "Isabella", "Charlotte", "Amelia", "Mia", "Harper", "Ella", "Aria", "Layla",
]

LAST = [
    "Smith", "Johnson", "Williams", "Brown", "Jones", "Garcia", "Miller", "Davis",
    "Rodriguez", "Martinez", "Hernandez", "Lopez", "Gonzalez", "Wilson", "Anderson",
    "Thomas", "Taylor", "Moore", "Jackson", "Martin", "Lee", "Perez", "Thompson",
    "White", "Harris", "Sanchez", "Clark", "Ramirez", "Lewis", "Robinson", "Walker",
    "Young", "Allen", "King", "Wright", "Scott", "Torres", "Nguyen", "Hill", "Flores",
    "Green", "Adams", "Nelson", "Baker", "Hall", "Rivera", "Campbell", "Mitchell",
    "Carter", "Roberts", "Gomez", "Phillips", "Evans", "Turner", "Diaz", "Parker",
    "Cruz", "Edwards", "Collins", "Reyes", "Stewart", "Morris", "Morales", "Murphy",
    "Cook", "Rogers", "Gutierrez", "Ortiz", "Morgan", "Cooper", "Peterson", "Bailey",
    "Reed", "Kelly", "Howard", "Ramos", "Kim", "Cox", "Ward", "Richardson", "Watson",
    "Brooks", "Chavez", "Wood", "James", "Bennett", "Gray", "Mendoza", "Ruiz",
    "Hughes", "Price", "Alvarez", "Castillo", "Sanders", "Patel", "Myers", "Long",
    "Ross", "Foster", "Jimenez", "Powell", "Jenkins", "Perry", "Russell", "Sullivan",
    "Bell", "Coleman", "Butler", "Henderson", "Barnes", "Gonzales", "Fisher", "Vasquez",
    "Simmons", "Romero", "Jordan", "Patterson", "Alexander", "Hamilton", "Graham",
    "Reynolds", "Griffin", "Wallace", "Moreno", "West", "Cole", "Hayes", "Bryant",
    "Herrera", "Gibson", "Ellis", "Tran", "Medina", "Aguilar", "Stevens", "Murray",
    "Ford", "Castro", "Marshall", "Owens", "Harrison", "Fernandez", "Mcdonald",
    "Woods", "Washington", "Kennedy", "Wells", "Vargas", "Henry", "Chen", "Freeman",
    "Webb", "Tucker", "Guzman", "Burns", "Crawford", "Olson", "Simpson", "Porter",
    "Hunter", "Gordon", "Mendez", "Silva", "Shaw", "Snyder", "Mason", "Dixon",
    "Munoz", "Hunt", "Hicks", "Holmes", "Palmer", "Wagner", "Black", "Robertson",
    "Boyd", "Rose", "Stone", "Salazar", "Fox", "Warren", "Mills", "Meyer", "Rice",
    "Schmidt", "Garza", "Daniels", "Ferguson", "Nichols", "Stephens", "Soto", "Weaver",
    "Ryan", "Gardner", "Payne", "Grant", "Dunn", "Kelley", "Spencer", "Hawkins",
    "Arnold", "Pierce", "Vazquez", "Hansen", "Peters", "Santos", "Hart", "Bradley",
    "Knight", "Elliott", "Cunningham", "Duncan", "Armstrong", "Hudson", "Carroll",
    "Lane", "Riley", "Andrews", "Alvarado", "Ray", "Delgado", "Berry", "Perkins",
    "Hoffman", "Johnston", "Matthews", "Pena", "Richards", "Contreras", "Willis",
    "Carpenter", "Lawrence", "Sandoval", "Guerrero", "George", "Chapman", "Rios",
    "Estrada", "Ortega", "Watkins", "Greene", "Nunez", "Wheeler", "Valdez", "Harper",
    "Burke", "Larson", "Santiago", "Maldonado", "Morrison", "Franklin", "Carlson",
    "Austin", "Dominguez", "Carr", "Lawson", "Jacobs", "Obrien", "Lynch", "Singh",
    "Vega", "Bishop", "Montgomery", "Oliver", "Jensen", "Harvey", "Williamson", "Gilbert",
    "Dean", "Sims", "Espinoza", "Howell", "Li", "Wong", "Reid", "Hanson", "Le",
    "Mccoy", "Garrett", "Burton", "Fuller", "Wang", "Weber", "Welch", "Rojas", "Lucas",
    "Marquez", "Fields", "Park", "Yang", "Little", "Banks", "Padilla", "Day", "Walsh",
    "Schultz", "Luna", "Fowler", "Mejia", "Davidson", "Acosta", "Brewer", "May", "Holland",
    "Juarez", "Newman", "Pearson", "Curtis", "Cortez", "Douglas", "Schneider", "Joseph",
    "Barrett", "Navarro", "Figueroa", "Keller", "Avila", "Wade", "Molina", "Stanley",
    "Hopkins", "Campos", "Barnett", "Bates", "Chambers", "Caldwell", "Beck", "Lambert",
    "Miranda", "Byrd", "Powers", "Neal", "Leonard", "Gregory", "Carrillo", "Sutton",
    "Fleming", "Rhodes", "Shelton", "Schwartz", "Norris", "Jennings", "Watts", "Duran",
    "Walters", "Cohen", "Mcdaniel", "Moran", "Parks", "Steele", "Vaughn", "Becker",
    "Holt", "Deleon", "Barker", "Terry", "Hale", "Leon", "Hail", "Benson", "Haynes",
    "Horton", "Finley", "Quinn", "Francis", "Giles", "Curry", "Sherman", "Petersen",
    "Barton", "Mclaughlin", "Wise", "Manning", "Carlson", "Harrell", "Booth", "Roth",
    "Hess", "Mosley", "Olsen", "Prince", "Briggs", "Marsh", "Mcbride", "Solomon",
    "Velez", "Odonnell", "Kerr", "Stout", "Meade", "Ho", "Mcgrath", "Mckee", "Bauer",
    "Schaefer", "Hurst", "Hebert", "Cleveland", "Snider", "Mcconnell", "Wiley",
    "Donaldson", "Slater", "Carver", "Hensley", "Bond", "Dyer", "Cameron", "Grimes",
    "Contreras", "Christian", "Wyatt", "Baxter", "Snow", "Mosley", "Shepherd", "Larsen",
    "Hoover", "Beasley", "Glenn", "Phelps", "Avery", "Spears", "Friedman", "Potter",
    "Goodwin", "Walton", "Rowe", "Hampton", "Ortega", "Patton", "Swanson", "Joseph",
    "Francis", "Gould", "Schaffer", "Mercado", "Moyer", "Mcclure", "Bentley", "Peck",
    "Key", "Salas", "Rollins", "Casanova", "Mcneil", "Baird", "Mcdowell", "Goldberg",
]

COLLEGES = [
    "Ohio State", "Alabama", "Georgia", "Michigan", "Texas", "USC", "Notre Dame",
    "LSU", "Florida", "Penn State", "Oregon", "Miami", "Clemson", "Wisconsin",
    "Nebraska", "Oklahoma", "Tennessee", "Auburn", "Stanford", "UCLA", "Florida State",
    "Iowa", "North Carolina", "Virginia Tech", "Texas A&M", "Washington", "Utah",
    "Kansas State", "Baylor", "TCU", "West Virginia", "Pittsburgh", "Syracuse",
    "Boston College", "Louisville", "Cincinnati", "UCF", "Boise State", "BYU",
    "San Diego State", "Fresno State", "Colorado", "Arizona", "Arizona State",
    "Ole Miss", "Mississippi State", "Arkansas", "South Carolina", "Kentucky",
    "Vanderbilt", "Missouri", "Illinois", "Minnesota", "Northwestern", "Purdue",
    "Indiana", "Maryland", "Rutgers", "Duke", "Wake Forest", "NC State", "Virginia",
    "Georgia Tech", "Michigan State", "Iowa State", "Texas Tech", "Houston", "SMU",
    "Memphis", "Navy", "Army", "Air Force", "Marshall", "Appalachian State",
    "Coastal Carolina", "Liberty", "James Madison", "North Dakota State",
]

CITIES = [
    ("Houston", "TX", "USA"), ("Dallas", "TX", "USA"), ("Miami", "FL", "USA"),
    ("Atlanta", "GA", "USA"), ("Phoenix", "AZ", "USA"), ("Philadelphia", "PA", "USA"),
    ("Chicago", "IL", "USA"), ("Los Angeles", "CA", "USA"), ("San Diego", "CA", "USA"),
    ("Seattle", "WA", "USA"), ("Denver", "CO", "USA"), ("Detroit", "MI", "USA"),
    ("Boston", "MA", "USA"), ("Nashville", "TN", "USA"), ("Charlotte", "NC", "USA"),
    ("Indianapolis", "IN", "USA"), ("Columbus", "OH", "USA"), ("Jacksonville", "FL", "USA"),
    ("San Antonio", "TX", "USA"), ("Austin", "TX", "USA"), ("Portland", "OR", "USA"),
    ("Las Vegas", "NV", "USA"), ("Tampa", "FL", "USA"), ("Orlando", "FL", "USA"),
    ("Cleveland", "OH", "USA"), ("Pittsburgh", "PA", "USA"), ("Kansas City", "MO", "USA"),
    ("St. Louis", "MO", "USA"), ("Minneapolis", "MN", "USA"), ("Milwaukee", "WI", "USA"),
    ("Baltimore", "MD", "USA"), ("Richmond", "VA", "USA"), ("Raleigh", "NC", "USA"),
    ("Salt Lake City", "UT", "USA"), ("Tucson", "AZ", "USA"), ("Albuquerque", "NM", "USA"),
    ("Oklahoma City", "OK", "USA"), ("Tulsa", "OK", "USA"), ("New Orleans", "LA", "USA"),
    ("Baton Rouge", "LA", "USA"), ("Birmingham", "AL", "USA"), ("Mobile", "AL", "USA"),
    ("Little Rock", "AR", "USA"), ("Memphis", "TN", "USA"), ("Louisville", "KY", "USA"),
    ("Lexington", "KY", "USA"), ("Cincinnati", "OH", "USA"), ("Buffalo", "NY", "USA"),
    ("Rochester", "NY", "USA"), ("Albany", "NY", "USA"), ("Syracuse", "NY", "USA"),
    ("Toronto", "ON", "Canada"), ("Montreal", "QC", "Canada"), ("Vancouver", "BC", "Canada"),
    ("Calgary", "AB", "Canada"), ("London", "England", "UK"), ("Manchester", "England", "UK"),
    ("Dublin", "Leinster", "Ireland"), ("Sydney", "NSW", "Australia"),
    ("Melbourne", "VIC", "Australia"), ("Brisbane", "QLD", "Australia"),
]

STAT_KEYS = [
    "speed", "strength", "stamina", "awareness",
    "acceleration", "catching", "carrying", "agility", "toughness", "tackling",
    "throw_power", "throw_accuracy", "blocking", "route_running",
    "pass_rush", "coverage", "block_shedding",
    "kick_power", "kick_accuracy",
]


def roll_stat(rng: random.Random) -> int:
    u = rng.random()
    if u < 0.50:
        return rng.randint(1, 3)
    if u < 0.80:
        return rng.randint(4, 6)
    if u < 0.95:
        return rng.randint(7, 9)
    return 10


def height_weight_age(rng: random.Random):
    ft = rng.choice([5, 6])
    inch = rng.randint(8, 11) if ft == 5 else rng.randint(0, 6)
    height = f"{ft}'{inch}\""
    wt = rng.randint(185, 325)
    age = rng.randint(21, 34)
    return height, wt, age


def main() -> None:
    rng = random.Random(20260513)
    teams = json.loads(TEAMS_PATH.read_text(encoding="utf-8"))
    team_ids = [str(t["id"]) for t in teams]
    n_teams = len(team_ids)
    players_out: list[dict] = []
    pid = 1
    used_names: set[tuple[str, str]] = set()

    for ti, tid in enumerate(team_ids):
        jerseys = list(range(1, 100))
        rng.shuffle(jerseys)
        team_players: list[dict] = []

        for _ in range(17):
            for _ in range(200):
                fn = rng.choice(FIRST)
                ln = rng.choice(LAST)
                if (fn, ln) not in used_names:
                    used_names.add((fn, ln))
                    break
            cid = f"{pid:04d}"
            pid += 1
            city, st, country = rng.choice(CITIES)
            hometown = f"{city}, {st}, {country}"
            height, weight, age = height_weight_age(rng)
            jn = jerseys.pop()

            p = {
                "id": cid,
                "first_name": fn,
                "last_name": ln,
                "age": age,
                "college": rng.choice(COLLEGES),
                "hometown": hometown,
                "team": tid,
                "jersey_number": jn,
                "height": height,
                "weight": weight,
            }
            for k in STAT_KEYS:
                p[k] = roll_stat(rng)
            team_players.append(p)

        # Designate specialists by stats (3 distinct)
        def score_kicker(pl):
            return pl["kick_accuracy"] * 2 + pl["kick_power"]

        def score_punter(pl):
            return pl["kick_power"] * 2 + pl["kick_accuracy"]

        def score_returner(pl):
            return pl["speed"] + pl["agility"] + pl["catching"]

        sorted_k = sorted(team_players, key=score_kicker, reverse=True)
        kicker = sorted_k[0]
        rest = [x for x in team_players if x["id"] != kicker["id"]]
        sorted_p = sorted(rest, key=score_punter, reverse=True)
        punter = sorted_p[0]
        rest2 = [x for x in rest if x["id"] != punter["id"]]
        sorted_r = sorted(rest2, key=score_returner, reverse=True)
        returner = sorted_r[0]
        field_pool = [x for x in team_players if x["id"] not in (kicker["id"], punter["id"], returner["id"])]
        assert len(field_pool) == 14

        # Order roster: 7 best offensive profile first (by throw+run composite), then 7 defensive, then specialists
        def off_score(pl):
            return (
                pl["throw_power"] + pl["throw_accuracy"] + pl["route_running"]
                + pl["catching"] + pl["carrying"] + pl["blocking"] + pl["speed"]
            )

        def def_score(pl):
            return pl["tackling"] + pl["coverage"] + pl["pass_rush"] + pl["block_shedding"] + pl["strength"]

        off_sorted = sorted(field_pool, key=off_score, reverse=True)
        off7 = off_sorted[:7]
        off7_ids = {p["id"] for p in off7}
        def_candidates = [p for p in field_pool if p["id"] not in off7_ids]
        def7 = sorted(def_candidates, key=def_score, reverse=True)[:7]

        ordered = off7 + def7 + [kicker, punter, returner]
        assert len(ordered) == 17
        roster_ids = [p["id"] for p in ordered]

        for p in team_players:
            players_out.append(p)

        teams[ti]["roster_player_ids"] = roster_ids

    PLAYERS_PATH.write_text(json.dumps(players_out, indent=2), encoding="utf-8")
    TEAMS_PATH.write_text(json.dumps(teams, indent=2), encoding="utf-8")
    print(f"Wrote {len(players_out)} players, {n_teams} team rosters.")


if __name__ == "__main__":
    main()
