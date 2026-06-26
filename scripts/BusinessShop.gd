extends Control

var gm: Node
var bm: Node

var _panel       : Panel
var _tabs        : TabContainer
var _toast_lbl   : Label
var _toast_tween : Tween  = null
var _sell_confirm: bool   = false
var _tab_vboxes  : Dictionary = {}

func _ready() -> void:
	gm = get_node("/root/GameManager")
	bm = get_node("/root/BusinessManager")
	add_to_group("business_shop")
	_build_ui()
	bm.business_changed.connect(func(): if visible: _refresh())
	bm.bank_changed.connect(func(_v): if visible: _refresh())
	bm.security_event.connect(_on_security_event)
	visible = false

func _build_ui() -> void:
	anchor_right  = 1.0
	anchor_bottom = 1.0

	var dimmer = ColorRect.new()
	dimmer.set_anchors_preset(Control.PRESET_FULL_RECT)
	dimmer.color        = Color(0, 0, 0, 0.72)
	dimmer.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(dimmer)

	_panel = Panel.new()
	_panel.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	_panel.size     = Vector2(990, 660)
	_panel.position = Vector2(-495, -330)
	var ps = StyleBoxFlat.new()
	ps.bg_color     = Color(0.04, 0.04, 0.08, 0.98)
	ps.border_color = Color(0.55, 0.42, 0.10, 0.90)
	for s in [SIDE_LEFT, SIDE_RIGHT, SIDE_TOP, SIDE_BOTTOM]:
		ps.set_border_width(s, 2)
		ps.set_corner_radius(s, 12)
	_panel.add_theme_stylebox_override("panel", ps)
	add_child(_panel)

	var hdr = HBoxContainer.new()
	hdr.position = Vector2(14, 12)
	hdr.size     = Vector2(962, 34)
	hdr.add_theme_constant_override("separation", 10)
	_panel.add_child(hdr)

	var title_lbl = Label.new()
	title_lbl.text = "💹 Центр инвестиций"
	title_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title_lbl.add_theme_font_size_override("font_size", 22)
	title_lbl.add_theme_color_override("font_color", Color(1.0, 0.88, 0.25))
	title_lbl.add_theme_constant_override("outline_size", 3)
	title_lbl.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.70))
	hdr.add_child(title_lbl)

	var close_btn = Button.new()
	close_btn.text = "✖"
	close_btn.custom_minimum_size = Vector2(34, 34)
	close_btn.add_theme_font_size_override("font_size", 14)
	close_btn.add_theme_color_override("font_color", Color.WHITE)
	_style_btn(close_btn, Color(0.22, 0.07, 0.07), Color(0.55, 0.18, 0.18))
	close_btn.pressed.connect(func(): visible = false)
	hdr.add_child(close_btn)

	_toast_lbl = Label.new()
	_toast_lbl.position  = Vector2(0, 48)
	_toast_lbl.size      = Vector2(990, 22)
	_toast_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_toast_lbl.add_theme_font_size_override("font_size", 13)
	_toast_lbl.add_theme_color_override("font_color", Color(1.0, 0.40, 0.40))
	_toast_lbl.visible = false
	_panel.add_child(_toast_lbl)

	_tabs = TabContainer.new()
	_tabs.position = Vector2(5, 52)
	_tabs.size     = Vector2(980, 602)
	_panel.add_child(_tabs)

	var tab_names = ["Бизнес", "Сотрудники", "Банк", "Кредит", "Охрана"]
	for i in tab_names.size():
		var tab_name = tab_names[i]
		var scroll = ScrollContainer.new()
		scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		scroll.size_flags_vertical   = Control.SIZE_EXPAND_FILL
		var vb = VBoxContainer.new()
		vb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		vb.add_theme_constant_override("separation", 8)
		vb.custom_minimum_size = Vector2(950, 0)
		scroll.add_child(vb)
		_tabs.add_child(scroll)
		_tabs.set_tab_title(i, tab_name)
		_tab_vboxes[tab_name] = vb

func open() -> void:
	_sell_confirm = false
	visible = true
	_panel.modulate.a = 0.0
	_panel.scale      = Vector2(0.92, 0.92)
	var tw = create_tween()
	tw.set_parallel(true)
	tw.tween_property(_panel, "modulate:a", 1.0, 0.22)
	tw.tween_property(_panel, "scale", Vector2(1.0, 1.0), 0.22).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	_refresh()

func _refresh() -> void:
	_build_business_tab()
	_build_team_tab()
	_build_bank_tab()
	_build_loan_tab()
	_build_security_tab()

func _vbox(tab: String) -> VBoxContainer:
	return _tab_vboxes[tab]

# ══════════════════════════════════════════════════════════════════════════════
# Бизнес
# ══════════════════════════════════════════════════════════════════════════════
func _build_business_tab() -> void:
	var vb = _vbox("Бизнес")
	for c in vb.get_children(): c.queue_free()

	# Заголовок империи: сколько бизнесов из лимита
	var cap: int = bm.max_businesses()
	var cnt: int = bm.business_count()
	_lbl(vb, "🏢 Бизнесов в империи: %d / %d   📈 Доход: +%s/день" % [
		cnt, cap, gm.format_money(bm.get_daily_income())], Color(0.70, 0.85, 1.00), 14)

	# Управление империей (нагрузка/ёмкость/эффективность + найм топ-менеджмента)
	if cnt > 0:
		vb.add_child(_make_management())
		vb.add_child(_make_ipo())

	# Переключатель активного бизнеса (если их несколько)
	if cnt > 1:
		vb.add_child(_make_switcher())

	# Карточка активного бизнеса
	var owned_id = bm.owned_business_id
	var cur_idx  = -1
	for i in bm.BUSINESS_TYPES.size():
		if bm.BUSINESS_TYPES[i].id == owned_id:
			cur_idx = i
	if cur_idx >= 0:
		vb.add_child(_make_owned_card(bm.BUSINESS_TYPES[cur_idx]))

	vb.add_child(_sep())

	# Каталог: открыть НОВЫЙ бизнес (компании накапливаются, а не заменяются)
	var at_cap: bool = cnt >= cap
	_lbl(vb, "Лимит бизнесов достигнут — повышай титул" if at_cap else "Открыть новый бизнес:",
		Color(0.85, 0.55, 0.45) if at_cap else Color(0.75, 0.78, 0.85), 13)
	for i in bm.BUSINESS_TYPES.size():
		var bt        : Dictionary = bm.BUSINESS_TYPES[i]
		var is_locked = gm.current_title_index < bt.min_title
		vb.add_child(_make_biz_card(bt, is_locked, at_cap, cur_idx))

