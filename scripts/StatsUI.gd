extends CanvasLayer

var _gm: Node
var _graph: Control
var _panel: Panel
var _stats_box: GridContainer
var _graph_progress: float = 1.0

func _ready() -> void:
	layer = 8
	visible = false
	_gm = get_node("/root/GameManager")
	_build_ui()

func _build_ui() -> void:
	var dimmer = ColorRect.new()
	dimmer.set_anchors_preset(Control.PRESET_FULL_RECT)
	dimmer.color = Color(0, 0, 0, 0.78)
	dimmer.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(dimmer)

	_panel = Panel.new()
	var panel: Panel = _panel
	panel.set_anchors_preset(Control.PRESET_CENTER)
	panel.position = Vector2(-380, -280)
	panel.size     = Vector2(760, 560)
	var ps := StyleBoxFlat.new()
	ps.bg_color = UITheme.PANEL
	ps.border_color = UITheme.GOLD_DIM
	for side in [SIDE_LEFT, SIDE_RIGHT, SIDE_TOP, SIDE_BOTTOM]:
		ps.set_border_width(side, 2)
		ps.set_corner_radius(side, 10)
	panel.add_theme_stylebox_override("panel", ps)
	add_child(panel)

	var vbox = VBoxContainer.new()
	vbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	vbox.add_theme_constant_override("separation", 6)
	panel.add_child(vbox)

	# Заголовок
	var header = HBoxContainer.new()
	vbox.add_child(header)
	var title_lbl = Label.new()
	title_lbl.text = "📊 Статистика"
	title_lbl.add_theme_font_size_override("font_size", 22)
	title_lbl.add_theme_color_override("font_color", Color(1.0, 0.88, 0.25))
	title_lbl.add_theme_constant_override("outline_size", 3)
	title_lbl.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.70))
	title_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(title_lbl)
	var close = Button.new()
	close.text = "✕"
	close.custom_minimum_size = Vector2(34, 34)
	close.add_theme_font_size_override("font_size", 14)
	var cs := StyleBoxFlat.new()
	cs.bg_color = Color(0.22, 0.07, 0.07, 0.90)
	cs.border_color = Color(0.55, 0.18, 0.18, 0.80)
	for s in [SIDE_LEFT, SIDE_RIGHT, SIDE_TOP, SIDE_BOTTOM]:
		cs.set_border_width(s, 1)
		cs.set_corner_radius(s, 6)
	close.add_theme_stylebox_override("normal", cs)
	close.pressed.connect(func(): visible = false)
	header.add_child(close)

	# Показатели
	_stats_box = GridContainer.new()
	_stats_box.columns = 2
	_stats_box.add_theme_constant_override("h_separation", 20)
	vbox.add_child(_stats_box)

	vbox.add_child(HSeparator.new())

	# Граф
	var graph_lbl = Label.new()
	graph_lbl.text = "📈 Рост состояния по дням:"
	graph_lbl.add_theme_font_size_override("font_size", 13)
	vbox.add_child(graph_lbl)

	_graph = Control.new()
	_graph.custom_minimum_size = Vector2(720, 180)
	_graph.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_graph.draw.connect(_draw_graph)
	vbox.add_child(_graph)

func open() -> void:
	visible = true
	_panel.modulate.a = 0.0
	_panel.scale = Vector2(0.92, 0.92)
	var tw := create_tween()
	tw.set_parallel(true)
	tw.tween_property(_panel, "modulate:a", 1.0, 0.22)
	tw.tween_property(_panel, "scale", Vector2(1.0, 1.0), 0.22).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	_refresh_stats()
	_graph_progress = 0.0
	var gtw := create_tween()
	gtw.tween_method(func(v: float) -> void:
		_graph_progress = v
		if _graph: _graph.queue_redraw()
	, 0.0, 1.0, 1.4).set_delay(0.30).set_ease(Tween.EASE_OUT)

