extends Control

# ── signals ──────────────────────────────────────────────────────────────────
signal flip_continue_pressed

# ── state ────────────────────────────────────────────────────────────────────
var run_state:           Dictionary = {}
var current_shop:        Dictionary = {}
var battle_active:       bool       = false
var selected_pile_idx:   int        = -1
var pending_power_up_id: String     = ""
var pending_power_up_cost: int      = 0

# ── ui refs ───────────────────────────────────────────────────────────────────
var status_bar:           Control
var player_hp_label:      Label
var ai_hp_label:          Label
var gold_label:           Label
var mana_label:           Label
var round_label:          Label
var joker_status_label:   Label

var shop_section:         Control
var shop_cards_row:       HBoxContainer
var joker_shop_row:       HBoxContainer
var joker_hint_label:     Label
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

# ── palette ───────────────────────────────────────────────────────────────────
const C_BG      = Color(0.06, 0.06, 0.10)
const C_PANEL   = Color(0.10, 0.10, 0.17)
const C_CARD    = Color(0.13, 0.13, 0.22)
const C_SEL     = Color(0.18, 0.18, 0.30)
const C_BTN     = Color(0.18, 0.20, 0.30)
const C_ACCENT  = Color(0.95, 0.78, 0.20)
const C_WIN     = Color(0.22, 0.85, 0.45)
const C_LOSE    = Color(0.90, 0.25, 0.25)
const C_TIE     = Color(0.85, 0.80, 0.25)
const C_TEXT    = Color(0.92, 0.92, 0.96)
const C_DIM     = Color(0.48, 0.48, 0.60)
const C_GOLD    = Color(1.00, 0.82, 0.20)
const C_MANA    = Color(0.45, 0.65, 1.00)
const C_SELL    = Color(0.90, 0.28, 0.28)
const C_FREEZE  = Color(0.22, 0.55, 0.80)

func ability_color(abl: String) -> Color:
	match abl:
		"valor":    return Color(1.00, 0.80, 0.20)
		"spite":    return Color(0.90, 0.30, 0.30)
		"blaze":    return Color(1.00, 0.55, 0.15)
		"pierce":   return Color(0.75, 0.80, 0.95)
		"echo":     return Color(0.70, 0.40, 1.00)
		"comeback": return Color(0.22, 0.85, 0.45)
		"anchor":   return Color(0.30, 0.65, 1.00)
	return Color(0.30, 0.30, 0.42)

# ── boot ─────────────────────────────────────────────────────────────────────
func _ready() -> void:
	_build_ui()

# ── ui construction ───────────────────────────────────────────────────────────
func _build_ui() -> void:
	var bg = ColorRect.new()
	bg.color = C_BG
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	var scroll = ScrollContainer.new()
	scroll.set_anchors_preset(Control.PRESET_FULL_RECT)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	add_child(scroll)

	var outer = HBoxContainer.new()
	outer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	outer.size_flags_vertical   = Control.SIZE_EXPAND_FILL
	scroll.add_child(outer)

	_spacer(outer)

	var root = VBoxContainer.new()
	root.custom_minimum_size.x = 980
	root.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	root.size_flags_vertical   = Control.SIZE_EXPAND_FILL
	root.add_theme_constant_override("separation", 8)
	outer.add_child(root)

	_spacer(outer)

	_build_header(root)
	_build_status_bar(root)

	shop_section = VBoxContainer.new()
	shop_section.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	shop_section.add_theme_constant_override("separation", 10)
	shop_section.hide()
	root.add_child(shop_section)
	_build_shop_section(shop_section)

	battle_section = VBoxContainer.new()
	battle_section.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	battle_section.add_theme_constant_override("separation", 8)
	battle_section.hide()
	root.add_child(battle_section)
	_build_battle_section(battle_section)

	# log
	var log_wrap = _panel(root, Color(0.08, 0.08, 0.13), 8)
	log_wrap.custom_minimum_size.y = 90
	var log_scroll = ScrollContainer.new()
	log_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	log_scroll.custom_minimum_size.y = 80
	log_wrap.add_child(log_scroll)
	log_list = VBoxContainer.new()
	log_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	log_list.add_theme_constant_override("separation", 2)
	log_scroll.add_child(log_list)

