extends CanvasLayer

var _lm: Node
var _gm: Node
var _panel: Panel

# Вкладки
var _tab_offers: Control
var _tab_active: Control
var _tab_history: Control
var _tab_btns: Array = []

# Конфигуратор
var _cfg_panel: PanelContainer = null
var _cfg_type_idx: int = -1
var _cfg_amount_slider: HSlider = null
var _cfg_months_slider: HSlider = null
var _cfg_summary_box: VBoxContainer = null
var _cfg_amount_val: Label = null
var _cfg_months_val: Label = null

# Перетаскивание окна конфигуратора за заголовок
var _cfg_dragging: bool = false
var _cfg_drag_offset: Vector2 = Vector2.ZERO

# Инфо-строка (прямые ссылки чтобы не зависеть от auto-именования узлов)
var _rating_lbl_ref: Label = null
var _debt_lbl_ref: Label = null

func _ready() -> void:
	layer = 10
	visible = false
	add_to_group("loan_ui")
	_lm = get_node("/root/LoanManager")
	_gm = get_node("/root/GameManager")
	_lm.loans_changed.connect(_refresh_active)
	_build_ui()

# ── Построение UI ────────────────────────────────────────────────────────────

func _build_ui() -> void:
	var dimmer := ColorRect.new()
	dimmer.set_anchors_preset(Control.PRESET_FULL_RECT)
	dimmer.color = Color(0, 0, 0, 0.78)
	dimmer.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(dimmer)

	_panel = Panel.new()
	_panel.set_anchors_preset(Control.PRESET_CENTER)
	_panel.size = Vector2(640, 560)
	_panel.position = Vector2(-320, -280)
	var ps := StyleBoxFlat.new()
	ps.bg_color = UITheme.PANEL
	ps.border_color = UITheme.GOLD_DIM
	for s in [SIDE_LEFT, SIDE_RIGHT, SIDE_TOP, SIDE_BOTTOM]:
		ps.set_border_width(s, 2)
		ps.set_corner_radius(s, 10)
	_panel.add_theme_stylebox_override("panel", ps)
	add_child(_panel)

	var root := VBoxContainer.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.add_theme_constant_override("separation", 6)
	_panel.add_child(root)

	# Заголовок
	var hdr := HBoxContainer.new()
	root.add_child(hdr)
	var title := Label.new()
	title.text = "🏦 Кредитный центр"
	title.add_theme_font_size_override("font_size", 22)
	title.add_theme_color_override("font_color", Color(1.0, 0.88, 0.25))
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hdr.add_child(title)
	var close_btn := Button.new()
	close_btn.text = "✕"
	close_btn.custom_minimum_size = Vector2(34, 34)
	close_btn.add_theme_font_size_override("font_size", 14)
	_style_close(close_btn)
	close_btn.pressed.connect(func(): visible = false; _close_cfg())
	hdr.add_child(close_btn)

	# Рейтинг + долг
	var info_row := HBoxContainer.new()
	info_row.add_theme_constant_override("separation", 16)
	root.add_child(info_row)
	var rating_lbl := Label.new()
	rating_lbl.add_theme_font_size_override("font_size", 13)
	info_row.add_child(rating_lbl)
	_rating_lbl_ref = rating_lbl
	var debt_lbl := Label.new()
	debt_lbl.add_theme_font_size_override("font_size", 13)
	debt_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info_row.add_child(debt_lbl)
	_debt_lbl_ref = debt_lbl

	# Вкладки
	var tabs_row := HBoxContainer.new()
	tabs_row.add_theme_constant_override("separation", 4)
	root.add_child(tabs_row)
	var tab_names := ["📋 Кредиты", "💳 Активные", "📜 История"]
	for i in tab_names.size():
		var tb := Button.new()
		tb.text = tab_names[i]
		tb.custom_minimum_size = Vector2(0, 30)
		tb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		tb.add_theme_font_size_override("font_size", 12)
		var ti := i
		tb.pressed.connect(func(): _switch_tab(ti))
		tabs_row.add_child(tb)
		_tab_btns.append(tb)

	root.add_child(HSeparator.new())

	# Страницы
	var pages := Control.new()
	pages.size_flags_vertical = Control.SIZE_EXPAND_FILL
	pages.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	root.add_child(pages)

	_tab_offers  = _build_offers_page()
	_tab_active  = _build_active_page()
	_tab_history = _build_history_page()
	for pg in [_tab_offers, _tab_active, _tab_history]:
		pg.set_anchors_preset(Control.PRESET_FULL_RECT)
		pages.add_child(pg)

	_switch_tab(0)

func _style_close(btn: Button) -> void:
	var cs := StyleBoxFlat.new()
	cs.bg_color = Color(0.22, 0.07, 0.07, 0.90)
	cs.border_color = Color(0.55, 0.18, 0.18, 0.80)
	for s in [SIDE_LEFT, SIDE_RIGHT, SIDE_TOP, SIDE_BOTTOM]:
		cs.set_border_width(s, 1)
		cs.set_corner_radius(s, 6)
	btn.add_theme_stylebox_override("normal", cs)
	btn.add_theme_color_override("font_color", Color.WHITE)

func _switch_tab(idx: int) -> void:
	_tab_offers.visible  = idx == 0
	_tab_active.visible  = idx == 1
	_tab_history.visible = idx == 2
	for i in _tab_btns.size():
		var active := i == idx
		var tb: Button = _tab_btns[i]
		var bs := StyleBoxFlat.new()
		bs.bg_color = Color(0.14, 0.10, 0.04) if active else Color(0.07, 0.07, 0.11)
		bs.border_color = Color(0.80, 0.55, 0.15) if active else Color(0.22, 0.22, 0.30)
		for s in [SIDE_LEFT, SIDE_RIGHT, SIDE_TOP, SIDE_BOTTOM]:
			bs.set_border_width(s, 2 if active else 1)
			bs.set_corner_radius(s, 5)
		tb.add_theme_stylebox_override("normal", bs)
		tb.add_theme_color_override("font_color",
			Color(1.0, 0.85, 0.30) if active else Color(0.65, 0.65, 0.70))

