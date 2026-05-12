extends Node

const FLIP_COUNT  = 5
const BASE_WEIGHT = 100
const MIN_WEIGHT  = 10

func effective_weight(card: Dictionary) -> int:
	var base = BASE_WEIGHT + card.get("weight", 0)
	var abls = card.get("abilities", [])
	if abls.has("spotlight"):      base += 40
	if abls.has("stage_hog"):      base += 90
	if abls.has("phantom"):        base += 100
	if abls.has("wallflower"):     base -= 50
	if card.get("_weighted_dice"): base += 25
	return max(MIN_WEIGHT, base)

func weighted_sample(pool: Array, count: int) -> Array:
	var remaining = pool.duplicate()
	var picked = []
	for _i in range(count):
		if remaining.is_empty():
			break
		var total_weight = 0
		for card in remaining:
			total_weight += effective_weight(card)
		var roll = randf() * total_weight
		var pick_index = 0
		for j in range(remaining.size()):
			roll -= effective_weight(remaining[j])
			if roll <= 0:
				pick_index = j
				break
		picked.append(remaining[pick_index])
		remaining.remove_at(pick_index)
	return picked

func shuffle_array(arr: Array) -> Array:
	var a = arr.duplicate()
	for i in range(a.size() - 1, 0, -1):
		var j = randi() % (i + 1)
		var tmp = a[i]
		a[i] = a[j]
		a[j] = tmp
	return a

func _has_anchor(card: Dictionary) -> bool:
	return card.get("abilities", []).has("anchor")

func select_flipped(pile: Dictionary) -> Array:
	var cards: Array = pile["cards"]
	if cards.size() <= FLIP_COUNT:
		return shuffle_array(cards)

	var anchor_cards = cards.filter(func(c): return _has_anchor(c))
	var normal_cards  = cards.filter(func(c): return not _has_anchor(c))

	var anchored   = anchor_cards.slice(0, FLIP_COUNT)
	var slots_left = FLIP_COUNT - anchored.size()

	var first_cards   = normal_cards.filter(func(c): return c.get("position") == "first" or c.get("abilities", []).has("first_light"))
	var last_cards    = normal_cards.filter(func(c): return c.get("position") == "last"  or c.get("abilities", []).has("grand_finale"))
	var neutral_cards = normal_cards.filter(func(c): return c.get("position", "") == "" and not c.get("abilities", []).has("first_light") and not c.get("abilities", []).has("grand_finale"))

	var res_first = weighted_sample(first_cards,   min(first_cards.size(),   slots_left))
	var rem1      = slots_left - res_first.size()
	var res_last  = weighted_sample(last_cards,    min(last_cards.size(),    rem1))
	var rem2      = rem1 - res_last.size()
	var middle    = weighted_sample(neutral_cards, rem2)

	var shuffled_middle = shuffle_array(middle + anchored)
	return res_first + shuffled_middle + res_last

func flip_probabilities(pile: Dictionary) -> Array:
	var cards: Array = pile["cards"]
	if cards.size() <= FLIP_COUNT:
		return cards.map(func(_c): return 100)

	var anchor_count = cards.filter(func(c): return _has_anchor(c)).size()
	var anchor_slots = min(anchor_count, FLIP_COUNT)
	var normal_slots = FLIP_COUNT - anchor_slots
	var normal_cards = cards.filter(func(c): return not _has_anchor(c))

	var total_weight = 0
	for card in normal_cards:
		total_weight += effective_weight(card)

	var probs = []
	for card in cards:
		if _has_anchor(card):
			probs.append(100)
		else:
			var w    = effective_weight(card)
			var prob = 1.0 - pow(1.0 - (float(w) / total_weight), normal_slots)
			probs.append(roundi(prob * 100))
	return probs

func pile_stats(pile: Dictionary) -> Dictionary:
	var cards: Array = pile["cards"]
	var n = cards.size()
	if n == 0:
		return {"avg_value": 0.0, "odd_count": 0, "even_count": 0, "total_weight": 0, "expected_value": 0.0}

	var probs        = flip_probabilities(pile)
	var sum_val      = 0
	var odd_count    = 0
	var total_weight = 0
	var expected     = 0.0

	for i in range(n):
		var card = cards[i]
		sum_val      += card["value"]
		if card["value"] % 2 != 0:
			odd_count += 1
		total_weight += card.get("weight", 0)
		expected     += card["value"] * (probs[i] / 100.0)

	return {
		"avg_value":      snappedf(float(sum_val) / n, 0.1),
		"odd_count":      odd_count,
		"even_count":     n - odd_count,
		"total_weight":   total_weight,
		"expected_value": snappedf(expected, 0.1)
	}