func _refresh_stats() -> void:
	for c in _stats_box.get_children():
		c.queue_free()
	var bm  = get_node_or_null("/root/BusinessManager")
	var qm  = get_node_or_null("/root/QuestManager")
	var rm  = get_node_or_null("/root/ReputationManager")
	var am_node = get_node_or_null("/root/AchievementManager")
	var tm  = get_node_or_null("/root/TransportManager")
	var em  = get_node_or_null("/root/EducationManager")
	_stat(_stats_box, "💰 Наличные",      _gm.format_money(_gm.money))
	_stat(_stats_box, "📊 Чистые активы", _gm.format_money(_gm.get_net_worth()))
	_stat(_stats_box, "📅 Дней прожито", str(_gm.day))
	_stat(_stats_box, "🏅 Титул",        _gm.get_title())
	_stat(_stats_box, "🏠 Жильё",        _gm.get_housing())
	_stat(_stats_box, "❤ Здоровье",     "%.0f%%" % _gm.health)
	if tm:
		_stat(_stats_box, "🚗 Транспорт", tm.get_current_name())
	if em:
		_stat(_stats_box, "🎓 Образование", em.get_level_name())
	if rm:
		_stat(_stats_box, "⭐ Репутация", rm.get_level_name() + " (%d)" % rm.reputation)
	if bm:
		var biz = bm.get_business()
		_stat(_stats_box, "💼 Бизнес", biz.name if not biz.is_empty() else "Нет")
		_stat(_stats_box, "👥 Сотрудников", str(bm.employees.size()))
		_stat(_stats_box, "🏦 Вклад", _gm.format_money(bm.bank_deposit))
		_stat(_stats_box, "📈 Доход/день", _gm.format_money(bm.get_daily_income()))
	if qm:
		_stat(_stats_box, "✅ Целей выполнено", str(qm.completed_ids.size()))
	if am_node:
		_stat(_stats_box, "🏆 Достижений", "%d / %d" % [am_node.unlocked_ids.size(), am_node.ALL.size()])

func _stat(parent: Node, label: String, value: String) -> void:
	var lbl = Label.new()
	lbl.text = label
	lbl.add_theme_font_size_override("font_size", 13)
	lbl.add_theme_color_override("font_color", Color(0.60, 0.65, 0.75))
	parent.add_child(lbl)
	var val = Label.new()
	val.text = value
	val.add_theme_font_size_override("font_size", 13)
	val.add_theme_color_override("font_color", Color(1.0, 0.95, 0.70))
	val.add_theme_constant_override("outline_size", 2)
	val.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.50))
	parent.add_child(val)

func _draw_graph() -> void:
	var history: Array = _gm.money_history
	if history.size() < 2:
		_graph.draw_string(ThemeDB.fallback_font, Vector2(10, 90), "Мало данных — играй дольше!", HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color(0.5, 0.5, 0.5))
		return

	var w: float = _graph.size.x - 20
	var h: float = _graph.size.y - 20
	var pad_x: float = 10
	var pad_y: float = 10

	# Фон
	_graph.draw_rect(Rect2(pad_x, pad_y, w, h), Color(0.08, 0.08, 0.12))

	# Ось X и Y
	_graph.draw_line(Vector2(pad_x, pad_y), Vector2(pad_x, pad_y + h), Color(0.3, 0.3, 0.3))
	_graph.draw_line(Vector2(pad_x, pad_y + h), Vector2(pad_x + w, pad_y + h), Color(0.3, 0.3, 0.3))

	var max_money: float = 1.0
	for pt in history:
		if pt.money > max_money:
			max_money = pt.money

	var first_day: int = history[0].day
	var last_day: int  = history[history.size() - 1].day
	var day_range: float = max(float(last_day - first_day), 1.0)

	var draw_count: int = max(2, int(_graph_progress * history.size()))
	var prev_pt := Vector2.ZERO
	for i in draw_count:
		var pt = history[i]
		var fx: float = pad_x + (float(pt.day - first_day) / day_range) * w
		var fy: float = pad_y + h - (pt.money / max_money) * h
		var cur_pt := Vector2(fx, fy)
		if i > 0:
			_graph.draw_line(prev_pt, cur_pt, Color(0.3, 0.9, 0.4), 2.0)
		_graph.draw_circle(cur_pt, 3.0, Color(0.5, 1.0, 0.6))
		prev_pt = cur_pt

	# Метки: макс деньги и последний день
	_graph.draw_string(ThemeDB.fallback_font, Vector2(pad_x + 4, pad_y + 14), _gm.format_money(max_money), HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color(0.6, 0.9, 0.6))
	_graph.draw_string(ThemeDB.fallback_font, Vector2(pad_x + w - 30, pad_y + h + 2), "д.%d" % last_day, HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color(0.6, 0.6, 0.6))