# ── Страница кредитных предложений ───────────────────────────────────────────

func _build_offers_page() -> Control:
	var sc := ScrollContainer.new()
	sc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	var vb := VBoxContainer.new()
	vb.name = "OffersVBox"
	vb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vb.add_theme_constant_override("separation", 6)
	sc.add_child(vb)
	return sc

func _rebuild_offers() -> void:
	var vb: VBoxContainer = _tab_offers.get_node("OffersVBox")
	for c in vb.get_children(): c.queue_free()

	if _lm.is_banned(_gm.day):
		var ban_lbl := Label.new()
		ban_lbl.text = "🚫 Банк заблокировал вас до дня %d\nИз-за систематических просрочек." % _lm.ban_until_day
		ban_lbl.add_theme_font_size_override("font_size", 14)
		ban_lbl.add_theme_color_override("font_color", Color(1.0, 0.35, 0.35))
		ban_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		vb.add_child(ban_lbl)
		return

	var bm: Node = get_node_or_null("/root/BusinessManager")
	var has_business: bool = bm != null and bm.owned_business_id != ""
	var rm: Node = get_node_or_null("/root/ReputationManager")
	var rep: int = rm.reputation if rm else 0
	var housing_tier: int = _gm.HOUSINGS[_gm.current_housing_index].get("tier", 0) as int

	for i in _lm.LOAN_TYPES.size():
		var lt: Dictionary = _lm.LOAN_TYPES[i]
		var daily_income: float = _gm.get_monthly_income() / 30.0
		var income_ok: bool = daily_income * 30.0 >= lt.income_req
		var biz_ok: bool = (not lt.need_business) or has_business
		var rep_ok: bool = rep >= lt.rep_req
		var tier_ok: bool = housing_tier >= lt.get("housing_tier_req", 0)
		var unlocked: bool = income_ok and biz_ok and rep_ok and tier_ok

		var card := PanelContainer.new()
		var cs := StyleBoxFlat.new()
		var col: Color = lt.color
		cs.bg_color = Color(col.r * 0.12, col.g * 0.12, col.b * 0.12, 0.90) if unlocked \
			else Color(0.06, 0.06, 0.09, 0.70)
		cs.border_color = col if unlocked else Color(0.20, 0.20, 0.28)
		for s in [SIDE_LEFT, SIDE_RIGHT, SIDE_TOP, SIDE_BOTTOM]:
			cs.set_border_width(s, 2 if unlocked else 1)
			cs.set_corner_radius(s, 7)
		cs.content_margin_left = 10; cs.content_margin_right = 10
		cs.content_margin_top = 8; cs.content_margin_bottom = 8
		card.add_theme_stylebox_override("panel", cs)
		vb.add_child(card)

		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 10)
		card.add_child(row)

		var info := VBoxContainer.new()
		info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(info)

		var name_lbl := Label.new()
		name_lbl.text = lt.name
		name_lbl.add_theme_font_size_override("font_size", 15)
		name_lbl.add_theme_color_override("font_color",
			col.lerp(Color.WHITE, 0.3) if unlocked else Color(0.38, 0.38, 0.42))
		info.add_child(name_lbl)

		var range_lbl := Label.new()
		range_lbl.text = "%s — %s  •  %.0f%% в мес  •  %d–%d мес" % [
			_gm.format_money(lt.min), _gm.format_money(lt.max),
			lt.rate * 100.0, lt.min_months, lt.max_months
		]
		range_lbl.add_theme_font_size_override("font_size", 11)
		range_lbl.add_theme_color_override("font_color",
			Color(0.65, 0.65, 0.70) if unlocked else Color(0.30, 0.30, 0.33))
		info.add_child(range_lbl)

		# Превью минимального платежа
		if unlocked:
			var min_monthly: float = _lm._calc_monthly(lt.min, lt.rate, lt.max_months)
			var max_monthly: float = _lm._calc_monthly(lt.max, lt.rate, lt.min_months)
			var monthly_income: float = _gm.get_monthly_income()
			var preview_lbl := Label.new()
			preview_lbl.text = "💳 от %s/мес  (мин.сумма, макс.срок)" % _gm.format_money(min_monthly)
			preview_lbl.add_theme_font_size_override("font_size", 10)
			var load_ratio: float = max_monthly / maxf(monthly_income, 1.0)
			var prev_col := Color(0.45, 0.90, 0.55) if load_ratio < 0.4 else \
						   (Color(1.0, 0.80, 0.25) if load_ratio < 0.7 else Color(1.0, 0.40, 0.35))
			preview_lbl.add_theme_color_override("font_color", prev_col)
			info.add_child(preview_lbl)

		if not unlocked:
			var req_parts: Array = []
			if not income_ok:
				req_parts.append("доход ≥ %s/мес" % _gm.format_money(lt.income_req * 30.0))
			if not biz_ok:
				req_parts.append("нужен бизнес")
			if not rep_ok:
				req_parts.append("репутация ≥ %d" % lt.rep_req)
			if not tier_ok:
				req_parts.append("жильё ≥ Общага")
			var req_lbl := Label.new()
			req_lbl.text = "🔒 " + ", ".join(req_parts)
			req_lbl.add_theme_font_size_override("font_size", 10)
			req_lbl.add_theme_color_override("font_color", Color(0.80, 0.45, 0.20))
			info.add_child(req_lbl)

		# Кулдаун по категории после отказа
		var reject_until: int = _lm.rejection_cooldowns.get(lt.id, 0) as int
		var on_cooldown: bool = reject_until > _gm.day

		if on_cooldown and unlocked:
			var cd_lbl := Label.new()
			cd_lbl.text = "🚫 Повторная заявка с дня %d" % reject_until
			cd_lbl.add_theme_font_size_override("font_size", 10)
			cd_lbl.add_theme_color_override("font_color", Color(1.0, 0.40, 0.30))
			info.add_child(cd_lbl)

		var btn := Button.new()
		var btn_blocked: bool = not unlocked or on_cooldown
		if on_cooldown and unlocked:
			btn.text = "⏳ Отказ до дня %d" % reject_until
		else:
			btn.text = "Настроить"
		btn.custom_minimum_size = Vector2(100, 36)
		btn.add_theme_font_size_override("font_size", 12)
		btn.disabled = btn_blocked
		var bst := StyleBoxFlat.new()
		if not btn_blocked:
			bst.bg_color = Color(col.r * 0.22, col.g * 0.22, col.b * 0.22)
			bst.border_color = col
			btn.add_theme_color_override("font_color", col.lerp(Color.WHITE, 0.4))
		elif on_cooldown:
			bst.bg_color = Color(0.18, 0.07, 0.05)
			bst.border_color = Color(0.55, 0.20, 0.15)
			btn.add_theme_color_override("font_color", Color(0.70, 0.35, 0.30))
		else:
			bst.bg_color = Color(0.09, 0.09, 0.12)
			bst.border_color = Color(0.20, 0.20, 0.26)
			btn.add_theme_color_override("font_color", Color(0.30, 0.30, 0.33))
		for s in [SIDE_LEFT, SIDE_RIGHT, SIDE_TOP, SIDE_BOTTOM]:
			bst.set_border_width(s, 1)
			bst.set_corner_radius(s, 5)
		btn.add_theme_stylebox_override("normal", bst)
		if not btn_blocked:
			var ti: int = i
			btn.pressed.connect(func(): _open_configurator(ti))
		row.add_child(btn)