# Панель IPO / публичной компании.
func _make_ipo() -> Control:
	var box = VBoxContainer.new()
	box.add_theme_constant_override("separation", 4)
	var val: float = bm.company_valuation()
	if bm.is_public:
		var own_pct: int = int(round(bm.owner_fraction * 100.0))
		_lbl(box, "🏛 Публичная компания · ваша доля %d%% · капитализация %s" % [own_pct, gm.format_money(val)],
			Color(0.70, 0.85, 1.0), 12)
		_lbl(box, "Курс акции: %s · вы получаете %d%% прибыли" % [gm.format_money(bm.share_price()), own_pct],
			Color(0.60, 0.72, 0.85), 11)
		var row = HFlowContainer.new()
		row.add_theme_constant_override("h_separation", 6)
		row.add_theme_constant_override("v_separation", 6)
		if bm.can_secondary():
			var sb = Button.new()
			sb.text = "📈 Допэмиссия (+%s)" % gm.format_money(val * bm.SECONDARY_FRACTION)
			sb.add_theme_font_size_override("font_size", 11)
			_style_btn(sb, Color(0.10, 0.18, 0.12), Color(0.30, 0.60, 0.30, 0.8))
			sb.add_theme_color_override("font_color", Color(0.70, 1.0, 0.70))
			sb.pressed.connect(func(): bm.secondary_offering())
			row.add_child(sb)
		var bb = Button.new()
		bb.text = "💼 Выкуп доли (%s)" % gm.format_money(bm.buyback_cost())
		bb.add_theme_font_size_override("font_size", 11)
		if bm.can_buyback():
			_style_btn(bb, Color(0.10, 0.14, 0.24), Color(0.30, 0.50, 0.70, 0.8))
			bb.add_theme_color_override("font_color", Color(0.75, 0.85, 1.0))
			bb.pressed.connect(func():
				if not bm.buyback(): _flash_toast("Недостаточно денег!"))
		else:
			_style_btn(bb, Color(0.09, 0.09, 0.13), Color(0.26, 0.26, 0.36, 0.55))
			bb.disabled = true
			bb.add_theme_color_override("font_color", Color(0.40, 0.40, 0.45))
		row.add_child(bb)
		box.add_child(row)
	elif bm.can_ipo():
		_lbl(box, "🏛 Можно провести IPO! Капитализация: %s" % gm.format_money(val), Color(1.0, 0.90, 0.40), 12)
		var ib = Button.new()
		ib.text = "🏛 Провести IPO (привлечь ~%s)" % gm.format_money(val * bm.IPO_SELL_FRACTION)
		ib.add_theme_font_size_override("font_size", 12)
		_style_btn(ib, Color(0.14, 0.16, 0.26), Color(0.40, 0.45, 0.80, 0.85))
		ib.add_theme_color_override("font_color", Color(0.80, 0.85, 1.0))
		ib.pressed.connect(_on_ipo)
		box.add_child(ib)
	else:
		_lbl(box, "🏛 Капитализация: %s  (для IPO нужно ≥ %s)" % [gm.format_money(val), gm.format_money(bm.IPO_MIN_VALUATION)],
			Color(0.60, 0.65, 0.75), 11)
	return box

func _on_ipo() -> void:
	var p: float = bm.do_ipo()
	if p > 0.0:
		_flash_toast("🏛 IPO состоялось! Привлечено " + gm.format_money(p))

# Панель управления империей: нагрузка/ёмкость/эффективность + найм управленцев.
func _make_management() -> Control:
	var box = VBoxContainer.new()
	box.add_theme_constant_override("separation", 4)
	var load_n: int = bm.management_load()
	var cap_n: int = bm.management_capacity()
	var eff: float = bm.efficiency_mult()
	var eff_pct: int = int(round(eff * 100.0))
	var col := Color(0.95, 0.5, 0.4) if eff < 1.0 else Color(0.60, 0.85, 0.60)
	var warn := "   ⚠ перегрузка — наймите управленцев!" if eff < 1.0 else ""
	_lbl(box, "🧑‍💼 Управление: нагрузка %d / ёмкость %d · эффективность %d%%%s" % [
		load_n, cap_n, eff_pct, warn], col, 12)
	var exec_sal: float = bm.get_executive_salary()
	if exec_sal > 0.0:
		_lbl(box, "ЗП топ-менеджмента: -%s/день" % gm.format_money(exec_sal), Color(0.72, 0.62, 0.52), 11)
	var counts: Dictionary = bm.executive_counts()
	var row = HFlowContainer.new()
	row.add_theme_constant_override("h_separation", 6)
	row.add_theme_constant_override("v_separation", 6)
	for et in bm.EXECUTIVE_TYPES:
		var have: int = counts.get(et.id, 0)
		var btn = Button.new()
		btn.text = "%s %s ×%d  +%d ёмк (%s)" % [et.icon, et.name, have, et.capacity, gm.format_money(et.cost)]
		btn.add_theme_font_size_override("font_size", 11)
		btn.tooltip_text = "%s  ЗП %s/день" % [et.desc, gm.format_money(et.salary)]
		var afford: bool = gm.money >= et.cost
		if afford:
			_style_btn(btn, Color(0.10, 0.16, 0.24), Color(0.30, 0.50, 0.70, 0.8))
			btn.add_theme_color_override("font_color", Color(0.75, 0.85, 1.0))
			var eid: String = et.id
			btn.pressed.connect(func():
				if not bm.hire_executive(eid): _flash_toast("Недостаточно денег!"))
		else:
			_style_btn(btn, Color(0.09, 0.09, 0.13), Color(0.26, 0.26, 0.36, 0.55))
			btn.disabled = true
			btn.add_theme_color_override("font_color", Color(0.40, 0.40, 0.45))
		row.add_child(btn)
	box.add_child(row)
	return box

# Переключатель бизнесов империи — чипы по каждому владению.
func _make_switcher() -> Control:
	var box = HFlowContainer.new()
	box.add_theme_constant_override("h_separation", 6)
	box.add_theme_constant_override("v_separation", 6)
	for i in bm.businesses.size():
		var b = bm.businesses[i]
		var bt = bm._get_type(String(b.get("type_id", "")))
		if bt.is_empty(): continue
		var btn = Button.new()
		btn.text = "%s %s" % [bt.get("icon", "?"), bt.get("name", "?")]
		btn.add_theme_font_size_override("font_size", 12)
		var is_active: bool = (i == bm.active_index)
		if is_active:
			_style_btn(btn, Color(0.10, 0.22, 0.12), Color(0.30, 0.72, 0.30, 0.9))
			btn.add_theme_color_override("font_color", Color(0.70, 1.0, 0.70))
		else:
			_style_btn(btn, Color(0.08, 0.09, 0.13), Color(0.26, 0.26, 0.36, 0.6))
			btn.add_theme_color_override("font_color", Color(0.78, 0.80, 0.88))
		var idx: int = i
		btn.pressed.connect(func(): bm.set_active(idx))
		box.add_child(btn)
	return box