func _build_header(parent: Control) -> void:
	var hdr = HBoxContainer.new()
	hdr.add_theme_constant_override("separation", 14)
	parent.add_child(hdr)

	var title = Label.new()
	title.text = "PILEUP"
	title.add_theme_font_size_override("font_size", 26)
	title.add_theme_color_override("font_color", C_ACCENT)
	hdr.add_child(title)

	_spacer(hdr)

	var new_run_btn = _btn(hdr, "New Run", Color(0.18, 0.50, 0.25))
	new_run_btn.custom_minimum_size.x = 100
	new_run_btn.pressed.connect(_on_new_run)

func _build_status_bar(parent: Control) -> void:
	status_bar = _panel(parent, Color(0.09, 0.09, 0.16), 10)
	status_bar.hide()
	var row = HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	status_bar.add_child(row)

	# Player
	var pl = HBoxContainer.new()
	pl.add_theme_constant_override("separation", 8)
	row.add_child(pl)
	_lbl(pl, "YOU", C_DIM).add_theme_font_size_override("font_size", 11)
	player_hp_label = _lbl(pl, "25 HP", C_WIN)
	player_hp_label.add_theme_font_size_override("font_size", 16)

	_spacer(row)

	# Center
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
	gold_label = _lbl(cur, "10g", C_GOLD)
	gold_label.add_theme_font_size_override("font_size", 15)
	mana_label = _lbl(cur, "0m", C_MANA)
	mana_label.add_theme_font_size_override("font_size", 15)
	joker_status_label = _lbl(center, "", C_ACCENT)
	joker_status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	joker_status_label.add_theme_font_size_override("font_size", 11)

	_spacer(row)

	# AI
	var ai = HBoxContainer.new()
	ai.add_theme_constant_override("separation", 8)
	row.add_child(ai)
	ai_hp_label = _lbl(ai, "25 HP", C_LOSE)
	ai_hp_label.add_theme_font_size_override("font_size", 16)
	_lbl(ai, "AI", C_DIM).add_theme_font_size_override("font_size", 11)

