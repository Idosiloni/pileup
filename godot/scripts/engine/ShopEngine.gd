extends Node

const REROLL_COST = 1

# ── power-up rarity pools ──────────────────────────────────────────────────────
const POWER_UP_POOL = {
	"common":    ["valor", "spite", "blaze", "martyr", "spotlight", "draw_power", "bully", "first_light"],
	"uncommon":  ["pierce", "echo", "comeback", "coin_press", "shield", "avenger", "phoenix", "resilience", "bounty", "grand_finale", "wallflower", "bitter_end", "last_laugh"],
	"rare":      ["anchor", "stage_hog", "eclipse", "storm", "late_bloomer", "reaper", "rage_build"],
	"epic":      ["titan", "fortress", "warlord", "nemesis", "phantom"],
	"legendary": ["godslayer", "annihilator", "ascendant"],
}

const RARITIES = ["common", "uncommon", "rare", "epic", "legendary"]

# Weighted chances per shop level [common, uncommon, rare, epic, legendary]
# Each row sums to 100.
const RARITY_WEIGHTS = [
	[100,  0,   0,   0,   0],   # level 1
	[ 70, 30,   0,   0,   0],   # level 2
	[ 50, 35,  15,   0,   0],   # level 3
	[ 35, 35,  25,   5,   0],   # level 4
	[ 25, 30,  30,  14,   1],   # level 5
	[ 15, 25,  35,  22,   3],   # level 6
	[ 10, 20,  30,  30,  10],   # level 7
	[  5, 15,  25,  35,  20],   # level 8
	[  2, 10,  20,  35,  33],   # level 9
	[  1,  5,  14,  30,  50],   # level 10
]

func _pick_rarity(shop_level: int) -> String:
	var weights = RARITY_WEIGHTS[clampi(shop_level - 1, 0, 9)]
	var total   = 0
	for w in weights: total += w
	var roll       = randi() % total
	var cumulative = 0
	for i in range(weights.size()):
		cumulative += weights[i]
		if roll < cumulative:
			return RARITIES[i]
	return RARITIES[0]

func generate_power_ups(count: int = 3, shop_level: int = 1) -> Array:
	var result = []
	var used: Dictionary = {}
	var attempts = 0
	while result.size() < count and attempts < 60:
		attempts += 1
		var rarity = _pick_rarity(shop_level)
		var pool   = POWER_UP_POOL.get(rarity, [])
		if pool.is_empty(): continue
		var available = pool.filter(func(a): return not used.has(a))
		if available.is_empty(): continue
		var pick = available[randi() % available.size()]
		used[pick] = true
		result.append(pick)
	return result

# ── joker offers ──────────────────────────────────────────────────────────────
func generate_joker_offers(shop_level: int, owned_jokers: Array = []) -> Array:
	if shop_level <= 1: return []
	var result = []
	var used: Dictionary = {}
	for jid in owned_jokers: used[jid] = true
	var attempts = 0
	while result.size() < 3 and attempts < 60:
		attempts += 1
		var rarity = _pick_rarity(shop_level)
		var pool   = Jokers.JOKER_POOL_BY_RARITY.get(rarity, [])
		if pool.is_empty(): continue
		var available = pool.filter(func(j): return not used.has(j))
		if available.is_empty(): continue
		var pick = available[randi() % available.size()]
		used[pick] = true
		result.append(pick)
	return result

# ── full shop state ────────────────────────────────────────────────────────────
func generate_shop(shop_level: int = 1, owned_jokers: Array = []) -> Dictionary:
	return {
		"power_ups":    generate_power_ups(3, shop_level),
		"joker_offers": generate_joker_offers(shop_level, owned_jokers)
	}
