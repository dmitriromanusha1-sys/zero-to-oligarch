extends CanvasLayer

var _tm: Node
var _gm: Node
var _panel: Panel

func _ready() -> void:
	layer = 22
	visible = false
	add_to_group("transport_shop")
	_gm = get_node("/root/GameManager")
	_tm = get_node_or_null("/root/TransportManager")
	if _tm == null:
		push_error("TransportShopUI: TransportManager не найден — перезапусти Godot")
		return
	_tm.transport_changed.connect(_on_transport_changed)
	_build_ui()

func open() -> void:
	if _tm == null:
		_tm = get_node_or_null("/root/TransportManager")
	if _tm == null:
		return
	_refresh()
	visible = true
	_panel.modulate.a = 0.0
	_panel.scale = Vector2(0.92, 0.92)
	var tw := create_tween()
	tw.set_parallel(true)
	tw.tween_property(_panel, "modulate:a", 1.0, 0.22)
	tw.tween_property(_panel, "scale", Vector2(1.0, 1.0), 0.22).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)

# ─── Построение интерфейса ────────────────────────────────────────────────────
func _build_ui() -> void:
	var dimmer := ColorRect.new()
	dimmer.set_anchors_preset(Control.PRESET_FULL_RECT)
	dimmer.color = Color(0, 0, 0, 0.72)
	dimmer.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(dimmer)

	_panel = Panel.new()
	var panel: Panel = _panel
	panel.name = "MainPanel"
	panel.set_anchors_preset(Control.PRESET_CENTER)
	panel.position = Vector2(-320, -260)
	panel.size     = Vector2(640, 520)
	var ps := StyleBoxFlat.new()
	ps.bg_color = Color(0.05, 0.05, 0.09, 0.97)
	ps.border_color = Color(0.45, 0.35, 0.12, 0.90)
	for side in [SIDE_LEFT, SIDE_RIGHT, SIDE_TOP, SIDE_BOTTOM]:
		ps.set_border_width(side, 2)
		ps.set_corner_radius(side, 10)
	panel.add_theme_stylebox_override("panel", ps)
	add_child(panel)

	var vbox := VBoxContainer.new()
	vbox.name = "Root"
	vbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	vbox.add_theme_constant_override("separation", 8)
	panel.add_child(vbox)

	# Заголовок
	var hdr := HBoxContainer.new()
	vbox.add_child(hdr)

	var title := Label.new()
	title.text = "🚗  Авторынок — Выбери транспорт"
	title.add_theme_font_size_override("font_size", 20)
	title.add_theme_color_override("font_color", Color(1.0, 0.88, 0.25))
	title.add_theme_constant_override("outline_size", 3)
	title.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.70))
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hdr.add_child(title)

	var cls := Button.new()
	cls.text = "✕"
	cls.custom_minimum_size = Vector2(34, 34)
	cls.add_theme_font_size_override("font_size", 14)
	var cs := StyleBoxFlat.new()
	cs.bg_color = Color(0.22, 0.07, 0.07, 0.90)
	cs.border_color = Color(0.55, 0.18, 0.18, 0.80)
	for s in [SIDE_LEFT, SIDE_RIGHT, SIDE_TOP, SIDE_BOTTOM]:
		cs.set_border_width(s, 1)
		cs.set_corner_radius(s, 6)
	cls.add_theme_stylebox_override("normal", cs)
	cls.pressed.connect(func(): visible = false)
	hdr.add_child(cls)

	vbox.add_child(HSeparator.new())

	# Текущий транспорт
	var cur := Label.new()
	cur.name = "CurLbl"
	cur.add_theme_font_size_override("font_size", 13)
	cur.add_theme_color_override("font_color", Color(0.7, 0.9, 1.0))
	vbox.add_child(cur)

	vbox.add_child(HSeparator.new())

	# Список транспорта (скролл)
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.custom_minimum_size = Vector2(0, 300)
	vbox.add_child(scroll)

	var list := VBoxContainer.new()
	list.name = "VehicleList"
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	list.add_theme_constant_override("separation", 6)
	scroll.add_child(list)

	# Подсказка внизу
	var hint := Label.new()
	hint.text = "Купил — твоё навсегда. Пересаживаться можно бесплатно."
	hint.add_theme_font_size_override("font_size", 11)
	hint.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5))
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(hint)

