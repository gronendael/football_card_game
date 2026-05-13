extends RefCounted
class_name ScrimmagePlayResolver

const BUCKET_RUN := "run"
const BUCKET_PASS := "pass"

var _pass := PassSimResolver.new()
var _run := RunPlayResolver.new()


func resolve(
	ctx: PlaySimContext,
	play_id: String,
	play_row: Dictionary,
	bucket: String,
	selected_player_id: String
) -> Dictionary:
	var log := PlayEventLog.new()
	var inner: Dictionary
	if bucket == BUCKET_PASS:
		inner = _pass.resolve(ctx, play_row, log)
	elif bucket == BUCKET_RUN:
		inner = _run.resolve(ctx, play_row, selected_player_id, log)
	else:
		inner = {
			"tile_delta": 0,
			"score_delta": 0,
			"success": false,
			"result_text": "Unknown play bucket",
			"incomplete_pass": false,
			"pressure_level": 0,
			"target_receiver_id": "",
			"tackled_by_id": "",
			"broken_tackles": 0,
			"turnover_outcome": {"occurred": false, "calc_lines": []},
		}

	var breakdown: Array = log.to_breakdown_strings()
	var td := int(inner.get("tile_delta", 0))
	breakdown.append("Net tile rows toward goal: %+d" % td)

	var key_matchups: Array = []
	for e in log.events:
		if str(e.get("code", "")) in ["pass_ol_dl", "run_ol_dl", "route_sep"]:
			key_matchups.append(e.duplicate(true))

	return {
		"play_type": play_id,
		"selected_player_id": selected_player_id,
		"success": bool(inner.get("success", td > 0)),
		"tile_delta": td,
		"score_delta": int(inner.get("score_delta", 0)),
		"possession_switch": false,
		"clock_seconds_used": 0,
		"result_text": str(inner.get("result_text", "")),
		"breakdown": breakdown,
		"play_type_bucket": bucket,
		"incomplete_pass": bool(inner.get("incomplete_pass", false)),
		"pressure_level": int(inner.get("pressure_level", 0)),
		"target_receiver_id": str(inner.get("target_receiver_id", "")),
		"tackled_by_id": str(inner.get("tackled_by_id", "")),
		"broken_tackles": int(inner.get("broken_tackles", 0)),
		"event_log": log.events.duplicate(true),
		"key_matchups": key_matchups,
		"turnover_outcome": inner.get("turnover_outcome", {"occurred": false, "calc_lines": []}),
	}
