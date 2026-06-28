extends CanvasLayer
# Окно «Недвижимость»: портфель доходных объектов (покупка/продажа/аренда).
# Открывается из агентства недвижимости.

var gm
var rem
var _panel: PanelContainer
var _vb: VBoxContainer

func _ready() -> void:
	layer = 21
	visible = false
	add_to_group("realestate_ui")
	gm = get_node_or_null("/root/GameManager")
	rem = get_node_or_null("/root/RealEstateManager")
	_build_shell()
	if rem and rem.has_signal("portfolio_changed"):
		rem.portfolio_changed.connect(func(): if visible: _rebuild())

func _build_shell() -> void:
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.55)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.gui_input.connect(func(e):
		if e is InputEventMouseButton and e.pressed: close())
	add_child(dim)

	_panel = PanelContainer.new()
	_panel.set_anchors_preset(Control.PRESET_CENTER)
	_panel.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_panel.grow_vertical = Control.GROW_DIRECTION_BOTH
	var sb := StyleBoxFlat.new()
	sb.bg_color = UITheme.PANEL
	sb.border_color = UITheme.GOLD_DIM
	sb.set_border_width_all(2)
	sb.set_corner_radius_all(14)
	sb.set_content_margin_all(18)
	_panel.add_theme_stylebox_override("panel", sb)
	add_child(_panel)

	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(540, 580)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_panel.add_child(scroll)

	_vb = VBoxContainer.new()
	_vb.add_theme_constant_override("separation", 6)
	_vb.custom_minimum_size = Vector2(520, 0)
	scroll.add_child(_vb)

func open() -> void:
	if gm == null: gm = get_node_or_null("/root/GameManager")
	if rem == null: rem = get_node_or_null("/root/RealEstateManager")
	_rebuild()
	visible = true
	var fit: float = UITheme.fit_scale(_panel)
	_panel.pivot_offset = _panel.size * 0.5
	_panel.modulate.a = 0.0
	_panel.scale = Vector2(fit, fit) * 0.95
	var tw := create_tween()
	tw.set_parallel(true)
	tw.tween_property(_panel, "modulate:a", 1.0, 0.15)
	tw.tween_property(_panel, "scale", Vector2(fit, fit), 0.15).set_ease(Tween.EASE_OUT)

func close() -> void:
	visible = false

