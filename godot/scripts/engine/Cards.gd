extends Node

var _card_id_counter: int = 0

func next_card_id() -> String:
	_card_id_counter += 1
	return "c" + str(_card_id_counter)

func make_card(value: int, opts: Dictionary = {}) -> Dictionary:
	return {
		"id":        next_card_id(),
		"value":     value,
		"suit":      opts.get("suit", "black"),
		"weight":    opts.get("weight", 0),
		"abilities": opts.get("abilities", []),
		"position":  opts.get("position", "")
	}

# 20-card random pile used for the AI: 10 red + 10 black, varied values/abilities
func make_random_pile(owner_id: String = "anon") -> Dictionary:
	var cards = []
	var suits = []
	for _i in range(10): suits.append("red")
	for _i in range(10): suits.append("black")
	suits.shuffle()
	var ability_pool = [
		"valor", "spite", "blaze", "martyr", "spotlight",
		"pierce", "echo", "shield", "avenger", "bully",
		"coin_press", "comeback", "phoenix", "draw_power", "resilience"
	]
	for i in range(20):
		var r       = randf()
		var ability = ""
		var weight  = 0
		if r < 0.25:
			ability = ability_pool[randi() % ability_pool.size()]
		elif r < 0.38:
			weight = 50
		elif r < 0.50:
			weight = -50
		var abilities = [ability] if not ability.is_empty() else []
		cards.append(make_card(randi_range(1, 10), {"suit": suits[i], "weight": weight, "abilities": abilities}))
	return {"cards": cards, "owner_id": owner_id}

# Player starter: 10 red ♥ (values 1–10) + 10 black ♣ (values 1–10)
func make_starter_pile(owner_id: String = "anon") -> Dictionary:
	var cards = []
	for v in range(1, 11):
		cards.append(make_card(v, {"suit": "red"}))
	for v in range(1, 11):
		cards.append(make_card(v, {"suit": "black"}))
	return {"cards": cards, "owner_id": owner_id}

func upgrade_card_value(card: Dictionary) -> Dictionary:
	var new_card = card.duplicate(true)
	new_card["value"] = card["value"] + 1
	return new_card
