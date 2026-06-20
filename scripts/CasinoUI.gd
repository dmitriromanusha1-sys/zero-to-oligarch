extends CanvasLayer

signal game_finished(delta_money: float)

var _gm: Node
var _am: Node
var _panel: Panel
var _balance_lbl: Label
var _bet_lbl: Label
var _bet: float = 1000.0
var _result_lbl: Label
var _result_tween: Tween = null

# Блэкджек
var _player_hand: Array = []
var _dealer_hand: Array = []
var _bj_active: bool = false
var _bj_vbox: VBoxContainer = null
var _bj_hand_lbl: Label = null
var _bj_dealer_lbl: Label = null
var _bj_status_lbl: Label = null

const MIN_BET: float = 500.0
const BET_STEPS: Array = [500.0, 1000.0, 5000.0, 10000.0, 50000.0, 100000.0]

func _ready() -> void:
	layer = 14
	visible = false
	add_to_group("casino_ui")
	_gm = get_node("/root/GameManager")
	_am = get_node_or_null("/root/AudioManager")
	_build_ui()
	# Подключаемся к QuestManager здесь, чтобы связь работала и после reload_current_scene
	var qm := get_node_or_null("/root/QuestManager")
	if qm: game_finished.connect(qm._on_casino_finished)

func _build_ui() -> void:
	var dimmer := ColorRect.new()
	dimmer.set_anchors_preset(Control.PRESET_FULL_RECT)
	dimmer.color = Color(0, 0, 0, 0.80)
	dimmer.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(dimmer)

	_panel = Panel.new()
	_panel.set_anchors_preset(Control.PRESET_CENTER)
	_panel.position = Vector2(-370, -280)
	_panel.size = Vector2(740, 560)
	var ps := StyleBoxFlat.new()
	ps.bg_color = Color(0.04, 0.03, 0.06, 0.98)
	ps.border_color = Color(0.68, 0.50, 0.10, 0.95)
	for s in [SIDE_LEFT, SIDE_RIGHT, SIDE_TOP, SIDE_BOTTOM]:
		ps.set_border_width(s, 3)
		ps.set_corner_radius(s, 14)
	_panel.add_theme_stylebox_override("panel", ps)
	add_child(_panel)

	var vbox := VBoxContainer.new()
	vbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	vbox.add_theme_constant_override("separation", 6)
	_panel.add_child(vbox)

	# Заголовок
	var hdr := HBoxContainer.new()
	hdr.add_theme_constant_override("separation", 8)
	vbox.add_child(hdr)

	var title_lbl := Label.new()
	title_lbl.text = "🎰 Казино «Олигарх»"
	title_lbl.add_theme_font_size_override("font_size", 24)
	title_lbl.add_theme_color_override("font_color", Color(1.0, 0.88, 0.20))
	title_lbl.add_theme_constant_override("outline_size", 3)
	title_lbl.add_theme_color_override("font_outline_color", Color(0.3, 0.18, 0.0, 0.80))
	title_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hdr.add_child(title_lbl)

	var close_btn := Button.new()
	close_btn.text = "✖"
	close_btn.custom_minimum_size = Vector2(36, 36)
	close_btn.add_theme_font_size_override("font_size", 15)
	var cs := StyleBoxFlat.new()
	cs.bg_color = Color(0.22, 0.07, 0.07)
	cs.border_color = Color(0.55, 0.18, 0.18)
	for s in [SIDE_LEFT, SIDE_RIGHT, SIDE_TOP, SIDE_BOTTOM]:
		cs.set_border_width(s, 1)
		cs.set_corner_radius(s, 6)
	close_btn.add_theme_stylebox_override("normal", cs)
	close_btn.add_theme_color_override("font_color", Color.WHITE)
	close_btn.pressed.connect(func(): visible = false)
	hdr.add_child(close_btn)

	# Баланс + ставка
	var info_row := HBoxContainer.new()
	info_row.add_theme_constant_override("separation", 20)
	vbox.add_child(info_row)

	_balance_lbl = Label.new()
	_balance_lbl.add_theme_font_size_override("font_size", 14)
	_balance_lbl.add_theme_color_override("font_color", Color(0.55, 1.0, 0.55))
	info_row.add_child(_balance_lbl)

	var bet_row := HBoxContainer.new()
	bet_row.add_theme_constant_override("separation", 6)
	bet_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info_row.add_child(bet_row)

	var bet_lbl_title := Label.new()
	bet_lbl_title.text = "Ставка:"
	bet_lbl_title.add_theme_font_size_override("font_size", 13)
	bet_lbl_title.add_theme_color_override("font_color", Color(0.75, 0.75, 0.75))
	bet_row.add_child(bet_lbl_title)

	_bet_lbl = Label.new()
	_bet_lbl.add_theme_font_size_override("font_size", 14)
	_bet_lbl.add_theme_color_override("font_color", Color(1.0, 0.88, 0.20))
	bet_row.add_child(_bet_lbl)

	var sp := Control.new()
	sp.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bet_row.add_child(sp)

	for step in BET_STEPS:
		var b := Button.new()
		b.text = _short(step)
		b.custom_minimum_size = Vector2(56, 24)
		b.add_theme_font_size_override("font_size", 11)
		var bs := StyleBoxFlat.new()
		bs.bg_color = Color(0.12, 0.10, 0.04)
		bs.border_color = Color(0.55, 0.42, 0.10, 0.80)
		for s in [SIDE_LEFT, SIDE_RIGHT, SIDE_TOP, SIDE_BOTTOM]:
			bs.set_border_width(s, 1)
			bs.set_corner_radius(s, 4)
		b.add_theme_stylebox_override("normal", bs)
		b.add_theme_color_override("font_color", Color(1.0, 0.88, 0.25))
		var bh := bs.duplicate() as StyleBoxFlat
		bh.bg_color = Color(0.18, 0.15, 0.06)
		b.add_theme_stylebox_override("hover", bh)
		var sv: float = step
		b.pressed.connect(func(): _set_bet(sv))
		bet_row.add_child(b)

	# Разделитель
	var sep := ColorRect.new()
	sep.color = Color(0.55, 0.42, 0.10, 0.40)
	sep.custom_minimum_size = Vector2(0, 1)
	vbox.add_child(sep)

	# Результат
	_result_lbl = Label.new()
	_result_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_result_lbl.add_theme_font_size_override("font_size", 18)
	_result_lbl.add_theme_constant_override("outline_size", 4)
	_result_lbl.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.80))
	_result_lbl.custom_minimum_size = Vector2(0, 32)
	vbox.add_child(_result_lbl)

	# TabContainer с играми
	var tabs := TabContainer.new()
	tabs.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(tabs)

	_build_roulette_tab(tabs)
	_build_slots_tab(tabs)
	_build_blackjack_tab(tabs)

