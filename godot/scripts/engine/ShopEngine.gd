extends Node

const REROLL_COST = 1

# ── power-up rarity pools ──────────────────────────────────────────────────────
const POWER_UP_POOL = {
	"common":   ["valor", "spite", "blaze", "martyr", "spotlight", "draw_power", "bully", "first_light"],
	"uncommon": ["pierce", "echo", "comeback", "coin_press", "shield", "avenger", "phoenix", "resilience", "bounty", "grand_finale", "wallflower"],
	"rare":     ["anchor", "stage_hog", "eclipse", "storm", "late_bloomer", "reaper", "rage_build"]
}

func _power_up_rarities_for_level(shop_level: int) -> Array:
	if shop_level <= 1: return ["common"]
	if shop_level <= 2: return ["common", "uncommon"]
	return ["common", "uncommon", "rare"]

func generate_power_ups(count: int = 3, shop_level: int = 1) -> Array:
	var rarities = _power_up_rarities_for_level(shop_level)
	var pool: Array = []
	for rarity in rarities:
		pool += POWER_UP_POOL[rarity]
	var result = []
	for _i in range(mini(count, pool.size())):
		var idx = randi() % pool.size()
		result.append(pool[idx])
		pool.remove_at(idx)
	return result

# ── joker offers (unlocked at shop level 2) ───────────────────────────────────
func _joker_rarities_for_level(shop_level: int) -> Array:
	if shop_level <= 1: return []
	if shop_level <= 2: return ["common"]
	return ["common", "uncommon", "rare"]

func generate_joker_offers(shop_level: int, owned_jokers: Array = []) -> Array:
	var rarities = _joker_rarities_for_level(shop_level)
	if rarities.is_empty(): return []
	var pool: Array = []
	for rarity in rarities:
		pool += Jokers.JOKER_POOL_BY_RARITY[rarity]
	pool = pool.filter(func(j): return not owned_jokers.has(j))
	var result = []
	for _i in range(mini(3, pool.size())):
		var idx = randi() % pool.size()
		result.append(pool[idx])
		pool.remove_at(idx)
	return result

# ── full shop state ────────────────────────────────────────────────────────────
func generate_shop(shop_level: int = 1, owned_jokers: Array = []) -> Dictionary:
	return {
		"power_ups":    generate_power_ups(3, shop_level),
		"joker_offers": generate_joker_offers(shop_level, owned_jokers)
	}