func _make_owned_card(bt: Dictionary) -> PanelContainer:
	var card = PanelContainer.new()
	var cs   = StyleBoxFlat.new()
	cs.bg_color     = Color(0.05, 0.12, 0.05, 0.94)
	cs.border_color = Color(0.30, 0.75, 0.30, 0.94)
	cs.set_border_width_all(2)
	cs.set_corner_radius_all(10)
	cs.content_margin_left   = 16
	cs.content_margin_right  = 16
	cs.content_margin_top    = 12
	cs.content_margin_bottom = 12
	card.add_theme_stylebox_override("panel", cs)

	var col = VBoxContainer.new()
	col.add_theme_constant_override("separation", 8)
	card.add_child(col)

	var r1 = HBoxContainer.new()
	r1.add_theme_constant_override("separation", 12)
	col.add_child(r1)

	var icon_lbl = Label.new()
	icon_lbl.text = bt.icon
	icon_lbl.add_theme_font_size_override("font_size", 38)
	icon_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	r1.add_child(icon_lbl)

	var ncol = VBoxContainer.new()
	ncol.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	ncol.add_theme_constant_override("separation", 3)
	r1.add_child(ncol)

	var stars = ""
	for i in bm.MAX_BIZ_LEVEL:
		stars += "⭐" if i < bm.business_level else "☆"
	_lbl(ncol, bt.name + "   " + stars, Color(0.60, 1.00, 0.60), 18)
	_lbl(ncol,
		"📈 +%s/день   👥 %d/%d сотр.   🏆 Всего: %s   📅 %d дней" % [
			gm.format_money(bm.get_active_income()),
			bm.employees.size(), bt.max_employees,
			gm.format_money(bm.total_earned),
			bm.business_days
		], Color(0.55, 0.90, 0.55), 12)

	# Доля рынка в секторе бизнеса + захват доли
	var sector: String = bm.sector_of(bt.id)
	if sector != "":
		var mrow = HBoxContainer.new()
		mrow.add_theme_constant_override("separation", 8)
		col.add_child(mrow)
		var share_pct: int = int(round(bm.get_share(sector) * 100.0))
		var comp: float = bm.sector_competition_mult(sector)
		var comp_pct: int = int(round((comp - 1.0) * 100.0))
		var sname: String = bm.SECTOR_NAMES.get(sector, sector)
		var ml = _lbl(mrow, "%s · доля рынка %d%%  (доход %+d%%)" % [sname, share_pct, comp_pct],
			Color(0.62, 0.78, 1.0), 12)
		ml.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var mcost: int = bm.market_invest_cost(sector)
		var mbtn = Button.new()
		mbtn.text = "📣 Захватить долю (%s)" % gm.format_money(mcost)
		mbtn.add_theme_font_size_override("font_size", 11)
		_style_btn(mbtn, Color(0.10, 0.14, 0.26), Color(0.30, 0.45, 0.75, 0.8))
		mbtn.add_theme_color_override("font_color", Color(0.70, 0.85, 1.0))
		var sec: String = sector
		mbtn.pressed.connect(func():
			if not bm.invest_market_share(sec): _flash_toast("Недостаточно денег!"))
		mrow.add_child(mbtn)

		# Конкуренты в секторе — поглощения (M&A)
		var rivals: Array = bm.get_competitors(sector)
		for ri in range(rivals.size()):
			var r = rivals[ri]
			var crow = HBoxContainer.new()
			crow.add_theme_constant_override("separation", 8)
			col.add_child(crow)
			var rl = _lbl(crow, "🏴 %s · доля рынка %d%%" % [
				r.get("name", "?"), int(round(float(r.get("share", 0.0)) * 100.0))],
				Color(0.85, 0.62, 0.62), 11)
			rl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			var acost: int = bm.acquisition_cost(sector, ri)
			var abtn = Button.new()
			abtn.text = "🤝 Поглотить (%s)" % gm.format_money(acost)
			abtn.add_theme_font_size_override("font_size", 11)
			if gm.money >= acost:
				_style_btn(abtn, Color(0.18, 0.10, 0.20), Color(0.60, 0.30, 0.60, 0.8))
				abtn.add_theme_color_override("font_color", Color(0.95, 0.75, 1.0))
				var sec2: String = sector
				var idx2: int = ri
				abtn.pressed.connect(func():
					if not bm.acquire_competitor(sec2, idx2): _flash_toast("Недостаточно денег!"))
			else:
				_style_btn(abtn, Color(0.09, 0.09, 0.13), Color(0.26, 0.26, 0.36, 0.55))
				abtn.disabled = true
				abtn.add_theme_color_override("font_color", Color(0.40, 0.40, 0.45))
			crow.add_child(abtn)
		if rivals.is_empty():
			_lbl(col, "👑 Монополия в секторе — конкурентов не осталось!", Color(1.0, 0.85, 0.40), 11)

	var lvl_row = HBoxContainer.new()
	lvl_row.add_theme_constant_override("separation", 8)
	col.add_child(lvl_row)

	var lvl_lbl = _lbl(lvl_row, "Уровень %d/%d" % [bm.business_level, bm.MAX_BIZ_LEVEL],
		Color(0.78, 0.92, 0.78), 12)
	lvl_lbl.custom_minimum_size = Vector2(100, 0)

	var pb = ProgressBar.new()
	pb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	pb.custom_minimum_size   = Vector2(0, 12)
	pb.max_value  = bm.MAX_BIZ_LEVEL
	pb.value      = bm.business_level
	pb.show_percentage = false
	var fill = StyleBoxFlat.new()
	fill.bg_color = Color(0.28, 0.82, 0.28)
	fill.set_corner_radius_all(6)
	var bg2 = StyleBoxFlat.new()
	bg2.bg_color = Color(0.10, 0.18, 0.10)
	bg2.set_corner_radius_all(6)
	pb.add_theme_stylebox_override("fill", fill)
	pb.add_theme_stylebox_override("background", bg2)
	lvl_row.add_child(pb)

	var btn_row = HBoxContainer.new()
	btn_row.add_theme_constant_override("separation", 10)
	col.add_child(btn_row)

	if bm.business_level < bm.MAX_BIZ_LEVEL:
		var upg_cost = bm.get_upgrade_cost()
		var can_upg  = gm.money >= upg_cost
		var upg_btn  = Button.new()
		upg_btn.text = "⬆ Улучшить до ур.%d — %s" % [bm.business_level + 1, gm.format_money(upg_cost)]
		upg_btn.custom_minimum_size = Vector2(310, 36)
		upg_btn.add_theme_font_size_override("font_size", 13)
		if can_upg:
			upg_btn.add_theme_color_override("font_color", Color(0.70, 1.00, 0.70))
			_style_btn(upg_btn, Color(0.08, 0.22, 0.10), Color(0.25, 0.65, 0.28, 0.88))
			upg_btn.pressed.connect(func():
				if not bm.upgrade_level(): _flash_toast("Недостаточно денег!")
			)
		else:
			upg_btn.add_theme_color_override("font_color", Color(0.35, 0.35, 0.42))
			_style_btn(upg_btn, Color(0.09, 0.09, 0.13), Color(0.26, 0.26, 0.36))
			upg_btn.disabled = true
		btn_row.add_child(upg_btn)
	else:
		_lbl(btn_row, "✨ Максимальный уровень!", Color(1.0, 0.88, 0.25), 13)

	var spacer = Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	btn_row.add_child(spacer)

	var sell_val = bm.get_business_value() * 0.5
	var sell_btn = Button.new()
	sell_btn.custom_minimum_size = Vector2(240, 36)
	sell_btn.add_theme_font_size_override("font_size", 13)
	if _sell_confirm:
		sell_btn.text = "⚠ Подтвердить продажу?"
		sell_btn.add_theme_color_override("font_color", Color(1.0, 0.25, 0.25))
		_style_btn(sell_btn, Color(0.22, 0.04, 0.04), Color(0.75, 0.18, 0.18, 0.90))
		sell_btn.pressed.connect(func():
			var got = bm.sell_business()
			_sell_confirm = false
			_flash_toast("Бизнес продан за " + gm.format_money(got) + "!")
		)
	else:
		sell_btn.text = "🏷 Продать (50%% = %s)" % gm.format_money(sell_val)
		sell_btn.add_theme_color_override("font_color", Color(1.0, 0.62, 0.38))
		_style_btn(sell_btn, Color(0.16, 0.08, 0.04), Color(0.55, 0.28, 0.10, 0.80))
		sell_btn.pressed.connect(func():
			_sell_confirm = true
			_refresh()
			get_tree().create_timer(4.0).timeout.connect(func():
				if _sell_confirm:
					_sell_confirm = false
					if visible: _refresh()
			)
		)
	btn_row.add_child(sell_btn)
	return card