# ── Конфигуратор кредита ─────────────────────────────────────────────────────

func _open_configurator(type_idx: int) -> void:
	_close_cfg()
	_cfg_type_idx = type_idx
	var lt: Dictionary = _lm.LOAN_TYPES[type_idx]
	var col: Color = lt.color

	_cfg_panel = PanelContainer.new()
	_cfg_panel.set_anchors_preset(Control.PRESET_TOP_LEFT)
	_cfg_panel.custom_minimum_size = Vector2(460, 0)
	_cfg_panel.z_index = 20
	var cps := StyleBoxFlat.new()
	cps.bg_color = Color(0.05, 0.05, 0.10, 0.98)
	cps.border_color = col
	for s in [SIDE_LEFT, SIDE_RIGHT, SIDE_TOP, SIDE_BOTTOM]:
		cps.set_border_width(s, 2)
		cps.set_corner_radius(s, 10)
	cps.content_margin_left = 16; cps.content_margin_right = 16
	cps.content_margin_top = 14; cps.content_margin_bottom = 14
	_cfg_panel.add_theme_stylebox_override("panel", cps)
	add_child(_cfg_panel)

	var outer_vb := VBoxContainer.new()
	outer_vb.add_theme_constant_override("separation", 6)
	_cfg_panel.add_child(outer_vb)

	# Заголовок вне скролла чтобы всегда был виден; перетаскивание окна за заголовок
	var hdr_wrap := VBoxContainer.new()
	hdr_wrap.mouse_filter = Control.MOUSE_FILTER_PASS
	hdr_wrap.gui_input.connect(_on_cfg_header_input)
	outer_vb.add_child(hdr_wrap)

	# Скролл для основного содержимого
	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(0, 420)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	outer_vb.add_child(scroll)

	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 10)
	vb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(vb)

	# Кнопки всегда внизу
	var btn_wrap := VBoxContainer.new()
	outer_vb.add_child(btn_wrap)

	var hdr := HBoxContainer.new()
	hdr_wrap.add_child(hdr)
	var tl := Label.new()
	tl.text = lt.name
	tl.add_theme_font_size_override("font_size", 18)
	tl.add_theme_color_override("font_color", col.lerp(Color.WHITE, 0.3))
	tl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hdr.add_child(tl)
	var xbtn := Button.new()
	xbtn.text = "✕"
	xbtn.custom_minimum_size = Vector2(28, 28)
	_style_close(xbtn)
	xbtn.pressed.connect(_close_cfg)
	hdr.add_child(xbtn)

	vb.add_child(HSeparator.new())

	# Слайдер суммы
	var amount_row := VBoxContainer.new()
	vb.add_child(amount_row)
	var amount_hdr := HBoxContainer.new()
	amount_row.add_child(amount_hdr)
	var al := Label.new()
	al.text = "Сумма:"
	al.add_theme_font_size_override("font_size", 13)
	al.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	amount_hdr.add_child(al)
	var amount_val := Label.new()
	amount_val.name = "AmountVal"
	amount_val.add_theme_font_size_override("font_size", 14)
	amount_val.add_theme_color_override("font_color", col.lerp(Color.WHITE, 0.3))
	amount_hdr.add_child(amount_val)

	var amount_slider := HSlider.new()
	amount_slider.min_value = lt.min
	amount_slider.max_value = lt.max
	amount_slider.step = maxf(lt.min, 1000.0)
	amount_slider.value = (lt.min + lt.max) / 2.0
	amount_slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	amount_row.add_child(amount_slider)
	_cfg_amount_slider = amount_slider
	_cfg_amount_val = amount_val

	# Слайдер срока
	var months_row := VBoxContainer.new()
	vb.add_child(months_row)
	var months_hdr := HBoxContainer.new()
	months_row.add_child(months_hdr)
	var ml := Label.new()
	ml.text = "Срок:"
	ml.add_theme_font_size_override("font_size", 13)
	ml.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	months_hdr.add_child(ml)
	var months_val := Label.new()
	months_val.name = "MonthsVal"
	months_val.add_theme_font_size_override("font_size", 14)
	months_val.add_theme_color_override("font_color", col.lerp(Color.WHITE, 0.3))
	months_hdr.add_child(months_val)

	var months_slider := HSlider.new()
	months_slider.min_value = lt.min_months
	months_slider.max_value = lt.max_months
	months_slider.step = 1
	months_slider.value = float(lt.min_months + lt.max_months) / 2.0
	months_slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	months_row.add_child(months_slider)
	_cfg_months_slider = months_slider
	_cfg_months_val = months_val

	vb.add_child(HSeparator.new())

	# Итоги
	var summary_box := VBoxContainer.new()
	summary_box.add_theme_constant_override("separation", 4)
	vb.add_child(summary_box)
	_cfg_summary_box = summary_box

	# Кнопки (в btn_wrap, вне скролла — всегда внизу)
	btn_wrap.add_child(HSeparator.new())
	var btn_row := HBoxContainer.new()
	btn_row.add_theme_constant_override("separation", 8)
	btn_wrap.add_child(btn_row)

	var cancel_btn := Button.new()
	cancel_btn.text = "✕ Отмена"
	cancel_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	cancel_btn.custom_minimum_size = Vector2(0, 36)
	cancel_btn.pressed.connect(_close_cfg)
	btn_row.add_child(cancel_btn)

	var take_btn := Button.new()
	take_btn.name = "TakeBtn"
	take_btn.text = "✓ Взять кредит"
	take_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	take_btn.custom_minimum_size = Vector2(0, 36)
	var tbs := StyleBoxFlat.new()
	tbs.bg_color = Color(col.r * 0.25, col.g * 0.25, col.b * 0.25)
	tbs.border_color = col
	for s in [SIDE_LEFT, SIDE_RIGHT, SIDE_TOP, SIDE_BOTTOM]:
		tbs.set_border_width(s, 1)
		tbs.set_corner_radius(s, 6)
	take_btn.add_theme_stylebox_override("normal", tbs)
	take_btn.add_theme_color_override("font_color", col.lerp(Color.WHITE, 0.4))
	take_btn.pressed.connect(_do_take_loan)
	btn_row.add_child(take_btn)

	# Подключаем слайдеры
	amount_slider.value_changed.connect(func(_v): _update_cfg_summary())
	months_slider.value_changed.connect(func(_v): _update_cfg_summary())
	_update_cfg_summary()

	# Центрируем окно по экрану — размер становится известен только после
	# раскладки контейнеров, поэтому ждём один кадр перед позиционированием
	call_deferred("_center_cfg_panel")

