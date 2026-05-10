extends Node

const REROLL_COST = 1

# ── card packs ─────────────────────────────────────────────────────────────────
const CARD_PACKS = [
	{"id": "basic",    "name": "Basic Pack",    "cost": 2, "min_val": 1, "max_val": 4,  "hint": "value 1–4"},
	{"id": "standard", "name": "Standard Pack", "cost": 4, "min_val": 3, "max_val": 7,  "hint": "value 3–7"},
	{"id": "premium",  "name": "Premium Pack",  "cost": 7, "min_val": 6, "max_val": 10, "hint": "value 6–10"}
]

func packs_for_round(round: int) -> Array:
	if round <= 2: return CARD_PACKS.slice(0, 2)
	return CARD_PACKS

# ── power-up rarity pools ──────────────────────────────────────────────────────
const POWER_UP_POOL = {
	"common":   ["valor", "spite", "blaze", "martyr", "spotlight", "draw_power"],
	"uncommon": ["pierce", "echo", "comeback", "coin_press", "shield", "avenger", "phoenix", "resilience", "bounty"],
	"rare":     ["anchor", "stage_hog", "eclipse", "storm"]
}

func _power_up_rarities_for_round(round: int) -> Array:
	if round <= 1: return ["common"]
	if round <= 2: return ["common", "uncommon"]
	return ["common", "uncommon", "rare"]

func generate_power_ups(count: int = 3, round: int = 1) -> Array:
	var rarities = _power_up_rarities_for_round(round)
	var pool: Array = []
	for rarity in rarities:
		pool += POWER_UP_POOL[rarity]
	var result = []
	for _i in range(mini(count, pool.size())):
		var idx = randi() % pool.size()
		result.append(pool[idx])
		pool.remove_at(idx)
	return result

# ── joker offers (only at rounds 3 and 6) ────────────────────────────────────
func _joker_rarities_for_round(round: int) -> Array:
	if round < 3: return []
	if round < 6: return ["common", "uncommon"]
	return ["common", "uncommon", "rare"]

func generate_joker_offers(round: int, owned_jokers: Array = []) -> Array:
	var rarities = _joker_rarities_for_round(round)
	if rarities.is_empty(): return []
	var pool: Array = []
	for rarity in rarities:
		pool += Jokers.JOKER_POOL_BY_RARITY[rarity]
	# exclude already-owned
	pool = pool.filter(func(j): return not owned_jokers.has(j))
	var result = []
	for _i in range(mini(3, pool.size())):
		var idx = randi() % pool.size()
		result.append(pool[idx])
		pool.remove_at(idx)
	return result

# ── full shop state ────────────────────────────────────────────────────────────
func generate_shop(round: int = 1, owned_jokers: Array = []) -> Dictionary:
	return {
		"packs":        packs_for_round(round),
		"power_ups":    generate_power_ups(3, round),
		"joker_offers": generate_joker_offers(round, owned_jokers)
	}