func _build_shop_section(parent: Control) -> void:
	# ── top action bar ────────────────────────────────────────────────────────
	var actions = HBoxContainer.new()
	actions.add_theme_constant_override("separation", 10)
	parent.add_child(actions)
	_lbl(actions, "SHOP", C_ACCENT).add_theme_font_size_override("font_size", 14)
	_spacer(actions)
	var reroll_btn = _btn(actions, "Reroll  1g", C_FREEZE)
	reroll_btn.pressed.connect(_on_reroll)
	var battle_btn = _btn(actions, "⚔  Battle", Color(0.45, 0.22, 0.12))
	battle_btn.pressed.connect(_on_go_battle)

	# ── card packs ────────────────────────────────────────────────────────────
	_section_header(parent, "CARD PACKS", "Buy a random card")
	var packs_wrap = _panel(parent, Color(0.09, 0.09, 0.15), 14)
	shop_cards_row = HBoxContainer.new()
	shop_cards_row.alignment = BoxContainer.ALIGNMENT_CENTER
	shop_cards_row.add_theme_constant_override("separation", 16)
	packs_wrap.add_child(shop_cards_row)

	# ── power-ups ─────────────────────────────────────────────────────────────
	_section_header(parent, "POWER UPS", "Apply an ability to a pile card")
	var pow_wrap = _panel(parent, Color(0.09, 0.09, 0.15), 14)
	shop_cards_row  # (re-used slot — power-ups use their own container below)
	var pow_inner = HBoxContainer.new()
	pow_inner.alignment = BoxContainer.ALIGNMENT_CENTER
	pow_inner.add_theme_constant_override("separation", 16)
	pow_wrap.add_child(pow_inner)
	# store reference so we can rebuild it
	pow_wrap.set_meta("inner", pow_inner)
	parent.set_meta("pow_wrap", pow_wrap)

	# ── joker ─────────────────────────────────────────────────────────────────
	var j_hdr = HBoxContainer.new()
	parent.add_child(j_hdr)
	_lbl(j_hdr, "JOKER", C_DIM).add_theme_font_size_override("font_size", 11)
	_spacer(j_hdr)
	joker_hint_label = _lbl(j_hdr, "One Joker per run", C_DIM)
	joker_hint_label.add_theme_font_size_override("font_size", 11)
	var joker_wrap = _panel(parent, Color(0.09, 0.09, 0.15), 12)
	joker_shop_row = HBoxContainer.new()
	joker_shop_row.alignment = BoxContainer.ALIGNMENT_CENTER
	joker_shop_row.add_theme_constant_override("separation", 16)
	joker_wrap.add_child(joker_shop_row)

	# ── your pile ─────────────────────────────────────────────────────────────
	var pile_hdr = HBoxContainer.new()
	pile_hdr.add_theme_constant_override("separation", 10)
	parent.add_child(pile_hdr)
	_lbl(pile_hdr, "YOUR PILE", C_ACCENT).add_theme_font_size_override("font_size", 13)
	pile_count_label = _lbl(pile_hdr, "", C_DIM)
	pile_count_label.add_theme_font_size_override("font_size", 11)
	_spacer(pile_hdr)
	pile_stats_label = _lbl(pile_hdr, "", C_DIM)
	pile_stats_label.add_theme_font_size_override("font_size", 11)

	var pile_wrap = _panel(parent, Color(0.09, 0.09, 0.15), 12)
	pile_wrap.custom_minimum_size.y = 130
	var pile_scroll = ScrollContainer.new()
	pile_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	pile_scroll.vertical_scroll_mode  = ScrollContainer.SCROLL_MODE_DISABLED
	pile_wrap.add_child(pile_scroll)
	pile_cards_row = HBoxContainer.new()
	pile_cards_row.add_theme_constant_override("separation", 10)
	pile_scroll.add_child(pile_cards_row)

	selected_card_panel = _panel(parent, Color(0.12, 0.12, 0.20), 14)
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

	# left pile label
	var left_col = VBoxContainer.new()
	left_col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	field.add_child(left_col)
	_lbl(left_col, "YOU", C_TEXT).add_theme_font_size_override("font_size", 13)
	left_score_label = _lbl(left_col, "Score: 0", C_DIM)

	# arena center
	var arena = VBoxContainer.new()
	arena.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	arena.alignment = BoxContainer.ALIGNMENT_CENTER
	arena.add_theme_constant_override("separation", 10)
	field.add_child(arena)

	arena_status_label = _lbl(arena, "", C_DIM)
	arena_status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	arena_status_label.add_theme_font_size_override("font_size", 12)

	var stag_panel = _panel(arena, Color(0.10, 0.10, 0.18), 10)
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

	flip_btn = _btn(arena, "Flip Card", Color(0.25, 0.35, 0.58))
	flip_btn.custom_minimum_size = Vector2(160, 44)
	flip_btn.disabled = true
	flip_btn.pressed.connect(_on_flip_btn)

	# right pile label
	var right_col = VBoxContainer.new()
	right_col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	field.add_child(right_col)
	var ail = _lbl(right_col, "AI", C_TEXT)
	ail.add_theme_font_size_override("font_size", 13)
	ail.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	right_score_label = _lbl(right_col, "Score: 0", C_DIM)
	right_score_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT

