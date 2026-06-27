extends CanvasLayer
# Экран «Финансы»: единая сводка экономики — состав капитала, денежный поток,
# налоги, макроэкономика страны и стоимость жизни. Открывается кнопкой в HUD.

var gm
var _panel: PanelContainer
var _vb: VBoxContainer

func _ready() -> void:
	layer = 22
	visible = false
	add_to_group("economy_ui")
	gm = get_node_or_null("/root/GameManager")
	_build_shell()

func _build_shell() -> void:
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.55)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.gui_input.connect(func(e):
		if e is InputEventMouseButton and e.pressed: close())
	add_child(dim)

	_panel = PanelContainer.new()
	# Якорь по центру + симметричный рост, чтобы панель центрировалась, а не
	# уезжала вниз-вправо от центральной точки.
	_panel.set_anchors_preset(Control.PRESET_CENTER)
	_panel.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_panel.grow_vertical = Control.GROW_DIRECTION_BOTH
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.07, 0.08, 0.13, 0.98)
	sb.border_color = Color(0.30, 0.50, 0.75, 0.9)
	sb.set_border_width_all(2)
	sb.set_corner_radius_all(14)
	sb.set_content_margin_all(18)
	_panel.add_theme_stylebox_override("panel", sb)
	add_child(_panel)

	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(440, 560)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_panel.add_child(scroll)

	_vb = VBoxContainer.new()
	_vb.add_theme_constant_override("separation", 6)
	_vb.custom_minimum_size = Vector2(420, 0)
	scroll.add_child(_vb)

func open() -> void:
	if gm == null:
		gm = get_node_or_null("/root/GameManager")
	_rebuild()
	visible = true
	_panel.modulate.a = 0.0
	_panel.scale = Vector2(0.95, 0.95)
	var tw := create_tween()
	tw.set_parallel(true)
	tw.tween_property(_panel, "modulate:a", 1.0, 0.15)
	tw.tween_property(_panel, "scale", Vector2.ONE, 0.15).set_ease(Tween.EASE_OUT)

func close() -> void:
	visible = false

