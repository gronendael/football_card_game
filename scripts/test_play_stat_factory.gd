extends RefCounted
class_name TestPlayStatFactory

const STAT_KEYS: Array[String] = [
	"speed", "strength", "stamina", "awareness", "acceleration", "catching", "carrying",
	"agility", "toughness", "tackling", "throw_power", "throw_accuracy", "blocking",
	"route_running", "pass_rush", "coverage", "block_shedding", "kick_power", "kick_accuracy",
]


static func flat_five_player(id: String, label: String) -> Dictionary:
	var d: Dictionary = {
		"id": id,
		"first_name": "Test",
		"last_name": label,
		"team": "test",
	}
	for k in STAT_KEYS:
		d[k] = 5
	return d


## Pool large enough for PlaySimContext role assignment (flat stats → any role fits).
static func build_team_pool(team_key: String, count: int = 14) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for i in count:
		var n := "%s_%02d" % [team_key, i + 1]
		out.append(flat_five_player(n, n))
	return out