func _center_cfg_panel() -> void:
	if _cfg_panel == null or not is_instance_valid(_cfg_panel):
		return
	var vp_size: Vector2 = get_viewport().get_visible_rect().size
	_cfg_panel.position = ((vp_size - _cfg_panel.size) * 0.5).round()

func _on_cfg_header_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			_cfg_dragging = true
			_cfg_drag_offset = _cfg_panel.position - get_viewport().get_mouse_position()
		else:
			_cfg_dragging = false
	elif event is InputEventMouseMotion and _cfg_dragging:
		var vp_size: Vector2 = get_viewport().get_visible_rect().size
		var new_pos: Vector2 = get_viewport().get_mouse_position() + _cfg_drag_offset
		new_pos.x = clampf(new_pos.x, 0.0, maxf(0.0, vp_size.x - _cfg_panel.size.x))
		new_pos.y = clampf(new_pos.y, 0.0, maxf(0.0, vp_size.y - _cfg_panel.size.y))
		_cfg_panel.position = new_pos

func _update_cfg_summary() -> void:
	if _cfg_panel == null or not is_instance_valid(_cfg_panel):
		return
	if not _cfg_amount_slider or not _cfg_months_slider:
		return
	var lt: Dictionary = _lm.LOAN_TYPES[_cfg_type_idx]

	var amount: float = _cfg_amount_slider.value
	var months: int = int(_cfg_months_slider.value)

	if _cfg_amount_val: _cfg_amount_val.text = _gm.format_money(amount)
	if _cfg_months_val: _cfg_months_val.text = "%d мес." % months

	var monthly: float    = _lm._calc_monthly(amount, lt.rate, months)
	var total: float      = _lm.calc_total(amount, lt.rate, months)
	var overpay: float    = _lm.calc_overpay(amount, lt.rate, months)
	var overpay_pct: float = overpay / maxf(amount, 1.0) * 100.0
	var chance: float     = _lm.approval_chance(_cfg_type_idx, amount, months)
	var end_day: int      = _gm.day + months * 30
	var monthly_income: float = _gm.get_monthly_income()
	var existing_monthly: float = _lm.get_monthly_total()
	var total_monthly: float  = existing_monthly + monthly
	var load_pct: float = total_monthly / maxf(monthly_income, 1.0) * 100.0

	var sb: VBoxContainer = _cfg_summary_box
	if not sb or not is_instance_valid(sb): return
	for c in sb.get_children(): c.queue_free()

	# ── Основные параметры ────────────────────────────────────────────────────
	var eff_rate: float = _lm.get_effective_rate(lt.rate)
	var rate_str: String = "%.2f%% / мес" % (eff_rate * 100.0)
	if eff_rate > lt.rate + 0.001:
		rate_str += "  (ЦБ: %.2f%%)" % (lt.rate * 100.0)
	_cfg_add_row(sb, "Ставка:", rate_str,
		Color(0.65, 0.65, 0.70), Color(0.92, 0.92, 0.95))
	_cfg_add_row(sb, "Ежемес. платёж:", _gm.format_money(monthly),
		Color(0.65, 0.65, 0.70), Color(1.0, 0.88, 0.30))
	_cfg_add_row(sb, "Итого выплат:", _gm.format_money(total),
		Color(0.65, 0.65, 0.70), Color(0.92, 0.92, 0.95))
	_cfg_add_row(sb, "Переплата:",
		"%s (%.0f%%)" % [_gm.format_money(overpay), overpay_pct],
		Color(0.65, 0.65, 0.70),
		Color(1.0, 0.50, 0.40) if overpay_pct > 50.0 else Color(1.0, 0.75, 0.35))
	_cfg_add_row(sb, "Выплачивать до:", "дня %d (~%d мес.)" % [end_day, months],
		Color(0.65, 0.65, 0.70), Color(0.75, 0.85, 1.0))

	sb.add_child(_cfg_sep())

	# ── Нагрузка на доход ─────────────────────────────────────────────────────
	var load_col: Color
	var load_icon: String
	if load_pct < 30.0:
		load_col = Color(0.35, 1.0, 0.45); load_icon = "✅"
	elif load_pct < 50.0:
		load_col = Color(1.0, 0.85, 0.20); load_icon = "⚠"
	elif load_pct < 75.0:
		load_col = Color(1.0, 0.55, 0.20); load_icon = "🔴"
	else:
		load_col = Color(1.0, 0.25, 0.25); load_icon = "🚨"

	_cfg_add_row(sb, "Нагрузка на доход:",
		"%s %.0f%% от дохода" % [load_icon, load_pct],
		Color(0.65, 0.65, 0.70), load_col)

	if existing_monthly > 0:
		_cfg_add_row(sb, "  Текущие платежи:", _gm.format_money(existing_monthly) + "/мес",
			Color(0.50, 0.50, 0.58), Color(0.80, 0.60, 0.60))
		_cfg_add_row(sb, "  После взятия:", _gm.format_money(total_monthly) + "/мес",
			Color(0.50, 0.50, 0.58), load_col)

	# ── Блок последствий ──────────────────────────────────────────────────────
	var warnings: Array = []
	if load_pct >= 75.0:
		warnings.append(["🚨 Критическая нагрузка! Высок риск просрочки и штрафов.", Color(1.0, 0.22, 0.22)])
	elif load_pct >= 50.0:
		warnings.append(["⚠ Высокая нагрузка. Любой финансовый сбой = просрочка.", Color(1.0, 0.60, 0.20)])
	if overpay_pct > 100.0:
		warnings.append(["💸 Переплата больше суммы кредита — пересмотри срок.", Color(1.0, 0.55, 0.20)])
	if load_pct >= 50.0:
		warnings.append(["❗ Просрочка: долг +20%, репутация −5. Коллекторы: −15 реп.", Color(0.80, 0.45, 0.45)])

	if not warnings.is_empty():
		sb.add_child(_cfg_sep())
		for w in warnings:
			var wl := Label.new()
			wl.text = w[0]
			wl.add_theme_font_size_override("font_size", 11)
			wl.add_theme_color_override("font_color", w[1])
			wl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			sb.add_child(wl)

	sb.add_child(_cfg_sep())

	# ── Шанс одобрения ────────────────────────────────────────────────────────
	var chance_row := HBoxContainer.new()
	sb.add_child(chance_row)
	var cl := Label.new()
	cl.text = "📊 Шанс одобрения:"
	cl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	cl.add_theme_font_size_override("font_size", 13)
	cl.add_theme_color_override("font_color", Color(0.70, 0.70, 0.75))
	chance_row.add_child(cl)
	var cv := Label.new()
	cv.text = "%.0f%%" % (chance * 100.0)
	cv.add_theme_font_size_override("font_size", 14)
	var cc := Color(0.3, 1.0, 0.4) if chance > 0.7 else \
			  (Color(1.0, 0.85, 0.2) if chance > 0.4 else Color(1.0, 0.35, 0.35))
	cv.add_theme_color_override("font_color", cc)
	chance_row.add_child(cv)

	# Подсказки почему шанс низкий
	if chance < 0.6:
		var hints: Array = _get_approval_hints(_cfg_type_idx, amount, months)
		for h in hints:
			var hl := Label.new()
			hl.text = "  • " + h
			hl.add_theme_font_size_override("font_size", 10)
			hl.add_theme_color_override("font_color", Color(0.75, 0.60, 0.35))
			sb.add_child(hl)

