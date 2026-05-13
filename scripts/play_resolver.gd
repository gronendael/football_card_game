extends Node
class_name PlayResolver

const BUCKET_RUN := "run"
const BUCKET_PASS := "pass"
const BUCKET_SPOT_KICK := "spot_kick"
const PLAY_PUNT := "punt"
const ZONE_MIDFIELD := 4
const ZONE_ATTACK := 5
const ZONE_RED := 6

var _special_teams: SpecialTeamsResolverLegacy = SpecialTeamsResolverLegacy.new()
var _scrimmage: ScrimmagePlayResolver = ScrimmagePlayResolver.new()


func resolve_scrimmage_play(ctx: PlaySimContext, play_id: String, play_row: Dictionary, bucket: String, selected_player_id: String) -> Dictionary:
	return _scrimmage.resolve(ctx, play_id, play_row, bucket, selected_player_id)


func resolve_spot_kick(selected_player_id: String, current_zone: int, kick_stats: Dictionary, opponent_mod: int = 0) -> Dictionary:
	return _special_teams.resolve_spot_kick(selected_player_id, current_zone, kick_stats, opponent_mod)


func resolve_extra_point(selected_player_id: String, kick_stats: Dictionary, opponent_mod: int = 0) -> Dictionary:
	return _special_teams.resolve_extra_point(selected_player_id, kick_stats, opponent_mod)


func resolve_punt(los_row_engine: int, kick_stats: Dictionary, defense_called_return: bool = false, return_modifiers: Dictionary = {}) -> Dictionary:
	return _special_teams.resolve_punt(los_row_engine, kick_stats, defense_called_return, return_modifiers)
