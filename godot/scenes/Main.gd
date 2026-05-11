extends Control

# ── signals ───────────────────────────────────────────────────────────────────
signal flip_continue_pressed

# ── state ─────────────────────────────────────────────────────────────────────
var run_state:             Dictionary = {}
var current_shop:          Dictionary = {}
var battle_active:         bool       = false
var selected_pile_idx:     int        = -1
var pending_power_up_id:   String     = ""
var pending_power_up_cost: int        = 0

# ── ui refs ───────────────────────────────────────────────────────────────────
var status_bar:           Control
var player_hp_label:      Label
var ai_hp_label:          Label
var gold_label:           Label
var round_label:          Label
var joker_status_label:   Label

var shop_section:         Control
var joker_section:        Control
var joker_shop_row:       HBoxContainer
var shop_level_label:     Label
var pile_section:         Control
var pile_count_label:     Label
var pile_stats_label:     Label
var pile_cards_row:       HBoxContainer
var selected_card_panel:  Control

var battle_section:       Control
var arena_status_label:   Label
var left_score_label:     Label
var right_score_label:    Label
var left_staging:         HBoxContainer
var right_staging:        HBoxContainer
var flip_display:         HBoxContainer
var result_label:         Label
var flip_btn:             Button

var log_list:             VBoxContainer
var perk_overlay:         Control = null

# ── palette ───────────────────────────────────────────────────────────────────
const C_BG       = Color(0.05, 0.05, 0.09)
const C_PANEL    = Color(0.09, 0.09, 0.15)
const C_CARD     = Color(0.11, 0.11, 0.20)
const C_SEL      = Color(0.16, 0.16, 0.28)
const C_BTN      = Color(0.16, 0.18, 0.28)
const C_ACCENT   = Color(0.95, 0.78, 0.20)
const C_WIN      = Color(0.22, 0.85, 0.45)
const C_LOSE     = Color(0.90, 0.25, 0.25)
const C_TIE      = Color(0.85, 0.80, 0.25)
const C_TEXT     = Color(0.92, 0.92, 0.96)
const C_DIM      = Color(0.45, 0.45, 0.58)
const C_GOLD     = Color(1.00, 0.82, 0.20)
const C_MANA     = Color(0.45, 0.65, 1.00)
const C_SELL     = Color(0.85, 0.22, 0.22)
const C_FREEZE   = Color(0.22, 0.55, 0.80)
const C_COMMON   = Color(0.55, 0.55, 0.65)
const C_UNCOMMON = Color(0.35, 0.65, 1.00)
const C_RARE     = Color(1.00, 0.75, 0.10)
const C_JOKER    = Color(0.65, 0.30, 1.00)

func ability_color(abl: String) -> Color:
	match abl:
		"valor":      return Color(1.00, 0.80, 0.20)
		"spite":      return Color(0.90, 0.30, 0.30)
		"blaze":      return Color(1.00, 0.55, 0.15)
		"martyr":     return Color(0.80, 0.50, 0.90)
		"spotlight":  return Color(0.98, 0.95, 0.50)
		"pierce":     return Color(0.75, 0.80, 0.95)
		"echo":       return Color(0.70, 0.40, 1.00)
		"comeback":   return Color(0.22, 0.85, 0.45)
		"coin_press": return Color(1.00, 0.75, 0.10)
		"shield":     return Color(0.40, 0.70, 1.00)
		"anchor":     return Color(0.30, 0.65, 1.00)
		"stage_hog":  return Color(1.00, 0.45, 0.75)
		"eclipse":    return Color(0.55, 0.20, 0.95)
		"storm":      return Color(0.45, 0.85, 1.00)
		"avenger":    return Color(0.95, 0.25, 0.40)
		"phoenix":    return Color(1.00, 0.60, 0.20)
		"draw_power":   return Color(0.80, 0.75, 0.20)
		"resilience":   return Color(0.40, 0.80, 0.60)
		"bounty":       return Color(0.95, 0.85, 0.10)
		"bully":        return Color(0.90, 0.50, 0.20)
		"late_bloomer": return Color(0.35, 0.80, 0.35)
		"first_light":  return Color(1.00, 0.95, 0.55)
		"grand_finale": return Color(0.75, 0.45, 1.00)
		"wallflower":   return Color(0.65, 0.50, 0.80)
		"reaper":       return Color(0.45, 0.85, 0.65)
		"rage_build":   return Color(0.95, 0.35, 0.20)
		"bitter_end":   return Color(0.60, 0.20, 0.50)
		"last_laugh":   return Color(0.85, 0.85, 0.30)
	return Color(0.30, 0.30, 0.42)

func rarity_color(rarity: String) -> Color:
	match rarity:
		"common":   return C_COMMON
		"uncommon": return C_UNCOMMON
		"rare":     return C_RARE
	return C_DIM

# ── boot ──────────────────────────────────────────────────────────────────────
func _ready() -> void:
	_build_ui()

# ── ui construction ───────────────────────────────────────────────────────────
func _build_ui() -> void:
	var bg = ColorRect.new()
	bg.color = C_BG
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	# Root layout: header → status → scrollable content → pile (pinned bottom)
	var root = VBoxContainer.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.add_theme_constant_override("separation", 0)
	add_child(root)

	_build_header(root)
	_build_status_bar(root)

	# Scrollable middle content
	var mid_scroll = ScrollContainer.new()
	mid_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	mid_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	root.add_child(mid_scroll)

	var mid_inner = VBoxContainer.new()
	mid_inner.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	mid_inner.add_theme_constant_override("separation", 8)
	mid_scroll.add_child(mid_inner)

	shop_section = VBoxContainer.new()
	shop_section.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	shop_section.add_theme_constant_override("separation", 10)
	shop_section.hide()
	mid_inner.add_child(shop_section)
	_build_shop_section(shop_section)

	battle_section = VBoxContainer.new()
	battle_section.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	battle_section.add_theme_constant_override("separation", 8)
	battle_section.hide()
	mid_inner.add_child(battle_section)
	_build_battle_section(battle_section)

	var log_wrap = _panel(mid_inner, Color(0.07, 0.07, 0.12), 8)
	log_wrap.custom_minimum_size.y = 80
	var log_scroll = ScrollContainer.new()
	log_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	log_scroll.custom_minimum_size.y = 70
	log_wrap.add_child(log_scroll)
	log_list = VBoxContainer.new()
	log_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	log_list.add_theme_constant_override("separation", 2)
	log_scroll.add_child(log_list)

	# Pile section — always visible at the bottom of the screen
	_build_pile_section(root)

func _build_header(parent: Control) -> void:
	var hdr = HBoxContainer.new()
	hdr.add_theme_constant_override("separation", 14)
	parent.add_child(hdr)

	var title = Label.new()
	title.text = "PILEUP"
	title.add_theme_font_size_override("font_size", 28)
	title.add_theme_color_override("font_color", C_ACCENT)
	hdr.add_child(title)

	_spacer(hdr)

	var new_run_btn = _btn(hdr, "New Run", Color(0.16, 0.48, 0.22))
	new_run_btn.custom_minimum_size.x = 100
	new_run_btn.pressed.connect(_on_new_run)

