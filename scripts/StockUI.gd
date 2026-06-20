extends CanvasLayer

var _sm: Node
var _gm: Node
var _list:          VBoxContainer
var _portfolio_lbl: Label
var _pnl_lbl:       Label
var _toast_lbl:     Label
var _event_banner:  PanelContainer
var _event_lbl:     Label
var _panel:         Panel
var _toast_tween:   Tween = null
var _qty_input:     LineEdit
var _custom_qty:    int = 1

func _ready() -> void:
	layer = 8
	visible = false
	add_to_group("stock_ui")
	_sm = get_node("/root/StockMarket")
	_gm = get_node("/root/GameManager")
	_sm.prices_changed.connect(_refresh)
	_sm.dividend_paid.connect(_on_dividend)
	_sm.market_event_triggered.connect(_on_market_event)
	_build_ui()

func _build_ui() -> void:
	var dimmer := ColorRect.new()
	dimmer.set_anchors_preset(Control.PRESET_FULL_RECT)
	dimmer.color = Color(0, 0, 0, 0.72)
	dimmer.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(dimmer)

	_panel = Panel.new()
	_panel.set_anchors_preset(Control.PRESET_CENTER)
	_panel.position = Vector2(-430, -350)
	_panel.size     = Vector2(860, 700)
	var ps := StyleBoxFlat.new()
	ps.bg_color     = Color(0.04, 0.05, 0.09, 0.98)
	ps.border_color = Color(0.20, 0.55, 0.30, 0.90)
	for s in [SIDE_LEFT, SIDE_RIGHT, SIDE_TOP, SIDE_BOTTOM]:
		ps.set_border_width(s, 2)
		ps.set_corner_radius(s, 12)
	_panel.add_theme_stylebox_override("panel", ps)
	add_child(_panel)

	var vbox := VBoxContainer.new()
	vbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	vbox.add_theme_constant_override("separation", 5)
	_panel.add_child(vbox)

	# ── Заголовок ─────────────────────────────────────────────────────
	var hdr := HBoxContainer.new()
	hdr.add_theme_constant_override("separation", 8)
	vbox.add_child(hdr)

	var title_lbl := Label.new()
	title_lbl.text = "📈 Фондовая биржа"
	title_lbl.add_theme_font_size_override("font_size", 22)
	title_lbl.add_theme_color_override("font_color", Color(1.0, 0.88, 0.25))
	title_lbl.add_theme_constant_override("outline_size", 3)
	title_lbl.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.70))
	title_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hdr.add_child(title_lbl)

	var close_btn := Button.new()
	close_btn.text = "✖"
	close_btn.custom_minimum_size = Vector2(34, 34)
	close_btn.add_theme_font_size_override("font_size", 14)
	close_btn.add_theme_color_override("font_color", Color.WHITE)
	var cs := StyleBoxFlat.new()
	cs.bg_color     = Color(0.22, 0.07, 0.07)
	cs.border_color = Color(0.55, 0.18, 0.18)
	for s in [SIDE_LEFT, SIDE_RIGHT, SIDE_TOP, SIDE_BOTTOM]:
		cs.set_border_width(s, 1)
		cs.set_corner_radius(s, 6)
	close_btn.add_theme_stylebox_override("normal", cs)
	var csh := cs.duplicate() as StyleBoxFlat
	csh.bg_color = Color(0.32, 0.10, 0.10)
	close_btn.add_theme_stylebox_override("hover", csh)
	close_btn.pressed.connect(func(): visible = false)
	hdr.add_child(close_btn)

	# ── Баннер рыночного события ──────────────────────────────────────
	_event_banner = PanelContainer.new()
	_event_banner.visible = false
	var evs := StyleBoxFlat.new()
	evs.bg_color     = Color(0.14, 0.10, 0.03, 0.97)
	evs.border_color = Color(1.0, 0.78, 0.20, 0.90)
	for s in [SIDE_LEFT, SIDE_RIGHT, SIDE_TOP, SIDE_BOTTOM]:
		evs.set_border_width(s, 2)
		evs.set_corner_radius(s, 7)
	evs.content_margin_left   = 12
	evs.content_margin_right  = 12
	evs.content_margin_top    = 5
	evs.content_margin_bottom = 5
	_event_banner.add_theme_stylebox_override("panel", evs)
	vbox.add_child(_event_banner)

	_event_lbl = Label.new()
	_event_lbl.add_theme_font_size_override("font_size", 13)
	_event_lbl.add_theme_color_override("font_color", Color(1.0, 0.90, 0.35))
	_event_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_event_banner.add_child(_event_lbl)

	# ── Портфель ──────────────────────────────────────────────────────
	_portfolio_lbl = Label.new()
	_portfolio_lbl.add_theme_font_size_override("font_size", 13)
	_portfolio_lbl.add_theme_color_override("font_color", Color(0.65, 1.0, 0.65))
	vbox.add_child(_portfolio_lbl)

	_pnl_lbl = Label.new()
	_pnl_lbl.add_theme_font_size_override("font_size", 12)
	_pnl_lbl.visible = false
	vbox.add_child(_pnl_lbl)

	# ── Toast ─────────────────────────────────────────────────────────
	_toast_lbl = Label.new()
	_toast_lbl.add_theme_font_size_override("font_size", 13)
	_toast_lbl.visible = false
	vbox.add_child(_toast_lbl)

	# ── Строка выбора количества ──────────────────────────────────────
	var qty_row := HBoxContainer.new()
	qty_row.add_theme_constant_override("separation", 6)
	vbox.add_child(qty_row)

	var qty_lbl := Label.new()
	qty_lbl.text = "Количество:"
	qty_lbl.add_theme_font_size_override("font_size", 12)
	qty_lbl.add_theme_color_override("font_color", Color(0.72, 0.72, 0.90))
	qty_row.add_child(qty_lbl)

	for q in [1, 10, 100, 1000]:
		var qbtn := Button.new()
		qbtn.text = str(q)
		qbtn.custom_minimum_size = Vector2(46, 24)
		qbtn.add_theme_font_size_override("font_size", 11)
		var qbs := StyleBoxFlat.new()
		qbs.bg_color     = Color(0.10, 0.10, 0.18)
		qbs.border_color = Color(0.35, 0.35, 0.60, 0.80)
		for sv in [SIDE_LEFT, SIDE_RIGHT, SIDE_TOP, SIDE_BOTTOM]:
			qbs.set_border_width(sv, 1)
			qbs.set_corner_radius(sv, 4)
		qbtn.add_theme_stylebox_override("normal", qbs)
		var qv: int = q
		qbtn.pressed.connect(func():
			_custom_qty = qv
			if _qty_input: _qty_input.text = str(qv)
			_refresh()
		)
		qty_row.add_child(qbtn)

	_qty_input = LineEdit.new()
	_qty_input.text = "1"
	_qty_input.placeholder_text = "кол-во"
	_qty_input.custom_minimum_size = Vector2(72, 24)
	_qty_input.add_theme_font_size_override("font_size", 12)
	_qty_input.text_changed.connect(func(t: String):
		var v := t.to_int()
		if v > 0:
			_custom_qty = v
	)
	qty_row.add_child(_qty_input)

	var sep_rect := ColorRect.new()
	sep_rect.color = Color(0.20, 0.45, 0.25, 0.55)
	sep_rect.custom_minimum_size = Vector2(0, 1)
	vbox.add_child(sep_rect)

	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(scroll)

	_list = VBoxContainer.new()
	_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_list.add_theme_constant_override("separation", 6)
	scroll.add_child(_list)