func _make_biz_card(bt: Dictionary, is_locked: bool, is_past: bool, cur_idx: int) -> PanelContainer:
	var card = PanelContainer.new()
	var cs   = StyleBoxFlat.new()
	if is_past:
		cs.bg_color     = Color(0.04, 0.04, 0.07, 0.40)
		cs.border_color = Color(0.12, 0.12, 0.18, 0.30)
	elif is_locked:
		cs.bg_color     = Color(0.05, 0.05, 0.09, 0.55)
		cs.border_color = Color(0.20, 0.18, 0.26, 0.45)
	elif cur_idx >= 0:
		cs.bg_color     = Color(0.10, 0.09, 0.04, 0.88)
		cs.border_color = Color(0.62, 0.47, 0.10, 0.88)
	else:
		cs.bg_color     = Color(0.07, 0.10, 0.05, 0.85)
		cs.border_color = Color(0.38, 0.55, 0.18, 0.80)
	cs.set_border_width_all(2)
	cs.set_corner_radius_all(8)
	cs.content_margin_left   = 12
	cs.content_margin_right  = 12
	cs.content_margin_top    = 8
	cs.content_margin_bottom = 8
	card.add_theme_stylebox_override("panel", cs)

	var row = HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	card.add_child(row)

	var icon_lbl = Label.new()
	icon_lbl.text = bt.icon
	icon_lbl.add_theme_font_size_override("font_size", 30)
	icon_lbl.custom_minimum_size = Vector2(44, 44)
	icon_lbl.vertical_alignment  = VERTICAL_ALIGNMENT_CENTER
	icon_lbl.modulate.a = 0.28 if (is_past or is_locked) else 1.0
	row.add_child(icon_lbl)

	var info = VBoxContainer.new()
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info.add_theme_constant_override("separation", 3)
	row.add_child(info)

	var nc: Color
	if is_past:        nc = Color(0.28, 0.28, 0.34)
	elif is_locked:    nc = Color(0.35, 0.35, 0.42)
	elif cur_idx >= 0: nc = Color(1.00, 0.90, 0.55)
	else:              nc = Color(0.85, 0.98, 0.68)

	_lbl(info, bt.name, nc, 15)
	_lbl(info, bt.desc,
		Color(0.28, 0.28, 0.34) if (is_past or is_locked) else Color(0.55, 0.58, 0.65), 11
	).autowrap_mode = TextServer.AUTOWRAP_WORD

	var sc       = Color(0.28, 0.28, 0.34) if (is_past or is_locked) else Color(0.68, 0.85, 0.58)
	var stat_row = HBoxContainer.new()
	stat_row.add_theme_constant_override("separation", 4)
	info.add_child(stat_row)
	_lbl(stat_row, "📈 +" + gm.format_money(bt.income_per_day) + "/день", sc, 12)
	_lbl(stat_row, "   👥 до " + str(bt.max_employees) + " сотр.", sc, 12)
	if is_locked and bt.min_title < gm.TITLES.size():
		_lbl(stat_row, "   🔒 " + gm.TITLES[bt.min_title].name, Color(0.55, 0.35, 0.35), 12)

	var rv = VBoxContainer.new()
	rv.alignment = BoxContainer.ALIGNMENT_CENTER
	rv.add_theme_constant_override("separation", 6)
	row.add_child(rv)

	var branches: int = bm.branch_count(bt.id)
	var cost_lbl = Label.new()
	cost_lbl.text = gm.format_money(bm.franchise_cost(bt.id))
	cost_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	cost_lbl.add_theme_font_size_override("font_size", 13)
	cost_lbl.add_theme_color_override("font_color",
		Color(0.25, 0.25, 0.30) if (is_past or is_locked) else Color(1.00, 0.88, 0.25))
	rv.add_child(cost_lbl)
	# Филиалы и бренд-бонус, если уже есть точки этого типа
	if branches > 0:
		var br_lbl = Label.new()
		br_lbl.text = "🏪 %d точк.  бренд +%d%%" % [branches, int(round((bm.brand_mult(bt.id) - 1.0) * 100.0))]
		br_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		br_lbl.add_theme_font_size_override("font_size", 10)
		br_lbl.add_theme_color_override("font_color", Color(0.55, 0.75, 1.0))
		rv.add_child(br_lbl)

	var btn = Button.new()
	btn.custom_minimum_size = Vector2(140, 34)
	btn.add_theme_font_size_override("font_size", 13)
	if is_past:
		btn.text = "↩ Пройдено"
		_style_btn(btn, Color(0.06, 0.06, 0.10), Color(0.14, 0.14, 0.20, 0.45))
		btn.disabled = true
		btn.add_theme_color_override("font_color", Color(0.25, 0.25, 0.30))
	elif is_locked:
		btn.text = "🔒 Закрыто"
		_style_btn(btn, Color(0.07, 0.06, 0.10), Color(0.20, 0.18, 0.26, 0.50))
		btn.disabled = true
		btn.add_theme_color_override("font_color", Color(0.35, 0.35, 0.42))
	else:
		var can_afford = gm.money >= bm.franchise_cost(bt.id)
		# is_past здесь означает «лимит бизнесов достигнут» (передаётся из вкладки)
		var at_cap = is_past
		btn.text = ("🏪 Филиал" if branches > 0 else "🚀 Открыть")
		if can_afford and not at_cap:
			var bid = bt.id
			_style_btn(btn, Color(0.08, 0.20, 0.10), Color(0.25, 0.62, 0.25, 0.85))
			btn.add_theme_color_override("font_color", Color(0.70, 1.00, 0.70))
			btn.pressed.connect(func():
				var ok = bm.open_business(bid)
				if not ok: _flash_toast("Недостаточно денег или лимит бизнесов!")
			)
		else:
			_style_btn(btn, Color(0.09, 0.09, 0.13), Color(0.26, 0.26, 0.36, 0.55))
			btn.add_theme_color_override("font_color", Color(0.38, 0.38, 0.45))
			btn.disabled = true
	rv.add_child(btn)
	return card

# ══════════════════════════════════════════════════════════════════════════════
# Сотрудники
# ══════════════════════════════════════════════════════════════════════════════
func _build_team_tab() -> void:
	var vb  = _vbox("Сотрудники")
	for c in vb.get_children(): c.queue_free()

	var biz = bm.get_business()
	if biz.is_empty():
		_lbl(vb, "Сначала откройте бизнес.", Color(0.80, 0.60, 0.30), 14
		).horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		return

	var base_income = biz.income_per_day * bm.get_level_income_mult()
	var emp_bonus   = bm.get_daily_income() - base_income
	vb.add_child(_info_card([
		["👥 Состав:",       "%d / %d сотрудников" % [bm.employees.size(), biz.max_employees]],
		["💸 Суммарная ЗП:", "-" + gm.format_money(bm.get_total_salary()) + " /день"],
		["📈 Бонус команды:","+" + gm.format_money(maxf(0, emp_bonus)) + " /день"],
	], Color(0.05, 0.10, 0.05), Color(0.22, 0.55, 0.22)))
	vb.add_child(_sep())

	if not bm.employees.is_empty():
		_lbl(vb, "📋 Текущая команда:", Color(0.72, 0.88, 0.72), 13)
		for i in bm.employees.size():
			var et = bm._get_employee_type(bm.employees[i].type_id)
			vb.add_child(_make_emp_card(et, i))
		vb.add_child(_sep())

	vb.add_child(_make_synergy_card())
	vb.add_child(_sep())

	if bm.employees.size() < biz.max_employees:
		_lbl(vb, "➕ Нанять сотрудника:", Color(0.72, 0.88, 0.72), 13)
		for et in bm.EMPLOYEE_TYPES:
			vb.add_child(_make_hire_card(et))
	else:
		_lbl(vb, "✅ Команда полностью укомплектована.", Color(0.55, 0.85, 0.55), 13)