# ─── Обновление списка ────────────────────────────────────────────────────────
func _refresh() -> void:
	var panel: Panel = get_node_or_null("MainPanel")
	if panel == null:
		return

	var cur_lbl: Label = panel.get_node_or_null("Root/CurLbl")
	if cur_lbl:
		cur_lbl.text = "Сейчас: %s  |  Скорость ×%.1f" % [
			_tm.get_current_name(), _tm.get_speed_mult()
		]

	# Ищем VehicleList вне зависимости от имени ScrollContainer
	var list: VBoxContainer = null
	var root_vbox: VBoxContainer = panel.get_node_or_null("Root")
	if root_vbox:
		for child in root_vbox.get_children():
			if child is ScrollContainer:
				list = child.get_node_or_null("VehicleList")
				break
	if list == null:
		return

	for c in list.get_children():
		c.queue_free()

	var zm: Node = get_node_or_null("/root/ZoneManager")
	var cur_zone: int = zm.max_zone_reached if zm else 0

	for v in _tm.VEHICLES:
		list.add_child(_make_row(v, cur_zone))

# ─── Строка одного транспорта ─────────────────────────────────────────────────
func _make_row(v: Dictionary, cur_zone: int) -> Control:
	var owned:    bool = _tm.is_owned(v.id)
	var current:  bool = _tm.current_vehicle_id == v.id
	var zone_ok:  bool = cur_zone >= v.zone_req
	var money_ok: bool = owned or _gm.money >= v.price

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)

	# Статус-иконка
	var status := Label.new()
	if current:
		status.text = "▶"
		status.add_theme_color_override("font_color", Color(0.3, 1.0, 0.5))
	elif owned:
		status.text = "✅"
		status.add_theme_color_override("font_color", Color(0.5, 0.8, 0.5))
	elif zone_ok:
		status.text = "🔓"
	else:
		status.text = "🔒"
	status.add_theme_font_size_override("font_size", 15)
	status.custom_minimum_size = Vector2(28, 0)
	row.add_child(status)

	# Инфо: название + характеристики
	var info := VBoxContainer.new()
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	var name_lbl := Label.new()
	name_lbl.text = v.name
	name_lbl.add_theme_font_size_override("font_size", 14)
	if current:
		name_lbl.add_theme_color_override("font_color", Color(0.3, 1.0, 0.5))
	elif not zone_ok:
		name_lbl.add_theme_color_override("font_color", Color(0.40, 0.40, 0.40))
	info.add_child(name_lbl)

	var price_str: String = "Бесплатно" if v.price == 0 else _gm.format_money(v.price) + " ₽"
	var zone_str:  String = "" if v.zone_req == 0 else "  |  Зона %d+" % (v.zone_req + 1)
	var sub := Label.new()
	sub.text = "Скорость ×%.1f  |  %s%s" % [v.mult, price_str, zone_str]
	sub.add_theme_font_size_override("font_size", 11)
	sub.add_theme_color_override("font_color",
		Color(0.40, 0.40, 0.40) if not zone_ok else Color(0.62, 0.62, 0.62))
	info.add_child(sub)

	row.add_child(info)

	# Кнопка действия
	var btn := Button.new()
	btn.custom_minimum_size = Vector2(120, 36)
	btn.add_theme_font_size_override("font_size", 12)
	btn.add_theme_color_override("font_color", Color.WHITE)

	if current:
		btn.text = "✔ Текущий"
		btn.disabled = true
		_style_btn(btn, Color(0.12, 0.35, 0.15))
	elif owned:
		btn.text = "🔄 Пересесть"
		_style_btn(btn, Color(0.15, 0.35, 0.55))
		btn.pressed.connect(_on_buy.bind(v.id))
	elif not zone_ok:
		btn.text = "🔒 Зона %d" % (v.zone_req + 1)
		btn.disabled = true
		_style_btn(btn, Color(0.22, 0.22, 0.25))
	elif not money_ok:
		btn.text = "💸 Нет денег"
		btn.disabled = true
		_style_btn(btn, Color(0.30, 0.18, 0.18))
	else:
		btn.text = "🛒 Купить"
		_style_btn(btn, Color(0.15, 0.42, 0.18))
		btn.pressed.connect(_on_buy.bind(v.id))

	row.add_child(btn)
	return row

func _style_btn(btn: Button, col: Color) -> void:
	var s := StyleBoxFlat.new()
	s.bg_color = col
	s.corner_radius_top_left     = 6
	s.corner_radius_top_right    = 6
	s.corner_radius_bottom_left  = 6
	s.corner_radius_bottom_right = 6
	btn.add_theme_stylebox_override("normal", s)
	var h := s.duplicate() as StyleBoxFlat
	h.bg_color = col.lightened(0.15)
	btn.add_theme_stylebox_override("hover", h)

func _on_buy(id: String) -> void:
	_tm.buy_and_equip(id)
	_refresh()

func _on_transport_changed(_vname: String, _mult: float) -> void:
	if visible:
		_refresh()
