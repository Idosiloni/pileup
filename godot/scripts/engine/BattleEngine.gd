extends Node

func resolve_flip(left_card: Dictionary, right_card: Dictionary,
		effective_left: int, effective_right: int) -> Dictionary:
	if effective_left > effective_right:
		return {"winner": "left",  "delta": effective_left  - effective_right}
	if effective_right > effective_left:
		return {"winner": "right", "delta": effective_right - effective_left}
	return {"winner": "tie", "delta": 0}

func simulate_battle(left_pile: Dictionary, right_pile: Dictionary, joker_id: String = "") -> Dictionary:
	# Sniper: guarantee highest-value left card flips
	var left_pile_for_selection = left_pile
	if joker_id == "sniper":
		var anchor_id = Jokers.sniper_anchor_id(left_pile)
		if not anchor_id.is_empty():
			var sniper_cards = []
			for c in left_pile["cards"]:
				if c["id"] == anchor_id:
					var nc = c.duplicate(true)
					nc["_sniper_anchor"] = true
					if nc.get("ability", "") == "":
						nc["ability"] = "anchor"
					sniper_cards.append(nc)
				else:
					sniper_cards.append(c)
			left_pile_for_selection = {"cards": sniper_cards, "owner_id": left_pile["owner_id"]}

	var left_flipped: Array = Selection.select_flipped(left_pile_for_selection)

	# Strip sniper markers and restore original abilities
	if joker_id == "sniper":
		var cleaned = []
		for c in left_flipped:
			if c.get("_sniper_anchor", false):
				var orig_arr = left_pile["cards"].filter(func(o): return o["id"] == c["id"])
				cleaned.append(orig_arr[0] if not orig_arr.is_empty() else c)
			else:
				cleaned.append(c)
		left_flipped = cleaned

	var right_flipped: Array = Selection.select_flipped(right_pile)

	var flip_count_override = Jokers.joker_flip_count(joker_id)
	var flip_count = mini(left_flipped.size(), right_flipped.size())
	if flip_count_override > 0:
		flip_count = mini(flip_count_override, flip_count)

	var flips          = []
	var left_score     = 0
	var right_score    = 0
	var left_pending   = 0
	var right_pending  = 0
	var left_gold_bonus  = 0
	var right_gold_bonus = 0
	var streak_count   = 0

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

		var left_eff  = left_card["value"]  + left_pending
		var right_eff = right_card["value"] + right_pending
		if left_pending  != 0: events.append({"side": "left",  "source": "pending", "delta": left_pending})
		if right_pending != 0: events.append({"side": "right", "source": "pending", "delta": right_pending})
		left_pending  = 0
		right_pending = 0

		# On Reveal
		var l_reveal = Abilities.on_reveal_bonus(left_card.get("ability",  ""))
		var r_reveal = Abilities.on_reveal_bonus(right_card.get("ability", ""))
		if l_reveal != 0:
			left_eff  += l_reveal
			events.append({"side": "left",  "ability": left_card["ability"],  "trigger": "on_reveal", "delta": l_reveal})
		if r_reveal != 0:
			right_eff += r_reveal
			events.append({"side": "right", "ability": right_card["ability"], "trigger": "on_reveal", "delta": r_reveal})

		# Joker pre-flip
		var joker_eff = Jokers.apply_joker_pre_flip(joker_id, left_card, right_card, left_eff, right_eff, streak_count)
		if joker_eff["left_eff"] != left_eff or joker_eff["right_eff"] != right_eff:
			events.append({"source": "joker", "joker_id": joker_id,
				"left_eff": joker_eff["left_eff"], "right_eff": joker_eff["right_eff"]})
		left_eff  = joker_eff["left_eff"]
		right_eff = joker_eff["right_eff"]

		var flip = resolve_flip(left_card, right_card, left_eff, right_eff)

		# Pierce
		if flip["winner"] == "tie":
			if left_card.get("ability") == "pierce":
				flip = {"winner": "left", "delta": 0}
				events.append({"side": "left",  "ability": "pierce", "trigger": "on_tie", "delta": 0, "note": "tie->win"})
			elif right_card.get("ability") == "pierce":
				flip = {"winner": "right", "delta": 0}
				events.append({"side": "right", "ability": "pierce", "trigger": "on_tie", "delta": 0, "note": "tie->win"})

		# Joker tie override
		var joker_flip = Jokers.apply_joker_tie(joker_id, flip)
		if joker_flip != flip:
			events.append({"source": "joker", "joker_id": joker_id, "note": joker_flip.get("joker_note", "")})
			flip = joker_flip

		if flip["winner"] == "left":
			left_score  += 1
			streak_count += 1
		else:
			streak_count = 0
		if flip["winner"] == "right":
			right_score += 1

		# On Win / On Loss
		var deltas = Abilities.post_flip_deltas(flip["winner"],
			left_card.get("ability", ""), right_card.get("ability", ""))
		left_pending  += deltas["left_delta"]
		right_pending += deltas["right_delta"]
		if deltas["left_delta"] != 0:
			events.append({"side": "left",
				"ability": left_card.get("ability", right_card.get("ability", "")),
				"trigger": "on_win" if flip["winner"] == "left" else "on_loss",
				"delta": deltas["left_delta"], "next": true})
		if deltas["right_delta"] != 0:
			events.append({"side": "right",
				"ability": right_card.get("ability", left_card.get("ability", "")),
				"trigger": "on_win" if flip["winner"] == "right" else "on_loss",
				"delta": deltas["right_delta"], "next": true})

		# Comeback gold
		var gold_bonuses = Abilities.post_flip_gold_bonus(flip["winner"],
			left_card.get("ability", ""), right_card.get("ability", ""), flip["delta"])
		if gold_bonuses["left_gold"] != 0:
			left_gold_bonus += gold_bonuses["left_gold"]
			events.append({"side": "left",  "ability": "comeback", "trigger": "on_loss",
				"delta": gold_bonuses["left_gold"], "currency": "gold"})
		if gold_bonuses["right_gold"] != 0:
			right_gold_bonus += gold_bonuses["right_gold"]
			events.append({"side": "right", "ability": "comeback", "trigger": "on_loss",
				"delta": gold_bonuses["right_gold"], "currency": "gold"})

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

	var joker_mana_bonus = Jokers.joker_mana_bonus_on_win(joker_id) if winner == "left" else 0

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
		"margin":           abs(left_score - right_score),
		"left_gold_bonus":  left_gold_bonus,
		"right_gold_bonus": right_gold_bonus,
		"joker_mana_bonus": joker_mana_bonus
	}