func _build_status_bar(parent: Control) -> void:
	status_bar = _panel(parent, Color(0.08, 0.08, 0.14), 10)
	status_bar.hide()
	var row = HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	status_bar.add_child(row)

	# Player HP
	var pl = HBoxContainer.new()
	pl.add_theme_constant_override("separation", 8)
	row.add_child(pl)
	_lbl(pl, "YOU", C_DIM).add_theme_font_size_override("font_size", 11)
	player_hp_label = _lbl(pl, "25 HP", C_WIN)
	player_hp_label.add_theme_font_size_override("font_size", 16)

	_spacer(row)

	# Center: round, resources, jokers
	var center = VBoxContainer.new()
	center.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_child(center)
	round_label = _lbl(center, "Round 1", C_TEXT)
	round_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	round_label.add_theme_font_size_override("font_size", 13)
	var cur = HBoxContainer.new()
	cur.alignment = BoxContainer.ALIGNMENT_CENTER
	cur.add_theme_constant_override("separation", 16)
	center.add_child(cur)
	gold_label = _lbl(cur, "7g", C_GOLD)
	gold_label.add_theme_font_size_override("font_size", 15)
	joker_status_label = _lbl(center, "", C_JOKER)
	joker_status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	joker_status_label.add_theme_font_size_override("font_size", 11)

	_spacer(row)

	# AI HP
	var ai = HBoxContainer.new()
	ai.add_theme_constant_override("separation", 8)
	row.add_child(ai)
	ai_hp_label = _lbl(ai, "25 HP", C_LOSE)
	ai_hp_label.add_theme_font_size_override("font_size", 16)
	_lbl(ai, "AI", C_DIM).add_theme_font_size_override("font_size", 11)

func _build_shop_section(parent: Control) -> void:
	# ── action bar: title + level + upgrade + reroll + battle ──────────────────
	var actions = HBoxContainer.new()
	actions.add_theme_constant_override("separation", 8)
	parent.add_child(actions)
	_lbl(actions, "SHOP", C_ACCENT).add_theme_font_size_override("font_size", 14)
	shop_level_label = _lbl(actions, "Lvl 1", C_GOLD)
	shop_level_label.add_theme_font_size_override("font_size", 12)
	_spacer(actions)
	var upgrade_shop_btn = _btn(actions, "Upgrade Shop  4g", Color(0.25, 0.18, 0.06))
	upgrade_shop_btn.pressed.connect(_on_upgrade_shop)
	parent.set_meta("upgrade_shop_btn", upgrade_shop_btn)
	var reroll_btn = _btn(actions, "Reroll  1g", C_FREEZE)
	reroll_btn.pressed.connect(_on_reroll)
	var battle_btn = _btn(actions, "⚔  Battle", Color(0.50, 0.22, 0.12))
	battle_btn.pressed.connect(_on_go_battle)

	# ── power-ups ──────────────────────────────────────────────────────────────
	_section_header(parent, "POWER UPS", "Select a card in your pile below, then click Apply")
	var pow_wrap = _panel(parent, Color(0.09, 0.09, 0.15), 14)
	var pow_inner = HBoxContainer.new()
	pow_inner.alignment = BoxContainer.ALIGNMENT_CENTER
	pow_inner.add_theme_constant_override("separation", 16)
	pow_wrap.add_child(pow_inner)
	pow_wrap.set_meta("inner", pow_inner)
	parent.set_meta("pow_wrap", pow_wrap)

	# ── jokers ─────────────────────────────────────────────────────────────────
	joker_section = VBoxContainer.new()
	joker_section.add_theme_constant_override("separation", 6)
	parent.add_child(joker_section)

	var j_hdr = HBoxContainer.new()
	joker_section.add_child(j_hdr)
	var j_title = _lbl(j_hdr, "JOKERS", C_JOKER)
	j_title.add_theme_font_size_override("font_size", 11)
	_spacer(j_hdr)
	var j_cap_lbl = _lbl(j_hdr, "", C_DIM)
	j_cap_lbl.add_theme_font_size_override("font_size", 11)
	joker_section.set_meta("cap_lbl", j_cap_lbl)

	var joker_wrap = _panel(joker_section, Color(0.10, 0.07, 0.18), 12)
	var joker_sb = joker_wrap.get_theme_stylebox("panel").duplicate()
	joker_sb.border_width_left   = 1; joker_sb.border_width_right  = 1
	joker_sb.border_width_top    = 1; joker_sb.border_width_bottom = 1
	joker_sb.border_color = Color(0.45, 0.20, 0.70, 0.6)
	joker_wrap.add_theme_stylebox_override("panel", joker_sb)
	joker_shop_row = HBoxContainer.new()
	joker_shop_row.alignment = BoxContainer.ALIGNMENT_CENTER
	joker_shop_row.add_theme_constant_override("separation", 16)
	joker_wrap.add_child(joker_shop_row)

func _build_pile_section(parent: Control) -> void:
	# Table felt area — always visible at the bottom
	pile_section = PanelContainer.new()
	pile_section.custom_minimum_size.y = 200
	pile_section.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var felt_sb = StyleBoxFlat.new()
	felt_sb.bg_color = Color(0.04, 0.07, 0.05)
	felt_sb.border_width_top = 2
	felt_sb.border_color     = Color(0.18, 0.38, 0.22, 0.7)
	felt_sb.set_content_margin_all(0)
	pile_section.add_theme_stylebox_override("panel", felt_sb)
	parent.add_child(pile_section)

	var mc = MarginContainer.new()
	mc.set_anchors_preset(Control.PRESET_FULL_RECT)
	mc.add_theme_constant_override("margin_left",   12)
	mc.add_theme_constant_override("margin_right",  12)
	mc.add_theme_constant_override("margin_top",    8)
	mc.add_theme_constant_override("margin_bottom", 6)
	pile_section.add_child(mc)

	var vcol = VBoxContainer.new()
	vcol.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vcol.size_flags_vertical   = Control.SIZE_EXPAND_FILL
	vcol.add_theme_constant_override("separation", 4)
	mc.add_child(vcol)

	# Header row
	var pile_hdr = HBoxContainer.new()
	pile_hdr.add_theme_constant_override("separation", 10)
	vcol.add_child(pile_hdr)
	_lbl(pile_hdr, "YOUR PILE", C_ACCENT).add_theme_font_size_override("font_size", 11)
	pile_count_label = _lbl(pile_hdr, "", C_DIM)
	pile_count_label.add_theme_font_size_override("font_size", 10)
	_spacer(pile_hdr)
	pile_stats_label = _lbl(pile_hdr, "", C_DIM)
	pile_stats_label.add_theme_font_size_override("font_size", 10)

	# Scrollable card row with slight overlap for "pile of cards" feel
	var pile_scroll = ScrollContainer.new()
	pile_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	pile_scroll.size_flags_vertical   = Control.SIZE_EXPAND_FILL
	pile_scroll.vertical_scroll_mode  = ScrollContainer.SCROLL_MODE_DISABLED
	vcol.add_child(pile_scroll)
	pile_cards_row = HBoxContainer.new()
	pile_cards_row.add_theme_constant_override("separation", -8)
	pile_scroll.add_child(pile_cards_row)

	# Selected card panel (shown below cards when a card is selected)
	selected_card_panel = _panel(vcol, Color(0.06, 0.09, 0.07), 10)
	var sel_sb = selected_card_panel.get_theme_stylebox("panel").duplicate()
	sel_sb.border_width_top = 1
	sel_sb.border_color = Color(0.18, 0.38, 0.22, 0.6)
	selected_card_panel.add_theme_stylebox_override("panel", sel_sb)
	selected_card_panel.hide()

func _section_header(parent: Control, title: String, hint: String) -> void:
	var row = HBoxContainer.new()
	parent.add_child(row)
	var tl = _lbl(row, title, C_TEXT)
	tl.add_theme_font_size_override("font_size", 11)
	_lbl(row, "  —  " + hint, C_DIM).add_theme_font_size_override("font_size", 10)

