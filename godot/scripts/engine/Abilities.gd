extends Node

const ABILITIES = {
	"valor":    {"id": "valor",    "label": "Valor",    "description": "On Win: next +1",            "trigger": "on_win"},
	"spite":    {"id": "spite",    "label": "Spite",    "description": "On Loss: foe next -1",        "trigger": "on_loss"},
	"blaze":    {"id": "blaze",    "label": "Blaze",    "description": "On Reveal: +2",               "trigger": "on_reveal"},
	"pierce":   {"id": "pierce",   "label": "Pierce",   "description": "On Tie: count as win",        "trigger": "on_tie"},
	"echo":     {"id": "echo",     "label": "Echo",     "description": "On Reveal: +3",               "trigger": "on_reveal"},
	"comeback": {"id": "comeback", "label": "Comeback", "description": "On Loss by 3+: +2g next shop","trigger": "on_loss"},
	"anchor":   {"id": "anchor",   "label": "Anchor",   "description": "Passive: always flips",       "trigger": "passive"}
}

func on_reveal_bonus(ability_id: String) -> int:
	if ability_id == "blaze": return 2
	if ability_id == "echo":  return 3
	return 0

func post_flip_deltas(winner: String, left_ability: String, right_ability: String) -> Dictionary:
	var ld = 0
	var rd = 0
	if winner == "left":
		if left_ability  == "valor": ld += 1
		if right_ability == "spite": ld -= 1
	elif winner == "right":
		if right_ability == "valor": rd += 1
		if left_ability  == "spite": rd -= 1
	return {"left_delta": ld, "right_delta": rd}

func post_flip_gold_bonus(winner: String, left_ability: String, right_ability: String, margin: int) -> Dictionary:
	var left_gold  = 0
	var right_gold = 0
	if winner == "right" and left_ability  == "comeback" and margin >= 3:
		left_gold  += 2
	if winner == "left"  and right_ability == "comeback" and margin >= 3:
		right_gold += 2
	return {"left_gold": left_gold, "right_gold": right_gold}
