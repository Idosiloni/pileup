extends Node

const STARTING_HP   = 25
const STARTING_GOLD = 7
const CARD_COST     = 3
const SELL_COST     = 1
const MIN_PILE_SIZE = 10
const MAX_PILE_SIZE = 14
const UPGRADE_COST  = 4
const MAX_JOKERS    = 2

const PERKS = {
	"merchant":    {"id": "merchant",    "name": "Merchant",    "description": "Start each shop with +2g bonus."},
	"veteran":     {"id": "veteran",     "name": "Veteran",     "description": "Your highest starter card has Blaze."},
	"scholar":     {"id": "scholar",     "name": "Scholar",     "description": "Power-ups cost 1g less (min 1g)."},
	"tactician":   {"id": "tactician",   "name": "Tactician",   "description": "Rerolling the shop is free."},
}

func make_run() -> Dictionary:
	return {
		"round":               1,
		"player_hp":           STARTING_HP,
		"ai_hp":               STARTING_HP,
		"gold":                STARTING_GOLD,
		"perk":                "",
		"jokers":              [],
		"player_pile":         Cards.make_starter_pile("player"),
		"phase":               "shop",
		"sells_used_this_shop": 0
	}

func apply_starting_perk(run: Dictionary, perk_id: String) -> Dictionary:
	var new_run = run.duplicate(true)
	new_run["perk"] = perk_id
	if perk_id == "veteran":
		var cards = new_run["player_pile"]["cards"].duplicate(true)
		var best_idx = 0
		for i in range(1, cards.size()):
			if cards[i]["value"] > cards[best_idx]["value"]:
				best_idx = i
		var nc = cards[best_idx].duplicate(true)
		var abls = nc.get("abilities", []).duplicate()
		if not abls.has("blaze"):
			abls.append("blaze")
		nc["abilities"] = abls
		cards[best_idx] = nc
		new_run["player_pile"]["cards"] = cards
	return new_run

func effective_pile_cap(run: Dictionary) -> int:
	var cap = Jokers.joker_pile_cap(run.get("jokers", []))
	return cap if cap > 0 else MAX_PILE_SIZE

func can_buy(run: Dictionary) -> bool:
	return run["gold"] >= CARD_COST and run["player_pile"]["cards"].size() < effective_pile_cap(run)

func can_sell(run: Dictionary, card_id: String) -> bool:
	if run.get("sells_used_this_shop", 0) >= 1: return false
	if run["gold"] < SELL_COST: return false
	if run["player_pile"]["cards"].size() <= MIN_PILE_SIZE: return false
	return run["player_pile"]["cards"].any(func(c): return c["id"] == card_id)

func can_upgrade(run: Dictionary) -> bool:
	return run["gold"] >= UPGRADE_COST

func effective_power_up_cost(run: Dictionary, base_cost: int) -> int:
	return maxi(1, base_cost - 1) if run.get("perk") == "scholar" else base_cost

func can_buy_joker(run: Dictionary, joker_id: String) -> bool:
	if not Jokers.JOKERS.has(joker_id): return false
	if run.get("jokers", []).size() >= MAX_JOKERS: return false
	if run.get("jokers", []).has(joker_id): return false
	return run["gold"] >= Jokers.JOKERS[joker_id]["cost"]

func buy_card(run: Dictionary, card: Dictionary) -> Dictionary:
	if run["gold"] < CARD_COST: return run
	if run["player_pile"]["cards"].size() >= effective_pile_cap(run): return run
	var new_run = run.duplicate(true)
	new_run["gold"] -= CARD_COST
	new_run["player_pile"]["cards"].append(card)
	return new_run