func _build_battle_section(parent: Control) -> void:
	var field = HBoxContainer.new()
	field.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	field.add_theme_constant_override("separation", 12)
	parent.add_child(field)

	var left_col = VBoxContainer.new()
	left_col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	field.add_child(left_col)
	_lbl(left_col, "YOU", C_TEXT).add_theme_font_size_override("font_size", 13)
	left_score_label = _lbl(left_col, "Score: 0", C_DIM)

	var arena = VBoxContainer.new()
	arena.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	arena.alignment = BoxContainer.ALIGNMENT_CENTER
	arena.add_theme_constant_override("separation", 10)
	field.add_child(arena)

	arena_status_label = _lbl(arena, "", C_DIM)
	arena_status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	arena_status_label.add_theme_font_size_override("font_size", 12)

	var stag_panel = _panel(arena, Color(0.09, 0.09, 0.16), 10)
	var stag_col = VBoxContainer.new()
	stag_col.add_theme_constant_override("separation", 6)
	stag_panel.add_child(stag_col)
	var ls_row = HBoxContainer.new()
	ls_row.add_theme_constant_override("separation", 6)
	stag_col.add_child(ls_row)
	_lbl(ls_row, "You", C_DIM).add_theme_font_size_override("font_size", 10)
	left_staging = HBoxContainer.new()
	left_staging.add_theme_constant_override("separation", 4)
	ls_row.add_child(left_staging)
	var rs_row = HBoxContainer.new()
	rs_row.add_theme_constant_override("separation", 6)
	stag_col.add_child(rs_row)
	_lbl(rs_row, "AI", C_DIM).add_theme_font_size_override("font_size", 10)
	right_staging = HBoxContainer.new()
	right_staging.add_theme_constant_override("separation", 4)
	rs_row.add_child(right_staging)

	flip_display = HBoxContainer.new()
	flip_display.alignment = BoxContainer.ALIGNMENT_CENTER
	flip_display.add_theme_constant_override("separation", 16)
	arena.add_child(flip_display)

	result_label = _lbl(arena, "", C_TEXT)
	result_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	result_label.add_theme_font_size_override("font_size", 20)

	flip_btn = _btn(arena, "Flip Card", Color(0.22, 0.32, 0.55))
	flip_btn.custom_minimum_size = Vector2(160, 44)
	flip_btn.disabled = true
	flip_btn.pressed.connect(_on_flip_btn)

	var right_col = VBoxContainer.new()
	right_col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	field.add_child(right_col)
	var ail = _lbl(right_col, "AI", C_TEXT)
	ail.add_theme_font_size_override("font_size", 13)
	ail.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	right_score_label = _lbl(right_col, "Score: 0", C_DIM)
	right_score_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT

# ── card visual ───────────────────────────────────────────────────────────────
func _card_suit(suit_name: String) -> String:
	return "♥" if suit_name == "red" else "♣"

func _make_card(parent: Control, card: Dictionary, w: float, h: float,
		selected: bool = false, prob: int = -1) -> PanelContainer:
	var abls      = card.get("abilities", [])
	var val       = card["value"]
	var suit_name = card.get("suit", "black")
	var is_red    = suit_name == "red"
	var suit      = _card_suit(suit_name)
	var has_abls  = not abls.is_empty()
	var first_abl = abls[0] if has_abls else ""
	var base_suit_clr = Color(0.85, 0.22, 0.22) if is_red else Color(0.38, 0.32, 0.55)
	var abl_clr  = ability_color(first_abl) if has_abls else base_suit_clr
	var border   = C_ACCENT if selected else (abl_clr if has_abls else base_suit_clr)
	var large    = h >= 110

	var cp = PanelContainer.new()
	cp.custom_minimum_size = Vector2(w, h)
	var sb = StyleBoxFlat.new()
	var card_bg = Color(0.20, 0.10, 0.14) if is_red else Color(0.12, 0.10, 0.22)
	sb.bg_color = Color(0.22, 0.14, 0.20) if (selected and is_red) else (Color(0.17, 0.14, 0.30) if selected else card_bg)
	sb.set_corner_radius_all(8)
	var bw = 3 if selected else 2
	sb.border_width_left   = bw; sb.border_width_right  = bw
	sb.border_width_top    = bw; sb.border_width_bottom = bw
	sb.border_color  = border
	sb.shadow_color  = Color(0, 0, 0, 0.65)
	sb.shadow_size   = 6
	sb.shadow_offset = Vector2(0, 3)
	sb.set_content_margin_all(0)
	cp.add_theme_stylebox_override("panel", sb)
	parent.add_child(cp)

	var mc = MarginContainer.new()
	mc.set_anchors_preset(Control.PRESET_FULL_RECT)
	var pad = 5 if large else 4
	mc.add_theme_constant_override("margin_left",   pad)
	mc.add_theme_constant_override("margin_right",  pad)
	mc.add_theme_constant_override("margin_top",    pad)
	mc.add_theme_constant_override("margin_bottom", pad)
	cp.add_child(mc)

	var col = VBoxContainer.new()
	col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	col.size_flags_vertical   = Control.SIZE_EXPAND_FILL
	col.add_theme_constant_override("separation", 0)
	mc.add_child(col)

	# Corner pip row: value (left) + suit (right)
	var top_row = HBoxContainer.new()
	top_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	col.add_child(top_row)

	var corner_val = Label.new()
	corner_val.text = str(val)
	corner_val.add_theme_font_size_override("font_size", 10 if large else 8)
	corner_val.add_theme_color_override("font_color", C_TEXT)
	top_row.add_child(corner_val)

	var spc = Control.new()
	spc.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top_row.add_child(spc)

	var corner_suit = Label.new()
	corner_suit.text = suit
	corner_suit.add_theme_font_size_override("font_size", 10 if large else 8)
	corner_suit.add_theme_color_override("font_color", abl_clr)
	top_row.add_child(corner_suit)

	# Center art area
	var center = VBoxContainer.new()
	center.size_flags_vertical   = Control.SIZE_EXPAND_FILL
	center.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	center.alignment = BoxContainer.ALIGNMENT_CENTER
	center.add_theme_constant_override("separation", 1)
	col.add_child(center)

	var deco = Label.new()
	deco.text = suit
	deco.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	deco.add_theme_font_size_override("font_size", 18 if large else 12)
	deco.add_theme_color_override("font_color", abl_clr)
	deco.modulate.a = 0.30
	center.add_child(deco)

	var val_lbl = Label.new()
	val_lbl.text = str(val)
	val_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	val_lbl.add_theme_font_size_override("font_size", 36 if large else 22)
	val_lbl.add_theme_color_override("font_color", C_TEXT)
	center.add_child(val_lbl)

	var wt = card.get("weight", 0)
	if wt != 0:
		var wl = Label.new()
		wl.text = ("+" if wt > 0 else "") + str(wt) + "w"
		wl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		wl.add_theme_font_size_override("font_size", 8)
		wl.add_theme_color_override("font_color", C_WIN if wt > 0 else C_LOSE)
		center.add_child(wl)

	if prob >= 0:
		var pl = Label.new()
		pl.text = str(prob) + "%"
		pl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		pl.add_theme_font_size_override("font_size", 8)
		pl.add_theme_color_override("font_color", C_DIM)
		center.add_child(pl)

	# Ability strip at bottom (divider + labels)
	if has_abls:
		var div = ColorRect.new()
		div.custom_minimum_size = Vector2(0, 1)
		div.color = abl_clr.darkened(0.35)
		col.add_child(div)

		var abl_mc = MarginContainer.new()
		abl_mc.add_theme_constant_override("margin_top",    2)
		abl_mc.add_theme_constant_override("margin_bottom", 1)
		col.add_child(abl_mc)

		var abl_col = VBoxContainer.new()
		abl_col.add_theme_constant_override("separation", 1)
		abl_mc.add_child(abl_col)

		for abl in abls:
			var al = Label.new()
			al.text = _ability_short(abl)
			al.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			al.add_theme_font_size_override("font_size", 8)
			al.add_theme_color_override("font_color", ability_color(abl))
			al.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			abl_col.add_child(al)

	return cp