func _build_roulette_tab(tabs: TabContainer) -> void:
	var root := VBoxContainer.new()
	root.name = "♠ Рулетка"
	root.add_theme_constant_override("separation", 10)
	tabs.add_child(root)

	var desc := Label.new()
	desc.text = "Выбери цвет или чётность — выигрыш ×2. Ставка на число — ×36!"
	desc.add_theme_font_size_override("font_size", 12)
	desc.add_theme_color_override("font_color", Color(0.60, 0.60, 0.65))
	desc.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	root.add_child(desc)

	# Кнопки ставок
	var row1 := HBoxContainer.new()
	row1.alignment = BoxContainer.ALIGNMENT_CENTER
	row1.add_theme_constant_override("separation", 12)
	root.add_child(row1)

	var bets := [
		{"text": "🔴 Красное", "col": Color(0.65, 0.10, 0.10), "brd": Color(1.0, 0.30, 0.30), "type": "red"},
		{"text": "⚫ Чёрное",  "col": Color(0.10, 0.10, 0.10), "brd": Color(0.55, 0.55, 0.55), "type": "black"},
		{"text": "2️⃣ Чётное",  "col": Color(0.08, 0.20, 0.38), "brd": Color(0.28, 0.55, 0.90), "type": "even"},
		{"text": "1️⃣ Нечётное","col": Color(0.20, 0.10, 0.38), "brd": Color(0.60, 0.30, 0.90), "type": "odd"},
	]
	for bd in bets:
		var btn := Button.new()
		btn.text = bd.text
		btn.custom_minimum_size = Vector2(130, 46)
		btn.add_theme_font_size_override("font_size", 13)
		btn.add_theme_color_override("font_color", Color(0.95, 0.95, 0.95))
		var bs := StyleBoxFlat.new()
		bs.bg_color = bd.col
		bs.border_color = bd.brd
		for s in [SIDE_LEFT, SIDE_RIGHT, SIDE_TOP, SIDE_BOTTOM]:
			bs.set_border_width(s, 2)
			bs.set_corner_radius(s, 8)
		btn.add_theme_stylebox_override("normal", bs)
		var bh := bs.duplicate() as StyleBoxFlat
		bh.bg_color = bd.col.lightened(0.15)
		btn.add_theme_stylebox_override("hover", bh)
		var t: String = bd.type
		btn.pressed.connect(func(): _play_roulette(t))
		row1.add_child(btn)

	# Поле числа
	var num_row := HBoxContainer.new()
	num_row.alignment = BoxContainer.ALIGNMENT_CENTER
	num_row.add_theme_constant_override("separation", 10)
	root.add_child(num_row)

	var num_hint := Label.new()
	num_hint.text = "Число 0–36 (×36):"
	num_hint.add_theme_font_size_override("font_size", 13)
	num_hint.add_theme_color_override("font_color", Color(0.75, 0.75, 0.75))
	num_row.add_child(num_hint)

	var spin := SpinBox.new()
	spin.min_value = 0
	spin.max_value = 36
	spin.value = 7
	spin.custom_minimum_size = Vector2(80, 34)
	num_row.add_child(spin)

	var num_btn := Button.new()
	num_btn.text = "Поставить на число"
	num_btn.custom_minimum_size = Vector2(180, 36)
	num_btn.add_theme_font_size_override("font_size", 13)
	num_btn.add_theme_color_override("font_color", Color(1.0, 0.88, 0.20))
	var nbs := StyleBoxFlat.new()
	nbs.bg_color = Color(0.15, 0.12, 0.03)
	nbs.border_color = Color(0.68, 0.50, 0.10, 0.90)
	for s in [SIDE_LEFT, SIDE_RIGHT, SIDE_TOP, SIDE_BOTTOM]:
		nbs.set_border_width(s, 2)
		nbs.set_corner_radius(s, 8)
	num_btn.add_theme_stylebox_override("normal", nbs)
	num_btn.pressed.connect(func(): _play_roulette_number(int(spin.value)))
	num_row.add_child(num_btn)