# ── Открытие ──────────────────────────────────────────────────────────────
func open() -> void:
	if not _sm.active_event.is_empty():
		_show_event_banner(_sm.active_event.name, _sm.active_event.desc, _sm.active_event.get("pos", true))
	else:
		_event_banner.visible = false
	visible = true
	_panel.modulate.a = 0.0
	_panel.scale = Vector2(0.93, 0.93)
	var tw := create_tween()
	tw.set_parallel(true)
	tw.tween_property(_panel, "modulate:a", 1.0, 0.22)
	tw.tween_property(_panel, "scale", Vector2(1.0, 1.0), 0.22).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	_refresh()

# ── События ───────────────────────────────────────────────────────────────
func _on_market_event(ev_name: String, ev_desc: String, is_pos: bool) -> void:
	_show_event_banner(ev_name, ev_desc, is_pos)

func _show_event_banner(ev_name: String, ev_desc: String, is_pos: bool) -> void:
	_event_lbl.text = "⚡ " + ev_name + "  —  " + ev_desc
	var col := Color(0.40, 1.0, 0.55) if is_pos else Color(1.0, 0.42, 0.42)
	_event_lbl.add_theme_color_override("font_color", col)
	var evs := _event_banner.get_theme_stylebox("panel") as StyleBoxFlat
	if evs:
		evs.border_color = col.darkened(0.2)
	_event_banner.visible = true

func _on_dividend(stock_id: String, amount: float) -> void:
	var s: Dictionary = _sm.get_stock(stock_id)
	_flash_toast("💵 Дивиденды: %s %s  +%s" % [s.get("icon",""), s.get("name",""), _gm.format_money(amount)],
		Color(0.55, 1.0, 0.55))