# Abbreviated label for small card display
func _ability_short(abl: String) -> String:
	if not Abilities.ABILITIES.has(abl): return abl
	return Abilities.ABILITIES[abl]["label"]

# ── run status ─────────────────────────────────────────────────────────────────
func _update_status() -> void:
	player_hp_label.text = str(run_state["player_hp"]) + " HP"
	ai_hp_label.text     = str(run_state["ai_hp"])     + " HP"
	gold_label.text      = str(run_state["gold"])      + "g"
	round_label.text     = "Round " + str(run_state["round"])
	var joker_ids   = run_state.get("jokers", [])
	var joker_names = joker_ids.map(func(j): return Jokers.JOKERS[j]["name"])
	joker_status_label.text = "  •  ".join(joker_names) if not joker_names.is_empty() else ""

# ── shop phase ─────────────────────────────────────────────────────────────────
func show_shop_phase() -> void:
	battle_section.hide()
	shop_section.show()
	selected_pile_idx    = -1
	pending_power_up_id  = ""
	var shop_level = run_state.get("shop_level", 1)
	current_shop = ShopEngine.generate_shop(shop_level, run_state.get("jokers", []))
	# Update shop level label and upgrade button
	shop_level_label.text = "Lvl " + str(shop_level)
	var upg_btn = shop_section.get_meta("upgrade_shop_btn")
	if shop_level >= RunEngine.MAX_SHOP_LEVEL:
		upg_btn.text     = "Max Level"
		upg_btn.disabled = true
	else:
		upg_btn.text     = "Upgrade Shop  " + str(RunEngine.effective_shop_upgrade_cost(run_state)) + "g"
		upg_btn.disabled = not RunEngine.can_upgrade_shop(run_state)
	render_shop_power_ups()
	render_joker_shop()
	render_pile_cards()
	_update_status()
	# Show perk on status bar
	var perk_id = run_state.get("perk", "")
	if perk_id != "" and RunEngine.PERKS.has(perk_id):
		joker_status_label.text = "[" + RunEngine.PERKS[perk_id]["name"] + "]  " + joker_status_label.text

func render_shop_power_ups() -> void:
	var pow_wrap = shop_section.get_meta("pow_wrap")
	var inner    = pow_wrap.get_meta("inner")
	for c in inner.get_children(): c.queue_free()

	for abl_id in current_shop["power_ups"]:
		if not Abilities.ABILITIES.has(abl_id): continue
		var abl  = Abilities.ABILITIES[abl_id]
		var cost = RunEngine.effective_power_up_cost(run_state, abl["cost"])
		var col  = ability_color(abl_id)
		var rar  = abl.get("rarity", "common")
		var can  = run_state["gold"] >= cost

		var wrap = VBoxContainer.new()
		wrap.add_theme_constant_override("separation", 8)
		wrap.custom_minimum_size.x = 148
		inner.add_child(wrap)

		var pp = _panel(wrap, Color(0.10, 0.10, 0.18).lerp(col, 0.07), 14)
		# Rarity border
		var pp_sb = pp.get_theme_stylebox("panel").duplicate()
		pp_sb.border_width_left   = 2
		pp_sb.border_width_right  = 2
		pp_sb.border_width_top    = 2
		pp_sb.border_width_bottom = 2
		pp_sb.border_color = rarity_color(rar)
		pp.add_theme_stylebox_override("panel", pp_sb)

		var pc = VBoxContainer.new()
		pc.alignment = BoxContainer.ALIGNMENT_CENTER
		pc.add_theme_constant_override("separation", 4)
		pp.add_child(pc)

		# Rarity tag
		var rar_lbl = _lbl(pc, rar.to_upper(), rarity_color(rar))
		rar_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		rar_lbl.add_theme_font_size_override("font_size", 9)

		var nl = _lbl(pc, abl["label"], col)
		nl.add_theme_font_size_override("font_size", 15)
		nl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		var dl = _lbl(pc, abl["description"], C_DIM)
		dl.add_theme_font_size_override("font_size", 10)
		dl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		dl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART

		var bb = _cost_btn(wrap, cost, "Apply to Card",
			col.darkened(0.45) if can else Color(0.10, 0.10, 0.16))
		bb.disabled = not can
		var aid_ref  = abl_id
		var cost_ref = cost
		bb.pressed.connect(func():
			pending_power_up_id   = aid_ref
			pending_power_up_cost = cost_ref
			selected_pile_idx = -1
			render_pile_cards()
		)

func render_joker_shop() -> void:
	for c in joker_shop_row.get_children(): c.queue_free()
	var shop_level = run_state.get("shop_level", 1)
	var joker_ids  = run_state.get("jokers", [])
	var cap_lbl    = joker_section.get_meta("cap_lbl")
	joker_section.show()

	if shop_level < 2:
		cap_lbl.text = "Upgrade shop to level 2 to unlock jokers"
		return

	var max_j = RunEngine.MAX_JOKERS
	cap_lbl.text = "Jokers full (" + str(max_j) + "/" + str(max_j) + ")" if joker_ids.size() >= max_j \
		else str(joker_ids.size()) + " / " + str(max_j) + " jokers"

	for jid in joker_ids:
		var jd   = Jokers.JOKERS[jid]
		var wrap = VBoxContainer.new()
		wrap.add_theme_constant_override("separation", 6)
		wrap.custom_minimum_size.x = 160
		joker_shop_row.add_child(wrap)
		_joker_card_panel(wrap, jd, true)

	if joker_ids.size() >= max_j:
		return

	for offer_jid in current_shop.get("joker_offers", []):
		var jd  = Jokers.JOKERS[offer_jid]
		var can = RunEngine.can_buy_joker(run_state, offer_jid)
		var wrap = VBoxContainer.new()
		wrap.add_theme_constant_override("separation", 6)
		wrap.custom_minimum_size.x = 160
		joker_shop_row.add_child(wrap)
		_joker_card_panel(wrap, jd, false)
		var bb = _cost_btn(wrap, jd["cost"], "Buy Joker",
			Color(0.30, 0.15, 0.50) if can else Color(0.12, 0.08, 0.18))
		bb.disabled = not can
		var jid_ref = offer_jid
		bb.pressed.connect(func():
			run_state = RunEngine.buy_joker(run_state, jid_ref)
			_update_status()
			render_joker_shop()
		)

func _joker_card_panel(parent: Control, jd: Dictionary, owned: bool) -> PanelContainer:
	var rar = jd.get("rarity", "common")
	var rc  = rarity_color(rar)
	var jp  = PanelContainer.new()
	jp.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var jsb = StyleBoxFlat.new()
	jsb.bg_color = Color(0.12, 0.08, 0.22) if not owned else Color(0.16, 0.10, 0.28)
	jsb.set_corner_radius_all(8)
	jsb.border_width_left   = 2
	jsb.border_width_right  = 2
	jsb.border_width_top    = 2
	jsb.border_width_bottom = 2
	jsb.border_color = rc
	jsb.shadow_color  = Color(0, 0, 0, 0.4)
	jsb.shadow_size   = 4
	jsb.set_content_margin_all(10)
	jp.add_theme_stylebox_override("panel", jsb)
	parent.add_child(jp)

	var jc = VBoxContainer.new()
	jc.add_theme_constant_override("separation", 4)
	jp.add_child(jc)

	var rl = _lbl(jc, (rar + ("  ★ OWNED" if owned else "")).to_upper(), rc)
	rl.add_theme_font_size_override("font_size", 9)
	rl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

	var nl = _lbl(jc, jd["name"], C_JOKER if not owned else C_ACCENT)
	nl.add_theme_font_size_override("font_size", 14)
	nl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

	var dl = _lbl(jc, jd["description"], C_DIM)
	dl.add_theme_font_size_override("font_size", 10)
	dl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	dl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART

	return jp