func _build_slots_tab(tabs: TabContainer) -> void:
	var root := VBoxContainer.new()
	root.name = "🎰 Слоты"
	root.alignment = BoxContainer.ALIGNMENT_CENTER
	root.add_theme_constant_override("separation", 12)
	tabs.add_child(root)

	var desc := Label.new()
	desc.text = "3 совпадения — ×5 | 2 совпадения — ×2 | Джекпот 777 — ×20!"
	desc.add_theme_font_size_override("font_size", 12)
	desc.add_theme_color_override("font_color", Color(0.60, 0.60, 0.65))
	desc.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	root.add_child(desc)

	var reel_row := HBoxContainer.new()
	reel_row.alignment = BoxContainer.ALIGNMENT_CENTER
	reel_row.add_theme_constant_override("separation", 16)
	root.add_child(reel_row)

	var reel_labels: Array[Label] = []
	for _i in 3:
		var reel_panel := PanelContainer.new()
		var rps := StyleBoxFlat.new()
		rps.bg_color = Color(0.07, 0.06, 0.02)
		rps.border_color = Color(0.68, 0.50, 0.10, 0.90)
		rps.set_border_width_all(2)
		rps.set_corner_radius_all(8)
		rps.content_margin_left   = 14
		rps.content_margin_right  = 14
		rps.content_margin_top    = 10
		rps.content_margin_bottom = 10
		reel_panel.add_theme_stylebox_override("panel", rps)
		reel_row.add_child(reel_panel)
		var rl := Label.new()
		rl.text = "🎰"
		rl.add_theme_font_size_override("font_size", 48)
		rl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		rl.custom_minimum_size = Vector2(80, 72)
		reel_panel.add_child(rl)
		reel_labels.append(rl)

	var spin_btn := Button.new()
	spin_btn.text = "🎰  Крутить!"
	spin_btn.custom_minimum_size = Vector2(220, 52)
	spin_btn.add_theme_font_size_override("font_size", 18)
	spin_btn.add_theme_color_override("font_color", Color(1.0, 0.88, 0.20))
	var sbs := StyleBoxFlat.new()
	sbs.bg_color = Color(0.18, 0.14, 0.03)
	sbs.border_color = Color(0.68, 0.50, 0.10, 0.90)
	for s in [SIDE_LEFT, SIDE_RIGHT, SIDE_TOP, SIDE_BOTTOM]:
		sbs.set_border_width(s, 2)
		sbs.set_corner_radius(s, 10)
	spin_btn.add_theme_stylebox_override("normal", sbs)
	var sbh := sbs.duplicate() as StyleBoxFlat
	sbh.bg_color = Color(0.26, 0.20, 0.04)
	spin_btn.add_theme_stylebox_override("hover", sbh)
	spin_btn.pressed.connect(func(): _play_slots(reel_labels, spin_btn))
	root.add_child(spin_btn)