func _rebuild() -> void:
	for c in _vb.get_children():
		c.queue_free()
	if rem == null or gm == null:
		return
	_title("🏘 Недвижимость")
	var pnote: String = "Портфель: %d объект(ов) · стоимость %s" % [
		rem.property_count(), gm.format_money(rem.portfolio_value())]
	if rem.project_count() > 0:
		pnote += " · 🏗 строится %d" % rem.project_count()
	_note(pnote)
	if rem.property_count() > 0:
		_lbl(_vb, "Чистый поток: %s/день  (аренда +%s − обслуж. %s%s)" % [
			gm.format_money(rem.net_daily_income()), gm.format_money(rem.rental_income()),
			gm.format_money(rem.maintenance_cost()),
			(" − управл. " + gm.format_money(rem.manager_fee())) if rem.has_manager else ""],
			Color(0.55, 0.9, 0.6) if rem.net_daily_income() >= 0 else Color(0.95, 0.55, 0.5), 12)
		_lbl(_vb, "Заселённость: %d/%d  (%.0f%%)" % [
			rem.occupied_count(), rem.property_count(), rem.occupancy_rate() * 100.0],
			Color(0.7, 0.85, 0.72), 12)
	var tr: int = rem.market_trend()
	var arrow: String = "📈 рост" if tr > 0 else ("📉 спад" if tr < 0 else "➡ стабильно")
	var tcol: Color = Color(0.55, 0.9, 0.6) if tr > 0 else (Color(0.95, 0.55, 0.5) if tr < 0 else Color(0.7, 0.72, 0.78))
	_lbl(_vb, "Индекс рынка: %.2f  (%s)" % [rem.market_index, arrow], tcol, 12)
	var cb = get_node_or_null("/root/CentralBankManager")
	if cb and cb.has_method("phase_label"):
		var boom: bool = cb.has_method("is_boom") and cb.is_boom()
		var rec: bool = cb.has_method("is_recession") and cb.is_recession()
		var pcol: Color = Color(0.55, 0.9, 0.6) if boom else (Color(0.95, 0.55, 0.5) if rec else Color(0.7, 0.72, 0.78))
		_lbl(_vb, "Фаза экономики: %s  (влияет на коммерцию)" % cb.phase_label(), pcol, 11)
	_sep()

	# Управляющий
	if rem.property_count() > 0:
		_vb.add_child(_manager_card())
		_sep()

	# Свои объекты
	if rem.property_count() > 0:
		_header("🔑 Ваши объекты")
		for i in range(rem.properties.size()):
			_vb.add_child(_owned_card(i))
		_sep()

	# Стройки в процессе
	if rem.project_count() > 0:
		_header("🏗 Стройки в процессе")
		for i in range(rem.projects.size()):
			_vb.add_child(_project_card(i))
		_sep()

	# Каталог — жилая недвижимость
	_header("🏠 Жилая недвижимость")
	for t in rem.PROPERTY_TYPES:
		_vb.add_child(_buy_card(t))
	_sep()

	# Каталог — коммерческая недвижимость
	_header("🏢 Коммерческая (доход выше, зависит от цикла)")
	for t in rem.COMMERCIAL_TYPES:
		_vb.add_child(_buy_card(t))

	var spacer := Control.new()
	spacer.custom_minimum_size = Vector2(0, 8)
	_vb.add_child(spacer)
	var close_btn := Button.new()
	close_btn.text = "Закрыть"
	close_btn.add_theme_font_size_override("font_size", 16)
	_style(close_btn, Color(0.12, 0.16, 0.14), Color(0.3, 0.55, 0.4))
	close_btn.pressed.connect(close)
	_vb.add_child(close_btn)

func _manager_card() -> PanelContainer:
	var card := PanelContainer.new()
	var cs := StyleBoxFlat.new()
	cs.bg_color = Color(0.06, 0.10, 0.14, 0.92)
	cs.border_color = Color(0.35, 0.50, 0.70, 0.8) if rem.has_manager else Color(0.30, 0.40, 0.48, 0.6)
	cs.set_border_width_all(1); cs.set_corner_radius_all(8); cs.set_content_margin_all(10)
	card.add_theme_stylebox_override("panel", cs)
	var row := HBoxContainer.new(); row.add_theme_constant_override("separation", 10); card.add_child(row)
	var icon := Label.new(); icon.text = "🧑‍💼"
	icon.add_theme_font_size_override("font_size", 24); icon.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	row.add_child(icon)
	var col := VBoxContainer.new(); col.size_flags_horizontal = Control.SIZE_EXPAND_FILL; row.add_child(col)
	_lbl(col, "Управляющий" + ("  ✅ нанят" if rem.has_manager else ""), Color(0.82, 0.88, 0.98), 14)
	_lbl(col, "Снижает простои и плохих жильцов. Комиссия %d%% от аренды (%s/день)." % [
		int(rem.MANAGER_FEE_RATE * 100.0), gm.format_money(rem.rental_income() * rem.MANAGER_FEE_RATE)],
		Color(0.66, 0.72, 0.82), 11)
	var btn := Button.new()
	btn.add_theme_font_size_override("font_size", 12)
	if rem.has_manager:
		btn.text = "Уволить"
		_style(btn, Color(0.18, 0.12, 0.10), Color(0.6, 0.4, 0.3))
		btn.pressed.connect(func(): rem.set_manager(false))
	else:
		btn.text = "Нанять"
		_style(btn, Color(0.10, 0.16, 0.24), Color(0.30, 0.50, 0.7))
		btn.pressed.connect(func(): rem.set_manager(true))
	btn.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(btn)
	return card

