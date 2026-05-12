extends Node

# cost is used by ShopEngine to price power-ups; rarity gates round availability
const ABILITIES = {
	# ── Common (3g) — available round 1+ ──────────────────────────────────────
	"valor":     {"id": "valor",     "label": "Valor",     "description": "On Win: next ally +1",   "trigger": "on_win",   "rarity": "common",   "cost": 3},
	"spite":     {"id": "spite",     "label": "Spite",     "description": "On Loss: foe next -1",   "trigger": "on_loss",  "rarity": "common",   "cost": 3},
	"blaze":     {"id": "blaze",     "label": "Blaze",     "description": "On Reveal: +2",          "trigger": "on_reveal","rarity": "common",   "cost": 3},
	"martyr":    {"id": "martyr",    "label": "Martyr",    "description": "On Loss: your next +2",  "trigger": "on_loss",  "rarity": "common",   "cost": 3},
	"spotlight": {"id": "spotlight", "label": "Spotlight", "description": "+40 flip weight",        "trigger": "passive",  "rarity": "common",   "cost": 3},
	"bully":     {"id": "bully",     "label": "Bully",     "description": "On Reveal: foe -1",      "trigger": "on_reveal","rarity": "common",   "cost": 3},
	# ── Uncommon (4-5g) — available round 2+ ─────────────────────────────────
	"pierce":    {"id": "pierce",    "label": "Pierce",    "description": "On Tie: count as win",        "trigger": "on_tie",   "rarity": "uncommon", "cost": 4},
	"echo":      {"id": "echo",      "label": "Echo",      "description": "On Reveal: +3",               "trigger": "on_reveal","rarity": "uncommon", "cost": 4},
	"comeback":  {"id": "comeback",  "label": "Comeback",  "description": "On Loss by 3+: +2g",          "trigger": "on_loss",  "rarity": "uncommon", "cost": 4},
	"coin_press":{"id": "coin_press","label": "Coin Press","description": "On Win: +1g",                 "trigger": "on_win",   "rarity": "uncommon", "cost": 5},
	"shield":    {"id": "shield",    "label": "Shield",    "description": "On Win: foe next -2",         "trigger": "on_win",   "rarity": "uncommon", "cost": 4},
	"avenger":   {"id": "avenger",   "label": "Avenger",   "description": "If prev flip lost: +3",       "trigger": "on_reveal","rarity": "uncommon", "cost": 5},
	"phoenix":   {"id": "phoenix",   "label": "Phoenix",   "description": "On Loss: +1g",                "trigger": "on_loss",  "rarity": "uncommon", "cost": 4},
	# ── Rare (6-7g) — available round 3+ ─────────────────────────────────────
	"anchor":       {"id": "anchor",       "label": "Anchor",       "description": "Passive: always flips",              "trigger": "passive",  "rarity": "rare", "cost": 6},
	"stage_hog":    {"id": "stage_hog",    "label": "Stage Hog",   "description": "+90 flip weight",                   "trigger": "passive",  "rarity": "rare", "cost": 6},
	"eclipse":      {"id": "eclipse",      "label": "Eclipse",      "description": "On Reveal: +5",                     "trigger": "on_reveal","rarity": "rare", "cost": 7},
	"storm":        {"id": "storm",        "label": "Storm",        "description": "On Win: foe next -3",               "trigger": "on_win",   "rarity": "rare", "cost": 7},
	"late_bloomer": {"id": "late_bloomer", "label": "Late Bloomer", "description": "+1 value after each battle (max 5)", "trigger": "passive",  "rarity": "rare", "cost": 5},
	# ── Tie-conditional (3-4g) — available round 1+ ───────────────────────────
	"draw_power":  {"id": "draw_power",  "label": "Draw Power",  "description": "On Tie: +1g",             "trigger": "on_tie",  "rarity": "common",   "cost": 3},
	"resilience":  {"id": "resilience",  "label": "Resilience",  "description": "On Tie: next ally +3",     "trigger": "on_tie",  "rarity": "uncommon", "cost": 4},
	# ── Win-conditional (5g) — available round 2+ ─────────────────────────────
	"bounty":      {"id": "bounty",      "label": "Bounty",      "description": "Win by 2+: +2g",           "trigger": "on_win",  "rarity": "uncommon", "cost": 5},
	# ── Positional (3-4g) ─────────────────────────────────────────────────────
	"first_light":  {"id": "first_light",  "label": "First Light",  "description": "Always flips first if drawn",                  "trigger": "passive",  "rarity": "common",   "cost": 3},
	"grand_finale": {"id": "grand_finale", "label": "Grand Finale", "description": "Always flips last if drawn",                   "trigger": "passive",  "rarity": "uncommon", "cost": 4},
	# ── Probability-shift with bonus (4-6g) ───────────────────────────────────
	"wallflower":   {"id": "wallflower",   "label": "Wallflower",   "description": "-50 flip weight, but +3 on reveal",            "trigger": "passive",  "rarity": "uncommon", "cost": 4},
	"reaper":       {"id": "reaper",       "label": "Reaper",       "description": "Win by 5+: foe's next card -3",                "trigger": "on_win",   "rarity": "rare",     "cost": 6},
	"rage_build":   {"id": "rage_build",   "label": "Rage Build",   "description": "+1 per prior loss this battle",               "trigger": "on_reveal","rarity": "rare",     "cost": 6},
	"bitter_end":   {"id": "bitter_end",   "label": "Bitter End",   "description": "Lose by 8+: foe's next card -4",             "trigger": "on_loss",  "rarity": "uncommon", "cost": 4},
	"last_laugh":   {"id": "last_laugh",   "label": "Last Laugh",   "description": "Lose on final flip: +5g",                    "trigger": "on_loss",  "rarity": "uncommon", "cost": 4},
	# ── Epic (9-11g) ──────────────────────────────────────────────────────────────
	"titan":        {"id": "titan",        "label": "Titan",        "description": "On Reveal: +6",                               "trigger": "on_reveal","rarity": "epic",      "cost": 9},
	"fortress":     {"id": "fortress",     "label": "Fortress",     "description": "On Win: foe next -4",                         "trigger": "on_win",   "rarity": "epic",      "cost": 10},
	"warlord":      {"id": "warlord",      "label": "Warlord",      "description": "On Win: your next +3",                        "trigger": "on_win",   "rarity": "epic",      "cost": 10},
	"nemesis":      {"id": "nemesis",      "label": "Nemesis",      "description": "On Loss: your next +4",                       "trigger": "on_loss",  "rarity": "epic",      "cost": 10},
	"phantom":      {"id": "phantom",      "label": "Phantom",      "description": "+100 flip weight",                            "trigger": "passive",  "rarity": "epic",      "cost": 11},
	# ── Legendary (14-16g) ────────────────────────────────────────────────────────
	"godslayer":    {"id": "godslayer",    "label": "Godslayer",    "description": "On Reveal: +9",                               "trigger": "on_reveal","rarity": "legendary", "cost": 14},
	"annihilator":  {"id": "annihilator",  "label": "Annihilator",  "description": "On Win: foe next -6",                         "trigger": "on_win",   "rarity": "legendary", "cost": 15},
	"ascendant":    {"id": "ascendant",    "label": "Ascendant",    "description": "On Reveal: +4, On Win: your next +4",         "trigger": "on_reveal","rarity": "legendary", "cost": 16},
}

