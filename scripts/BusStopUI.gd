extends CanvasLayer

const FARE: float = 50.0

var _gm: Node
var _from_stop: Node
var _panel: Control
var _list: VBoxContainer
var _status_lbl: Label
var _from_lbl: Label

func _ready() -> void:
	layer = 15
	visible = false
	add_to_group("bus_stop_ui")
	_gm = get_node("/root/GameManager")
	_build_ui()

func _build_ui() -> void:
	var dimmer := ColorRect.new()
	dimmer.set_anchors_preset(Control.PRESET_FULL_RECT)
	dimmer.color = Color(0, 0, 0, 0.65)
	dimmer.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(dimmer)

	_panel = Panel.new()
	_panel.set_anchors_preset(Control.PRESET_CENTER)
	_panel.position = Vector2(-230, -210)
	_panel.size = Vector2(460, 420)
	var ps := StyleBoxFlat.new()
	ps.bg_color = UITheme.PANEL
	ps.border_color = UITheme.GOLD_DIM
	for side in [SIDE_LEFT, SIDE_RIGHT, SIDE_TOP, SIDE_BOTTOM]:
		ps.set_border_width(side, 2)
		ps.set_corner_radius(side, 10)
	_panel.add_theme_stylebox_override("panel", ps)
	add_child(_panel)

	var vbox := VBoxContainer.new()
	vbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	vbox.add_theme_constant_override("separation", 8)
	_panel.add_child(vbox)

	# Заголовок
	var hdr := HBoxContainer.new()
	vbox.add_child(hdr)

	var ttl := Label.new()
	ttl.text = "🚌 Городской автобус"
	ttl.add_theme_font_size_override("font_size", 20)
	ttl.add_theme_color_override("font_color", Color(1.0, 0.88, 0.25))
	ttl.add_theme_constant_override("outline_size", 3)
	ttl.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.70))
	ttl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hdr.add_child(ttl)

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

	# Текущая остановка
	_from_lbl = Label.new()
	_from_lbl.add_theme_font_size_override("font_size", 12)
	_from_lbl.add_theme_color_override("font_color", Color(0.7, 0.8, 1.0))
	vbox.add_child(_from_lbl)

	var fare_lbl := Label.new()
	fare_lbl.text = "Стоимость: 50 ₽ за поездку. Куда едем?"
	fare_lbl.add_theme_font_size_override("font_size", 12)
	fare_lbl.add_theme_color_override("font_color", Color(0.65, 0.65, 0.65))
	vbox.add_child(fare_lbl)

	vbox.add_child(HSeparator.new())

	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(scroll)

	_list = VBoxContainer.new()
	_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_list.add_theme_constant_override("separation", 6)
	scroll.add_child(_list)

	vbox.add_child(HSeparator.new())

	_status_lbl = Label.new()
	_status_lbl.text = ""
	_status_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_status_lbl.add_theme_font_size_override("font_size", 13)
	_status_lbl.custom_minimum_size = Vector2(0, 28)
	vbox.add_child(_status_lbl)

func open(from_stop: Node) -> void:
	_from_stop = from_stop
	_from_lbl.text = "📍 Вы на: " + from_stop.stop_name
	_status_lbl.text = ""
	_refresh_list()
	visible = true
	_panel.modulate.a = 0.0
	_panel.scale = Vector2(0.92, 0.92)
	var tw := create_tween()
	tw.set_parallel(true)
	tw.tween_property(_panel, "modulate:a", 1.0, 0.22)
	tw.tween_property(_panel, "scale", Vector2(1.0, 1.0), 0.22).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)

func _refresh_list() -> void:
	for c in _list.get_children():
		c.queue_free()

	var stops: Array = get_tree().get_nodes_in_group("bus_stop")
	# Сортируем по имени для удобства
	stops.sort_custom(func(a, b): return a.stop_name < b.stop_name)

	for stop in stops:
		if stop == _from_stop or not is_instance_valid(stop):
			continue

		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 8)
		_list.add_child(row)

		var icon_lbl := Label.new()
		icon_lbl.text = "🚌"
		icon_lbl.add_theme_font_size_override("font_size", 16)
		row.add_child(icon_lbl)

		var name_lbl := Label.new()
		name_lbl.text = stop.stop_name
		name_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		name_lbl.add_theme_font_size_override("font_size", 14)
		row.add_child(name_lbl)

		var can_afford: bool = _gm.money >= FARE
		var btn := Button.new()
		btn.text = "50 ₽ →"
		btn.custom_minimum_size = Vector2(90, 34)
		btn.add_theme_font_size_override("font_size", 13)
		btn.disabled = not can_afford

		var style := StyleBoxFlat.new()
		style.bg_color = Color(0.10, 0.24, 0.55) if can_afford else Color(0.18, 0.18, 0.22)
		style.border_color = Color(0.28, 0.52, 0.90, 0.80) if can_afford else Color(0.30, 0.30, 0.35, 0.50)
		for s in [SIDE_LEFT, SIDE_RIGHT, SIDE_TOP, SIDE_BOTTOM]:
			style.set_border_width(s, 1)
			style.set_corner_radius(s, 6)
		btn.add_theme_stylebox_override("normal", style)
		if can_afford:
			btn.add_theme_color_override("font_color", Color(0.80, 0.92, 1.0))
			var hover := style.duplicate() as StyleBoxFlat
			hover.bg_color = Color(0.15, 0.33, 0.68)
			btn.add_theme_stylebox_override("hover", hover)
		btn.pressed.connect(_travel_to.bind(stop))
		row.add_child(btn)

func _travel_to(dest_stop: Node) -> void:
	if not is_instance_valid(dest_stop):
		return
	if not _gm.spend_money(FARE):
		_status_lbl.text = "❌ Нужно 50 ₽ на проезд!"
		_status_lbl.add_theme_color_override("font_color", Color(1.0, 0.35, 0.35))
		return

	var player = get_tree().get_first_node_in_group("player")
	if player:
		player.global_position = dest_stop.global_position + Vector2(0, 35)

	var am = get_node_or_null("/root/AudioManager")
	if am: am.play_buy()

	_status_lbl.text = "✅ Приехали: " + dest_stop.stop_name
	_status_lbl.add_theme_color_override("font_color", Color(0.35, 1.0, 0.5))

	await get_tree().create_timer(0.9).timeout
	if is_instance_valid(self): visible = false