func _owned_card(i: int) -> PanelContainer:
	var p = rem.properties[i]
	var t = rem._get_type(String(p.get("type_id", "")))
	var card := PanelContainer.new()
	var cs := StyleBoxFlat.new()
	cs.bg_color = Color(0.05, 0.12, 0.07, 0.92); cs.border_color = Color(0.30, 0.62, 0.36, 0.8)
	cs.set_border_width_all(1); cs.set_corner_radius_all(8)
	cs.set_content_margin_all(10)
	card.add_theme_stylebox_override("panel", cs)
	var row := HBoxContainer.new(); row.add_theme_constant_override("separation", 10); card.add_child(row)
	var icon := Label.new(); icon.text = t.get("icon", "🏠")
	icon.add_theme_font_size_override("font_size", 24); icon.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	row.add_child(icon)
	var col := VBoxContainer.new(); col.size_flags_horizontal = Control.SIZE_EXPAND_FILL; row.add_child(col)
	var idx: int = i
	var lvl: int = rem.property_level(i)
	var stars: String = ""
	for s in range(rem.MAX_RENO_LEVEL):
		stars += "⭐" if s < lvl else "☆"
	var vacant: bool = rem.is_vacant(i)
	var grace: int = int(p.get("grace", 0))
	var status: String = "🔴 Простой" if vacant else ("🟢 Сдан · новый" if grace > 0 else "🟢 Сдан")
	var scol: Color = Color(0.95, 0.55, 0.5) if vacant else Color(0.55, 0.9, 0.6)
	_lbl(col, "%s  %s   %s" % [t.get("name", "?"), stars, status], scol, 14)
	var rent_str: String = "—" if vacant else "+%s/день" % gm.format_money(rem.property_rent(i))
	_lbl(col, "Аренда %s · оценка %s" % [rent_str, gm.format_money(rem.property_value(i))], Color(0.62, 0.85, 0.66), 11)
	var tid_o: String = String(p.get("type_id", ""))
	if rem.is_commercial(tid_o):
		var cm: float = rem.cycle_mult(tid_o)
		if absf(cm - 1.0) > 0.01:
			var ccol: Color = Color(0.55, 0.9, 0.6) if cm > 1.0 else Color(0.95, 0.55, 0.5)
			_lbl(col, "📊 Аренда ×%.2f от экономического цикла" % cm, ccol, 11)
	var mort: float = float(p.get("mortgage", 0.0))
	if mort > 0.0:
		_lbl(col, "🏦 Ипотека: остаток %s" % gm.format_money(mort), Color(0.85, 0.70, 0.55), 11)
	var btns := VBoxContainer.new(); btns.add_theme_constant_override("separation", 4); row.add_child(btns)
	# Ремонт
	if lvl < rem.MAX_RENO_LEVEL:
		var rcost: int = rem.reno_cost(i)
		var rb := Button.new(); rb.text = "🔨 Ремонт (%s)" % gm.format_money(rcost)
		rb.add_theme_font_size_override("font_size", 11)
		if rem.can_renovate(i):
			_style(rb, Color(0.12, 0.16, 0.20), Color(0.35, 0.5, 0.6))
			rb.pressed.connect(func(): rem.renovate(idx))
		else:
			_style(rb, Color(0.09, 0.09, 0.13), Color(0.26, 0.26, 0.36, 0.55)); rb.disabled = true
		btns.add_child(rb)
	# Продажа
	var sval: float = maxf(0.0, rem.property_value(i) * rem.SELL_RATIO - mort)
	var sb := Button.new(); sb.text = "Продать (%s)" % gm.format_money(sval)
	sb.add_theme_font_size_override("font_size", 12)
	_style(sb, Color(0.18, 0.12, 0.10), Color(0.6, 0.4, 0.3))
	sb.pressed.connect(func(): rem.sell_property(idx))
	btns.add_child(sb)
	return card