func _build_blackjack_tab(tabs: TabContainer) -> void:
	var root := VBoxContainer.new()
	root.name = "♠ Блэкджек"
	root.add_theme_constant_override("separation", 8)
	tabs.add_child(root)

	var desc := Label.new()
	desc.text = "Набери 21 или ближе к 21 чем дилер. Перебор — проигрыш."
	desc.add_theme_font_size_override("font_size", 12)
	desc.add_theme_color_override("font_color", Color(0.60, 0.60, 0.65))
	desc.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	root.add_child(desc)

	_bj_vbox = root

	_bj_dealer_lbl = Label.new()
	_bj_dealer_lbl.text = "Дилер: —"
	_bj_dealer_lbl.add_theme_font_size_override("font_size", 16)
	_bj_dealer_lbl.add_theme_color_override("font_color", Color(1.0, 0.65, 0.65))
	_bj_dealer_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	root.add_child(_bj_dealer_lbl)

	_bj_hand_lbl = Label.new()
	_bj_hand_lbl.text = "Ваша рука: —"
	_bj_hand_lbl.add_theme_font_size_override("font_size", 18)
	_bj_hand_lbl.add_theme_color_override("font_color", Color(0.55, 1.0, 0.55))
	_bj_hand_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	root.add_child(_bj_hand_lbl)

	_bj_status_lbl = Label.new()
	_bj_status_lbl.add_theme_font_size_override("font_size", 14)
	_bj_status_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_bj_status_lbl.custom_minimum_size = Vector2(0, 24)
	root.add_child(_bj_status_lbl)

	var btn_row := HBoxContainer.new()
	btn_row.alignment = BoxContainer.ALIGNMENT_CENTER
	btn_row.add_theme_constant_override("separation", 12)
	root.add_child(btn_row)

	var deal_btn := _make_bj_btn("🃏 Раздать карты", Color(0.08, 0.20, 0.38), Color(0.25, 0.55, 0.90))
	deal_btn.pressed.connect(func(): _bj_deal())
	btn_row.add_child(deal_btn)

	var hit_btn := _make_bj_btn("➕ Взять карту", Color(0.08, 0.20, 0.10), Color(0.22, 0.60, 0.25))
	hit_btn.pressed.connect(func(): _bj_hit())
	btn_row.add_child(hit_btn)

	var stand_btn := _make_bj_btn("✋ Стоп", Color(0.18, 0.08, 0.04), Color(0.60, 0.30, 0.10))
	stand_btn.pressed.connect(func(): _bj_stand())
	btn_row.add_child(stand_btn)