# ── card visual ───────────────────────────────────────────────────────────────
func _make_card(parent: Control, card: Dictionary, w: float, h: float,
		selected: bool = false, prob: int = -1) -> PanelContainer:
	var abl    = card.get("ability", "")
	var border = ability_color(abl) if not abl.is_empty() else Color(0.25, 0.25, 0.38)

	var cp = PanelContainer.new()
	cp.custom_minimum_size = Vector2(w, h)
	var sb = StyleBoxFlat.new()
	sb.bg_color = C_SEL if selected else C_CARD
	sb.set_corner_radius_all(8)
	sb.border_width_left   = 2
	sb.border_width_right  = 2
	sb.border_width_top    = 2
	sb.border_width_bottom = 2
	sb.border_color = border if (selected or not abl.is_empty()) else Color(0.22, 0.22, 0.35)
	if selected:
		sb.border_color  = C_ACCENT
		sb.border_width_left = sb.border_width_right = sb.border_width_top = sb.border_width_bottom = 3
	sb.shadow_color  = Color(0, 0, 0, 0.5)
	sb.shadow_size   = 4
	sb.shadow_offset = Vector2(0, 2)
	sb.set_content_margin_all(6)
	cp.add_theme_stylebox_override("panel", sb)
	parent.add_child(cp)

	var col = VBoxContainer.new()
	col.alignment = BoxContainer.ALIGNMENT_CENTER
	col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	col.size_flags_vertical   = Control.SIZE_EXPAND_FILL
	col.add_theme_constant_override("separation", 2)
	cp.add_child(col)

	# value — big and centred
	var val_lbl = Label.new()
	val_lbl.text = str(card["value"])
	val_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	val_lbl.add_theme_font_size_override("font_size", 34 if h >= 110 else 20)
	val_lbl.add_theme_color_override("font_color", C_TEXT)
	val_lbl.size_flags_vertical = Control.SIZE_EXPAND_FILL
	col.add_child(val_lbl)

	# ability name
	if not abl.is_empty():
		var al = Label.new()
		al.text = ability_text(abl)
		al.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		al.add_theme_font_size_override("font_size", 9)
		al.add_theme_color_override("font_color", border)
		al.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		col.add_child(al)

	# weight badge
	var wt = card.get("weight", 0)
	if wt != 0:
		var wl = Label.new()
		wl.text = ("+" if wt > 0 else "") + str(wt) + "w"
		wl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		wl.add_theme_font_size_override("font_size", 9)
		wl.add_theme_color_override("font_color", C_WIN if wt > 0 else C_LOSE)
		col.add_child(wl)

	# flip probability
	if prob >= 0:
		var pl = Label.new()
		pl.text = str(prob) + "%"
		pl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		pl.add_theme_font_size_override("font_size", 9)
		pl.add_theme_color_override("font_color", C_DIM)
		col.add_child(pl)

	return cp

# ── run status ────────────────────────────────────────────────────────────────
func _update_status() -> void:
	player_hp_label.text    = str(run_state["player_hp"]) + " HP"
	ai_hp_label.text        = str(run_state["ai_hp"])     + " HP"
	gold_label.text         = str(run_state["gold"])      + "g"
	mana_label.text         = str(run_state["mana"])      + "m"
	round_label.text        = "Round " + str(run_state["round"])
	var jid = run_state.get("joker", "")
	joker_status_label.text = Jokers.JOKERS[jid]["name"] if not jid.is_empty() else ""

# ── shop phase ────────────────────────────────────────────────────────────────
func show_shop_phase() -> void:
	battle_section.hide()
	shop_section.show()
	selected_pile_idx    = -1
	pending_power_up_id  = ""
	current_shop         = ShopEngine.generate_shop(run_state["round"])
	render_shop_packs()
	render_shop_power_ups()
	render_joker_shop()
	render_pile_cards()
	_update_status()