func _buy_card(t: Dictionary) -> PanelContainer:
	var card := PanelContainer.new()
	var locked: bool = gm.current_title_index < int(t.min_title)
	var cs := StyleBoxFlat.new()
	cs.bg_color = Color(0.07, 0.09, 0.10, 0.9) if not locked else Color(0.06, 0.06, 0.08, 0.85)
	cs.border_color = Color(0.30, 0.45, 0.40, 0.7) if not locked else Color(0.22, 0.22, 0.26, 0.5)
	cs.set_border_width_all(1); cs.set_corner_radius_all(8)
	cs.set_content_margin_all(10)
	card.add_theme_stylebox_override("panel", cs)
	var row := HBoxContainer.new(); row.add_theme_constant_override("separation", 10); card.add_child(row)
	var icon := Label.new(); icon.text = t.get("icon", "🏠")
	icon.add_theme_font_size_override("font_size", 24); icon.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	row.add_child(icon)
	var col := VBoxContainer.new(); col.size_flags_horizontal = Control.SIZE_EXPAND_FILL; row.add_child(col)
	var owned: int = rem.count_of(t.id)
	var name_str: String = t.get("name", "?")
	if owned > 0: name_str += "  ×%d" % owned
	var cprice: int = rem.current_price(t.id)
	_lbl(col, name_str, Color(0.85, 0.88, 0.95), 14)
	_lbl(col, "%s · аренда +%s/день" % [t.get("desc", ""), gm.format_money(rem.current_rent(t.id))], Color(0.62, 0.68, 0.62), 11)
	if rem.is_commercial(t.id):
		var cm: float = rem.cycle_mult(t.id)
		var cyc_str: String = "аренда сейчас ×%.2f (цикл)" % cm if absf(cm - 1.0) > 0.01 else "цикличная аренда"
		var ccol: Color = Color(0.55, 0.9, 0.6) if cm > 1.01 else (Color(0.95, 0.55, 0.5) if cm < 0.99 else Color(0.6, 0.66, 0.74))
		_lbl(col, "📊 " + cyc_str, ccol, 11)
	var btns := VBoxContainer.new()
	btns.add_theme_constant_override("separation", 4)
	if locked:
		var lb := Button.new(); lb.text = "🔒 Титул %d" % int(t.min_title)
		lb.add_theme_font_size_override("font_size", 12)
		_style(lb, Color(0.09, 0.09, 0.13), Color(0.26, 0.26, 0.36, 0.55)); lb.disabled = true
		btns.add_child(lb)
	else:
		var tid: String = t.id
		# Покупка целиком
		var btn := Button.new(); btn.text = "🏠 Купить (%s)" % gm.format_money(cprice)
		btn.add_theme_font_size_override("font_size", 12)
		if gm.money >= float(cprice):
			_style(btn, Color(0.10, 0.18, 0.12), Color(0.30, 0.60, 0.35))
			btn.pressed.connect(func(): rem.buy_property(tid))
		else:
			_style(btn, Color(0.09, 0.09, 0.13), Color(0.26, 0.26, 0.36, 0.55)); btn.disabled = true
		btns.add_child(btn)
		# Покупка в ипотеку (первый взнос)
		var down: int = rem.mortgage_down_payment(t.id)
		var mb := Button.new(); mb.text = "🏦 В ипотеку (взнос %s)" % gm.format_money(down)
		mb.add_theme_font_size_override("font_size", 11)
		if rem.can_buy_mortgage(t.id):
			_style(mb, Color(0.10, 0.14, 0.22), Color(0.30, 0.45, 0.7))
			mb.pressed.connect(func(): rem.buy_property_mortgage(tid))
		else:
			_style(mb, Color(0.09, 0.09, 0.13), Color(0.26, 0.26, 0.36, 0.55)); mb.disabled = true
		btns.add_child(mb)
		# Построить (дешевле, но дольше)
		var bcost: int = rem.build_cost(t.id)
		var bb := Button.new(); bb.text = "🏗 Построить %s · %dдн" % [gm.format_money(bcost), rem.build_days(t.id)]
		bb.add_theme_font_size_override("font_size", 11)
		if rem.can_build(t.id):
			_style(bb, Color(0.16, 0.14, 0.10), Color(0.55, 0.45, 0.25))
			bb.pressed.connect(func(): rem.start_project(tid))
		else:
			_style(bb, Color(0.09, 0.09, 0.13), Color(0.26, 0.26, 0.36, 0.55)); bb.disabled = true
		btns.add_child(bb)
	row.add_child(btns)
	return card

