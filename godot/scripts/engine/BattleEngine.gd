extends Node

func resolve_flip(left_card: Dictionary, right_card: Dictionary,
		effective_left: int, effective_right: int) -> Dictionary:
	if effective_left > effective_right:
		return {"winner": "left",  "delta": effective_left  - effective_right}
	if effective_right > effective_left:
		return {"winner": "right", "delta": effective_right - effective_left}
	return {"winner": "tie", "delta": 0}

func _add_ability_to_card(card: Dictionary, ability_id: String) -> Dictionary:
	var nc   = card.duplicate(true)
	var abls = nc.get("abilities", []).duplicate()
	if not abls.has(ability_id):
		abls.append(ability_id)
	nc["abilities"] = abls
	return nc

func simulate_battle(left_pile: Dictionary, right_pile: Dictionary,
		joker_ids: Array = []) -> Dictionary:

	# ── Sniper: guarantee highest-value left card flips ──────────────────────
	var left_pile_for_selection = left_pile
	if joker_ids.has("sniper"):
		var anchor_id = Jokers.sniper_anchor_id(left_pile)
		if not anchor_id.is_empty():
			var sniper_cards = []
			for c in left_pile["cards"]:
				if c["id"] == anchor_id:
					var nc = c.duplicate(true)
					nc["_sniper_anchor"] = true
					nc = _add_ability_to_card(nc, "anchor")
					sniper_cards.append(nc)
				else:
					sniper_cards.append(c)
			left_pile_for_selection = {"cards": sniper_cards, "owner_id": left_pile["owner_id"]}

	# ── Ironclad: guarantee lowest-value left card flips ─────────────────────
	if joker_ids.has("ironclad"):
		var anchor_id = Jokers.ironclad_anchor_id(left_pile)
		if not anchor_id.is_empty():
			var iron_cards = []
			for c in left_pile_for_selection["cards"]:
				if c["id"] == anchor_id:
					var nc = c.duplicate(true)
					nc["_ironclad_anchor"] = true
					nc = _add_ability_to_card(nc, "anchor")
					iron_cards.append(nc)
				else:
					iron_cards.append(c)
			left_pile_for_selection = {"cards": iron_cards, "owner_id": left_pile["owner_id"]}

	var left_flipped: Array = Selection.select_flipped(left_pile_for_selection)

	# Strip joker-added anchor markers; restore original cards from source pile
	var cleaned = []
	for c in left_flipped:
		if c.get("_sniper_anchor", false) or c.get("_ironclad_anchor", false):
			var orig_arr = left_pile["cards"].filter(func(o): return o["id"] == c["id"])
			cleaned.append(orig_arr[0] if not orig_arr.is_empty() else c)
		else:
			cleaned.append(c)
	left_flipped = cleaned

	var right_flipped: Array = Selection.select_flipped(right_pile)

	var flip_count_override = Jokers.joker_flip_count(joker_ids)
	var flip_count          = mini(left_flipped.size(), right_flipped.size())
	if flip_count_override > 0:
		if flip_count_override < flip_count:   # gambler restricts
			flip_count = flip_count_override
		elif flip_count_override > flip_count: # time_warp expands (capped by available)
			flip_count = mini(flip_count_override, mini(left_flipped.size(), right_flipped.size()))

	var flips            = []
	var left_score       = 0
	var right_score      = 0
	var left_pending     = 0
	var right_pending    = 0
	var left_gold_bonus  = 0
	var right_gold_bonus = 0
	var streak_count     = 0
	var prev_winner      = ""

	var left_flipped_ids  = {}
	for c in left_flipped:  left_flipped_ids[c["id"]]  = true
	var right_flipped_ids = {}
	for c in right_flipped: right_flipped_ids[c["id"]] = true

	var left_unflipped  = left_pile["cards"].filter(func(c):  return not left_flipped_ids.has(c["id"]))
	var right_unflipped = right_pile["cards"].filter(func(c): return not right_flipped_ids.has(c["id"]))

	for i in range(flip_count):
		var left_card  = left_flipped[i]
		var right_card = right_flipped[i]
		var events     = []

		var left_abls  = left_card.get("abilities",  [])
		var right_abls = right_card.get("abilities", [])

		var left_eff  = left_card["value"]  + left_pending
		var right_eff = right_card["value"] + right_pending
		if left_pending  != 0: events.append({"side": "left",  "source": "pending", "delta": left_pending})
		if right_pending != 0: events.append({"side": "right", "source": "pending", "delta": right_pending})
		left_pending  = 0
		right_pending = 0

		# ── Avenger: +3 if previous flip was lost ────────────────────────────
		if left_abls.has("avenger") and prev_winner == "right":
			left_eff += 3
			events.append({"side": "left",  "ability": "avenger", "trigger": "on_reveal", "delta": 3})
		if right_abls.has("avenger") and prev_winner == "left":
			right_eff += 3
			events.append({"side": "right", "ability": "avenger", "trigger": "on_reveal", "delta": 3})

		# ── On Reveal ────────────────────────────────────────────────────────
		for rev_ev in Abilities.on_reveal_events(left_abls):
			left_eff += rev_ev["delta"]
			events.append({"side": "left",  "ability": rev_ev["ability"], "trigger": "on_reveal", "delta": rev_ev["delta"]})
		for rev_ev in Abilities.on_reveal_events(right_abls):
			right_eff += rev_ev["delta"]
			events.append({"side": "right", "ability": rev_ev["ability"], "trigger": "on_reveal", "delta": rev_ev["delta"]})

		# ── Joker pre-flip ────────────────────────────────────────────────────
		var joker_eff = Jokers.apply_joker_pre_flip(joker_ids, left_card, right_card, left_eff, right_eff, streak_count)
		if joker_eff["left_eff"] != left_eff or joker_eff["right_eff"] != right_eff:
			events.append({"source": "joker", "joker_ids": joker_ids,
				"left_eff": joker_eff["left_eff"], "right_eff": joker_eff["right_eff"]})
		left_eff  = joker_eff["left_eff"]
		right_eff = joker_eff["right_eff"]

		var flip = resolve_flip(left_card, right_card, left_eff, right_eff)

		# ── Pierce ───────────────────────────────────────────────────────────
		if flip["winner"] == "tie":
			if left_abls.has("pierce"):
				flip = {"winner": "left", "delta": 0}
				events.append({"side": "left",  "ability": "pierce", "trigger": "on_tie", "delta": 0, "note": "tie->win"})
			elif right_abls.has("pierce"):
				flip = {"winner": "right", "delta": 0}
				events.append({"side": "right", "ability": "pierce", "trigger": "on_tie", "delta": 0, "note": "tie->win"})

		# ── Joker tie override ────────────────────────────────────────────────
		var joker_flip = Jokers.apply_joker_tie(joker_ids, flip)
		if joker_flip != flip:
			events.append({"source": "joker", "joker_ids": joker_ids, "note": joker_flip.get("joker_note", "")})
			flip = joker_flip

		if flip["winner"] == "left":
			left_score   += 1
			streak_count += 1
		else:
			streak_count = 0
		if flip["winner"] == "right":
			right_score += 1

		# ── Post-flip pending events (valor, spite, martyr, shield, storm) ──
		for pev in Abilities.post_flip_events(flip["winner"], left_abls, right_abls):
			if pev["side"] == "left":  left_pending  += pev["delta"]
			else:                      right_pending += pev["delta"]
			events.append(pev)

		# ── Post-flip gold events (comeback, coin_press) ────────────────────
		for gev in Abilities.post_flip_gold_events(flip["winner"], left_abls, right_abls, flip["delta"]):
			if gev["side"] == "left":  left_gold_bonus  += gev["delta"]
			else:                      right_gold_bonus += gev["delta"]
			events.append(gev)

		prev_winner = flip["winner"]

		flips.append({
			"index":           i,
			"left":            left_card,
			"right":           right_card,
			"left_effective":  left_eff,
			"right_effective": right_eff,
			"winner":          flip["winner"],
			"delta":           flip["delta"],
			"events":          events
		})

	var winner = "tie"
	if left_score  > right_score: winner = "left"
	elif right_score > left_score: winner = "right"

	var margin = abs(left_score - right_score)

	var joker_gold_bonus = 0
	if winner == "left":
		joker_gold_bonus = Jokers.joker_gold_bonus_on_win(joker_ids)
		joker_gold_bonus += Jokers.joker_gold_bonus_on_big_win(joker_ids, margin)
	elif winner == "tie":
		joker_gold_bonus = Jokers.joker_gold_bonus_on_tie(joker_ids)

	return {
		"left_pile":        left_pile,
		"right_pile":       right_pile,
		"left_flipped":     left_flipped,
		"right_flipped":    right_flipped,
		"left_unflipped":   left_unflipped,
		"right_unflipped":  right_unflipped,
		"flips":            flips,
		"left_score":       left_score,
		"right_score":      right_score,
		"winner":           winner,
		"margin":           margin,
		"left_gold_bonus":  left_gold_bonus + joker_gold_bonus,
		"right_gold_bonus": right_gold_bonus
	}