func render_shop_packs() -> void:
	for c in shop_cards_row.get_children(): c.queue_free()
	for pack in current_shop["packs"]:
		var wrap = VBoxContainer.new()
		wrap.add_theme_constant_override("separation", 8)
		wrap.custom_minimum_size.x = 140
		shop_cards_row.add_child(wrap)

		# pack visual
		var pp = _panel(wrap, Color(0.12, 0.15, 0.22), 14)
		var pc = VBoxContainer.new()
		pc.alignment = BoxContainer.ALIGNMENT_CENTER
		pc.add_theme_constant_override("separation", 6)
		pp.add_child(pc)
		var nl = _lbl(pc, pack["name"], C_TEXT)
		nl.add_theme_font_size_override("font_size", 14)
		nl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		var hl = _lbl(pc, pack["hint"], C_DIM)
		hl.add_theme_font_size_override("font_size", 11)
		hl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

		var can = RunEngine.can_buy_pack(run_state, pack)
		var bb  = _btn(wrap, str(pack["cost"]) + "g  Buy",
			Color(0.20, 0.45, 0.20) if can else Color(0.12, 0.15, 0.12))
		bb.disabled = not can
		var pref = pack
		bb.pressed.connect(func():
			run_state = RunEngine.buy_pack(run_state, pref)
			_update_status()
			render_shop_packs()
			render_pile_cards()
		)

func render_shop_power_ups() -> void:
	var pow_wrap = shop_section.get_meta("pow_wrap")
	var inner    = pow_wrap.get_meta("inner")
	for c in inner.get_children(): c.queue_free()

	for abl_id in current_shop["power_ups"]:
		var cost = ShopEngine.POWER_UP_COSTS[abl_id]
		var abl  = Abilities.ABILITIES[abl_id]
		var col  = ability_color(abl_id)
		var can  = run_state["gold"] >= cost

		var wrap = VBoxContainer.new()
		wrap.add_theme_constant_override("separation", 8)
		wrap.custom_minimum_size.x = 140
		inner.add_child(wrap)

		var pp = _panel(wrap, Color(0.10, 0.10, 0.18).lerp(col, 0.06), 14)
		var pc = VBoxContainer.new()
		pc.alignment = BoxContainer.ALIGNMENT_CENTER
		pc.add_theme_constant_override("separation", 4)
		pp.add_child(pc)
		var nl = _lbl(pc, abl["label"], col)
		nl.add_theme_font_size_override("font_size", 14)
		nl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		var dl = _lbl(pc, abl["description"], C_DIM)
		dl.add_theme_font_size_override("font_size", 10)
		dl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

		var bb = _btn(wrap, str(cost) + "g  Apply to card",
			col.darkened(0.4) if can else Color(0.12, 0.12, 0.18))
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
	var jid = run_state.get("joker", "")

	if not jid.is_empty():
		joker_hint_label.text = "Active"
		var jd  = Jokers.JOKERS[jid]
		var wrap = VBoxContainer.new()
		wrap.add_theme_constant_override("separation", 6)
		joker_shop_row.add_child(wrap)
		var jp = _panel(wrap, Color(0.18, 0.14, 0.28), 10)
		var jc = VBoxContainer.new()
		jc.add_theme_constant_override("separation", 4)
		jp.add_child(jc)
		var nl = _lbl(jc, jd["name"], C_ACCENT)
		nl.add_theme_font_size_override("font_size", 14)
		_lbl(jc, jd["description"], C_DIM).add_theme_font_size_override("font_size", 11)
		return

	joker_hint_label.text = "One Joker per run"
	var pool    = Jokers.JOKER_POOL.duplicate()
	var offered = []
	for _i in range(mini(3, pool.size())):
		var idx = randi() % pool.size()
		offered.append(pool[idx])
		pool.remove_at(idx)

	for offer_jid in offered:
		var jd  = Jokers.JOKERS[offer_jid]
		var can = RunEngine.can_buy_joker(run_state, offer_jid)
		var wrap = VBoxContainer.new()
		wrap.add_theme_constant_override("separation", 6)
		joker_shop_row.add_child(wrap)
		var jp = _panel(wrap, Color(0.14, 0.10, 0.22), 10)
		var jc = VBoxContainer.new()
		jc.add_theme_constant_override("separation", 4)
		jp.add_child(jc)
		var nl = _lbl(jc, jd["name"], C_ACCENT)
		nl.add_theme_font_size_override("font_size", 13)
		_lbl(jc, jd["description"], C_DIM).add_theme_font_size_override("font_size", 10)
		var jb = _btn(wrap, str(jd["cost"]) + "g  Buy",
			Color(0.35, 0.18, 0.50) if can else Color(0.15, 0.10, 0.20))
		jb.disabled = not can
		var jid_ref = offer_jid
		jb.pressed.connect(func():
			run_state = RunEngine.buy_joker(run_state, jid_ref)
			_update_status()
			render_joker_shop()
			render_pile_cards()
		)