func _make_bj_btn(txt: String, col: Color, brd: Color) -> Button:
	var btn := Button.new()
	btn.text = txt
	btn.custom_minimum_size = Vector2(150, 42)
	btn.add_theme_font_size_override("font_size", 13)
	btn.add_theme_color_override("font_color", Color(0.95, 0.95, 0.95))
	var bs := StyleBoxFlat.new()
	bs.bg_color = col
	bs.border_color = brd
	for s in [SIDE_LEFT, SIDE_RIGHT, SIDE_TOP, SIDE_BOTTOM]:
		bs.set_border_width(s, 2)
		bs.set_corner_radius(s, 8)
	btn.add_theme_stylebox_override("normal", bs)
	var bh := bs.duplicate() as StyleBoxFlat
	bh.bg_color = col.lightened(0.15)
	btn.add_theme_stylebox_override("hover", bh)
	return btn

# ── Открытие ─────────────────────────────────────────────────────────────────

func open() -> void:
	visible = true
	_bet = clampf(_bet, MIN_BET, maxf(_gm.money * 0.20, MIN_BET))
	_refresh_info()
	_panel.modulate.a = 0.0
	_panel.scale = Vector2(0.92, 0.92)
	var tw := create_tween()
	tw.set_parallel(true)
	tw.tween_property(_panel, "modulate:a", 1.0, 0.22)
	tw.tween_property(_panel, "scale", Vector2(1.0, 1.0), 0.22).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	_bj_active = false
	_bj_dealer_lbl.text = "Дилер: —"
	_bj_hand_lbl.text = "Ваша рука: —"
	_bj_status_lbl.text = "Нажми «Раздать карты» чтобы начать"
	_bj_status_lbl.add_theme_color_override("font_color", Color(0.65, 0.65, 0.70))

func _set_bet(amount: float) -> void:
	_bet = minf(amount, maxf(_gm.money, MIN_BET))
	_refresh_info()

func _refresh_info() -> void:
	_balance_lbl.text = "💰 " + _gm.format_money(_gm.money)
	_bet_lbl.text = _gm.format_money(_bet)

# ── Рулетка ──────────────────────────────────────────────────────────────────

func _play_roulette(bet_type: String) -> void:
	if not _can_bet(): return
	var number: int = randi() % 37
	var is_red: bool = number in [1,3,5,7,9,12,14,16,18,19,21,23,25,27,30,32,34,36]
	var is_even: bool = (number > 0 and number % 2 == 0)

	var won := false
	match bet_type:
		"red":   won = is_red
		"black": won = (number > 0 and not is_red)
		"even":  won = is_even
		"odd":   won = (number > 0 and not is_even)

	var num_str := "[%d]" % number

	if won:
		_win(_bet, "🎡 Рулетка: %s  →  выпало %s  ×2" % [bet_type.to_upper(), num_str])
	else:
		_lose("🎡 Рулетка: %s  →  выпало %s" % [bet_type.to_upper(), num_str])

func _play_roulette_number(chosen: int) -> void:
	if not _can_bet(): return
	var number: int = randi() % 37
	if chosen == number:
		_win(_bet * 35.0, "🎡 ЧИСЛО %d — ПОПАЛ! ×36 🔥🔥🔥" % number)
	else:
		_lose("🎡 Число %d — выпало %d" % [chosen, number])

# ── Слоты ─────────────────────────────────────────────────────────────────────

const SLOT_SYMBOLS: Array = ["🍒", "🍋", "🍊", "🍇", "💎", "7️⃣", "⭐"]

func _play_slots(reels: Array, spin_btn: Button) -> void:
	if not _can_bet(): return
	spin_btn.disabled = true

	var results: Array[String] = []
	var delay := 0.0
	var tw := create_tween()
	for i in 3:
		delay += 0.22
		var idx: int = i
		tw.tween_callback(func():
			var sym: String = SLOT_SYMBOLS[randi() % SLOT_SYMBOLS.size()]
			reels[idx].text = sym
			results.append(sym)
			if _am: _am.play_coin()
		).set_delay(delay if i == 0 else 0.22)

	tw.tween_callback(func():
		spin_btn.disabled = false
		_resolve_slots(results)
	).set_delay(0.22)