func _cfg_add_row(parent: VBoxContainer, label: String, value: String, lc: Color, vc: Color) -> void:
	var row := HBoxContainer.new()
	parent.add_child(row)
	var rl := Label.new()
	rl.text = label
	rl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	rl.add_theme_font_size_override("font_size", 12)
	rl.add_theme_color_override("font_color", lc)
	row.add_child(rl)
	var rv := Label.new()
	rv.text = value
	rv.add_theme_font_size_override("font_size", 12)
	rv.add_theme_color_override("font_color", vc)
	row.add_child(rv)

func _cfg_sep() -> ColorRect:
	var sep := ColorRect.new()
	sep.color = Color(0.22, 0.22, 0.35, 0.40)
	sep.custom_minimum_size = Vector2(0, 1)
	return sep

func _get_approval_hints(type_idx: int, amount: float, months: int) -> Array:
	var hints: Array = []
	var lt: Dictionary = _lm.LOAN_TYPES[type_idx]
	var monthly_income: float = _gm.get_monthly_income()
	var monthly_payment: float = _lm._calc_monthly(amount, lt.rate, months)
	if monthly_income < monthly_payment * 2.0:
		hints.append("Доход мал для такого платежа")
	var debt_ratio: float = _lm.get_total_debt() / maxf(_gm.money + 1.0, 1.0)
	if debt_ratio > 0.5:
		hints.append("Высокий существующий долг относительно накоплений")
	if _lm.credit_rating == "C":
		hints.append("Кредитный рейтинг C — банк настороже")
	elif _lm.credit_rating == "D":
		hints.append("Рейтинг D — банк почти наверняка откажет")
	var rm: Node = get_node_or_null("/root/ReputationManager")
	if rm and rm.reputation < 10:
		hints.append("Низкая репутация снижает доверие банка")
	return hints