# ── Синергия ──────────────────────────────────────────────────────────────────
func _make_synergy_card() -> PanelContainer:
	var card = PanelContainer.new()
	var cs   = StyleBoxFlat.new()
	var mult   = bm.get_synergy_mult()
	var active = bm.is_synergy_active()
	var penalty = mult < 1.0
	cs.bg_color     = Color(0.10, 0.08, 0.02, 0.80) if active else (Color(0.12, 0.04, 0.04, 0.75) if penalty else Color(0.07, 0.07, 0.10, 0.70))
	cs.border_color = Color(0.85, 0.65, 0.15, 0.85) if active else (Color(0.65, 0.20, 0.20, 0.80) if penalty else Color(0.30, 0.30, 0.40, 0.60))
	cs.set_border_width_all(2 if active else 1)
	cs.set_corner_radius_all(6)
	cs.content_margin_left = 12; cs.content_margin_right  = 12
	cs.content_margin_top  = 8;  cs.content_margin_bottom = 8
	card.add_theme_stylebox_override("panel", cs)

	var vb = VBoxContainer.new()
	vb.add_theme_constant_override("separation", 4)
	card.add_child(vb)

	var syn = bm.get_synergy_recipe()
	if syn.is_empty():
		_lbl(vb, "⚡ Синергия для этого бизнеса не определена.", Color(0.55, 0.55, 0.62), 12)
		return card

	var pct = int(round((mult - 1.0) * 100))
	var pct_str = ("+%d%%" % pct) if pct >= 0 else ("%d%%" % pct)
	var tier = bm.get_synergy_tier_name()
	var header_col = Color(1.00, 0.85, 0.35) if active else (Color(1.00, 0.55, 0.55) if penalty else Color(0.78, 0.78, 0.85))
	_lbl(vb, "⚡ Синергия: %s — %s к прибыли" % [tier, pct_str], header_col, 13)

	var fulfillment = int(round(bm.get_synergy_fulfillment() * 100))
	_lbl(vb, "Заполненность рецепта: %d%%   (мин. %d%% снимает штраф, %d%%+ растёт бонус)" % [
		fulfillment, int(bm.SYN_MIN_R * 100), int(bm.SYN_MID_R * 100)
	], Color(0.60, 0.60, 0.68), 10)

	var progress = bm.get_synergy_progress()
	var parts: Array = []
	for type_id in progress:
		var et = bm._get_employee_type(type_id)
		var p  = progress[type_id]
		var ok = p.have >= p.need
		parts.append("%s%s %d/%d" % [et.icon, "✅" if ok else "", p.have, p.need])
	_lbl(vb, "Нужно: " + "   ".join(parts), Color(0.65, 0.65, 0.72), 11)

	if not active:
		var auto_btn = Button.new()
		auto_btn.text = "🤖 Авто-набор под синергию"
		auto_btn.custom_minimum_size = Vector2(0, 32)
		auto_btn.add_theme_font_size_override("font_size", 12)
		auto_btn.add_theme_color_override("font_color", Color(1.00, 0.90, 0.55))
		_style_btn(auto_btn, Color(0.18, 0.13, 0.03), Color(0.70, 0.55, 0.15, 0.85))
		auto_btn.pressed.connect(func():
			var hired = bm.auto_fill_synergy()
			if hired <= 0: _flash_toast("Не хватает мест или средств!")
		)
		vb.add_child(auto_btn)
	return card

func _make_emp_card(et: Dictionary, idx: int) -> PanelContainer:
	var card = PanelContainer.new()
	var cs   = StyleBoxFlat.new()
	cs.bg_color     = Color(0.06, 0.10, 0.06, 0.80)
	cs.border_color = Color(0.22, 0.40, 0.22, 0.70)
	cs.set_border_width_all(1)
	cs.set_corner_radius_all(6)
	cs.content_margin_left = 12; cs.content_margin_right  = 12
	cs.content_margin_top  = 7;  cs.content_margin_bottom = 7
	card.add_theme_stylebox_override("panel", cs)

	var row = HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	card.add_child(row)

	var icon = Label.new()
	icon.text = et.icon
	icon.add_theme_font_size_override("font_size", 24)
	icon.custom_minimum_size = Vector2(36, 36)
	icon.vertical_alignment  = VERTICAL_ALIGNMENT_CENTER
	row.add_child(icon)

	var info = VBoxContainer.new()
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info.add_theme_constant_override("separation", 2)
	row.add_child(info)

	_lbl(info, et.name, Color(0.85, 0.95, 0.85), 14)
	var net = et.income_bonus - et.salary_per_day
	_lbl(info,
		"ЗП: -%s/д   Бонус: +%s/д   Вклад: %s%s/д" % [
			gm.format_money(et.salary_per_day), gm.format_money(et.income_bonus),
			"+" if net >= 0 else "", gm.format_money(net)
		], Color(0.50, 0.70, 0.50), 11)

	var fire_btn = Button.new()
	fire_btn.text = "🔥 Уволить"
	fire_btn.custom_minimum_size = Vector2(100, 30)
	fire_btn.add_theme_font_size_override("font_size", 12)
	fire_btn.add_theme_color_override("font_color", Color(1.00, 0.55, 0.55))
	_style_btn(fire_btn, Color(0.20, 0.07, 0.07), Color(0.52, 0.20, 0.20, 0.80))
	fire_btn.pressed.connect(func(): bm.fire_employee(idx))
	row.add_child(fire_btn)
	return card

func _make_hire_card(et: Dictionary) -> PanelContainer:
	var card = PanelContainer.new()
	var cs   = StyleBoxFlat.new()
	cs.bg_color     = Color(0.06, 0.09, 0.05, 0.70)
	cs.border_color = Color(0.22, 0.42, 0.18, 0.65)
	cs.set_border_width_all(1)
	cs.set_corner_radius_all(6)
	cs.content_margin_left = 12; cs.content_margin_right  = 12
	cs.content_margin_top  = 7;  cs.content_margin_bottom = 7
	card.add_theme_stylebox_override("panel", cs)

	var row = HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	card.add_child(row)

	var icon = Label.new()
	icon.text = et.icon
	icon.add_theme_font_size_override("font_size", 24)
	icon.custom_minimum_size = Vector2(36, 36)
	icon.vertical_alignment  = VERTICAL_ALIGNMENT_CENTER
	row.add_child(icon)

	var info = VBoxContainer.new()
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info.add_theme_constant_override("separation", 2)
	row.add_child(info)

	_lbl(info, "%s   💼 Найм: %s" % [et.name, gm.format_money(et.cost)], Color(0.88, 0.96, 0.88), 14)
	var net = et.income_bonus - et.salary_per_day
	_lbl(info,
		"ЗП: -%s/д   Бонус: +%s/д   Чистый вклад: +%s/д   %s" % [
			gm.format_money(et.salary_per_day), gm.format_money(et.income_bonus),
			gm.format_money(net), et.desc
		], Color(0.50, 0.68, 0.50), 11)

	var can_afford = gm.money >= et.cost
	var eid        = et.id
	var qty_box = HBoxContainer.new()
	qty_box.add_theme_constant_override("separation", 4)
	row.add_child(qty_box)

	for qty_label in ["1", "10", "100", "Макс"]:
		var hire_btn   = Button.new()
		hire_btn.text  = qty_label
		hire_btn.custom_minimum_size = Vector2(52, 30)
		hire_btn.add_theme_font_size_override("font_size", 12)
		if can_afford:
			hire_btn.add_theme_color_override("font_color", Color(0.65, 1.00, 0.65))
			_style_btn(hire_btn, Color(0.08, 0.20, 0.10), Color(0.25, 0.62, 0.30, 0.80))
			hire_btn.pressed.connect(func():
				var n = 1000000000 if qty_label == "Макс" else int(qty_label)
				var hired = bm.hire_employees(eid, n)
				if hired <= 0: _flash_toast("Нет мест или средств!")
				elif hired < n: _flash_toast("Нанято %d (не хватило мест/денег)" % hired)
			)
		else:
			hire_btn.add_theme_color_override("font_color", Color(0.35, 0.35, 0.42))
			_style_btn(hire_btn, Color(0.09, 0.09, 0.13), Color(0.22, 0.22, 0.30, 0.55))
			hire_btn.disabled = true
		qty_box.add_child(hire_btn)
	return card

