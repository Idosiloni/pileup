extends Node

const REROLL_COST = 1

# ── card packs ────────────────────────────────────────────────────────────────
# Buying a pack gives one random card within the value range.
const CARD_PACKS = [
	{"id": "basic",    "name": "Basic Pack",    "cost": 2, "min_val": 1, "max_val": 4,  "hint": "value 1–4"},
	{"id": "standard", "name": "Standard Pack", "cost": 4, "min_val": 3, "max_val": 7,  "hint": "value 3–7"},
	{"id": "premium",  "name": "Premium Pack",  "cost": 7, "min_val": 6, "max_val": 10, "hint": "value 6–10"}
]

# Rounds 1-2: only basic+standard. Round 3+: all three.
func packs_for_round(round: int) -> Array:
	if round <= 2: return CARD_PACKS.slice(0, 2)
	return CARD_PACKS

# ── power-ups ─────────────────────────────────────────────────────────────────
# Buying a power-up lets the player apply an ability to a chosen pile card.
const POWER_UP_COSTS = {
	"valor":    3,
	"spite":    3,
	"blaze":    4,
	"pierce":   4,
	"echo":     5,
	"comeback": 4,
	"anchor":   6
}
const POWER_UP_POOL = ["valor", "spite", "blaze", "pierce", "echo", "comeback", "anchor"]

func generate_power_ups(count: int = 3) -> Array:
	var pool   = POWER_UP_POOL.duplicate()
	var result = []
	for _i in range(mini(count, pool.size())):
		var idx = randi() % pool.size()
		result.append(pool[idx])
		pool.remove_at(idx)
	return result

# ── full shop state ───────────────────────────────────────────────────────────
func generate_shop(round: int = 1) -> Dictionary:
	return {
		"packs":      packs_for_round(round),
		"power_ups":  generate_power_ups(3)
	}
