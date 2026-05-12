extends Node

const STARTING_HP       = 25
const STARTING_GOLD     = 7
const SELL_COST         = 1
const MIN_PILE_SIZE     = 10
const MAX_PILE_SIZE     = 20
const UPGRADE_COST      = 4
const SHOP_UPGRADE_COST = 4
const MAX_JOKERS        = 2
const MAX_SHOP_LEVEL    = 10

const PERKS = {
	"merchant":    {"id": "merchant",    "name": "Merchant",    "description": "Start each shop with +2g bonus."},
	"veteran":     {"id": "veteran",     "name": "Veteran",     "description": "Your highest starter card has Blaze."},
	"scholar":     {"id": "scholar",     "name": "Scholar",     "description": "Power-ups cost 1g less (min 1g)."},
	"tactician":   {"id": "tactician",   "name": "Tactician",   "description": "Rerolling the shop is free."},
	"aggressor":   {"id": "aggressor",   "name": "Aggressor",   "description": "Your three highest starter cards: +1 value each."},
	"patron":      {"id": "patron",      "name": "Patron",      "description": "Shop upgrades cost 2g less."},
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
		"shop_level":          1,
		"sells_used_this_shop": 0,
		"win_streak":          0
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
	elif perk_id == "aggressor":
		var cards = new_run["player_pile"]["cards"].duplicate(true)
		var sorted_idxs = range(cards.size())
		sorted_idxs.sort_custom(func(a, b): return cards[a]["value"] > cards[b]["value"])
		for rank in range(mini(3, sorted_idxs.size())):
			var idx = sorted_idxs[rank]
			var nc = cards[idx].duplicate(true)
			nc["value"] = nc["value"] + 1
			cards[idx] = nc
		new_run["player_pile"]["cards"] = cards
	return new_run

func effective_pile_cap(run: Dictionary) -> int:
	var cap = Jokers.joker_pile_cap(run.get("jokers", []))
	return cap if cap > 0 else MAX_PILE_SIZE

func can_sell(run: Dictionary, card_id: String) -> bool:
	if run.get("sells_used_this_shop", 0) >= 1: return false
	if run["gold"] < SELL_COST: return false
	if run["player_pile"]["cards"].size() <= MIN_PILE_SIZE: return false
	return run["player_pile"]["cards"].any(func(c): return c["id"] == card_id)

func can_upgrade(run: Dictionary) -> bool:
	return run["gold"] >= UPGRADE_COST

func effective_power_up_cost(run: Dictionary, base_cost: int) -> int:
	return maxi(1, base_cost - 1) if run.get("perk") == "scholar" else base_cost

func effective_max_jokers(run: Dictionary) -> int:
	var override = Jokers.joker_max_jokers(run.get("jokers", []))
	return override if override > 0 else MAX_JOKERS

func can_buy_joker(run: Dictionary, joker_id: String) -> bool:
	if not Jokers.JOKERS.has(joker_id): return false
	if run.get("jokers", []).size() >= effective_max_jokers(run): return false
	if run.get("jokers", []).has(joker_id): return false
	return run["gold"] >= Jokers.JOKERS[joker_id]["cost"]

func effective_shop_upgrade_cost(run: Dictionary) -> int:
	var level = run.get("shop_level", 1)
	var base  = 3 + level  # 4g (lv1→2) … 12g (lv9→10)
	if run.get("perk") == "patron": base = maxi(1, base - 2)
	return base

func can_upgrade_shop(run: Dictionary) -> bool:
	return run.get("shop_level", 1) < MAX_SHOP_LEVEL and run["gold"] >= effective_shop_upgrade_cost(run)

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

func upgrade_shop(run: Dictionary) -> Dictionary:
	if not can_upgrade_shop(run): return run
	var new_run = run.duplicate(true)
	new_run["gold"] -= effective_shop_upgrade_cost(run)
	new_run["shop_level"] = run.get("shop_level", 1) + 1
	return new_run

func apply_battle_result(run: Dictionary, result: Dictionary) -> Dictionary:
	var damage        = mini(3, result.get("margin", 0)) + result.get("extra_damage", 0)
	var new_player_hp = run["player_hp"]
	var new_ai_hp     = run["ai_hp"]
	if result["winner"] == "ai":     new_player_hp = maxi(0, run["player_hp"] - damage)
	if result["winner"] == "player": new_ai_hp     = maxi(0, run["ai_hp"]     - damage)
	# ── Doomsday: ties deal 1 HP damage to opponent ───────────────────────────
	if run.get("jokers", []).has("doomsday") and result["winner"] == "tie":
		new_ai_hp = maxi(0, new_ai_hp - 1)
	var phase = "over" if (new_player_hp <= 0 or new_ai_hp <= 0) else "shop"

	var perk_gold_bonus  = 2 if run.get("perk") == "merchant" else 0
	var frugal_carryover = int(run["gold"] * 0.25) if run.get("jokers", []).has("frugal") else 0
	var new_run = run.duplicate(true)
	var new_round  = run["round"] + 1
	var win_streak = run.get("win_streak", 0)
	if result["winner"] == "player": win_streak += 1
	else:                            win_streak  = 0

	new_run["round"]                = new_round
	new_run["gold"]                 = STARTING_GOLD + result.get("gold_bonus", 0) + perk_gold_bonus + frugal_carryover
	# ── Rampage: win streak 3+ earns +4g per battle victory ──────────────────
	if run.get("jokers", []).has("rampage") and result["winner"] == "player" and win_streak >= 3:
		new_run["gold"] += 4
	new_run["player_hp"]            = new_player_hp
	new_run["ai_hp"]                = new_ai_hp
	new_run["phase"]                = phase
	new_run["shop_level"]           = run.get("shop_level", 1)
	new_run["sells_used_this_shop"] = 0
	new_run["win_streak"]           = win_streak

	# ── Late Bloomer: +1 value per battle (max 5 stacks) ─────────────────────
	var grown_cards = []
	for c in new_run["player_pile"]["cards"]:
		if c.get("abilities", []).has("late_bloomer"):
			var nc     = c.duplicate(true)
			var blooms = nc.get("_bloomer_count", 0)
			if blooms < 5:
				nc["value"]          = nc["value"] + 1
				nc["_bloomer_count"] = blooms + 1
			grown_cards.append(nc)
		else:
			grown_cards.append(c)
	new_run["player_pile"]["cards"] = grown_cards

	# ── Compound Card: random card +1 value after each battle ─────────────
	if run.get("jokers", []).has("compound_card") and new_run["player_pile"]["cards"].size() > 0:
		var idx = randi() % new_run["player_pile"]["cards"].size()
		var cc_cards = new_run["player_pile"]["cards"].duplicate(true)
		var nc       = cc_cards[idx].duplicate(true)
		nc["value"]  = nc["value"] + 1
		cc_cards[idx] = nc
		new_run["player_pile"]["cards"] = cc_cards

	# ── Rolling Stone: consecutive wins → lowest card +2 ──────────────────
	if run.get("jokers", []).has("rolling_stone") and result["winner"] == "player" and win_streak > 0:
		var rs_cards   = new_run["player_pile"]["cards"].duplicate(true)
		var lowest_idx = 0
		for i in range(1, rs_cards.size()):
			if rs_cards[i]["value"] < rs_cards[lowest_idx]["value"]:
				lowest_idx = i
		var nc = rs_cards[lowest_idx].duplicate(true)
		nc["value"]      = nc["value"] + 2
		rs_cards[lowest_idx] = nc
		new_run["player_pile"]["cards"] = rs_cards

	# ── Old Soul: +1 to all cards at the start of round 6 and round 9 ────
	if run.get("jokers", []).has("old_soul") and (new_round == 6 or new_round == 9):
		var os_cards = new_run["player_pile"]["cards"].duplicate(true)
		for i in range(os_cards.size()):
			var nc  = os_cards[i].duplicate(true)
			nc["value"] = nc["value"] + 1
			os_cards[i] = nc
		new_run["player_pile"]["cards"] = os_cards

	# ── Sacrifice: each loss permanently grows a random non-sacrifice card ─
	var sacrifice_count = result.get("left_sacrifice_count", 0)
	if sacrifice_count > 0:
		var sacr_cards = new_run["player_pile"]["cards"].duplicate(true)
		for _s in range(sacrifice_count):
			var targets = []
			for ci in range(sacr_cards.size()):
				if not sacr_cards[ci].get("abilities", []).has("sacrifice"):
					targets.append(ci)
			if targets.is_empty(): break
			var pick = targets[randi() % targets.size()]
			var nc   = sacr_cards[pick].duplicate(true)
			nc["value"] = nc["value"] + 1
			sacr_cards[pick] = nc
		new_run["player_pile"]["cards"] = sacr_cards

	# ── Funeral Procession: flips lost → weight bonus on 8+ value cards ──
	if run.get("jokers", []).has("funeral_procession"):
		var flips_lost = result.get("right_score", 0)
		if flips_lost > 0:
			var fp_cards = new_run["player_pile"]["cards"].duplicate(true)
			for i in range(fp_cards.size()):
				if fp_cards[i]["value"] >= 8:
					var nc = fp_cards[i].duplicate(true)
					nc["weight"] = nc.get("weight", 0) + flips_lost * 10
					fp_cards[i] = nc
			new_run["player_pile"]["cards"] = fp_cards

	return new_run