# ══════════════════════════════════════════════════════════════════════════════
# Банк
# ══════════════════════════════════════════════════════════════════════════════
func _build_bank_tab() -> void:
	var vb = _vbox("Банк")
	for c in vb.get_children(): c.queue_free()

	var rate          = bm.get_tiered_rate()
	var interest_days = 30 - (gm.day % 30)
	var projected     = bm.bank_deposit * rate

	var bal_card = PanelContainer.new()
	var bcs = StyleBoxFlat.new()
	bcs.bg_color     = Color(0.05, 0.08, 0.18, 0.94)
	bcs.border_color = Color(0.22, 0.42, 0.88, 0.90)
	bcs.set_border_width_all(2)
	bcs.set_corner_radius_all(10)
	bcs.content_margin_left   = 20; bcs.content_margin_right  = 20
	bcs.content_margin_top    = 14; bcs.content_margin_bottom = 14
	bal_card.add_theme_stylebox_override("panel", bcs)
	vb.add_child(bal_card)

	var bal_row = HBoxContainer.new()
	bal_row.add_theme_constant_override("separation", 20)
	bal_card.add_child(bal_row)

	var left = VBoxContainer.new()
	left.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	left.add_theme_constant_override("separation", 5)
	bal_row.add_child(left)

	_lbl(left, "🏦 Банковский вклад", Color(0.55, 0.72, 0.98), 12)
	var dl = _lbl(left, gm.format_money(bm.bank_deposit), Color(1.00, 0.88, 0.25), 30)
	dl.add_theme_constant_override("outline_size", 2)
	dl.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.70))
	_lbl(left, "💰 Наличные: " + gm.format_money(gm.money), Color(0.62, 0.78, 0.62), 12)

	var right = VBoxContainer.new()
	right.add_theme_constant_override("separation", 5)
	right.custom_minimum_size = Vector2(270, 0)
	bal_row.add_child(right)

	var cb_node: Node = get_node_or_null("/root/CentralBankManager")
	var key_rate_pct: float = (cb_node.key_rate if cb_node else 0.16) * 100.0
	var infl_pct: float = (cb_node.inflation if cb_node else 0.08) * 100.0
	_lbl(right, "📊 Ваша ставка: %.2f%%/мес  (≈%.1f%%/год)" % [rate * 100.0, rate * 12.0 * 100.0], Color(0.72, 0.88, 0.98), 15)
	_lbl(right, "🏦 ЦБ: %.1f%%/год  |  📈 Инфл: %.1f%%/год" % [key_rate_pct, infl_pct], Color(0.52, 0.60, 0.82), 11)
	_lbl(right, "📅 До начисления: %d дн." % interest_days, Color(0.65, 0.82, 0.65), 12)
	if projected > 0:
		_lbl(right, "💰 Ожидается: +%s  |  ≈%s/год" % [gm.format_money(projected), gm.format_money(bm.bank_deposit * rate * 12.0)], Color(0.55, 0.90, 0.55), 12)
	var cb_base: float = (cb_node.get_deposit_rate() if cb_node else 0.0425)
	var next_lbl = ""
	if bm.bank_deposit < 100_000:
		next_lbl = "📈 +%s → ставка %.2f%%/мес" % [gm.format_money(100_000 - bm.bank_deposit), cb_base * 1.20 * 100.0]
	elif bm.bank_deposit < 1_000_000:
		next_lbl = "📈 +%s → ставка %.2f%%/мес" % [gm.format_money(1_000_000 - bm.bank_deposit), cb_base * 1.80 * 100.0]
	elif bm.bank_deposit < 10_000_000:
		next_lbl = "📈 +%s → ставка %.2f%%/мес" % [gm.format_money(10_000_000 - bm.bank_deposit), cb_base * 2.40 * 100.0]
	else:
		next_lbl = "✨ Максимальная ставка %.2f%%/мес!" % (cb_base * 2.40 * 100.0)
	_lbl(right, next_lbl, Color(0.88, 0.82, 0.45), 11)

	vb.add_child(_sep())

	# Внести
	_lbl(vb, "💳 Внести на вклад:", Color(0.65, 1.00, 0.65), 13)
	if gm.money > 100:
		var pct_row = HBoxContainer.new()
		pct_row.add_theme_constant_override("separation", 6)
		vb.add_child(pct_row)
		for pct in [25, 50, 75, 100]:
			# 100% — ровно все наличные; иначе округляем ВНИЗ, чтобы сумма
			# никогда не превышала наличные (иначе вылетает «недостаточно»)
			var amount = gm.money if pct == 100 else floorf(gm.money * pct / 100.0)
			var pbtn   = Button.new()
			pbtn.text  = "%d%%  (%s)" % [pct, gm.format_money(amount)]
			pbtn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			pbtn.custom_minimum_size   = Vector2(0, 32)
			pbtn.add_theme_font_size_override("font_size", 12)
			pbtn.add_theme_color_override("font_color", Color(0.65, 1.00, 0.65))
			_style_btn(pbtn, Color(0.07, 0.18, 0.10), Color(0.22, 0.55, 0.28, 0.80))
			var a = amount
			pbtn.pressed.connect(func(): if not bm.deposit(a): _flash_toast("Недостаточно наличных!"))
			pct_row.add_child(pbtn)

	var dep_row = HBoxContainer.new()
	dep_row.add_theme_constant_override("separation", 6)
	vb.add_child(dep_row)
	for amount in [10000.0, 50000.0, 100000.0, 500000.0, 1000000.0]:
		var can  = gm.money >= amount
		var dbtn = Button.new()
		dbtn.text = gm.format_money(amount)
		dbtn.custom_minimum_size = Vector2(110, 32)
		dbtn.add_theme_font_size_override("font_size", 12)
		if can:
			dbtn.add_theme_color_override("font_color", Color(0.65, 1.00, 0.65))
			_style_btn(dbtn, Color(0.07, 0.18, 0.10), Color(0.22, 0.55, 0.28, 0.80))
			var a = amount
			dbtn.pressed.connect(func(): if not bm.deposit(a): _flash_toast("Недостаточно наличных!"))
		else:
			dbtn.add_theme_color_override("font_color", Color(0.35, 0.35, 0.42))
			_style_btn(dbtn, Color(0.09, 0.09, 0.13), Color(0.22, 0.22, 0.30))
			dbtn.disabled = true
		dep_row.add_child(dbtn)

	vb.add_child(_sep())

	# Снять
	_lbl(vb, "💸 Снять со вклада:", Color(1.00, 0.85, 0.40), 13)
	var wit_row = HBoxContainer.new()
	wit_row.add_theme_constant_override("separation", 6)
	vb.add_child(wit_row)
	for amount in [10000.0, 50000.0, 100000.0, 500000.0, 1000000.0]:
		var can  = bm.bank_deposit >= amount
		var wbtn = Button.new()
		wbtn.text = gm.format_money(amount)
		wbtn.custom_minimum_size = Vector2(110, 32)
		wbtn.add_theme_font_size_override("font_size", 12)
		if can:
			wbtn.add_theme_color_override("font_color", Color(1.00, 0.82, 0.40))
			_style_btn(wbtn, Color(0.18, 0.14, 0.04), Color(0.55, 0.42, 0.10, 0.80))
			var a = amount
			wbtn.pressed.connect(func(): if not bm.withdraw(a): _flash_toast("На вкладе недостаточно!"))
		else:
			wbtn.add_theme_color_override("font_color", Color(0.35, 0.35, 0.42))
			_style_btn(wbtn, Color(0.09, 0.09, 0.13), Color(0.22, 0.22, 0.30))
			wbtn.disabled = true
		wit_row.add_child(wbtn)

	var dep_snap = bm.bank_deposit
	var all_btn  = Button.new()
	all_btn.text = "Снять всё (%s)" % gm.format_money(dep_snap)
	all_btn.custom_minimum_size   = Vector2(0, 34)
	all_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	all_btn.add_theme_font_size_override("font_size", 13)
	all_btn.add_theme_color_override("font_color", Color(1.00, 0.78, 0.30))
	_style_btn(all_btn, Color(0.20, 0.15, 0.04), Color(0.55, 0.42, 0.10, 0.80))
	all_btn.pressed.connect(func(): bm.withdraw(dep_snap))
	vb.add_child(all_btn)