func render_pile_cards() -> void:
	for c in pile_cards_row.get_children(): c.queue_free()
	selected_card_panel.hide()
	for c in selected_card_panel.get_children(): c.queue_free()

	var cards = run_state["player_pile"]["cards"]
	var cap   = RunEngine.effective_pile_cap(run_state)
	pile_count_label.text = "  " + str(cards.size()) + " / " + str(cap)

	var stats = Selection.pile_stats(run_state["player_pile"])
	pile_stats_label.text = "avg " + str(stats["avg_value"]) + "  •  exp " + str(stats["expected_value"])

	var probs = Selection.flip_probabilities(run_state["player_pile"])

	# Power-up mode banner (only in shop)
	if not pending_power_up_id.is_empty() and not battle_active:
		selected_card_panel.show()
		var banner_row = HBoxContainer.new()
		banner_row.add_theme_constant_override("separation", 12)
		selected_card_panel.add_child(banner_row)
		var abl_col = ability_color(pending_power_up_id)
		if Abilities.ABILITIES.has(pending_power_up_id):
			var bl = _lbl(banner_row,
				"Select a card to apply  " + Abilities.ABILITIES[pending_power_up_id]["label"], abl_col)
			bl.add_theme_font_size_override("font_size", 12)
		_spacer(banner_row)
		var cancel = _btn(banner_row, "Cancel", Color(0.20, 0.10, 0.10))
		cancel.pressed.connect(func():
			pending_power_up_id = ""
			render_pile_cards()
		)

	for i in range(cards.size()):
		var card   = cards[i]
		var is_sel = (i == selected_pile_idx) and pending_power_up_id.is_empty()
		var glow   = not pending_power_up_id.is_empty()
		var cv     = _make_card(pile_cards_row, card, 72, 110, is_sel or glow, probs[i])
		if battle_active: continue  # not interactive during battle
		cv.mouse_filter = Control.MOUSE_FILTER_STOP
		var idx = i
		cv.gui_input.connect(func(ev):
			if not (ev is InputEventMouseButton and ev.button_index == MOUSE_BUTTON_LEFT and ev.pressed):
				return
			if not pending_power_up_id.is_empty():
				run_state = RunEngine.buy_power_up(
					run_state, cards[idx]["id"], pending_power_up_id, pending_power_up_cost)
				pending_power_up_id = ""
				_update_status()
				render_shop_power_ups()
				render_pile_cards()
			else:
				selected_pile_idx = -1 if (selected_pile_idx == idx) else idx
				render_pile_cards()
		)

	if selected_pile_idx >= 0 and selected_pile_idx < cards.size() and pending_power_up_id.is_empty():
		_render_selected_panel(cards[selected_pile_idx], probs[selected_pile_idx])

func _render_selected_panel(card: Dictionary, prob: int) -> void:
	selected_card_panel.show()
	var row = HBoxContainer.new()
	row.add_theme_constant_override("separation", 20)
	selected_card_panel.add_child(row)

	_make_card(row, card, 72, 110)

	var info = VBoxContainer.new()
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info.add_theme_constant_override("separation", 6)
	row.add_child(info)

	var abls = card.get("abilities", [])
	if abls.is_empty():
		_lbl(info, "No abilities", C_DIM).add_theme_font_size_override("font_size", 12)
	else:
		for abl in abls:
			if Abilities.ABILITIES.has(abl):
				var ab_data = Abilities.ABILITIES[abl]
				var row2 = HBoxContainer.new()
				row2.add_theme_constant_override("separation", 6)
				info.add_child(row2)
				var dot = _lbl(row2, "●", ability_color(abl))
				dot.add_theme_font_size_override("font_size", 10)
				var desc = _lbl(row2, ab_data["label"] + ": " + ab_data["description"], ability_color(abl))
				desc.add_theme_font_size_override("font_size", 12)

	var wt = card.get("weight", 0)
	if wt != 0:
		_lbl(info, ("+" if wt > 0 else "") + str(wt) + " flip weight", C_DIM).add_theme_font_size_override("font_size", 11)
	_lbl(info, str(prob) + "% flip chance", C_DIM).add_theme_font_size_override("font_size", 11)

	_spacer(info)

	var act = HBoxContainer.new()
	act.add_theme_constant_override("separation", 10)
	info.add_child(act)

	var can_up = RunEngine.can_upgrade(run_state)
	var up_btn = _btn(act, "Upgrade  " + str(RunEngine.UPGRADE_COST) + "g",
		Color(0.16, 0.34, 0.56) if can_up else Color(0.10, 0.12, 0.18))
	up_btn.disabled = not can_up
	var cid = card["id"]
	up_btn.pressed.connect(func():
		run_state = RunEngine.upgrade_card(run_state, cid)
		_update_status()
		render_pile_cards()
	)

	var can_sell = RunEngine.can_sell(run_state, card["id"])
	var sell_btn = _btn(act, "Sell  -" + str(RunEngine.SELL_COST) + "g",
		Color(0.42, 0.12, 0.12) if can_sell else Color(0.16, 0.10, 0.10))
	sell_btn.disabled = not can_sell
	sell_btn.pressed.connect(func():
		run_state = RunEngine.sell_card(run_state, cid)
		selected_pile_idx = -1
		_update_status()
		render_pile_cards()
	)

	var close_btn = _btn(act, "✕", Color(0.18, 0.18, 0.26))
	close_btn.pressed.connect(func():
		selected_pile_idx = -1
		render_pile_cards()
	)

# ── battle phase ───────────────────────────────────────────────────────────────
func show_battle_phase() -> void:
	shop_section.hide()
	battle_section.show()
	run_battle()

