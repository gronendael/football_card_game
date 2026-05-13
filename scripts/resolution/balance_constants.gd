extends RefCounted
class_name ResolutionBalanceConstants

## Raw stat (roughly 40–99 in data) → 1–10 scale for sim math.
static func raw_to_s10(raw: int) -> int:
	return clampi(1 + int((float(raw) - 50.0) / 5.0), 1, 10)


static func noise_small(rng: RandomNumberGenerator) -> int:
	return rng.randi_range(-2, 2)


static func noise_medium(rng: RandomNumberGenerator) -> int:
	return rng.randi_range(-3, 3)
