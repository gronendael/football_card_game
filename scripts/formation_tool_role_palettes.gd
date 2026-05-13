extends RefCounted
class_name FormationToolRolePalettes

## Role strings allowed per `formation_shell` (matches docs/Properties.md position lists).


static func roles_for_shell(shell: String) -> Array[String]:
	match shell:
		FormationsCatalog.FORMATION_SHELL_SCRIMMAGE_OFFENSE:
			return _arr(["QB", "RB1", "RB2", "TE1", "TE2", "WR1", "WR2", "WR3", "OL1", "OL2", "OL3"])
		FormationsCatalog.FORMATION_SHELL_SCRIMMAGE_DEFENSE:
			return _arr(["DL1", "DL2", "DL3", "LB1", "LB2", "LB3", "CB1", "CB2", "CB3", "S1", "S2"])
		FormationsCatalog.FORMATION_SHELL_KICK_FG_XP:
			return _arr(["K", "QB", "RB1", "RB2", "OL1", "OL2", "OL3", "OL4", "OL5", "TE1", "TE2", "TE3"])
		FormationsCatalog.FORMATION_SHELL_BLOCK_FG_XP:
			return _arr(["DL1", "DL2", "DL3", "DL4", "DL5", "LB1", "LB2", "LB3", "CB1", "CB2", "S1", "S2"])
		FormationsCatalog.FORMATION_SHELL_PUNT:
			return _arr(["P", "RB1", "RB2", "OL1", "OL2", "OL3", "OL4", "OL5", "TE1", "TE2", "TE3", "GUN1", "GUN2"])
		FormationsCatalog.FORMATION_SHELL_PUNT_RETURN:
			return _arr(["RET1", "RET2", "DL1", "DL2", "DL3", "DL4", "DL5", "LB1", "LB2", "LB3", "CB1", "CB2", "S1", "S2"])
		FormationsCatalog.FORMATION_SHELL_KICKOFF:
			return _arr(["K", "ST1", "ST2", "ST3", "ST4", "ST5", "ST6"])
		FormationsCatalog.FORMATION_SHELL_KICKOFF_RETURN:
			return _arr(["RET1", "RET2", "ST1", "ST2", "ST3", "ST4", "ST5", "ST6"])
		_:
			return _arr([])


static func shell_label(shell: String) -> String:
	match shell:
		FormationsCatalog.FORMATION_SHELL_SCRIMMAGE_OFFENSE:
			return "Scrimmage — Offense"
		FormationsCatalog.FORMATION_SHELL_SCRIMMAGE_DEFENSE:
			return "Scrimmage — Defense"
		FormationsCatalog.FORMATION_SHELL_KICK_FG_XP:
			return "Kick — FG/XP"
		FormationsCatalog.FORMATION_SHELL_BLOCK_FG_XP:
			return "Kick — Block FG/XP"
		FormationsCatalog.FORMATION_SHELL_PUNT:
			return "Punt"
		FormationsCatalog.FORMATION_SHELL_PUNT_RETURN:
			return "Punt return"
		FormationsCatalog.FORMATION_SHELL_KICKOFF:
			return "Kickoff — Offense"
		FormationsCatalog.FORMATION_SHELL_KICKOFF_RETURN:
			return "Kickoff — Defense"
		_:
			return shell


static func _arr(a: Array) -> Array[String]:
	var out: Array[String] = []
	for x in a:
		out.append(str(x))
	return out