# ── Обновление списка ─────────────────────────────────────────────────────
func _refresh() -> void:
	if not visible: return
	for c in _list.get_children(): c.queue_free()

	# Портфель
	var port_val: float = _sm.get_portfolio_value()
	var invested: float = _sm.get_total_invested()
	_portfolio_lbl.text = "💼 Портфель: %s  |  💰 Наличные: %s" % [
		_gm.format_money(port_val), _gm.format_money(_gm.money)
	]

	if invested > 0:
		var pnl: float     = port_val - invested
		var pnl_pct: float = pnl / invested * 100.0
		var col := Color(0.40, 1.0, 0.50) if pnl >= 0 else Color(1.0, 0.40, 0.40)
		var pnl_sign := "+" if pnl >= 0 else ""
		_pnl_lbl.text = "📊 Вложено: %s  |  P&L: %s%s (%.1f%%)" % [
			_gm.format_money(invested), pnl_sign, _gm.format_money(pnl), pnl_pct
		]
		_pnl_lbl.add_theme_color_override("font_color", col)
		_pnl_lbl.visible = true
	else:
		_pnl_lbl.visible = false

	for s in _sm.STOCKS:
		var price:    float = _sm.prices[s.id]
		var shares:   int   = _sm.owned[s.id]
		var hist:     Array = _sm.history[s.id]
		var day_chg:  float = _sm.daily_change[s.id]
		var basis:    float = _sm.cost_basis[s.id]

		var trend_col  := Color(0.75, 0.75, 0.75)
		var trend_icon := "➡"
		if day_chg > 0.001:
			trend_icon = "📈"; trend_col = Color(0.30, 1.0, 0.40)
		elif day_chg < -0.001:
			trend_icon = "📉"; trend_col = Color(1.0, 0.40, 0.40)

		# ── Карточка ──────────────────────────────────────────────────
		var card := PanelContainer.new()
		var cps := StyleBoxFlat.new()
		if shares > 0:
			cps.bg_color     = Color(0.05, 0.10, 0.06, 0.90)
			cps.border_color = Color(0.22, 0.55, 0.28, 0.85)
		else:
			cps.bg_color     = Color(0.05, 0.05, 0.09, 0.80)
			cps.border_color = Color(0.18, 0.28, 0.22, 0.55)
		cps.set_border_width_all(1)
		cps.set_corner_radius_all(7)
		cps.content_margin_left   = 10
		cps.content_margin_right  = 10
		cps.content_margin_top    = 8
		cps.content_margin_bottom = 8
		card.add_theme_stylebox_override("panel", cps)
		_list.add_child(card)

		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 12)
		card.add_child(row)

		# Мини-график
		var graph := Control.new()
		graph.custom_minimum_size = Vector2(110, 54)
		var snap_hist := hist.duplicate()
		graph.draw.connect(func(): _draw_graph(graph, snap_hist))
		row.add_child(graph)

		# Инфо-колонка
		var info := VBoxContainer.new()
		info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		info.add_theme_constant_override("separation", 3)
		row.add_child(info)

		# Название + тренд
		var name_row := HBoxContainer.new()
		name_row.add_theme_constant_override("separation", 6)
		info.add_child(name_row)

		var name_lbl := Label.new()
		name_lbl.text = s.icon + " " + s.name
		name_lbl.add_theme_font_size_override("font_size", 14)
		name_lbl.add_theme_color_override("font_color", Color(0.92, 0.95, 0.88))
		name_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		name_row.add_child(name_lbl)

		if s.div_yield > 0.0:
			var div_lbl := Label.new()
			div_lbl.text = "💵 %.0f%% год." % (s.div_yield * 100.0)
			div_lbl.add_theme_font_size_override("font_size", 10)
			div_lbl.add_theme_color_override("font_color", Color(0.75, 1.0, 0.55))
			name_row.add_child(div_lbl)

		var trend_lbl := Label.new()
		trend_lbl.text = trend_icon
		trend_lbl.add_theme_font_size_override("font_size", 14)
		trend_lbl.add_theme_color_override("font_color", trend_col)
		name_row.add_child(trend_lbl)

		# Цена + дневное изменение
		var price_row := HBoxContainer.new()
		price_row.add_theme_constant_override("separation", 8)
		info.add_child(price_row)

		var price_lbl := Label.new()
		price_lbl.text = "Цена: " + _gm.format_money(price)
		price_lbl.add_theme_font_size_override("font_size", 12)
		price_lbl.add_theme_color_override("font_color", Color(0.82, 0.82, 0.92))
		price_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		price_row.add_child(price_lbl)

		var chg_sign := "+" if day_chg >= 0 else ""
		var chg_lbl := Label.new()
		chg_lbl.text = "%s%.1f%% сегодня" % [chg_sign, day_chg * 100.0]
		chg_lbl.add_theme_font_size_override("font_size", 11)
		chg_lbl.add_theme_color_override("font_color", trend_col)
		price_row.add_child(chg_lbl)

		# Позиция + P&L (только если есть акции)
		if shares > 0:
			var hold_pnl: float = (price - basis) * shares
			var hold_pct: float = (price - basis) / basis * 100.0 if basis > 0 else 0.0
			var hold_col := Color(0.40, 1.0, 0.50) if hold_pnl >= 0 else Color(1.0, 0.42, 0.42)
			var pnl_sign := "+" if hold_pnl >= 0 else ""
			var hold_lbl := Label.new()
			hold_lbl.text = "У вас: %d шт. = %s  |  P&L: %s%s (%.1f%%)" % [
				shares, _gm.format_money(price * shares),
				pnl_sign, _gm.format_money(hold_pnl), hold_pct
			]
			hold_lbl.add_theme_font_size_override("font_size", 11)
			hold_lbl.add_theme_color_override("font_color", hold_col)
			info.add_child(hold_lbl)

		# Кнопки торговли
		var btn_row := HBoxContainer.new()
		btn_row.add_theme_constant_override("separation", 5)
		info.add_child(btn_row)

		var sid: String = s.id

		# Купить N
		var buy_btn := Button.new()
		buy_btn.text = "Купить ×%d" % _custom_qty
		buy_btn.custom_minimum_size = Vector2(90, 26)
		buy_btn.add_theme_font_size_override("font_size", 11)
		buy_btn.add_theme_color_override("font_color", Color(0.55, 1.0, 0.65))
		var bbs := StyleBoxFlat.new()
		bbs.bg_color     = Color(0.07, 0.18, 0.09)
		bbs.border_color = Color(0.20, 0.58, 0.28, 0.85)
		for sv in [SIDE_LEFT, SIDE_RIGHT, SIDE_TOP, SIDE_BOTTOM]:
			bbs.set_border_width(sv, 1)
			bbs.set_corner_radius(sv, 4)
		buy_btn.add_theme_stylebox_override("normal", bbs)
		var bbh := bbs.duplicate() as StyleBoxFlat
		bbh.bg_color = Color(0.10, 0.26, 0.12)
		buy_btn.add_theme_stylebox_override("hover", bbh)
		buy_btn.pressed.connect(func(): _buy(sid, _custom_qty))
		btn_row.add_child(buy_btn)

		# Стоимость покупки
		var cost_lbl := Label.new()
		cost_lbl.text = "= " + _gm.format_money(price * _custom_qty)
		cost_lbl.add_theme_font_size_override("font_size", 10)
		cost_lbl.add_theme_color_override("font_color", Color(0.58, 0.62, 0.80))
		cost_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		btn_row.add_child(cost_lbl)

		# Продать N
		var sell_btn := Button.new()
		sell_btn.text = "Продать ×%d" % _custom_qty
		sell_btn.custom_minimum_size = Vector2(96, 26)
		sell_btn.add_theme_font_size_override("font_size", 11)
		sell_btn.add_theme_color_override("font_color", Color(1.0, 0.55, 0.55))
		sell_btn.disabled = shares < _custom_qty
		var sbs := StyleBoxFlat.new()
		sbs.bg_color     = Color(0.20, 0.07, 0.07)
		sbs.border_color = Color(0.55, 0.18, 0.18, 0.85)
		for sv in [SIDE_LEFT, SIDE_RIGHT, SIDE_TOP, SIDE_BOTTOM]:
			sbs.set_border_width(sv, 1)
			sbs.set_corner_radius(sv, 4)
		sell_btn.add_theme_stylebox_override("normal", sbs)
		var sbh := sbs.duplicate() as StyleBoxFlat
		sbh.bg_color = Color(0.30, 0.10, 0.10)
		sell_btn.add_theme_stylebox_override("hover", sbh)
		sell_btn.pressed.connect(func(): _sell(sid, _custom_qty))
		btn_row.add_child(sell_btn)

		# Продать всё (только если держит акции)
		if shares > 0:
			var sell_all_btn := Button.new()
			sell_all_btn.text = "Всё"
			sell_all_btn.custom_minimum_size = Vector2(42, 26)
			sell_all_btn.add_theme_font_size_override("font_size", 10)
			sell_all_btn.add_theme_color_override("font_color", Color(1.0, 0.72, 0.40))
			var sa_sbs := StyleBoxFlat.new()
			sa_sbs.bg_color     = Color(0.22, 0.10, 0.04)
			sa_sbs.border_color = Color(0.65, 0.35, 0.12, 0.80)
			for sv in [SIDE_LEFT, SIDE_RIGHT, SIDE_TOP, SIDE_BOTTOM]:
				sa_sbs.set_border_width(sv, 1)
				sa_sbs.set_corner_radius(sv, 4)
			sell_all_btn.add_theme_stylebox_override("normal", sa_sbs)
			sell_all_btn.pressed.connect(func(): _sell_all(sid))
			btn_row.add_child(sell_all_btn)

