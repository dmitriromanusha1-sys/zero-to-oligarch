extends CanvasLayer

var _im: Node
var _gm: Node
var _am: Node
var _sm: Node
var _grid: GridContainer
var _panel: Panel
var _radio_name_lbl: Label
var _radio_vol_slider: HSlider

func _ready() -> void:
	layer = 10
	visible = false
	_im = get_node("/root/InventoryManager")
	_gm = get_node("/root/GameManager")
	_am = get_node_or_null("/root/AudioManager")
	_sm = get_node_or_null("/root/SettingsManager")
	_im.inventory_changed.connect(_refresh)
	_build_ui()

func _build_ui() -> void:
	var dimmer := ColorRect.new()
	dimmer.set_anchors_preset(Control.PRESET_FULL_RECT)
	dimmer.color = Color(0, 0, 0, 0.78)
	dimmer.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(dimmer)

	_panel = Panel.new()
	var panel: Panel = _panel
	panel.set_anchors_preset(Control.PRESET_CENTER)
	panel.position = Vector2(-280, -220)
	panel.size = Vector2(560, 440)
	var ps := StyleBoxFlat.new()
	ps.bg_color = Color(0.05, 0.05, 0.09, 0.97)
	ps.border_color = Color(0.35, 0.28, 0.55, 0.90)
	for side in [SIDE_LEFT, SIDE_RIGHT, SIDE_TOP, SIDE_BOTTOM]:
		ps.set_border_width(side, 2)
		ps.set_corner_radius(side, 10)
	panel.add_theme_stylebox_override("panel", ps)
	add_child(panel)

	var vbox := VBoxContainer.new()
	vbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	vbox.add_theme_constant_override("separation", 6)
	panel.add_child(vbox)

	var header := HBoxContainer.new()
	vbox.add_child(header)
	var title_lbl := Label.new()
	title_lbl.text = "🎒 Инвентарь"
	title_lbl.add_theme_font_size_override("font_size", 22)
	title_lbl.add_theme_color_override("font_color", Color(1.0, 0.88, 0.25))
	title_lbl.add_theme_constant_override("outline_size", 3)
	title_lbl.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.70))
	title_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(title_lbl)
	var close := Button.new()
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

	var hint := Label.new()
	hint.text = "Нажми «Использовать» чтобы применить предмет"
	hint.add_theme_font_size_override("font_size", 11)
	hint.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6))
	vbox.add_child(hint)

	vbox.add_child(HSeparator.new())

	if _am:
		_build_radio_box(vbox)
		vbox.add_child(HSeparator.new())

	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(scroll)

	_grid = GridContainer.new()
	_grid.columns = 2
	_grid.add_theme_constant_override("h_separation", 8)
	_grid.add_theme_constant_override("v_separation", 6)
	_grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(_grid)

