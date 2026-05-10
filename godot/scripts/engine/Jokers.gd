extends Node

const JOKER_COST = 6

const JOKERS = {
	"tiebreaker": {"id": "tiebreaker", "name": "Tiebreaker", "description": "Ties count as wins for you.",                       "cost": 6},
	"underdog":   {"id": "underdog",   "name": "Underdog",   "description": "When your card has lower value: it gains +2.",       "cost": 6},
	"streak":     {"id": "streak",     "name": "Streak",     "description": "Each consecutive flip you win adds +1 to the next.", "cost": 6},
	"sniper":     {"id": "sniper",     "name": "Sniper",     "description": "Your highest card is always among the 5 that flip.", "cost": 6},
	"doubler":    {"id": "doubler",    "name": "Doubler",    "description": "If both flipped cards have same value: +1 to yours.","cost": 6},
	"gambler":    {"id": "gambler",    "name": "Gambler",    "description": "You flip only 4 cards, winning earns +2 mana.",      "cost": 6},
	"pyromancer": {"id": "pyromancer", "name": "Pyromancer", "description": "All your 1s get +3 on reveal.",                     "cost": 6},
	"hoarder":    {"id": "hoarder",    "name": "Hoarder",    "description": "Pile cap raised to 12.",                            "cost": 6}
}

var JOKER_POOL: Array = JOKERS.keys()

func apply_joker_pre_flip(joker_id: String, left_card: Dictionary, right_card: Dictionary,
		left_eff: int, right_eff: int, streak_count: int) -> Dictionary:
	if joker_id.is_empty():
		return {"left_eff": left_eff, "right_eff": right_eff}
	if joker_id == "underdog"   and left_card["value"] < right_card["value"]: left_eff  += 2
	if joker_id == "streak":     left_eff += streak_count
	if joker_id == "doubler"    and left_card["value"] == right_card["value"]: left_eff += 1
	if joker_id == "pyromancer" and left_card["value"] == 1:                   left_eff += 3
	return {"left_eff": left_eff, "right_eff": right_eff}

func apply_joker_tie(joker_id: String, flip: Dictionary) -> Dictionary:
	if joker_id.is_empty() or flip["winner"] != "tie":
		return flip
	if joker_id == "tiebreaker":
		return {"winner": "left", "delta": 0, "joker_note": "tiebreaker"}
	return flip

func joker_mana_bonus_on_win(joker_id: String) -> int:
	if joker_id == "gambler": return 2
	return 0

func joker_pile_cap(joker_id: String) -> int:
	if joker_id == "hoarder": return 12
	return -1

func joker_flip_count(joker_id: String) -> int:
	if joker_id == "gambler": return 4
	return -1

func sniper_anchor_id(pile: Dictionary) -> String:
	var cards: Array = pile["cards"]
	if cards.is_empty(): return ""
	var best = cards[0]
	for card in cards:
		if card["value"] > best["value"]:
			best = card
	return best["id"]