# ── График ────────────────────────────────────────────────────────────────
func _draw_graph(ctrl: Control, hist: Array) -> void:
	if hist.size() < 2: return
	var w: float = ctrl.size.x
	var h: float = ctrl.size.y
	var mn: float = hist[0]; var mx: float = hist[0]
	for v in hist:
		mn = minf(mn, v)
		mx = maxf(mx, v)
	if mx == mn: mx = mn + 1.0

	ctrl.draw_rect(Rect2(0, 0, w, h), Color(0.04, 0.08, 0.05, 0.75))

	# Горизонтальная нулевая линия (базовая цена)
	var is_up: bool = hist[hist.size() - 1] >= hist[0]

	# Заполнение под линией
	var fill_pts := PackedVector2Array()
	fill_pts.append(Vector2(0, h))
	for i in hist.size():
		var fx: float = (float(i) / (hist.size() - 1)) * w
		var fy: float = h - ((hist[i] - mn) / (mx - mn)) * (h - 8) - 4
		fill_pts.append(Vector2(fx, fy))
	fill_pts.append(Vector2(w, h))
	var fill_col := Color(0.12, 0.60, 0.22, 0.20) if is_up else Color(0.60, 0.12, 0.12, 0.20)
	ctrl.draw_colored_polygon(fill_pts, fill_col)

	# Линия графика
	var prev := Vector2.ZERO
	for i in hist.size():
		var fx: float = (float(i) / (hist.size() - 1)) * w
		var fy: float = h - ((hist[i] - mn) / (mx - mn)) * (h - 8) - 4
		var pt := Vector2(fx, fy)
		if i > 0:
			var col: Color = Color(0.30, 0.92, 0.42) if hist[i] >= hist[i - 1] else Color(0.92, 0.30, 0.30)
			ctrl.draw_line(prev, pt, col, 2.0)
		prev = pt

	# Точка последней цены
	ctrl.draw_circle(prev, 3.5, Color(1.0, 1.0, 0.50, 0.95))

	# Рамка
	ctrl.draw_rect(Rect2(0, 0, w, h), Color(0.22, 0.40, 0.25, 0.60), false, 1.0)

