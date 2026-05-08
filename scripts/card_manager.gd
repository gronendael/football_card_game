extends Node
class_name CardManager

var cards_db: Array[Dictionary] = []
var _next_instance_serial: int = 1

func setup(cards: Array[Dictionary]) -> void:
	cards_db = cards.duplicate(true)

func build_deck(deck_size: int = 12) -> Array:
	var source := cards_db.duplicate(true)
	source.shuffle()
	var deck: Array = []
	for i in range(min(deck_size, source.size())):
		deck.append(source[i])
	return deck

func draw(hand: Array, deck: Array, discard: Array, count: int, hand_max: int = 5) -> void:
	for _i in range(count):
		if hand.size() >= hand_max:
			return
		if deck.is_empty() and not discard.is_empty():
			deck.assign(discard.duplicate())
			discard.clear()
			deck.shuffle()
		if deck.is_empty():
			return
		var drawn_raw: Variant = deck.pop_back()
		if typeof(drawn_raw) != TYPE_DICTIONARY:
			continue
		var drawn := drawn_raw as Dictionary
		if str(drawn.get("instance_id", "")).is_empty():
			drawn["instance_id"] = "%s#%d" % [str(drawn.get("id", "card")), _next_instance_serial]
			_next_instance_serial += 1
		hand.append(drawn)

func can_afford(card: Dictionary, momentum: int) -> bool:
	return momentum >= int(card.get("cost", 0))

func play_non_targeted_card(card: Dictionary, momentum: int) -> Dictionary:
	var cost := int(card.get("cost", 0))
	if momentum < cost:
		return {"ok": false, "reason": "Not enough Momentum."}
	return {
		"ok": true,
		"momentum_cost": cost,
		"effect_data": card.get("effect_data", {}),
		"description": card.get("description", "")
	}