# ── reveal events ─────────────────────────────────────────────────────────────
# Returns list of {ability, delta} for all on-reveal abilities a card has.
func on_reveal_events(abilities: Array) -> Array:
	var events = []
	for abl in abilities:
		if abl == "blaze":      events.append({"ability": abl, "delta": 2,  "target": "self"})
		if abl == "echo":       events.append({"ability": abl, "delta": 3,  "target": "self"})
		if abl == "eclipse":    events.append({"ability": abl, "delta": 5,  "target": "self"})
		if abl == "bully":        events.append({"ability": abl, "delta": -1, "target": "opponent"})
		if abl == "wallflower":   events.append({"ability": abl, "delta": 3,  "target": "self"})
		if abl == "titan":        events.append({"ability": abl, "delta": 6,  "target": "self"})
		if abl == "godslayer":    events.append({"ability": abl, "delta": 9,  "target": "self"})
		if abl == "ascendant":    events.append({"ability": abl, "delta": 4,  "target": "self"})
	return events

func on_reveal_bonus(abilities: Array) -> int:
	var total = 0
	for ev in on_reveal_events(abilities):
		if ev.get("target", "self") == "self":
			total += ev["delta"]
	return total

# ── post-flip pending events ───────────────────────────────────────────────────
# Returns events that affect the NEXT flip's effective values.
# "side" = which side's next card is affected; "delta" = pending amount.
func post_flip_events(winner: String, left_abls: Array, right_abls: Array, margin: int = 0) -> Array:
	var events = []
	if winner == "left":
		for abl in left_abls:
			if abl == "valor":
				events.append({"side": "left",  "ability": abl, "trigger": "on_win",  "delta":  1, "next": true})
			if abl == "shield":
				events.append({"side": "right", "ability": abl, "trigger": "on_win",  "delta": -2, "next": true})
			if abl == "storm":
				events.append({"side": "right", "ability": abl, "trigger": "on_win",  "delta": -3, "next": true})
			if abl == "reaper" and margin >= 5:
				events.append({"side": "right", "ability": abl, "trigger": "on_win",  "delta": -3, "next": true})
			if abl == "fortress":
				events.append({"side": "right", "ability": abl, "trigger": "on_win",  "delta": -4, "next": true})
			if abl == "warlord":
				events.append({"side": "left",  "ability": abl, "trigger": "on_win",  "delta":  3, "next": true})
			if abl == "annihilator":
				events.append({"side": "right", "ability": abl, "trigger": "on_win",  "delta": -6, "next": true})
			if abl == "ascendant":
				events.append({"side": "left",  "ability": abl, "trigger": "on_win",  "delta":  4, "next": true})
		for abl in right_abls:
			if abl == "spite":
				events.append({"side": "right", "ability": abl, "trigger": "on_loss", "delta": -1, "next": true})
			if abl == "martyr":
				events.append({"side": "right", "ability": abl, "trigger": "on_loss", "delta":  2, "next": true})
			if abl == "nemesis":
				events.append({"side": "right", "ability": abl, "trigger": "on_loss", "delta":  4, "next": true})
	elif winner == "right":
		for abl in right_abls:
			if abl == "valor":
				events.append({"side": "right", "ability": abl, "trigger": "on_win",  "delta":  1, "next": true})
			if abl == "shield":
				events.append({"side": "left",  "ability": abl, "trigger": "on_win",  "delta": -2, "next": true})
			if abl == "storm":
				events.append({"side": "left",  "ability": abl, "trigger": "on_win",  "delta": -3, "next": true})
			if abl == "fortress":
				events.append({"side": "left",  "ability": abl, "trigger": "on_win",  "delta": -4, "next": true})
			if abl == "warlord":
				events.append({"side": "right", "ability": abl, "trigger": "on_win",  "delta":  3, "next": true})
			if abl == "annihilator":
				events.append({"side": "left",  "ability": abl, "trigger": "on_win",  "delta": -6, "next": true})
			if abl == "ascendant":
				events.append({"side": "right", "ability": abl, "trigger": "on_win",  "delta":  4, "next": true})
		for abl in left_abls:
			if abl == "spite":
				events.append({"side": "left",  "ability": abl, "trigger": "on_loss", "delta": -1, "next": true})
			if abl == "martyr":
				events.append({"side": "left",  "ability": abl, "trigger": "on_loss", "delta":  2, "next": true})
			if abl == "bitter_end" and margin >= 8:
				events.append({"side": "right", "ability": abl, "trigger": "on_loss", "delta": -4, "next": true})
			if abl == "nemesis":
				events.append({"side": "left",  "ability": abl, "trigger": "on_loss", "delta":  4, "next": true})
	elif winner == "tie":
		for abl in left_abls:
			if abl == "resilience":
				events.append({"side": "left",  "ability": abl, "trigger": "on_tie", "delta": 3, "next": true})
		for abl in right_abls:
			if abl == "resilience":
				events.append({"side": "right", "ability": abl, "trigger": "on_tie", "delta": 3, "next": true})
	return events

