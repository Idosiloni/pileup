extends Node

const JOKERS = {
	# ── Common (5g) — available from round 3 ──────────────────────────────────
	"fortune":     {"id": "fortune",     "name": "Fortune",     "description": "Win the battle: +3g bonus.",               "cost": 5, "rarity": "common"},
	"ironclad":    {"id": "ironclad",    "name": "Ironclad",    "description": "Your lowest-value card always flips.",     "cost": 5, "rarity": "common"},
	"tiebreaker":  {"id": "tiebreaker",  "name": "Tiebreaker",  "description": "Ties count as wins for you.",              "cost": 5, "rarity": "common"},
	"odd_job":     {"id": "odd_job",     "name": "Odd Job",     "description": "All your odd-value cards: +1 on reveal.", "cost": 5, "rarity": "common"},
	"even_steven": {"id": "even_steven", "name": "Even Steven", "description": "All your even-value cards: +1 on reveal.","cost": 5, "rarity": "common"},
	"scrapper":    {"id": "scrapper",    "name": "Scrapper",    "description": "Battle tie: +1g bonus.",                  "cost": 5, "rarity": "common"},
	# ── Uncommon (6g) — available from round 3 ────────────────────────────────
	"underdog":   {"id": "underdog",   "name": "Underdog",   "description": "Your card has lower value: +2.",          "cost": 6, "rarity": "uncommon"},
	"streak":     {"id": "streak",     "name": "Streak",     "description": "Each consecutive win adds +1 to next.",   "cost": 6, "rarity": "uncommon"},
	"doubler":    {"id": "doubler",    "name": "Doubler",    "description": "Matched values: +1 to yours.",            "cost": 6, "rarity": "uncommon"},
	"pyromancer": {"id": "pyromancer", "name": "Pyromancer", "description": "Your 1s get +3 on reveal.",              "cost": 6, "rarity": "uncommon"},
	"hoarder":    {"id": "hoarder",    "name": "Hoarder",    "description": "Pile cap raised to 12.",                 "cost": 6, "rarity": "uncommon"},
	"balance":    {"id": "balance",    "name": "Balance",    "description": "Ties earn +2g bonus.",                    "cost": 6, "rarity": "uncommon"},
	"opportunist":{"id": "opportunist","name": "Opportunist","description": "Your cards value 5+: +1 on reveal.",     "cost": 6, "rarity": "uncommon"},
	"momentum":   {"id": "momentum",   "name": "Momentum",   "description": "Win battle by 3+: +2g bonus.",           "cost": 6, "rarity": "uncommon"},
	# ── Rare (8g) — available from round 6 ───────────────────────────────────
	"sniper":     {"id": "sniper",     "name": "Sniper",     "description": "Highest card always among the 5 flips.", "cost": 8, "rarity": "rare"},
	"gambler":    {"id": "gambler",    "name": "Gambler",    "description": "Flip 4 cards; battle win earns +2g.",     "cost": 8, "rarity": "rare"},
	"colossus":   {"id": "colossus",   "name": "Colossus",   "description": "Cards value 8-10: +2 on reveal.",        "cost": 8, "rarity": "rare"},
	"time_warp":  {"id": "time_warp",  "name": "Time Warp",  "description": "You flip 6 cards instead of 5.",         "cost": 8, "rarity": "rare"},
}

const JOKER_POOL_BY_RARITY = {
	"common":   ["fortune", "ironclad", "tiebreaker", "odd_job", "even_steven", "scrapper"],
	"uncommon": ["underdog", "streak", "doubler", "pyromancer", "hoarder", "balance", "opportunist", "momentum"],
	"rare":     ["sniper", "gambler", "colossus", "time_warp"]
}

# ── pre-flip joker effects ────────────────────────────────────────────────────
func apply_joker_pre_flip(joker_ids: Array, left_card: Dictionary, right_card: Dictionary,
		left_eff: int, right_eff: int, streak_count: int) -> Dictionary:
	if joker_ids.is_empty():
		return {"left_eff": left_eff, "right_eff": right_eff}
	for jid in joker_ids:
		if jid == "underdog"    and left_card["value"] < right_card["value"]:  left_eff  += 2
		if jid == "streak":    left_eff += streak_count
		if jid == "doubler"    and left_card["value"] == right_card["value"]:  left_eff  += 1
		if jid == "pyromancer" and left_card["value"] == 1:                    left_eff  += 3
		if jid == "opportunist" and left_card["value"] >= 5:                   left_eff  += 1
		if jid == "colossus"   and left_card["value"] >= 8:                    left_eff  += 2
		if jid == "odd_job"    and left_card["value"] % 2 != 0:               left_eff  += 1
		if jid == "even_steven" and left_card["value"] % 2 == 0:              left_eff  += 1
	return {"left_eff": left_eff, "right_eff": right_eff}

# ── tie overrides ─────────────────────────────────────────────────────────────
func apply_joker_tie(joker_ids: Array, flip: Dictionary) -> Dictionary:
	if joker_ids.is_empty() or flip["winner"] != "tie":
		return flip
	for jid in joker_ids:
		if jid == "tiebreaker":
			return {"winner": "left", "delta": 0, "joker_note": "tiebreaker"}
	return flip

# ── mana bonuses (all converted to gold — kept as stubs for compatibility) ───
func joker_mana_bonus_on_win(joker_ids: Array) -> int:
	return 0

func joker_mana_bonus_on_tie(joker_ids: Array) -> int:
	return 0

# ── gold bonuses ──────────────────────────────────────────────────────────────
func joker_gold_bonus_on_win(joker_ids: Array) -> int:
	var bonus = 0
	for jid in joker_ids:
		if jid == "fortune": bonus += 3
		if jid == "gambler": bonus += 2
	return bonus

func joker_gold_bonus_on_tie(joker_ids: Array) -> int:
	var bonus = 0
	for jid in joker_ids:
		if jid == "scrapper": bonus += 1
		if jid == "balance":  bonus += 2
	return bonus

func joker_gold_bonus_on_big_win(joker_ids: Array, margin: int) -> int:
	var bonus = 0
	if margin >= 3:
		for jid in joker_ids:
			if jid == "momentum": bonus += 2
	return bonus

# ── pile modifiers ────────────────────────────────────────────────────────────
func joker_pile_cap(joker_ids: Array) -> int:
	var cap = -1
	for jid in joker_ids:
		if jid == "hoarder": cap = max(cap, 12)
	return cap

func joker_flip_count(joker_ids: Array) -> int:
	var override = -1
	for jid in joker_ids:
		if jid == "gambler":   override = (4 if override < 0 else min(override, 4))
		if jid == "time_warp": override = (6 if override < 0 else max(override, 6))
	return override

# ── highest/lowest anchor helpers ─────────────────────────────────────────────
func sniper_anchor_id(pile: Dictionary) -> String:
	var cards: Array = pile["cards"]
	if cards.is_empty(): return ""
	var best = cards[0]
	for card in cards:
		if card["value"] > best["value"]:
			best = card
	return best["id"]

func ironclad_anchor_id(pile: Dictionary) -> String:
	var cards: Array = pile["cards"]
	if cards.is_empty(): return ""
	var worst = cards[0]
	for card in cards:
		if card["value"] < worst["value"]:
			worst = card
	return worst["id"]