func _do_take_loan() -> void:
	if _cfg_panel == null or not is_instance_valid(_cfg_panel): return
	if not _cfg_amount_slider or not _cfg_months_slider: return
	var amount: float = _cfg_amount_slider.value
	var months: int = int(_cfg_months_slider.value)
	var am: Node = get_node_or_null("/root/AudioManager")

	# Проверка кулдауна до попытки
	var lt: Dictionary = _lm.LOAN_TYPES[_cfg_type_idx]
	var reject_until: int = _lm.rejection_cooldowns.get(lt.id, 0) as int
	if reject_until > _gm.day:
		if am: am.play_negative()
		_show_toast("🚫 Повторная заявка возможна с дня %d" % reject_until)
		return

	var result: bool = _lm.try_take_loan(_cfg_type_idx, amount, months)
	if result:
		if am: am.play_buy()
		_close_cfg()
		_switch_tab(1)
		_refresh_active()
		_rebuild_offers()
	else:
		if am: am.play_negative()
		# Определяем причину отказа
		var reason := _get_denial_reason(_cfg_type_idx, amount, months)
		_show_toast("❌ Банк отказал: %s" % reason)

func _get_denial_reason(type_idx: int, amount: float, months: int) -> String:
	var lt: Dictionary = _lm.LOAN_TYPES[type_idx]
	# Кулдаун уже выставлен — сообщаем об этом
	var reject_until: int = _lm.rejection_cooldowns.get(lt.id, 0) as int
	if reject_until > _gm.day:
		return "следующая заявка с дня %d" % reject_until
	var monthly_income: float = _gm.get_monthly_income()
	var monthly_payment: float = _lm._calc_monthly(amount, lt.rate, months)
	if monthly_income < monthly_payment * 1.5:
		return "недостаточный доход"
	var debt_ratio: float = _lm.get_total_debt() / maxf(_gm.money + 1.0, 1.0)
	if debt_ratio > 0.8:
		return "слишком высокий долг"
	if _lm.credit_rating == "D":
		return "кредитный рейтинг D"
	return "не прошли скоринг"

func _close_cfg() -> void:
	if _cfg_panel and is_instance_valid(_cfg_panel):
		_cfg_panel.queue_free()
		_cfg_panel = null
	_cfg_type_idx = -1
	_cfg_amount_slider = null
	_cfg_months_slider = null
	_cfg_summary_box = null
	_cfg_amount_val = null
	_cfg_months_val = null
	_cfg_dragging = false

# ── Страница активных кредитов ────────────────────────────────────────────────

func _build_active_page() -> Control:
	var sc := ScrollContainer.new()
	sc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	var vb := VBoxContainer.new()
	vb.name = "ActiveVBox"
	vb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vb.add_theme_constant_override("separation", 6)
	sc.add_child(vb)
	return sc