# ── Торговля ──────────────────────────────────────────────────────────────
func _buy(stock_id: String, qty: int) -> void:
	if qty <= 0: qty = 1
	if not _sm.buy(stock_id, qty):
		_flash_toast("⚠ Недостаточно денег! Нужно " + _gm.format_money(_sm.prices[stock_id] * qty),
			Color(1.0, 0.40, 0.40))
	else:
		var am := get_node_or_null("/root/AudioManager")
		if am: am.play_buy()
		_refresh()

func _sell(stock_id: String, qty: int) -> void:
	if qty <= 0: qty = 1
	if not _sm.sell(stock_id, qty):
		_flash_toast("⚠ Недостаточно акций! У вас: %d шт." % _sm.owned[stock_id],
			Color(1.0, 0.40, 0.40))
	else:
		var am := get_node_or_null("/root/AudioManager")
		if am: am.play_coin()
		_refresh()

func _sell_all(stock_id: String) -> void:
	if not _sm.sell_all(stock_id):
		_flash_toast("⚠ Нет акций для продажи.", Color(1.0, 0.40, 0.40))
	else:
		var am := get_node_or_null("/root/AudioManager")
		if am: am.play_coin()
		_refresh()

func _flash_toast(msg: String, col: Color = Color(1.0, 0.40, 0.40)) -> void:
	_toast_lbl.text = msg
	_toast_lbl.add_theme_color_override("font_color", col)
	_toast_lbl.visible = true
	if _toast_tween and _toast_tween.is_valid():
		_toast_tween.kill()
	_toast_tween = create_tween()
	_toast_tween.tween_interval(3.0)
	_toast_tween.tween_callback(func(): _toast_lbl.visible = false)