func _resolve_slots(r: Array[String]) -> void:
	if r[0] == "7️⃣" and r[1] == "7️⃣" and r[2] == "7️⃣":
		_win(_bet * 19.0, "🎰 ДЖЕКПОТ 777! ×20 🔥🔥🔥")
	elif r[0] == r[1] and r[1] == r[2]:
		_win(_bet * 4.0, "🎰 Три одинаковых! ×5 ✅")
	elif r[0] == r[1] or r[1] == r[2] or r[0] == r[2]:
		_win(_bet * 1.0, "🎰 Два совпадения ×2 👍")
	else:
		_lose("🎰 Нет совпадений")

# ── Блэкджек ─────────────────────────────────────────────────────────────────

func _bj_card_value(card: int) -> int:
	return mini(card, 10)

func _bj_hand_sum(hand: Array) -> int:
	var total := 0
	var aces := 0
	for c in hand:
		var v := _bj_card_value(c)
		if c == 1: aces += 1
		total += (v if c != 1 else 11)
	while total > 21 and aces > 0:
		total -= 10
		aces -= 1
	return total

func _bj_card_str(c: int) -> String:
	var names := ["A","2","3","4","5","6","7","8","9","10","J","Q","K"]
	return names[c - 1] if c <= 13 else "?"

func _bj_hand_display(hand: Array) -> String:
	var parts: Array[String] = []
	for c in hand:
		parts.append(_bj_card_str(c))
	return " ".join(parts) + "  (%d)" % _bj_hand_sum(hand)

func _bj_draw() -> int:
	return randi_range(1, 13)

func _bj_deal() -> void:
	if not _can_bet(): return
	_bj_active = true
	_player_hand = [_bj_draw(), _bj_draw()]
	_dealer_hand = [_bj_draw()]
	_bj_update_display(false)
	_bj_status_lbl.text = "Взять карту или остановиться?"
	_bj_status_lbl.add_theme_color_override("font_color", Color(0.80, 0.80, 0.80))
	if _bj_hand_sum(_player_hand) == 21:
		_bj_stand()

func _bj_hit() -> void:
	if not _bj_active: return
	_player_hand.append(_bj_draw())
	_bj_update_display(false)
	if _am: _am.play_coin()
	var sum := _bj_hand_sum(_player_hand)
	if sum > 21:
		_bj_finish(false, "перебор (%d)" % sum)
	elif sum == 21:
		_bj_stand()

func _bj_stand() -> void:
	if not _bj_active: return
	while _bj_hand_sum(_dealer_hand) < 17:
		_dealer_hand.append(_bj_draw())
	_bj_update_display(true)
	var ps := _bj_hand_sum(_player_hand)
	var ds := _bj_hand_sum(_dealer_hand)
	if ds > 21 or ps > ds:
		var bonus := 1.5 if ps == 21 and _player_hand.size() == 2 else 1.0
		_bj_finish(true, "вы %d, дилер %d" % [ps, ds], bonus)
	elif ps == ds:
		_bj_active = false
		_bj_status_lbl.text = "🤝 Ничья — ставка возвращена"
		_bj_status_lbl.add_theme_color_override("font_color", Color(0.80, 0.80, 0.55))
		_show_result("🤝 Ничья", Color(0.80, 0.80, 0.55))
	else:
		_bj_finish(false, "вы %d, дилер %d" % [ps, ds])

func _bj_update_display(reveal_dealer: bool) -> void:
	_bj_hand_lbl.text = "Ваша рука: " + _bj_hand_display(_player_hand)
	if reveal_dealer:
		_bj_dealer_lbl.text = "Дилер: " + _bj_hand_display(_dealer_hand)
	else:
		_bj_dealer_lbl.text = "Дилер: %s ?" % _bj_card_str(_dealer_hand[0])