# ── Радио ────────────────────────────────────────────────────────────────────
func _build_radio_box(parent: VBoxContainer) -> void:
	var box := PanelContainer.new()
	var bs := StyleBoxFlat.new()
	bs.bg_color     = Color(0.07, 0.06, 0.11, 0.85)
	bs.border_color = Color(0.45, 0.30, 0.55, 0.70)
	bs.set_border_width_all(1)
	bs.set_corner_radius_all(8)
	bs.content_margin_left = 10; bs.content_margin_right  = 10
	bs.content_margin_top  = 8;  bs.content_margin_bottom = 8
	box.add_theme_stylebox_override("panel", bs)
	parent.add_child(box)

	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 6)
	box.add_child(vb)

	var row1 := HBoxContainer.new()
	row1.add_theme_constant_override("separation", 8)
	vb.add_child(row1)

	var prev_btn := Button.new()
	prev_btn.text = "◀"
	prev_btn.custom_minimum_size = Vector2(32, 28)
	prev_btn.pressed.connect(func(): _cycle_station(-1))
	row1.add_child(prev_btn)

	_radio_name_lbl = Label.new()
	_radio_name_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_radio_name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_radio_name_lbl.add_theme_font_size_override("font_size", 13)
	_radio_name_lbl.add_theme_color_override("font_color", Color(1.0, 0.80, 0.95))
	row1.add_child(_radio_name_lbl)

	var next_btn := Button.new()
	next_btn.text = "▶"
	next_btn.custom_minimum_size = Vector2(32, 28)
	next_btn.pressed.connect(func(): _cycle_station(1))
	row1.add_child(next_btn)

	var row2 := HBoxContainer.new()
	row2.add_theme_constant_override("separation", 8)
	vb.add_child(row2)

	var vol_lbl := Label.new()
	vol_lbl.text = "🔊"
	vol_lbl.add_theme_font_size_override("font_size", 14)
	row2.add_child(vol_lbl)

	_radio_vol_slider = HSlider.new()
	_radio_vol_slider.min_value = 0.0; _radio_vol_slider.max_value = 1.0; _radio_vol_slider.step = 0.05
	_radio_vol_slider.value = _sm.music_vol if _sm else 1.0
	_radio_vol_slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_radio_vol_slider.value_changed.connect(func(v: float):
		if _sm: _sm.set_music_vol(v))
	row2.add_child(_radio_vol_slider)

	var shop_btn := Button.new()
	shop_btn.text = "🛒 Ещё станции"
	shop_btn.tooltip_text = "Открыть магазин радио (в Элитном районе)"
	shop_btn.add_theme_font_size_override("font_size", 10)
	shop_btn.pressed.connect(func():
		var rs = get_tree().get_first_node_in_group("radio_shop")
		if rs: visible = false; rs.open())
	vb.add_child(shop_btn)

	_refresh_radio()

func _owned_station_ids() -> Array:
	var ids: Array = []
	for st in _am.RADIO_STATIONS:
		if _am.is_station_owned(st.id): ids.append(st.id)
	return ids

func _cycle_station(dir: int) -> void:
	var ids := _owned_station_ids()
	if ids.size() <= 1: return
	var idx := ids.find(_am.current_station)
	idx = (idx + dir + ids.size()) % ids.size()
	_am.select_station(ids[idx])
	_refresh_radio()

func _refresh_radio() -> void:
	if _radio_name_lbl == null: return
	var st: Dictionary = {}
	for s in _am.RADIO_STATIONS:
		if s.id == _am.current_station: st = s
	_radio_name_lbl.text = (st.get("icon", "📻") + " " + st.get("name", "")) if not st.is_empty() else "📻 —"

func open() -> void:
	visible = true
	_panel.modulate.a = 0.0
	_panel.scale = Vector2(0.92, 0.92)
	var tw := create_tween()
	tw.set_parallel(true)
	tw.tween_property(_panel, "modulate:a", 1.0, 0.22)
	tw.tween_property(_panel, "scale", Vector2(1.0, 1.0), 0.22).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	_refresh_radio()
	_refresh()