func post_flip_gold_events(winner: String, left_abls: Array, right_abls: Array, margin: int, is_last_flip: bool = false) -> Array:
	var events = []
	if winner == "right" and left_abls.has("comeback") and margin >= 3:
		events.append({"side": "left",  "ability": "comeback",   "trigger": "on_loss", "delta": 2, "currency": "gold"})
	if winner == "left"  and right_abls.has("comeback") and margin >= 3:
		events.append({"side": "right", "ability": "comeback",   "trigger": "on_loss", "delta": 2, "currency": "gold"})
	if winner == "left"  and left_abls.has("coin_press"):
		events.append({"side": "left",  "ability": "coin_press", "trigger": "on_win",  "delta": 1, "currency": "gold"})
	if winner == "right" and right_abls.has("coin_press"):
		events.append({"side": "right", "ability": "coin_press", "trigger": "on_win",  "delta": 1, "currency": "gold"})
	if winner == "left"  and left_abls.has("bounty") and margin >= 2:
		events.append({"side": "left",  "ability": "bounty",     "trigger": "on_win",  "delta": 2, "currency": "gold"})
	if winner == "right" and right_abls.has("bounty") and margin >= 2:
		events.append({"side": "right", "ability": "bounty",     "trigger": "on_win",  "delta": 2, "currency": "gold"})
	if winner == "tie" and left_abls.has("draw_power"):
		events.append({"side": "left",  "ability": "draw_power", "trigger": "on_tie",  "delta": 1, "currency": "gold"})
	if winner == "tie" and right_abls.has("draw_power"):
		events.append({"side": "right", "ability": "draw_power", "trigger": "on_tie",  "delta": 1, "currency": "gold"})
	if winner == "right" and left_abls.has("phoenix"):
		events.append({"side": "left",  "ability": "phoenix",    "trigger": "on_loss", "delta": 1, "currency": "gold"})
	if winner == "left"  and right_abls.has("phoenix"):
		events.append({"side": "right", "ability": "phoenix",    "trigger": "on_loss", "delta": 1, "currency": "gold"})
	if winner != "left"  and left_abls.has("last_laugh") and is_last_flip:
		events.append({"side": "left",  "ability": "last_laugh", "trigger": "on_loss", "delta": 5, "currency": "gold"})
	if winner != "right" and right_abls.has("last_laugh") and is_last_flip:
		events.append({"side": "right", "ability": "last_laugh", "trigger": "on_loss", "delta": 5, "currency": "gold"})
	return events

# Convenience wrappers returning totals (used by RunEngine / legacy callers)
func post_flip_deltas(winner: String, left_abls: Array, right_abls: Array) -> Dictionary:
	var ld = 0
	var rd = 0
	for ev in post_flip_events(winner, left_abls, right_abls):
		if ev["side"] == "left":  ld += ev["delta"]
		else:                     rd += ev["delta"]
	return {"left_delta": ld, "right_delta": rd}

func post_flip_gold_bonus(winner: String, left_abls: Array, right_abls: Array, margin: int) -> Dictionary:
	var lg = 0
	var rg = 0
	for ev in post_flip_gold_events(winner, left_abls, right_abls, margin):
		if ev["side"] == "left": lg += ev["delta"]
		else:                    rg += ev["delta"]
	return {"left_gold": lg, "right_gold": rg}