# ══════════════════════════════════════════════════════════════════════════════
# Кредит
# ══════════════════════════════════════════════════════════════════════════════
func _build_loan_tab() -> void:
	var vb = _vbox("Кредит")
	for c in vb.get_children(): c.queue_free()

	var lm: Node = get_node_or_null("/root/LoanManager")
	if lm == null:
		_lbl(vb, "⚠ LoanManager не найден.", Color(1.0, 0.4, 0.4), 13)
		return

	var total_debt: float = lm.get_total_debt()
	var rl = _lbl(vb, "Кредитный рейтинг: %s" % lm.credit_rating, lm.rating_color(), 18)
	rl.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	if total_debt > 0:
		_lbl(vb,
			"💸 Общий долг: %s   •   /мес: %s" % [gm.format_money(total_debt), gm.format_money(lm.get_monthly_total())],
			Color(1.0, 0.50, 0.50), 13)
		_lbl(vb, "Активных кредитов: %d" % lm.active_loans.size(), Color(0.70, 0.70, 0.75), 12)
	else:
		_lbl(vb, "✅ Нет активных кредитов", Color(0.40, 1.0, 0.45), 13)

	if lm.is_banned(gm.day):
		_lbl(vb, "🚫 Банк заблокировал вас до дня %d" % lm.ban_until_day, Color(1.0, 0.35, 0.35), 13)

	vb.add_child(_sep())

	var desc = _lbl(vb,
		"Здесь можно взять кредит на любые нужды: от микрозайма до VIP-кредита.\nСтавки, шанс одобрения, последствия просрочек — всё в Кредитном центре.",
		Color(0.60, 0.62, 0.68), 12)
	desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART

	vb.add_child(_sep())

	var open_btn = Button.new()
	open_btn.text = "🏦 Открыть кредитный центр"
	open_btn.custom_minimum_size = Vector2(0, 48)
	open_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	open_btn.add_theme_font_size_override("font_size", 16)
	open_btn.add_theme_color_override("font_color", Color(1.0, 0.88, 0.25))
	_style_btn(open_btn, Color(0.12, 0.09, 0.02), Color(0.70, 0.50, 0.10, 0.90))
	open_btn.pressed.connect(func():
		visible = false
		var loan_ui: Node = get_tree().get_first_node_in_group("loan_ui")
		if loan_ui: loan_ui.open()
	)
	vb.add_child(open_btn)

# ══════════════════════════════════════════════════════════════════════════════
# Охрана
# ══════════════════════════════════════════════════════════════════════════════
func _build_security_tab() -> void:
	var vb = _vbox("Охрана")
	for c in vb.get_children(): c.queue_free()

	var biz = bm.get_business()
	if biz.is_empty():
		_lbl(vb, "⚠ Охрана доступна только при наличии бизнеса.",
			Color(1.0, 0.7, 0.3), 14).horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		return

	var sec_lvl = bm.security_level
	var sec     = bm.SECURITY_LEVELS[sec_lvl]

	# ── Статус-карточка ───────────────────────────────────────────────────────
	var stat_card = PanelContainer.new()
	var scs = StyleBoxFlat.new()
	var threat_col: Color
	if sec_lvl == 0:   threat_col = Color(0.75, 0.15, 0.15)
	elif sec_lvl <= 2: threat_col = Color(0.70, 0.45, 0.10)
	else:              threat_col = Color(0.12, 0.45, 0.18)
	scs.bg_color     = threat_col.darkened(0.72)
	scs.border_color = threat_col
	scs.set_border_width_all(2)
	scs.set_corner_radius_all(10)
	scs.content_margin_left   = 18; scs.content_margin_right  = 18
	scs.content_margin_top    = 12; scs.content_margin_bottom = 12
	stat_card.add_theme_stylebox_override("panel", scs)
	vb.add_child(stat_card)

	var stat_row = HBoxContainer.new()
	stat_row.add_theme_constant_override("separation", 16)
	stat_card.add_child(stat_row)

	var icon_lbl = Label.new()
	icon_lbl.text = sec.icon
	icon_lbl.add_theme_font_size_override("font_size", 42)
	icon_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	stat_row.add_child(icon_lbl)

	var stat_info = VBoxContainer.new()
	stat_info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	stat_info.add_theme_constant_override("separation", 5)
	stat_row.add_child(stat_info)

	var stars_str = ""
	for i in bm.SECURITY_LEVELS.size() - 1:
		stars_str += "🛡" if i < sec_lvl else "○"

	_lbl(stat_info, sec.icon + " " + sec.name + "   " + stars_str, Color(0.90, 0.96, 0.90), 18)
	_lbl(stat_info, sec.desc, Color(0.60, 0.78, 0.60), 12)

	var chance_pct = int(sec.event_chance * 100)
	var chance_col: Color
	if sec.event_chance >= 0.20:   chance_col = Color(1.0, 0.28, 0.28)
	elif sec.event_chance >= 0.10: chance_col = Color(1.0, 0.68, 0.22)
	elif sec.event_chance >= 0.04: chance_col = Color(0.88, 0.88, 0.28)
	else:                          chance_col = Color(0.38, 1.00, 0.48)

	var chance_row = HBoxContainer.new()
	chance_row.add_theme_constant_override("separation", 10)
	stat_info.add_child(chance_row)
	_lbl(chance_row, "⚡ Риск события: %d%% в день" % chance_pct, chance_col, 14)
	if sec.cost_per_day > 0:
		_lbl(chance_row, "  💸 Обслуживание: -%s/день" % gm.format_money(sec.cost_per_day),
			Color(0.65, 0.78, 0.65), 12)

	# ── Шкала угрозы ─────────────────────────────────────────────────────────
	var pb = ProgressBar.new()
	pb.custom_minimum_size = Vector2(0, 10)
	pb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	pb.max_value = 25.0
	pb.value     = sec.event_chance * 100.0
	pb.show_percentage = false
	var pfill = StyleBoxFlat.new()
	pfill.bg_color = chance_col
	pfill.set_corner_radius_all(5)
	var pbg = StyleBoxFlat.new()
	pbg.bg_color = Color(0.10, 0.10, 0.10)
	pbg.set_corner_radius_all(5)
	pb.add_theme_stylebox_override("fill", pfill)
	pb.add_theme_stylebox_override("background", pbg)
	stat_info.add_child(pb)

	vb.add_child(_sep())

	# ── Последнее событие ─────────────────────────────────────────────────────
	if not bm.last_event.is_empty():
		var ev_card = PanelContainer.new()
		var ecs = StyleBoxFlat.new()
		ecs.bg_color     = Color(0.14, 0.07, 0.04, 0.90)
		ecs.border_color = Color(0.75, 0.35, 0.10, 0.88)
		ecs.set_border_width_all(1)
		ecs.set_corner_radius_all(8)
		ecs.content_margin_left   = 12; ecs.content_margin_right  = 12
		ecs.content_margin_top    = 8;  ecs.content_margin_bottom = 8
		ev_card.add_theme_stylebox_override("panel", ecs)
		vb.add_child(ev_card)
		var ev_col = VBoxContainer.new()
		ev_col.add_theme_constant_override("separation", 4)
		ev_card.add_child(ev_col)
		_lbl(ev_col, "📜 Последнее происшествие:", Color(0.88, 0.60, 0.30), 11)
		var ev = bm.last_event
		_lbl(ev_col,
			"%s %s  —  %s  (-₽%s)" % [ev.icon, ev.name, ev.desc, gm.format_money(ev.loss)],
			Color(1.00, 0.72, 0.42), 13)
		vb.add_child(_sep())

	# ── Уровни охраны ─────────────────────────────────────────────────────────
	_lbl(vb, "🔐 Доступные уровни охраны:", Color(0.72, 0.92, 0.72), 13)

	for i in bm.SECURITY_LEVELS.size():
		var lvl = bm.SECURITY_LEVELS[i]
		var is_current = i == sec_lvl
		var is_past    = i < sec_lvl
		var is_next    = i == sec_lvl + 1

		var row_card = PanelContainer.new()
		var rcs = StyleBoxFlat.new()
		if is_current:
			rcs.bg_color     = Color(0.05, 0.14, 0.08, 0.92)
			rcs.border_color = Color(0.22, 0.72, 0.32, 0.90)
		elif is_past:
			rcs.bg_color     = Color(0.04, 0.06, 0.04, 0.50)
			rcs.border_color = Color(0.14, 0.22, 0.14, 0.40)
		elif is_next:
			rcs.bg_color     = Color(0.10, 0.10, 0.05, 0.85)
			rcs.border_color = Color(0.60, 0.52, 0.15, 0.88)
		else:
			rcs.bg_color     = Color(0.05, 0.05, 0.08, 0.55)
			rcs.border_color = Color(0.18, 0.18, 0.24, 0.40)
		rcs.set_border_width_all(2 if (is_current or is_next) else 1)
		rcs.set_corner_radius_all(8)
		rcs.content_margin_left   = 12; rcs.content_margin_right  = 12
		rcs.content_margin_top    = 8;  rcs.content_margin_bottom = 8
		row_card.add_theme_stylebox_override("panel", rcs)
		vb.add_child(row_card)

		var hr = HBoxContainer.new()
		hr.add_theme_constant_override("separation", 12)
		row_card.add_child(hr)

		var lvl_icon = Label.new()
		lvl_icon.text = lvl.icon
		lvl_icon.add_theme_font_size_override("font_size", 26)
		lvl_icon.custom_minimum_size = Vector2(40, 40)
		lvl_icon.vertical_alignment  = VERTICAL_ALIGNMENT_CENTER
		lvl_icon.modulate.a = 0.35 if is_past else 1.0
		hr.add_child(lvl_icon)

		var li = VBoxContainer.new()
		li.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		li.add_theme_constant_override("separation", 3)
		hr.add_child(li)

		var nc: Color
		if is_current: nc = Color(0.65, 1.00, 0.65)
		elif is_past:  nc = Color(0.28, 0.35, 0.28)
		elif is_next:  nc = Color(1.00, 0.92, 0.45)
		else:          nc = Color(0.42, 0.45, 0.50)
		_lbl(li, "Ур.%d — %s" % [i, lvl.name], nc, 14)

		var ev_pct2: int = int(lvl.event_chance * 100)
		var ev_c2: Color
		if lvl.event_chance >= 0.20: ev_c2 = Color(1.0, 0.35, 0.35)
		elif lvl.event_chance >= 0.10: ev_c2 = Color(1.0, 0.68, 0.22)
		elif lvl.event_chance >= 0.04: ev_c2 = Color(0.88, 0.88, 0.28)
		else: ev_c2 = Color(0.38, 1.00, 0.48)
		var risk_col: Color = Color(0.28, 0.35, 0.28) if is_past else ev_c2
		_lbl(li, "%s  Риск: %d%%/день   💸 -%s/день" % [
			lvl.desc,
			ev_pct2,
			gm.format_money(lvl.cost_per_day) if lvl.cost_per_day > 0 else "бесплатно"
		], risk_col, 11).autowrap_mode = TextServer.AUTOWRAP_WORD

		var rv2 = VBoxContainer.new()
		rv2.alignment = BoxContainer.ALIGNMENT_CENTER
		rv2.add_theme_constant_override("separation", 4)
		hr.add_child(rv2)

		if is_current:
			var cur_badge = Label.new()
			cur_badge.text = "✅ Активно"
			cur_badge.add_theme_font_size_override("font_size", 12)
			cur_badge.add_theme_color_override("font_color", Color(0.45, 1.00, 0.55))
			cur_badge.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			rv2.add_child(cur_badge)
		elif is_past:
			var done_lbl = Label.new()
			done_lbl.text = "↩ Пройдено"
			done_lbl.add_theme_font_size_override("font_size", 12)
			done_lbl.add_theme_color_override("font_color", Color(0.28, 0.35, 0.28))
			done_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			rv2.add_child(done_lbl)
		elif is_next:
			var cost_l = Label.new()
			cost_l.text = gm.format_money(lvl.install_cost)
			cost_l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			cost_l.add_theme_font_size_override("font_size", 13)
			cost_l.add_theme_color_override("font_color", Color(1.00, 0.88, 0.25))
			rv2.add_child(cost_l)
			var can_buy = gm.money >= lvl.install_cost
			var upg_btn2 = Button.new()
			upg_btn2.text = "⬆ Улучшить"
			upg_btn2.custom_minimum_size = Vector2(130, 34)
			upg_btn2.add_theme_font_size_override("font_size", 13)
			if can_buy:
				upg_btn2.add_theme_color_override("font_color", Color(0.70, 1.00, 0.70))
				_style_btn(upg_btn2, Color(0.08, 0.22, 0.10), Color(0.25, 0.65, 0.28, 0.88))
				upg_btn2.pressed.connect(func():
					if not bm.upgrade_security():
						_flash_toast("Недостаточно денег!")
				)
			else:
				upg_btn2.add_theme_color_override("font_color", Color(0.35, 0.35, 0.42))
				_style_btn(upg_btn2, Color(0.09, 0.09, 0.13), Color(0.26, 0.26, 0.36))
				upg_btn2.disabled = true
			rv2.add_child(upg_btn2)
		else:
			var locked_lbl = Label.new()
			locked_lbl.text = "🔒 Недоступно"
			locked_lbl.add_theme_font_size_override("font_size", 12)
			locked_lbl.add_theme_color_override("font_color", Color(0.30, 0.30, 0.38))
			locked_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			rv2.add_child(locked_lbl)