func _refresh() -> void:
	if not visible:
		return
	for c in _grid.get_children():
		c.queue_free()

	if _im.inventory.is_empty():
		var empty_lbl := Label.new()
		empty_lbl.text = "Инвентарь пуст"
		empty_lbl.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5))
		_grid.add_child(empty_lbl)
		return

	for item_id in _im.inventory:
		var count: int = _im.inventory[item_id]
		if count <= 0:
			continue
		var item: Dictionary = _im.ITEMS[item_id]

		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 8)
		row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		_grid.add_child(row)

		var icon_lbl := Label.new()
		icon_lbl.text = item.icon
		icon_lbl.add_theme_font_size_override("font_size", 22)
		icon_lbl.custom_minimum_size = Vector2(32, 32)
		row.add_child(icon_lbl)

		var info := VBoxContainer.new()
		info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(info)

		var name_lbl := Label.new()
		name_lbl.text = item.name + " x" + str(count)
		name_lbl.add_theme_font_size_override("font_size", 14)
		info.add_child(name_lbl)

		var effect := _get_effect_text(item)
		var eff_lbl := Label.new()
		eff_lbl.text = effect
		eff_lbl.add_theme_font_size_override("font_size", 11)
		eff_lbl.add_theme_color_override("font_color", Color(0.6, 0.8, 0.6))
		info.add_child(eff_lbl)

		var use_btn := Button.new()
		use_btn.text = "Использовать"
		use_btn.custom_minimum_size = Vector2(120, 28)
		use_btn.add_theme_font_size_override("font_size", 11)
		use_btn.add_theme_color_override("font_color", Color(0.65, 1.0, 0.75))
		var ubs := StyleBoxFlat.new()
		ubs.bg_color = Color(0.07, 0.18, 0.10)
		ubs.border_color = Color(0.22, 0.55, 0.30, 0.80)
		for s in [SIDE_LEFT, SIDE_RIGHT, SIDE_TOP, SIDE_BOTTOM]:
			ubs.set_border_width(s, 1)
			ubs.set_corner_radius(s, 5)
		use_btn.add_theme_stylebox_override("normal", ubs)
		var ubsh := ubs.duplicate() as StyleBoxFlat
		ubsh.bg_color = Color(0.10, 0.24, 0.14)
		use_btn.add_theme_stylebox_override("hover", ubsh)
		var iid: String = item_id
		use_btn.pressed.connect(func(): _use(iid))
		row.add_child(use_btn)

func _get_effect_text(item: Dictionary) -> String:
	if item.get("type", "") == "meal":
		var bonus: float = item.get("drain_bonus", 0.0)
		var s := "🍽 +100  💧 +100"
		if bonus > 0.0: s += "  ⏱ -%.0f%% расход/7д." % (bonus * 100)
		return s
	var parts: Array = []
	if item.hunger > 0: parts.append("🍽 +" + str(item.hunger) + " сытость")
	if item.thirst > 0: parts.append("💧 +" + str(item.thirst) + " жажда")
	if item.health > 0: parts.append("❤ +" + str(item.health) + " здоровье")
	return "  ".join(parts)

func _use(item_id: String) -> void:
	var am: Node = get_node_or_null("/root/AudioManager")
	if am: am.play_coin()
	_spawn_use_flash(_im.ITEMS[item_id])
	_im.use_item(item_id)

func _spawn_use_flash(item: Dictionary) -> void:
	var lbl := Label.new()
	lbl.text = item.icon + " ✨"
	lbl.add_theme_font_size_override("font_size", 34)
	lbl.add_theme_constant_override("outline_size", 3)
	lbl.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.60))
	lbl.position = Vector2(490, 350)
	lbl.modulate.a = 0.0
	add_child(lbl)
	var tw := lbl.create_tween()
	tw.set_parallel(true)
	tw.tween_property(lbl, "modulate:a", 1.0, 0.12)
	tw.tween_property(lbl, "scale", Vector2(1.3, 1.3), 0.12).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	tw.tween_property(lbl, "position:y", 310.0, 0.42).set_ease(Tween.EASE_OUT)
	tw.set_parallel(false)
	tw.tween_interval(0.08)
	tw.tween_property(lbl, "modulate:a", 0.0, 0.30)
	tw.tween_callback(lbl.queue_free)
	for i in 5:
		var sp := ColorRect.new()
		sp.size = Vector2(4, 4)
		sp.color = Color(0.45, 1.0, 0.55, 0.90)
		sp.position = Vector2(randf_range(470, 560), randf_range(330, 380))
		add_child(sp)
		var sc := Vector2(randf_range(-40, 40), randf_range(-55, -10))
		var stw := sp.create_tween()
		stw.set_parallel(true)
		stw.tween_property(sp, "position", sp.position + sc, 0.42).set_ease(Tween.EASE_OUT)
		stw.tween_property(sp, "modulate:a", 0.0, 0.35).set_delay(0.10)
		stw.set_parallel(false)
		stw.tween_callback(sp.queue_free)
