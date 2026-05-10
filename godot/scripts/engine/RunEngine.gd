extends Node

const STARTING_HP   = 25
const STARTING_GOLD = 10
const CARD_COST     = 3
const SELL_COST     = 1
const MIN_PILE_SIZE = 10
const MAX_PILE_SIZE = 14
const UPGRADE_COST  = 3
const MANA_WIN      = 2
const MANA_LOSS     = 1
const MANA_TIE      = 1

func make_run() -> Dictionary:
	return {
		"round":               1,
		"player_hp":           STARTING_HP,
		"ai_hp":               STARTING_HP,
		"gold":                STARTING_GOLD,
		"mana":                0,
		"joker":               "",
		"player_pile":         Cards.make_starter_pile("player"),
		"phase":               "shop",
		"sells_used_this_shop": 0
	}

func effective_pile_cap(run: Dictionary) -> int:
	var cap = Jokers.joker_pile_cap(run.get("joker", ""))
	return cap if cap > 0 else MAX_PILE_SIZE

func can_buy(run: Dictionary) -> bool:
	return run["gold"] >= CARD_COST and run["player_pile"]["cards"].size() < effective_pile_cap(run)

func can_sell(run: Dictionary, card_id: String) -> bool:
	if run.get("sells_used_this_shop", 0) >= 1: return false
	if run["gold"] < SELL_COST: return false
	if run["player_pile"]["cards"].size() <= MIN_PILE_SIZE: return false
	return run["player_pile"]["cards"].any(func(c): return c["id"] == card_id)

func can_upgrade(run: Dictionary) -> bool:
	return run["mana"] >= UPGRADE_COST

func can_buy_joker(run: Dictionary, joker_id: String) -> bool:
	if not Jokers.JOKERS.has(joker_id): return false
	return run["gold"] >= Jokers.JOKERS[joker_id]["cost"] and run.get("joker", "") == ""

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
	if run["mana"] < UPGRADE_COST: return run
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
	new_run["mana"] -= UPGRADE_COST
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
			nc["ability"] = ability_id
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
	var cost = Jokers.JOKERS[joker_id]["cost"]
	if run["gold"] < cost: return run
	var new_run = run.duplicate(true)
	new_run["gold"] -= cost
	new_run["joker"] = joker_id
	return new_run

func apply_battle_result(run: Dictionary, result: Dictionary) -> Dictionary:
	var damage       = mini(3, result.get("margin", 0))
	var new_player_hp = run["player_hp"]
	var new_ai_hp     = run["ai_hp"]
	if result["winner"] == "ai":     new_player_hp = maxi(0, run["player_hp"] - damage)
	if result["winner"] == "player": new_ai_hp     = maxi(0, run["ai_hp"]     - damage)
	var phase = "over" if (new_player_hp <= 0 or new_ai_hp <= 0) else "shop"

	var mana_earned = MANA_TIE
	if result["winner"] == "player": mana_earned = MANA_WIN
	elif result["winner"] == "ai":   mana_earned = MANA_LOSS
	mana_earned += result.get("joker_mana_bonus", 0)

	var new_run = run.duplicate(true)
	new_run["round"]                = run["round"] + 1
	new_run["gold"]                 = STARTING_GOLD + result.get("gold_bonus", 0)
	new_run["mana"]                 = run["mana"] + mana_earned
	new_run["player_hp"]            = new_player_hp
	new_run["ai_hp"]                = new_ai_hp
	new_run["phase"]                = phase
	new_run["sells_used_this_shop"] = 0
	return new_run