func _refresh_active() -> void:
	if not visible: return
	var vb: VBoxContainer = _tab_active.get_node("ActiveVBox")
	for c in vb.get_children(): c.queue_free()

	# Обновляем инфо-строки
	_refresh_info()

	if _lm.active_loans.is_empty():
		var lbl := Label.new()
		lbl.text = "✅ Нет активных кредитов"
		lbl.add_theme_color_override("font_color", Color(0.45, 0.90, 0.50))
		lbl.add_theme_font_size_override("font_size", 14)
		vb.add_child(lbl)
		return

	for i in _lm.active_loans.size():
		var loan: Dictionary = _lm.active_loans[i]
		var lt_data: Dictionary = {}
		for lt in _lm.LOAN_TYPES:
			if lt.id == loan.get("id", ""):
				lt_data = lt
				break
		var col: Color = lt_data.get("color", Color(0.60, 0.60, 0.70))

		var card := PanelContainer.new()
		var cs := StyleBoxFlat.new()
		cs.bg_color = Color(col.r * 0.12, col.g * 0.12, col.b * 0.12, 0.90)
		cs.border_color = col
		var overdue: int = loan.get("overdue_days", 0) as int
		if overdue > 0:
			cs.border_color = Color(1.0, 0.30, 0.30)
			cs.bg_color = Color(0.18, 0.06, 0.06, 0.90)
		for s in [SIDE_LEFT, SIDE_RIGHT, SIDE_TOP, SIDE_BOTTOM]:
			cs.set_border_width(s, 2)
			cs.set_corner_radius(s, 7)
		cs.content_margin_left = 10; cs.content_margin_right = 10
		cs.content_margin_top = 8; cs.content_margin_bottom = 8
		card.add_theme_stylebox_override("panel", cs)
		vb.add_child(card)

		var cv := VBoxContainer.new()
		cv.add_theme_constant_override("separation", 5)
		card.add_child(cv)

		# Строка 1: название + остаток
		var row1 := HBoxContainer.new()
		cv.add_child(row1)
		var nl := Label.new()
		nl.text = loan.name
		nl.add_theme_font_size_override("font_size", 14)
		nl.add_theme_color_override("font_color", col.lerp(Color.WHITE, 0.3))
		nl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row1.add_child(nl)
		var rl := Label.new()
		rl.text = "Осталось: " + _gm.format_money(loan.remaining)
		rl.add_theme_font_size_override("font_size", 13)
		rl.add_theme_color_override("font_color", Color(0.92, 0.92, 0.95))
		row1.add_child(rl)

		# Прогресс-бар
		var principal: float = (loan.get("principal", loan.remaining) as float)
		var progress: float = 1.0 - loan.remaining / maxf(principal, 1.0)
		var pb_bg := ColorRect.new()
		pb_bg.custom_minimum_size = Vector2(0, 6)
		pb_bg.color = Color(0.10, 0.10, 0.14)
		pb_bg.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		cv.add_child(pb_bg)

		var pb_fill := ColorRect.new()
		pb_fill.color = col
		pb_fill.set_anchors_preset(Control.PRESET_LEFT_WIDE)
		pb_fill.anchor_right = clampf(progress, 0.02, 1.0)
		pb_bg.add_child(pb_fill)

		# Строка 2: платёж + следующая дата + осталось месяцев
		var months_left: int = int(ceil(loan.remaining / maxf(loan.monthly, 1.0)))
		var row2 := HBoxContainer.new()
		cv.add_child(row2)
		var pl := Label.new()
		pl.text = "Платёж: %s/мес  •  Следующий: день %d  •  ~%d мес. осталось" % [
			_gm.format_money(loan.monthly), loan.next_due_day, months_left
		]
		pl.add_theme_font_size_override("font_size", 11)
		pl.add_theme_color_override("font_color",
			Color(1.0, 0.45, 0.45) if overdue > 0 else Color(0.60, 0.60, 0.65))
		pl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row2.add_child(pl)

		# Предупреждение о просрочке
		if overdue > 0:
			var warn := Label.new()
			if overdue <= 7:
				warn.text = "⚠ Просрочка %d дн. — погасите немедленно!" % overdue
				warn.add_theme_color_override("font_color", Color(1.0, 0.70, 0.20))
			elif overdue <= 30:
				warn.text = "🔴 Просрочка %d дн. — долг уже вырос на 20%%, репутация −5" % overdue
				warn.add_theme_color_override("font_color", Color(1.0, 0.40, 0.20))
			else:
				warn.text = "🚨 Просрочка %d дн. — коллекторы! Штраф 15%% от остатка, репутация −15" % overdue
				warn.add_theme_color_override("font_color", Color(1.0, 0.20, 0.20))
			warn.add_theme_font_size_override("font_size", 11)
			cv.add_child(warn)

		# Кнопки погашения
		var btn_row := HBoxContainer.new()
		btn_row.add_theme_constant_override("separation", 6)
		cv.add_child(btn_row)

		var partial_btn := Button.new()
		partial_btn.text = "💰 Погасить часть"
		partial_btn.custom_minimum_size = Vector2(0, 28)
		partial_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		partial_btn.add_theme_font_size_override("font_size", 11)
		var li: int = i
		partial_btn.pressed.connect(func(): _show_partial_dialog(li))
		btn_row.add_child(partial_btn)

		var pay_amount: float = loan.remaining * 0.95
		var can_full: bool = _gm.money >= pay_amount
		var full_btn := Button.new()
		full_btn.text = "✅ Закрыть: %s (скидка 5%%)" % _gm.format_money(pay_amount)
		full_btn.custom_minimum_size = Vector2(0, 28)
		full_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		full_btn.add_theme_font_size_override("font_size", 11)
		var bfs := StyleBoxFlat.new()
		if can_full:
			bfs.bg_color = Color(0.06, 0.18, 0.08)
			bfs.border_color = Color(0.25, 0.70, 0.30)
			full_btn.add_theme_color_override("font_color", Color(0.45, 1.0, 0.50))
		else:
			bfs.bg_color = Color(0.10, 0.10, 0.13)
			bfs.border_color = Color(0.22, 0.22, 0.28)
			full_btn.add_theme_color_override("font_color", Color(0.40, 0.40, 0.45))
			full_btn.disabled = true
		for s in [SIDE_LEFT, SIDE_RIGHT, SIDE_TOP, SIDE_BOTTOM]:
			bfs.set_border_width(s, 1)
			bfs.set_corner_radius(s, 5)
		full_btn.add_theme_stylebox_override("normal", bfs)
		full_btn.pressed.connect(func(): _repay_full(li))
		btn_row.add_child(full_btn)