func _on_security_event(event: Dictionary) -> void:
	_flash_toast("%s %s! Потеря: %s" % [event.icon, event.name, gm.format_money(event.loss)])
	if visible: _refresh()

# ══════════════════════════════════════════════════════════════════════════════
# Утилиты
# ══════════════════════════════════════════════════════════════════════════════
func _lbl(parent: Node, text: String, col: Color, font_size: int = 12) -> Label:
	var l = Label.new()
	l.text = text
	l.add_theme_color_override("font_color", col)
	l.add_theme_font_size_override("font_size", font_size)
	parent.add_child(l)
	return l

func _info_card(rows: Array, bg: Color, border: Color) -> PanelContainer:
	var card = PanelContainer.new()
	var cs   = StyleBoxFlat.new()
	cs.bg_color     = bg
	cs.border_color = border
	cs.set_border_width_all(1)
	cs.set_corner_radius_all(8)
	cs.content_margin_left   = 14; cs.content_margin_right  = 14
	cs.content_margin_top    = 10; cs.content_margin_bottom = 10
	card.add_theme_stylebox_override("panel", cs)
	var col = VBoxContainer.new()
	col.add_theme_constant_override("separation", 5)
	card.add_child(col)
	for row in rows:
		var hr = HBoxContainer.new()
		hr.add_theme_constant_override("separation", 6)
		col.add_child(hr)
		_lbl(hr, row[0], Color(0.65, 0.72, 0.65), 12)
		_lbl(hr, row[1], Color(0.90, 0.92, 0.90), 12)
	return card

func _sep() -> ColorRect:
	var sep = ColorRect.new()
	sep.color = Color(0.22, 0.22, 0.35, 0.45)
	sep.custom_minimum_size = Vector2(0, 1)
	return sep

func _style_btn(btn: Button, bg: Color, border: Color) -> void:
	var sn = StyleBoxFlat.new()
	sn.bg_color     = bg
	sn.border_color = border
	for s in [SIDE_LEFT, SIDE_RIGHT, SIDE_TOP, SIDE_BOTTOM]:
		sn.set_border_width(s, 1)
		sn.set_corner_radius(s, 5)
	btn.add_theme_stylebox_override("normal", sn)
	var sh = sn.duplicate() as StyleBoxFlat
	sh.bg_color = bg.lightened(0.12)
	btn.add_theme_stylebox_override("hover", sh)

func _flash_toast(msg: String) -> void:
	_toast_lbl.text    = "⚠ " + msg
	_toast_lbl.visible = true
	if _toast_tween and _toast_tween.is_valid():
		_toast_tween.kill()
	_toast_tween = create_tween()
	_toast_tween.tween_interval(2.5)
	_toast_tween.tween_callback(func(): _toast_lbl.visible = false)