func _project_card(i: int) -> PanelContainer:
	var p = rem.projects[i]
	var t = rem._get_type(String(p.get("type_id", "")))
	var card := PanelContainer.new()
	var cs := StyleBoxFlat.new()
	cs.bg_color = Color(0.12, 0.10, 0.05, 0.92); cs.border_color = Color(0.55, 0.45, 0.25, 0.8)
	cs.set_border_width_all(1); cs.set_corner_radius_all(8); cs.set_content_margin_all(10)
	card.add_theme_stylebox_override("panel", cs)
	var row := HBoxContainer.new(); row.add_theme_constant_override("separation", 10); card.add_child(row)
	var icon := Label.new(); icon.text = t.get("icon", "🏗")
	icon.add_theme_font_size_override("font_size", 24); icon.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	row.add_child(icon)
	var col := VBoxContainer.new(); col.size_flags_horizontal = Control.SIZE_EXPAND_FILL; row.add_child(col)
	var left: int = int(p.get("days_left", 0))
	var total: int = maxi(1, int(p.get("total_days", 1)))
	var pct: int = int(round((1.0 - float(left) / float(total)) * 100.0))
	_lbl(col, "%s — строится" % t.get("name", "?"), Color(0.95, 0.88, 0.70), 14)
	_lbl(col, "Готовность %d%% · осталось %d дн. · вложено %s" % [pct, left, gm.format_money(float(p.get("invested", 0.0)))], Color(0.80, 0.74, 0.58), 11)
	var idx: int = i
	var refund: float = float(p.get("invested", 0.0)) * rem.PROJECT_CANCEL_REFUND
	var cb := Button.new(); cb.text = "Отменить (%s)" % gm.format_money(refund)
	cb.add_theme_font_size_override("font_size", 11)
	cb.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_style(cb, Color(0.18, 0.12, 0.10), Color(0.6, 0.4, 0.3))
	cb.pressed.connect(func(): rem.cancel_project(idx))
	row.add_child(cb)
	return card

# ── helpers ───────────────────────────────────────────────────────────────────
func _title(t: String) -> void:
	var l := Label.new(); l.text = t
	l.add_theme_font_size_override("font_size", 24)
	l.add_theme_color_override("font_color", Color(1, 1, 1))
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_vb.add_child(l)

func _header(t: String) -> void:
	var s := Control.new(); s.custom_minimum_size = Vector2(0, 4); _vb.add_child(s)
	var l := Label.new(); l.text = t
	l.add_theme_font_size_override("font_size", 15)
	l.add_theme_color_override("font_color", Color(0.55, 0.85, 0.65))
	_vb.add_child(l)

func _lbl(parent: Node, t: String, c: Color, sz: int) -> Label:
	var l := Label.new(); l.text = t
	l.add_theme_font_size_override("font_size", sz)
	l.add_theme_color_override("font_color", c)
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	parent.add_child(l)
	return l

func _note(t: String) -> void:
	_lbl(_vb, t, Color(0.66, 0.78, 0.70), 13)

func _sep() -> void:
	var line := ColorRect.new()
	line.color = Color(0.3, 0.4, 0.35, 0.5)
	line.custom_minimum_size = Vector2(0, 1)
	_vb.add_child(line)

func _style(b: Button, bg: Color, border: Color) -> void:
	var sb := StyleBoxFlat.new()
	sb.bg_color = bg; sb.border_color = border
	sb.set_border_width_all(1); sb.set_corner_radius_all(8); sb.set_content_margin_all(8)
	b.add_theme_stylebox_override("normal", sb)
	var hov := sb.duplicate(); hov.bg_color = bg.lightened(0.10)
	b.add_theme_stylebox_override("hover", hov)
	b.add_theme_color_override("font_color", Color(0.9, 0.95, 0.9))