func render_pile_cards() -> void:
	for c in pile_cards_row.get_children(): c.queue_free()
	selected_card_panel.hide()
	for c in selected_card_panel.get_children(): c.queue_free()

	var cards = run_state["player_pile"]["cards"]
	var cap   = RunEngine.effective_pile_cap(run_state)
	pile_count_label.text = str(cards.size()) + " / " + str(cap)

	var stats = Selection.pile_stats(run_state["player_pile"])
	pile_stats_label.text = "avg " + str(stats["avg_value"]) + "  •  exp " + str(stats["expected_value"])

	var probs = Selection.flip_probabilities(run_state["player_pile"])

	# Power-up mode banner
	if not pending_power_up_id.is_empty():
		selected_card_panel.show()
		var banner_row = HBoxContainer.new()
		banner_row.add_theme_constant_override("separation", 12)
		selected_card_panel.add_child(banner_row)
		var abl_col = ability_color(pending_power_up_id)
		var bl = _lbl(banner_row,
			"Select a card to apply  " + Abilities.ABILITIES[pending_power_up_id]["label"], abl_col)
		bl.add_theme_font_size_override("font_size", 13)
		_spacer(banner_row)
		var cancel = _btn(banner_row, "Cancel", Color(0.22, 0.12, 0.12))
		cancel.pressed.connect(func():
			pending_power_up_id = ""
			render_pile_cards()
		)

	for i in range(cards.size()):
		var card   = cards[i]
		var is_sel = (i == selected_pile_idx) and pending_power_up_id.is_empty()
		var glow   = not pending_power_up_id.is_empty()  # all cards glow in power-up mode
		var cv     = _make_card(pile_cards_row, card, 80, 110, is_sel or glow, probs[i])
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

	# big card preview
	_make_card(row, card, 90, 130)

	# info + actions
	var info = VBoxContainer.new()
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info.add_theme_constant_override("separation", 8)
	row.add_child(info)

	var abl = card.get("ability", "")
	if not abl.is_empty() and Abilities.ABILITIES.has(abl):
		var desc = _lbl(info, Abilities.ABILITIES[abl]["description"], ability_color(abl))
		desc.add_theme_font_size_override("font_size", 13)
	var wt = card.get("weight", 0)
	if wt != 0:
		_lbl(info, ("+" if wt > 0 else "") + str(wt) + " flip weight", C_DIM).add_theme_font_size_override("font_size", 11)
	_lbl(info, str(prob) + "% flip chance", C_DIM).add_theme_font_size_override("font_size", 11)

	_spacer(info)

	var act = HBoxContainer.new()
	act.add_theme_constant_override("separation", 10)
	info.add_child(act)

	var can_up = RunEngine.can_upgrade(run_state)
	var up_btn = _btn(act, "Upgrade  +" + str(RunEngine.UPGRADE_COST) + "m",
		Color(0.18, 0.36, 0.58) if can_up else Color(0.12, 0.14, 0.18))
	up_btn.disabled = not can_up
	var cid = card["id"]
	up_btn.pressed.connect(func():
		run_state = RunEngine.upgrade_card(run_state, cid)
		_update_status()
		render_pile_cards()
	)

	var can_sell = RunEngine.can_sell(run_state, card["id"])
	var sell_btn = _btn(act, "Sell  -" + str(RunEngine.SELL_COST) + "g",
		Color(0.45, 0.14, 0.14) if can_sell else Color(0.18, 0.12, 0.12))
	sell_btn.disabled = not can_sell
	sell_btn.pressed.connect(func():
		run_state = RunEngine.sell_card(run_state, cid)
		selected_pile_idx = -1
		_update_status()
		render_pile_cards()
		render_shop_cards()
	)

	var close_btn = _btn(act, "✕", Color(0.20, 0.20, 0.28))
	close_btn.pressed.connect(func():
		selected_pile_idx = -1
		render_pile_cards()
	)