func _show_partial_dialog(loan_idx: int) -> void:
	if loan_idx >= _lm.active_loans.size(): return
	var loan: Dictionary = _lm.active_loans[loan_idx]
	if _gm.money <= 0:
		_show_toast("❌ Нет денег для погашения")
		return

	var dlg := PanelContainer.new()
	dlg.set_anchors_preset(Control.PRESET_CENTER)
	dlg.custom_minimum_size = Vector2(320, 0)
	dlg.z_index = 30
	var ds := StyleBoxFlat.new()
	ds.bg_color = Color(0.06, 0.06, 0.12, 0.98)
	ds.border_color = Color(0.50, 0.40, 0.15)
	for s in [SIDE_LEFT, SIDE_RIGHT, SIDE_TOP, SIDE_BOTTOM]:
		ds.set_border_width(s, 2)
		ds.set_corner_radius(s, 8)
	ds.content_margin_left = 14; ds.content_margin_right = 14
	ds.content_margin_top = 12; ds.content_margin_bottom = 12
	dlg.add_theme_stylebox_override("panel", ds)
	add_child(dlg)

	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 8)
	dlg.add_child(vb)

	var tl := Label.new()
	tl.text = "Частичное погашение"
	tl.add_theme_font_size_override("font_size", 16)
	tl.add_theme_color_override("font_color", Color(1.0, 0.85, 0.25))
	vb.add_child(tl)

	var info := Label.new()
	info.text = "Остаток: %s  •  У вас: %s" % [
		_gm.format_money(loan.remaining), _gm.format_money(_gm.money)
	]
	info.add_theme_font_size_override("font_size", 12)
	info.add_theme_color_override("font_color", Color(0.70, 0.70, 0.75))
	vb.add_child(info)

	var sl := HSlider.new()
	var _sl_max: float = minf(loan.remaining, _gm.money)
	var _sl_min: float = minf(minf(loan.monthly, loan.remaining), _sl_max)
	sl.min_value = _sl_min
	sl.max_value = _sl_max
	sl.step = 100.0
	sl.value = _sl_min
	sl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vb.add_child(sl)

	var val_lbl := Label.new()
	val_lbl.text = _gm.format_money(sl.value)
	val_lbl.add_theme_font_size_override("font_size", 15)
	val_lbl.add_theme_color_override("font_color", Color(0.90, 0.90, 0.95))
	val_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vb.add_child(val_lbl)
	sl.value_changed.connect(func(v):
		if is_instance_valid(val_lbl): val_lbl.text = _gm.format_money(v)
	)

	var btn_row := HBoxContainer.new()
	btn_row.add_theme_constant_override("separation", 8)
	vb.add_child(btn_row)

	var cancel := Button.new()
	cancel.text = "✕ Отмена"
	cancel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	cancel.pressed.connect(func():
		if is_instance_valid(dlg): dlg.queue_free()
	)
	btn_row.add_child(cancel)

	var ok := Button.new()
	ok.text = "✓ Погасить"
	ok.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var oks := StyleBoxFlat.new()
	oks.bg_color = Color(0.06, 0.18, 0.08)
	oks.border_color = Color(0.25, 0.70, 0.30)
	for s in [SIDE_LEFT, SIDE_RIGHT, SIDE_TOP, SIDE_BOTTOM]:
		oks.set_border_width(s, 1)
		oks.set_corner_radius(s, 5)
	ok.add_theme_stylebox_override("normal", oks)
	ok.add_theme_color_override("font_color", Color(0.45, 1.0, 0.50))
	ok.pressed.connect(func():
		if not is_instance_valid(dlg) or not is_instance_valid(sl): return
		var pay_val: float = sl.value
		dlg.queue_free()
		_lm.repay_partial(loan_idx, pay_val)
		_refresh_active()
	)
	btn_row.add_child(ok)

func _repay_full(loan_idx: int) -> void:
	if loan_idx >= _lm.active_loans.size():
		return
	var loan: Dictionary = _lm.active_loans[loan_idx]
	var pay: float = loan.remaining * 0.95
	var am: Node = get_node_or_null("/root/AudioManager")
	if _gm.money < pay:
		if am: am.play_negative()
		_show_toast("❌ Недостаточно денег! Нужно %s" % _gm.format_money(pay))
		return
	var result: bool = _lm.repay_full(loan_idx)
	if result:
		if am: am.play_level_up()
		_refresh_active()
		_refresh_history()
	else:
		if am: am.play_negative()
		_show_toast("❌ Не удалось погасить кредит")

func _show_toast(msg: String) -> void:
	var lbl := Label.new()
	lbl.text = msg
	lbl.add_theme_font_size_override("font_size", 13)
	lbl.add_theme_color_override("font_color", Color(1.0, 0.40, 0.40))
	lbl.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	lbl.position.y -= 60
	lbl.z_index = 50
	_panel.add_child(lbl)
	var tw := create_tween()
	tw.tween_property(lbl, "modulate:a", 0.0, 1.5).set_delay(1.0)
	tw.tween_callback(lbl.queue_free)

# ── Страница истории ─────────────────────────────────────────────────────────

func _build_history_page() -> Control:
	var sc := ScrollContainer.new()
	sc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	var vb := VBoxContainer.new()
	vb.name = "HistoryVBox"
	vb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vb.add_theme_constant_override("separation", 4)
	sc.add_child(vb)
	return sc

func _refresh_history() -> void:
	var vb: VBoxContainer = _tab_history.get_node("HistoryVBox")
	for c in vb.get_children(): c.queue_free()

	if _lm.loan_history.is_empty():
		var lbl := Label.new()
		lbl.text = "История кредитов пуста."
		lbl.add_theme_color_override("font_color", Color(0.50, 0.50, 0.55))
		vb.add_child(lbl)
		return

	for h in _lm.loan_history:
		var row := HBoxContainer.new()
		vb.add_child(row)
		var icon := "✅" if h.success else "❌"
		var lbl := Label.new()
		lbl.text = "%s %s — %s  (день %d)" % [icon, h.name, _gm.format_money(h.get("principal", 0.0)), h.get("closed_day", 0)]
		lbl.add_theme_font_size_override("font_size", 12)
		lbl.add_theme_color_override("font_color",
			Color(0.45, 0.90, 0.50) if h.success else Color(1.0, 0.40, 0.40))
		row.add_child(lbl)

func _refresh_info() -> void:
	if _rating_lbl_ref:
		_rating_lbl_ref.text = "Рейтинг: %s" % _lm.credit_rating
		_rating_lbl_ref.add_theme_color_override("font_color", _lm.rating_color())
	if _debt_lbl_ref:
		var debt: float = _lm.get_total_debt()
		if debt > 0:
			_debt_lbl_ref.text = "💸 Долг: %s  •  /мес: %s" % [
				_gm.format_money(debt), _gm.format_money(_lm.get_monthly_total())
			]
			_debt_lbl_ref.add_theme_color_override("font_color", Color(1.0, 0.50, 0.50))
		else:
			_debt_lbl_ref.text = "✅ Нет задолженностей"
			_debt_lbl_ref.add_theme_color_override("font_color", Color(0.40, 1.0, 0.45))

# ── Открытие ─────────────────────────────────────────────────────────────────

func open() -> void:
	visible = true
	_panel.modulate.a = 0.0
	_panel.scale = Vector2(0.92, 0.92)
	var tw := create_tween()
	tw.set_parallel(true)
	tw.tween_property(_panel, "modulate:a", 1.0, 0.22)
	tw.tween_property(_panel, "scale", Vector2(1.0, 1.0), 0.22).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	_rebuild_offers()
	_refresh_active()
	_refresh_history()
	_refresh_info()