func _rebuild() -> void:
	for c in _vb.get_children():
		c.queue_free()
	if gm == null:
		return
	var cb = get_node_or_null("/root/CentralBankManager")
	var zm = get_node_or_null("/root/ZoneManager")
	var bm = get_node_or_null("/root/BusinessManager")

	_title("📊 Финансы")

	# Капитал
	_header("💼 Капитал")
	var b: Dictionary = gm.get_net_worth_breakdown()
	_row("Наличные", b.cash)
	if b.property > 0: _row("Жильё", b.property)
	if b.business > 0: _row("Бизнес", b.business)
	if b.deposit > 0:  _row("Вклад", b.deposit)
	if b.stocks > 0:   _row("Акции", b.stocks)
	if b.inventory > 0:_row("Инвентарь", b.inventory)
	if b.transport > 0:_row("Транспорт", b.transport)
	if b.get("realestate", 0.0) > 0: _row("Доходная недвижимость", b.realestate)
	if b.get("luxury", 0.0) > 0: _row("Роскошь и коллекции", b.luxury)
	if b.debt > 0:     _row("Долги по кредитам", -b.debt, Color(0.95, 0.45, 0.4))
	_sep()
	_row("ИТОГО капитал", b.total, Color(0.95, 0.82, 0.32))
	_note("Титул: " + gm.get_title())

	# Денежный поток
	_header("💸 Денежный поток (в день)")
	var f: Dictionary = gm.get_finance()
	_row("Доход", f.income, Color(0.45, 0.9, 0.5))
	_row("Расход", -f.expense, Color(0.95, 0.45, 0.4))
	var net: float = f.income - f.expense
	_row("Итог", net, Color(0.45, 0.9, 0.5) if net >= 0 else Color(0.95, 0.45, 0.4))

	# Налоги
	var wage_tax: float = gm.get("total_wage_tax") if gm.get("total_wage_tax") != null else 0.0
	var biz_tax: float = 0.0
	if bm and bm.get("total_tax_paid") != null:
		biz_tax = bm.total_tax_paid
	_header("🧾 Налоги (уплачено всего)")
	_row("НДФЛ с зарплаты", wage_tax)
	_row("Налог на прибыль", biz_tax)
	_sep()
	_row("Всего налогов", wage_tax + biz_tax, Color(0.9, 0.55, 0.45))

	# Власть и влияние
	var inf = get_node_or_null("/root/InfluenceManager")
	if inf and (inf.influence > 0.0 or inf.power_rank() != "Начинающий"):
		_header("🏛 Власть")
		_note("Ранг: " + inf.power_rank())
		_note("Влияние: %d" % int(inf.influence))
		var pm: float = inf.political_income_mult() if inf.has_method("political_income_mult") else 1.0
		if pm > 1.0:
			_note("Политбонус к доходу бизнеса: +%d%%" % int(round((pm - 1.0) * 100.0)))
		if inf.get("is_president"):
			_note("Вы — " + ("Пожизненный президент" if inf.term_limits_abolished else "Президент") +
				" · одобрение народа %d%%" % int(round(inf.approval)))

	# Экономика страны
	if cb:
		_header("🏦 Экономика страны")
		_note("Ключевая ставка: %.1f%%/год" % (cb.key_rate * 100.0))
		_note("Инфляция: %.1f%%/год" % (cb.inflation * 100.0))
		if cb.has_method("phase_label"):
			_note("Фаза: " + cb.phase_label())
		_note("Индекс цен: %.3f   |   Индекс зарплат: %.3f" % [cb.price_index, cb.wage_index])
		if cb.has_method("has_shock") and cb.has_shock():
			var up: bool = cb.price_shock > 1.0
			_note("🛒 %s: цены %s %d%% (ещё %d дн.)" % [cb.shock_name,
				("выше" if up else "ниже"), int(round(absf(cb.price_shock - 1.0) * 100.0)), cb.shock_days_left])

	# Стоимость жизни
	if gm.has_method("shop_price"):
		_header("🛒 Стоимость жизни")
		var col_str := ""
		if zm and zm.has_method("cost_of_living_mult"):
			col_str = " (район ×%.2f)" % zm.cost_of_living_mult()
		_note("Хлеб: %s   Вода: %s   Обед: %s%s" % [
			gm.format_money(gm.shop_price(50)), gm.format_money(gm.shop_price(30)),
			gm.format_money(gm.shop_price(200)), col_str])

	# Кнопка закрытия
	var spacer := Control.new()
	spacer.custom_minimum_size = Vector2(0, 8)
	_vb.add_child(spacer)
	var close_btn := Button.new()
	close_btn.text = "Закрыть"
	close_btn.add_theme_font_size_override("font_size", 16)
	var cs := StyleBoxFlat.new()
	cs.bg_color = Color(0.12, 0.16, 0.24)
	cs.border_color = Color(0.3, 0.45, 0.65)
	cs.set_border_width_all(1)
	cs.set_corner_radius_all(8)
	cs.set_content_margin_all(8)
	close_btn.add_theme_stylebox_override("normal", cs)
	close_btn.pressed.connect(close)
	_vb.add_child(close_btn)

# ── helpers ───────────────────────────────────────────────────────────────────
func _title(t: String) -> void:
	var l := Label.new()
	l.text = t
	l.add_theme_font_size_override("font_size", 24)
	l.add_theme_color_override("font_color", Color(1, 1, 1))
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_vb.add_child(l)

func _header(t: String) -> void:
	var s := Control.new()
	s.custom_minimum_size = Vector2(0, 6)
	_vb.add_child(s)
	var l := Label.new()
	l.text = t
	l.add_theme_font_size_override("font_size", 15)
	l.add_theme_color_override("font_color", Color(0.55, 0.72, 0.95))
	_vb.add_child(l)

func _row(label_text: String, value: float, color: Color = Color(0.85, 0.88, 0.95)) -> void:
	var row := HBoxContainer.new()
	var n := Label.new()
	n.text = label_text
	n.add_theme_font_size_override("font_size", 14)
	n.add_theme_color_override("font_color", Color(0.72, 0.76, 0.85))
	n.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(n)
	var v := Label.new()
	v.text = gm.format_money(value)
	v.add_theme_font_size_override("font_size", 14)
	v.add_theme_color_override("font_color", color)
	row.add_child(v)
	_vb.add_child(row)

func _note(t: String) -> void:
	var l := Label.new()
	l.text = t
	l.add_theme_font_size_override("font_size", 13)
	l.add_theme_color_override("font_color", Color(0.66, 0.70, 0.80))
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.custom_minimum_size = Vector2(400, 0)
	_vb.add_child(l)

func _sep() -> void:
	var line := ColorRect.new()
	line.color = Color(0.3, 0.35, 0.45, 0.5)
	line.custom_minimum_size = Vector2(0, 1)
	_vb.add_child(line)