func sell_card(run: Dictionary, card_id: String) -> Dictionary:
	if run.get("sells_used_this_shop", 0) >= 1: return run
	if run["gold"] < SELL_COST: return run
	var remaining = run["player_pile"]["cards"].filter(func(c): return c["id"] != card_id)
	if remaining.size() == run["player_pile"]["cards"].size(): return run
	if remaining.size() < MIN_PILE_SIZE: return run
	var new_run = run.duplicate(true)
	new_run["gold"] -= SELL_COST
	new_run["player_pile"]["cards"] = remaining
	new_run["sells_used_this_shop"] = 1
	return new_run

func upgrade_card(run: Dictionary, card_id: String) -> Dictionary:
	if run["gold"] < UPGRADE_COST: return run
	var found = false
	var new_cards = []
	for c in run["player_pile"]["cards"]:
		if c["id"] == card_id:
			found = true
			new_cards.append(Cards.upgrade_card_value(c))
		else:
			new_cards.append(c)
	if not found: return run
	var new_run = run.duplicate(true)
	new_run["gold"] -= UPGRADE_COST
	new_run["player_pile"]["cards"] = new_cards
	return new_run

func buy_pack(run: Dictionary, pack: Dictionary) -> Dictionary:
	var cost = pack["cost"]
	if run["gold"] < cost: return run
	if run["player_pile"]["cards"].size() >= effective_pile_cap(run): return run
	var new_card = Cards.make_card(randi_range(pack["min_val"], pack["max_val"]))
	var new_run  = run.duplicate(true)
	new_run["gold"] -= cost
	new_run["player_pile"]["cards"].append(new_card)
	return new_run

func can_buy_pack(run: Dictionary, pack: Dictionary) -> bool:
	return run["gold"] >= pack["cost"] and run["player_pile"]["cards"].size() < effective_pile_cap(run)

func buy_power_up(run: Dictionary, card_id: String, ability_id: String, cost: int) -> Dictionary:
	if run["gold"] < cost: return run
	var found     = false
	var new_cards = []
	for c in run["player_pile"]["cards"]:
		if c["id"] == card_id:
			found = true
			var nc = c.duplicate(true)
			var abls = nc.get("abilities", []).duplicate()
			if not abls.has(ability_id):
				abls.append(ability_id)
			nc["abilities"] = abls
			new_cards.append(nc)
		else:
			new_cards.append(c)
	if not found: return run
	var new_run = run.duplicate(true)
	new_run["gold"] -= cost
	new_run["player_pile"]["cards"] = new_cards
	return new_run

func buy_joker(run: Dictionary, joker_id: String) -> Dictionary:
	if not Jokers.JOKERS.has(joker_id): return run
	if run.get("jokers", []).size() >= MAX_JOKERS: return run
	var cost = Jokers.JOKERS[joker_id]["cost"]
	if run["gold"] < cost: return run
	var new_run = run.duplicate(true)
	new_run["gold"] -= cost
	var new_jokers = run["jokers"].duplicate()
	new_jokers.append(joker_id)
	new_run["jokers"] = new_jokers
	return new_run

func apply_battle_result(run: Dictionary, result: Dictionary) -> Dictionary:
	var damage        = mini(3, result.get("margin", 0))
	var new_player_hp = run["player_hp"]
	var new_ai_hp     = run["ai_hp"]
	if result["winner"] == "ai":     new_player_hp = maxi(0, run["player_hp"] - damage)
	if result["winner"] == "player": new_ai_hp     = maxi(0, run["ai_hp"]     - damage)
	var phase = "over" if (new_player_hp <= 0 or new_ai_hp <= 0) else "shop"

	var perk_gold_bonus = 2 if run.get("perk") == "merchant" else 0
	var new_run = run.duplicate(true)
	new_run["round"]                = run["round"] + 1
	new_run["gold"]                 = STARTING_GOLD + result.get("gold_bonus", 0) + perk_gold_bonus
	new_run["player_hp"]            = new_player_hp
	new_run["ai_hp"]                = new_ai_hp
	new_run["phase"]                = phase
	new_run["sells_used_this_shop"] = 0
	return new_run