# ── battle phase ──────────────────────────────────────────────────────────────
func show_battle_phase() -> void:
	shop_section.hide()
	battle_section.show()
	run_battle()

func run_battle() -> void:
	if battle_active: return
	battle_active = true

	for c in log_list.get_children(): c.queue_free()
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
	var jid        = run_state.get("joker", "")

	_log("You:  [" + ", ".join(left_pile["cards"].map(func(c): return str(c["value"]))) + "]")
	_log("AI:   [" + ", ".join(right_pile["cards"].map(func(c): return str(c["value"]))) + "]")

	var result      = BattleEngine.simulate_battle(left_pile, right_pile, jid)
	var left_score  = 0
	var right_score = 0

	for i in range(result["flips"].size()):
		var flip = result["flips"][i]

		arena_status_label.text = "Flip " + str(i + 1) + " of " + str(Selection.FLIP_COUNT)
		flip_btn.text    = "Flip Card"
		flip_btn.disabled = false
		await flip_continue_pressed
		flip_btn.disabled = true

		_show_face_down()
		await get_tree().create_timer(0.36).timeout
		_reveal_pair(flip)
		await get_tree().create_timer(0.22).timeout

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
				_log("  " + side + " " + ev["ability"] + " [" + ev["trigger"] + "]: " +
					("+" if ev["delta"] > 0 else "") + str(ev["delta"]) + (" (next)" if ev.get("next") else ""))

	var win_text = ""
	if result["winner"] == "tie":
		win_text = "Tied " + str(left_score) + "–" + str(right_score)
	else:
		win_text = ("You win" if result["winner"] == "left" else "AI wins") + \
			"  " + str(maxi(left_score, right_score)) + "–" + str(mini(left_score, right_score))
	result_label.text = win_text
	_log("=== " + win_text + " ===")

	var bw = "player" if result["winner"] == "left" else ("ai" if result["winner"] == "right" else "tie")
	var prev_mana = run_state["mana"]
	run_state = RunEngine.apply_battle_result(run_state, {
		"winner": bw, "margin": result["margin"],
		"gold_bonus": result["left_gold_bonus"],
		"joker_mana_bonus": result["joker_mana_bonus"]
	})
	_log("+" + str(run_state["mana"] - prev_mana) + "m earned")
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

# ── battle helpers ────────────────────────────────────────────────────────────
func _show_face_down() -> void:
	for c in flip_display.get_children(): c.queue_free()
	var lc = _face_down_card(flip_display)
	lc.custom_minimum_size = Vector2(100, 140)
	_lbl(flip_display, "vs", C_DIM).add_theme_font_size_override("font_size", 18)
	var rc = _face_down_card(flip_display)
	rc.custom_minimum_size = Vector2(100, 140)

func _face_down_card(parent: Control) -> PanelContainer:
	var cp = PanelContainer.new()
	cp.custom_minimum_size = Vector2(100, 140)
	var sb = StyleBoxFlat.new()
	sb.bg_color = Color(0.12, 0.12, 0.20)
	sb.set_corner_radius_all(10)
	sb.border_width_left = sb.border_width_right = sb.border_width_top = sb.border_width_bottom = 2
	sb.border_color = Color(0.25, 0.25, 0.40)
	sb.shadow_color = Color(0, 0, 0, 0.5)
	sb.shadow_size = 6
	sb.set_content_margin_all(8)
	cp.add_theme_stylebox_override("panel", sb)
	parent.add_child(cp)
	var l = Label.new()
	l.text = "?"
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.vertical_alignment   = VERTICAL_ALIGNMENT_CENTER
	l.add_theme_font_size_override("font_size", 36)
	l.add_theme_color_override("font_color", Color(0.3, 0.3, 0.5))
	l.set_anchors_preset(Control.PRESET_FULL_RECT)
	cp.add_child(l)
	return cp