func run_battle() -> void:
	if battle_active: return
	battle_active = true
	selected_pile_idx   = -1
	pending_power_up_id = ""
	render_pile_cards()

	for c in log_list.get_children():    c.queue_free()
	for c in left_staging.get_children():  c.queue_free()
	for c in right_staging.get_children(): c.queue_free()
	for c in flip_display.get_children():  c.queue_free()
	result_label.text       = ""
	arena_status_label.text = ""
	flip_btn.disabled       = true
	flip_btn.text           = "Flip Card"
	left_score_label.text   = "Score: 0"
	right_score_label.text  = "Score: 0"

	var left_pile  = run_state["player_pile"]
	var right_pile = Cards.make_random_pile("ai")
	var joker_ids  = run_state.get("jokers", [])

	_log("You:  [" + ", ".join(left_pile["cards"].map(func(c): return str(c["value"]))) + "]")
	_log("AI:   [" + ", ".join(right_pile["cards"].map(func(c): return str(c["value"]))) + "]")

	var result      = BattleEngine.simulate_battle(left_pile, right_pile, joker_ids)
	var left_score  = 0
	var right_score = 0

	# ── The Hush ──────────────────────────────────────────────────────────────
	await _do_hush(result["left_flipped"].size(), result["right_flipped"].size())

	for i in range(result["flips"].size()):
		var flip = result["flips"][i]

		arena_status_label.text = "Flip " + str(i + 1) + " of " + str(result["flips"].size())
		flip_btn.text    = "Flip Card"
		flip_btn.disabled = false
		await flip_continue_pressed
		flip_btn.disabled = true

		await _animate_flip(flip)

		if flip["winner"] == "left":  left_score  += 1
		if flip["winner"] == "right": right_score += 1
		left_score_label.text  = "Score: " + str(left_score)
		right_score_label.text = "Score: " + str(right_score)

		var lo = "win" if flip["winner"] == "left"  else ("tie" if flip["winner"] == "tie" else "lose")
		var ro = "win" if flip["winner"] == "right" else ("tie" if flip["winner"] == "tie" else "lose")
		_add_history(left_staging,  _card_str(flip["left"],  flip["left_effective"]),  lo)
		_add_history(right_staging, _card_str(flip["right"], flip["right_effective"]), ro)

		var who = "tie" if flip["winner"] == "tie" else \
			(("You" if flip["winner"] == "left" else "AI") + " +" + str(flip["delta"]))
		_log("Flip " + str(i+1) + ": You " + _card_str(flip["left"], flip["left_effective"]) +
			" vs AI " + _card_str(flip["right"], flip["right_effective"]) + " — " + who)
		for ev in flip["events"]:
			if ev.get("trigger") and ev.get("ability"):
				var side = "You" if ev["side"] == "left" else "AI"
				var delta_str = ("+" if ev.get("delta", 0) > 0 else "") + str(ev.get("delta", 0))
				var suffix = " (next)" if ev.get("next") else (" [" + ev.get("currency", "") + "]" if ev.get("currency") else "")
				_log("  " + side + " " + ev["ability"] + " [" + ev["trigger"] + "]: " + delta_str + suffix)

	# ── Battle result flair ───────────────────────────────────────────────────
	var win_text = ""
	if result["winner"] == "tie":
		win_text = "TIED  " + str(left_score) + "–" + str(right_score)
	else:
		var who   = "YOU WIN" if result["winner"] == "left" else "AI WINS"
		var sc    = str(maxi(left_score, right_score)) + "–" + str(mini(left_score, right_score))
		var flair = ""
		if result["margin"] == result["flips"].size(): flair = "  SWEEP!"
		elif result["margin"] == 1:                    flair = "  Nail-biter!"
		win_text = who + "  " + sc + flair
	result_label.text = win_text
	result_label.add_theme_color_override("font_color",
		C_WIN if result["winner"] == "left" else (C_LOSE if result["winner"] == "right" else C_TIE))
	_log("=== " + win_text + " ===")

	# ── Reveal Window ─────────────────────────────────────────────────────────
	await _show_reveal_window(result["left_unflipped"], result["right_unflipped"])

	var bw = "player" if result["winner"] == "left" else ("ai" if result["winner"] == "right" else "tie")
	var extra_dmg = result.get("chain_lightning_bonus", 0) if bw == "player" else 0
	run_state = RunEngine.apply_battle_result(run_state, {
		"winner": bw, "margin": result["margin"],
		"gold_bonus": result["left_gold_bonus"],
		"extra_damage": extra_dmg
	})
	_update_status()
	battle_active = false

	if run_state["phase"] == "over":
		arena_status_label.text = "AI wins the run!" if run_state["player_hp"] <= 0 else "You win the run!"
		flip_btn.text    = "New Run"
		flip_btn.disabled = false
		await flip_continue_pressed
		_on_new_run()
	else:
		flip_btn.text    = "Continue →"
		flip_btn.disabled = false
		await flip_continue_pressed
		show_shop_phase()

# ── The Hush: pre-battle dramatic pause ───────────────────────────────────────
func _do_hush(n_left: int, n_right: int) -> void:
	for c in flip_display.get_children():
		flip_display.remove_child(c)
		c.queue_free()

	arena_status_label.text = "— The Hush —"
	arena_status_label.add_theme_color_override("font_color", C_ACCENT)

	var hrow = HBoxContainer.new()
	hrow.alignment = BoxContainer.ALIGNMENT_CENTER
	hrow.add_theme_constant_override("separation", 24)
	flip_display.add_child(hrow)

	var lside = HBoxContainer.new(); lside.add_theme_constant_override("separation", 5)
	hrow.add_child(lside)
	var lbl_vs = _lbl(hrow, "VS", C_DIM); lbl_vs.add_theme_font_size_override("font_size", 18)
	var rside = HBoxContainer.new(); rside.add_theme_constant_override("separation", 5)
	hrow.add_child(rside)

	for _i in range(n_left):  _hush_card(lside)
	for _i in range(n_right): _hush_card(rside)

	# Stagger fade-in
	var all_cards = lside.get_children() + rside.get_children()
	for card in all_cards: card.modulate = Color(1, 1, 1, 0)
	var tw_in = create_tween()
	tw_in.set_parallel(true)
	for i in range(all_cards.size()):
		tw_in.tween_property(all_cards[i], "modulate:a", 1.0, 0.15).set_delay(i * 0.07)
	await tw_in.finished

	# Pulse status label during the hush
	var pulse = create_tween()
	pulse.set_loops(2)
	pulse.tween_property(arena_status_label, "modulate:a", 0.4, 0.35)
	pulse.tween_property(arena_status_label, "modulate:a", 1.0, 0.35)
	await get_tree().create_timer(1.5).timeout
	pulse.kill()
	arena_status_label.modulate.a = 1.0

	# Fade out
	var tw_out = create_tween()
	tw_out.tween_property(hrow, "modulate:a", 0.0, 0.25)
	await tw_out.finished
	for c in flip_display.get_children():
		flip_display.remove_child(c)
		c.queue_free()
	arena_status_label.text = ""
	arena_status_label.add_theme_color_override("font_color", C_DIM)

func _hush_card(parent: Control) -> PanelContainer:
	var cp = PanelContainer.new()
	cp.custom_minimum_size = Vector2(46, 62)
	var sb = StyleBoxFlat.new()
	sb.bg_color = Color(0.10, 0.08, 0.20)
	sb.set_corner_radius_all(8)
	sb.border_width_left   = 2; sb.border_width_right  = 2
	sb.border_width_top    = 2; sb.border_width_bottom = 2
	sb.border_color = Color(0.38, 0.26, 0.65)
	sb.shadow_color = Color(0, 0, 0, 0.55); sb.shadow_size = 5
	sb.shadow_offset = Vector2(0, 2)
	sb.set_content_margin_all(0)
	cp.add_theme_stylebox_override("panel", sb)
	parent.add_child(cp)

	var mc = MarginContainer.new()
	mc.set_anchors_preset(Control.PRESET_FULL_RECT)
	mc.add_theme_constant_override("margin_left",   4)
	mc.add_theme_constant_override("margin_right",  4)
	mc.add_theme_constant_override("margin_top",    4)
	mc.add_theme_constant_override("margin_bottom", 4)
	cp.add_child(mc)

	var col = VBoxContainer.new()
	col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	col.size_flags_vertical   = Control.SIZE_EXPAND_FILL
	col.alignment = BoxContainer.ALIGNMENT_CENTER
	mc.add_child(col)

	# Top-left corner dot
	var top_dot = Label.new()
	top_dot.text = "◆"
	top_dot.add_theme_font_size_override("font_size", 7)
	top_dot.add_theme_color_override("font_color", Color(0.38, 0.26, 0.65))
	col.add_child(top_dot)

	# Center pattern
	var center = Label.new()
	center.text = "◆\n◆◆\n◆"
	center.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	center.add_theme_font_size_override("font_size", 10)
	center.add_theme_color_override("font_color", Color(0.30, 0.22, 0.50))
	center.size_flags_vertical = Control.SIZE_EXPAND_FILL
	center.vertical_alignment  = VERTICAL_ALIGNMENT_CENTER
	col.add_child(center)

	# Bottom-right corner dot
	var bot_row = HBoxContainer.new()
	bot_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	col.add_child(bot_row)
	var spc = Control.new(); spc.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bot_row.add_child(spc)
	var bot_dot = Label.new()
	bot_dot.text = "◆"
	bot_dot.add_theme_font_size_override("font_size", 7)
	bot_dot.add_theme_color_override("font_color", Color(0.38, 0.26, 0.65))
	bot_row.add_child(bot_dot)

	return cp

