extends Node

var _card_id_counter: int = 0

const ABILITY_POOL = ["valor", "spite", "blaze", "martyr", "spotlight"]

func next_card_id() -> String:
	_card_id_counter += 1
	return "c" + str(_card_id_counter)

func make_card(value: int, opts: Dictionary = {}) -> Dictionary:
	return {
		"id":        next_card_id(),
		"value":     value,
		"weight":    opts.get("weight", 0),
		"abilities": opts.get("abilities", []),
		"position":  opts.get("position", "")
	}

func make_random_pile(owner_id: String = "anon") -> Dictionary:
	var cards = []
	for i in range(10):
		var r       = randf()
		var ability = ""
		var weight  = 0
		if r < 0.20:
			ability = ABILITY_POOL[randi() % ABILITY_POOL.size()]
		elif r < 0.35:
			weight = 50
		elif r < 0.50:
			weight = -50
		var abilities = [ability] if not ability.is_empty() else []
		cards.append(make_card(randi_range(1, 10), {"weight": weight, "abilities": abilities}))
	return {"cards": cards, "owner_id": owner_id}

func make_starter_pile(owner_id: String = "anon") -> Dictionary:
	var cards = []
	for v in range(1, 11):
		cards.append(make_card(v))
	return {"cards": cards, "owner_id": owner_id}

func upgrade_card_value(card: Dictionary) -> Dictionary:
	var new_card = card.duplicate(true)
	new_card["value"] = card["value"] + 1
	return new_card