func _reveal_pair(flip: Dictionary) -> void:
	for c in flip_display.get_children(): c.queue_free()
	var lc = flip["winner"] == "left" and C_WIN or (flip["winner"] == "right" and C_LOSE or C_TIE)
	var rc = flip["winner"] == "right" and C_WIN or (flip["winner"] == "left"  and C_LOSE or C_TIE)
	var lcard = flip["left"].duplicate()
	lcard["value"] = flip["left_effective"]
	var rcard = flip["right"].duplicate()
	rcard["value"] = flip["right_effective"]
	var lv = _make_card(flip_display, flip["left"], 100, 140)
	lv.custom_minimum_size = Vector2(100, 140)
	_lbl(flip_display, "vs", C_DIM).add_theme_font_size_override("font_size", 18)
	var rv = _make_card(flip_display, flip["right"], 100, 140)
	rv.custom_minimum_size = Vector2(100, 140)
	# Tint border by outcome
	for pair in [[lv, lc], [rv, rc]]:
		var panel_node = pair[0]
		var col        = pair[1]
		var sb = panel_node.get_theme_stylebox("panel").duplicate()
		sb.border_color = col
		sb.border_width_left = sb.border_width_right = sb.border_width_top = sb.border_width_bottom = 3
		panel_node.add_theme_stylebox_override("panel", sb)

func _add_history(row: HBoxContainer, txt: String, outcome: String) -> void:
	var col = C_WIN if outcome == "win" else (C_LOSE if outcome == "lose" else C_TIE)
	var cp  = PanelContainer.new()
	cp.custom_minimum_size = Vector2(36, 36)
	var sb = StyleBoxFlat.new()
	sb.bg_color = col.darkened(0.5)
	sb.border_color = col
	sb.border_width_left = sb.border_width_right = sb.border_width_top = sb.border_width_bottom = 2
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

# ── ui factory ────────────────────────────────────────────────────────────────
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
	sb.set_content_margin_all(7)
	b.add_theme_stylebox_override("normal", sb)
	var sb_hov = sb.duplicate(); sb_hov.bg_color = color.lightened(0.15)
	b.add_theme_stylebox_override("hover", sb_hov)
	var sb_dis = sb.duplicate(); sb_dis.bg_color = color.darkened(0.5)
	b.add_theme_stylebox_override("disabled", sb_dis)
	b.add_theme_color_override("font_color",          C_TEXT)
	b.add_theme_color_override("font_hover_color",    C_TEXT)
	b.add_theme_color_override("font_disabled_color", C_DIM)
	b.add_theme_font_size_override("font_size", 13)
	parent.add_child(b)
	return b

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

func ability_text(abl: String) -> String:
	if abl.is_empty(): return ""
	return Abilities.ABILITIES[abl]["label"] if Abilities.ABILITIES.has(abl) else abl

# ── event handlers ────────────────────────────────────────────────────────────
func _on_new_run() -> void:
	run_state           = RunEngine.make_run()
	current_shop        = {}
	selected_pile_idx   = -1
	pending_power_up_id = ""
	status_bar.show()
	show_shop_phase()

func _on_reroll() -> void:
	if run_state.is_empty() or run_state["gold"] < ShopEngine.REROLL_COST: return
	run_state = run_state.duplicate(true)
	run_state["gold"] -= ShopEngine.REROLL_COST
	_update_status()
	current_shop["power_ups"] = ShopEngine.generate_power_ups(3)
	render_shop_power_ups()

func _on_go_battle() -> void:
	show_battle_phase()

func _on_flip_btn() -> void:
	flip_continue_pressed.emit()