func _bj_finish(won: bool, reason: String, mult: float = 1.0) -> void:
	_bj_active = false
	if won:
		_win(_bet * mult, "♠ Блэкджек — %s" % reason)
	else:
		_lose("♠ Блэкджек — %s" % reason)

# ── Общая логика выигрыша/проигрыша ─────────────────────────────────────────

func _can_bet() -> bool:
	if _gm.money < _bet:
		_show_result("⚠ Недостаточно денег!", Color(1.0, 0.40, 0.40))
		return false
	return true

func _win(profit: float, msg: String) -> void:
	_gm.add_money(profit)
	_refresh_info()
	_show_result("✅ ВЫИГРЫШ +%s" % _gm.format_money(profit), Color(0.40, 1.0, 0.50))
	_result_lbl.text += "\n" + msg
	if _am: _am.play_level_up()
	var am: Node = get_node_or_null("/root/AchievementManager")
	if am and am.has_method("on_casino_result"): am.on_casino_result(true)
	game_finished.emit(profit)
	_spawn_win_particles()

func _lose(msg: String) -> void:
	_gm.spend_money(_bet)
	_refresh_info()
	_show_result("❌ ПРОИГРЫШ -%s" % _gm.format_money(_bet), Color(1.0, 0.35, 0.35))
	_result_lbl.text += "\n" + msg
	if _am: _am.play_negative()
	var am: Node = get_node_or_null("/root/AchievementManager")
	if am and am.has_method("on_casino_result"): am.on_casino_result(false)
	game_finished.emit(-_bet)
	_shake_panel()

func _spawn_win_particles() -> void:
	for i in 22:
		var coin := ColorRect.new()
		var sz := randf_range(7.0, 14.0)
		coin.size = Vector2(sz, sz * randf_range(0.7, 1.0))
		coin.color = Color(1.0, randf_range(0.72, 0.95), 0.18, 0.92)
		coin.position = Vector2(randf_range(300, 900), randf_range(160, 250))
		add_child(coin)
		var fall := Vector2(randf_range(-100, 100), randf_range(140, 320))
		var delay := randf_range(0.0, 0.22)
		var tw := coin.create_tween()
		tw.set_parallel(true)
		tw.tween_property(coin, "position", coin.position + fall, randf_range(0.55, 0.90)).set_ease(Tween.EASE_IN).set_delay(delay)
		tw.tween_property(coin, "rotation_degrees", randf_range(-200.0, 200.0), 0.85).set_delay(delay)
		tw.tween_property(coin, "modulate:a", 0.0, 0.38).set_delay(delay + randf_range(0.45, 0.65))
		tw.set_parallel(false)
		tw.tween_callback(coin.queue_free)

func _shake_panel() -> void:
	var ox: float = _panel.position.x
	var tw := create_tween()
	tw.tween_property(_panel, "position:x", ox + 13.0, 0.05)
	tw.tween_property(_panel, "position:x", ox - 11.0, 0.05)
	tw.tween_property(_panel, "position:x", ox + 8.0, 0.04)
	tw.tween_property(_panel, "position:x", ox - 6.0, 0.04)
	tw.tween_property(_panel, "position:x", ox + 3.0, 0.03)
	tw.tween_property(_panel, "position:x", ox, 0.03)

func _show_result(text: String, col: Color) -> void:
	_result_lbl.text = text
	_result_lbl.add_theme_color_override("font_color", col)
	_result_lbl.modulate.a = 0.0
	_result_lbl.scale = Vector2(0.8, 0.8)
	if _result_tween and _result_tween.is_valid():
		_result_tween.kill()
	_result_tween = create_tween()
	_result_tween.set_parallel(true)
	_result_tween.tween_property(_result_lbl, "modulate:a", 1.0, 0.20)
	_result_tween.tween_property(_result_lbl, "scale", Vector2(1.0, 1.0), 0.20).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)

func _short(v: float) -> String:
	if v >= 1_000_000: return "%.0fм" % (v / 1_000_000)
	if v >= 1_000:     return "%.0fк" % (v / 1_000)
	return "%.0f" % v