# ── Reveal Window: show cards that didn't flip ────────────────────────────────
func _show_reveal_window(left_unflipped: Array, right_unflipped: Array) -> void:
	if left_unflipped.is_empty() and right_unflipped.is_empty(): return
	for c in flip_display.get_children():
		flip_display.remove_child(c)
		c.queue_free()

	arena_status_label.text = "Cards that stayed home:"
	arena_status_label.add_theme_color_override("font_color", C_DIM)

	var col = VBoxContainer.new()
	col.alignment = BoxContainer.ALIGNMENT_CENTER
	col.add_theme_constant_override("separation", 8)
	col.modulate = Color(1, 1, 1, 0)
	flip_display.add_child(col)

	if not left_unflipped.is_empty():
		var row = HBoxContainer.new()
		row.alignment = BoxContainer.ALIGNMENT_CENTER
		row.add_theme_constant_override("separation", 6)
		col.add_child(row)
		_lbl(row, "You:", C_DIM).add_theme_font_size_override("font_size", 10)
		for card in left_unflipped:
			_make_card(row, card, 50, 68)

	if not right_unflipped.is_empty():
		var row = HBoxContainer.new()
		row.alignment = BoxContainer.ALIGNMENT_CENTER
		row.add_theme_constant_override("separation", 6)
		col.add_child(row)
		_lbl(row, "AI:", C_DIM).add_theme_font_size_override("font_size", 10)
		for card in right_unflipped:
			_make_card(row, card, 50, 68)

	var tw_in = create_tween()
	tw_in.tween_property(col, "modulate:a", 1.0, 0.45)
	await tw_in.finished
	await get_tree().create_timer(2.2).timeout
	var tw_out = create_tween()
	tw_out.tween_property(col, "modulate:a", 0.0, 0.3)
	await tw_out.finished
	for c in flip_display.get_children():
		flip_display.remove_child(c)
		c.queue_free()
	arena_status_label.text = ""

# ── battle animations ──────────────────────────────────────────────────────────
func _animate_flip(flip: Dictionary) -> void:
	# Show face-down cards
	_show_face_down()

	# Set pivot to card center for scale pulse
	var fd_nodes = flip_display.get_children()
	for c in fd_nodes:
		if c is PanelContainer:
			c.pivot_offset = Vector2(50, 70)

	# Breathe in — suspense pulse
	var tw_in = create_tween()
	tw_in.set_parallel(true)
	for c in fd_nodes:
		if c is PanelContainer:
			tw_in.tween_property(c, "scale", Vector2(1.07, 1.07), 0.30).set_ease(Tween.EASE_OUT)
	await tw_in.finished

	# Breathe out
	var tw_out = create_tween()
	tw_out.set_parallel(true)
	for c in fd_nodes:
		if c is PanelContainer:
			tw_out.tween_property(c, "scale", Vector2(1.0, 1.0), 0.22).set_ease(Tween.EASE_IN)
	await tw_out.finished

	# Brief dramatic pause
	await get_tree().create_timer(0.18).timeout

	# Fold (scale X → 0)
	var children = flip_display.get_children()
	if children.size() >= 3:
		var lv = children[0]
		var rv = children[2]
		var tw1 = create_tween()
		tw1.set_parallel(true)
		tw1.tween_property(lv, "scale:x", 0.0, 0.22).set_ease(Tween.EASE_IN)
		tw1.tween_property(rv, "scale:x", 0.0, 0.22).set_ease(Tween.EASE_IN).set_delay(0.08)
		await tw1.finished

	# Replace with revealed cards at scale 0, then unfold
	for c in flip_display.get_children():
		flip_display.remove_child(c)
		c.queue_free()
	var lc = C_WIN if flip["winner"] == "left" else (C_TIE if flip["winner"] == "tie" else C_LOSE)
	var rc = C_WIN if flip["winner"] == "right" else (C_TIE if flip["winner"] == "tie" else C_LOSE)

	var lv2 = _make_card(flip_display, flip["left"],  100, 140)
	lv2.scale = Vector2(0.0, 1.0)
	lv2.pivot_offset = Vector2(50, 70)
	_lbl(flip_display, "vs", C_DIM).add_theme_font_size_override("font_size", 18)
	var rv2 = _make_card(flip_display, flip["right"], 100, 140)
	rv2.scale = Vector2(0.0, 1.0)
	rv2.pivot_offset = Vector2(50, 70)

	var tw2 = create_tween()
	tw2.set_parallel(true)
	tw2.tween_property(lv2, "scale:x", 1.0, 0.25).set_ease(Tween.EASE_OUT)
	tw2.tween_property(rv2, "scale:x", 1.0, 0.25).set_ease(Tween.EASE_OUT).set_delay(0.08)
	await tw2.finished

	# Flash result color on borders
	for pair in [[lv2, lc], [rv2, rc]]:
		var pn  = pair[0]
		var col = pair[1]
		var bsb = pn.get_theme_stylebox("panel").duplicate()
		bsb.border_color        = col
		bsb.border_width_left   = 3
		bsb.border_width_right  = 3
		bsb.border_width_top    = 3
		bsb.border_width_bottom = 3
		pn.add_theme_stylebox_override("panel", bsb)

	# Linger on the result
	await get_tree().create_timer(0.6).timeout

func _show_face_down() -> void:
	for c in flip_display.get_children():
		flip_display.remove_child(c)
		c.queue_free()
	_face_down_card(flip_display)
	_lbl(flip_display, "vs", C_DIM).add_theme_font_size_override("font_size", 18)
	_face_down_card(flip_display)

func _face_down_card(parent: Control) -> PanelContainer:
	var cp = PanelContainer.new()
	cp.custom_minimum_size = Vector2(100, 140)
	var sb = StyleBoxFlat.new()
	sb.bg_color = Color(0.10, 0.10, 0.18)
	sb.set_corner_radius_all(10)
	sb.border_width_left   = 2
	sb.border_width_right  = 2
	sb.border_width_top    = 2
	sb.border_width_bottom = 2
	sb.border_color = Color(0.22, 0.22, 0.38)
	sb.shadow_color = Color(0, 0, 0, 0.5)
	sb.shadow_size  = 6
	sb.set_content_margin_all(8)
	cp.add_theme_stylebox_override("panel", sb)
	parent.add_child(cp)
	var l = Label.new()
	l.text = "?"
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.vertical_alignment   = VERTICAL_ALIGNMENT_CENTER
	l.add_theme_font_size_override("font_size", 38)
	l.add_theme_color_override("font_color", Color(0.28, 0.28, 0.48))
	l.set_anchors_preset(Control.PRESET_FULL_RECT)
	cp.add_child(l)
	return cp

func _add_history(row: HBoxContainer, txt: String, outcome: String) -> void:
	var col = C_WIN if outcome == "win" else (C_LOSE if outcome == "lose" else C_TIE)
	var cp  = PanelContainer.new()
	cp.custom_minimum_size = Vector2(36, 36)
	var sb = StyleBoxFlat.new()
	sb.bg_color = col.darkened(0.5)
	sb.border_color        = col
	sb.border_width_left   = 2
	sb.border_width_right  = 2
	sb.border_width_top    = 2
	sb.border_width_bottom = 2
	sb.set_corner_radius_all(4)
	sb.set_content_margin_all(4)
	cp.add_theme_stylebox_override("panel", sb)
	row.add_child(cp)
	var l = Label.new()
	l.text = txt
	l.add_theme_color_override("font_color", col)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.add_theme_font_size_override("font_size", 11)
	cp.add_child(l)

func _log(msg: String) -> void:
	var l = Label.new()
	l.text = msg
	l.add_theme_color_override("font_color", C_DIM)
	l.add_theme_font_size_override("font_size", 11)
	log_list.add_child(l)

func _card_str(card: Dictionary, eff: int) -> String:
	return str(card["value"]) + "→" + str(eff) if eff != card["value"] else str(card["value"])

# ── ui factory ─────────────────────────────────────────────────────────────────
func _panel(parent: Control, color: Color = C_PANEL, pad: int = 8) -> PanelContainer:
	var pc = PanelContainer.new()
	var sb = StyleBoxFlat.new()
	sb.bg_color = color
	sb.set_corner_radius_all(6)
	sb.set_content_margin_all(pad)
	pc.add_theme_stylebox_override("panel", sb)
	pc.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	parent.add_child(pc)
	return pc

func _btn(parent: Control, text: String, color: Color = C_BTN) -> Button:
	var b = Button.new()
	b.text = text
	var sb = StyleBoxFlat.new()
	sb.bg_color = color
	sb.set_corner_radius_all(5)
	sb.set_content_margin_all(8)
	b.add_theme_stylebox_override("normal", sb)
	var sb_hov = sb.duplicate(); sb_hov.bg_color = color.lightened(0.18)
	b.add_theme_stylebox_override("hover", sb_hov)
	var sb_dis = sb.duplicate(); sb_dis.bg_color = color.darkened(0.55)
	b.add_theme_stylebox_override("disabled", sb_dis)
	b.add_theme_color_override("font_color",          C_TEXT)
	b.add_theme_color_override("font_hover_color",    C_TEXT)
	b.add_theme_color_override("font_disabled_color", C_DIM)
	b.add_theme_font_size_override("font_size", 13)
	parent.add_child(b)
	return b

# Button with a leading gold-colored cost badge
func _cost_btn(parent: Control, cost: int, label: String, color: Color) -> Button:
	return _btn(parent, str(cost) + "g  " + label, color)

func _lbl(parent: Control, text: String, color: Color = C_TEXT) -> Label:
	var l = Label.new()
	l.text = text
	l.add_theme_color_override("font_color", color)
	parent.add_child(l)
	return l

func _spacer(parent: Control) -> Control:
	var s = Control.new()
	s.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	parent.add_child(s)
	return s

# ── perk selection ─────────────────────────────────────────────────────────────
func _show_perk_selection() -> void:
	if perk_overlay:
		perk_overlay.queue_free()
	perk_overlay = Control.new()
	perk_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	perk_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(perk_overlay)

	var bg = ColorRect.new()
	bg.color = Color(0.0, 0.0, 0.0, 0.82)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	perk_overlay.add_child(bg)

	var center = CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	perk_overlay.add_child(center)

	var box = VBoxContainer.new()
	box.custom_minimum_size = Vector2(740, 0)
	box.add_theme_constant_override("separation", 20)
	center.add_child(box)

	var title = Label.new()
	title.text = "CHOOSE YOUR PERK"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 28)
	title.add_theme_color_override("font_color", C_ACCENT)
	box.add_child(title)

	var sub = Label.new()
	sub.text = "A passive bonus that lasts the entire run  —  choose wisely"
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sub.add_theme_font_size_override("font_size", 12)
	sub.add_theme_color_override("font_color", C_DIM)
	box.add_child(sub)

	var row = HBoxContainer.new()
	row.add_theme_constant_override("separation", 14)
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_child(row)

	for perk_id in RunEngine.PERKS.keys():
		var perk = RunEngine.PERKS[perk_id]
		var wp = VBoxContainer.new()
		wp.custom_minimum_size = Vector2(162, 0)
		wp.add_theme_constant_override("separation", 10)
		row.add_child(wp)

		var pp = _panel(wp, Color(0.10, 0.12, 0.22), 18)
		var sb = pp.get_theme_stylebox("panel").duplicate()
		sb.border_width_left   = 2
		sb.border_width_right  = 2
		sb.border_width_top    = 2
		sb.border_width_bottom = 2
		sb.border_color = C_ACCENT.darkened(0.35)
		sb.shadow_color = Color(0, 0, 0, 0.5)
		sb.shadow_size  = 8
		pp.add_theme_stylebox_override("panel", sb)

		var pc = VBoxContainer.new()
		pc.add_theme_constant_override("separation", 10)
		pc.alignment = BoxContainer.ALIGNMENT_CENTER
		pp.add_child(pc)

		var nl = _lbl(pc, perk["name"], C_ACCENT)
		nl.add_theme_font_size_override("font_size", 17)
		nl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

		var dl = _lbl(pc, perk["description"], C_TEXT)
		dl.add_theme_font_size_override("font_size", 12)
		dl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		dl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART

		var btn = _btn(wp, "Choose", Color(0.18, 0.28, 0.50))
		btn.custom_minimum_size.y = 38
		var pid = perk_id
		btn.pressed.connect(func(): _on_perk_selected(pid))

func _on_perk_selected(perk_id: String) -> void:
	run_state = RunEngine.apply_starting_perk(run_state, perk_id)
	if perk_overlay:
		perk_overlay.queue_free()
		perk_overlay = null
	status_bar.show()
	show_shop_phase()

# ── event handlers ─────────────────────────────────────────────────────────────
func _on_new_run() -> void:
	run_state           = RunEngine.make_run()
	current_shop        = {}
	selected_pile_idx   = -1
	pending_power_up_id = ""
	shop_section.hide()
	battle_section.hide()
	status_bar.hide()
	_show_perk_selection()

func _on_reroll() -> void:
	var cost = 0 if run_state.get("perk") == "tactician" else ShopEngine.REROLL_COST
	if run_state.is_empty() or run_state["gold"] < cost: return
	run_state = run_state.duplicate(true)
	run_state["gold"] -= cost
	_update_status()
	current_shop["power_ups"] = ShopEngine.generate_power_ups(3, run_state.get("shop_level", 1))
	render_shop_power_ups()

func _on_upgrade_shop() -> void:
	run_state = RunEngine.upgrade_shop(run_state)
	_update_status()
	var shop_level = run_state.get("shop_level", 1)
	current_shop = ShopEngine.generate_shop(shop_level, run_state.get("jokers", []))
	shop_level_label.text = "Lvl " + str(shop_level)
	var upg_btn = shop_section.get_meta("upgrade_shop_btn")
	if shop_level >= RunEngine.MAX_SHOP_LEVEL:
		upg_btn.text     = "Max Level"
		upg_btn.disabled = true
	else:
		upg_btn.text     = "Upgrade Shop  " + str(RunEngine.effective_shop_upgrade_cost(run_state)) + "g"
		upg_btn.disabled = not RunEngine.can_upgrade_shop(run_state)
	render_shop_power_ups()
	render_joker_shop()

func _on_go_battle() -> void:
	show_battle_phase()

func _on_flip_btn() -> void:
	flip_continue_pressed.emit()
