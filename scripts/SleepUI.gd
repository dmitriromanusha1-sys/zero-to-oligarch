extends CanvasLayer

# Выбор сна: сколько часов спать. Показывает прирост энергии, расход еды/воды,
# изменение здоровья и риск кражи — всё зависит от жилья.

const SLEEP_HOURS := [2, 4, 6, 8, 10, 12]

var _gm: Node
var _panel: Panel
var _list: VBoxContainer

func _ready() -> void:
	layer = 20
	visible = false
	add_to_group("sleep_ui")
	_gm = get_node_or_null("/root/GameManager")
	_build_ui()

func open() -> void:
	_refresh()
	visible = true
	_panel.modulate.a = 0.0
	_panel.scale = Vector2(0.93, 0.93)
	var tw := create_tween()
	tw.set_parallel(true)
	tw.tween_property(_panel, "modulate:a", 1.0, 0.16)
	tw.tween_property(_panel, "scale", Vector2(1.0, 1.0), 0.18).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)

func _close() -> void:
	visible = false

func _build_ui() -> void:
	var dimmer := ColorRect.new()
	dimmer.set_anchors_preset(Control.PRESET_FULL_RECT)
	dimmer.color = Color(0, 0, 0, 0.75)
	dimmer.mouse_filter = Control.MOUSE_FILTER_STOP
	dimmer.gui_input.connect(func(ev):
		if ev is InputEventMouseButton and ev.pressed and ev.button_index == MOUSE_BUTTON_LEFT:
			_close())
	add_child(dimmer)

	_panel = Panel.new()
	_panel.set_anchors_preset(Control.PRESET_CENTER)
	_panel.size = Vector2(460, 470)
	_panel.position = Vector2(-230, -235)
	var ps := StyleBoxFlat.new()
	ps.bg_color = Color(0.04, 0.045, 0.085, 0.98)
	ps.border_color = UITheme.GOLD_DIM
	ps.set_border_width_all(2); ps.set_corner_radius_all(12)
	ps.content_margin_left = 16; ps.content_margin_right = 16
	ps.content_margin_top = 14; ps.content_margin_bottom = 14
	_panel.add_theme_stylebox_override("panel", ps)
	add_child(_panel)

	_list = VBoxContainer.new()
	_list.set_anchors_preset(Control.PRESET_FULL_RECT)
	_list.add_theme_constant_override("separation", 8)
	_panel.add_child(_list)

func _refresh() -> void:
	for c in _list.get_children():
		c.queue_free()

	var housing_name: String = _gm.get_housing()
	var e_per: float = _gm.get_sleep_energy_per_hour()
	var hp_per: float = _gm.get_sleep_health_per_hour()
	var crime: float = _gm.HOUSINGS[_gm.current_housing_index].get("crime_risk", 0.0) as float

	# Заголовок
	var hdr := HBoxContainer.new()
	_list.add_child(hdr)
	var ttl := Label.new()
	ttl.text = "😴  Сон"
	ttl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	ttl.add_theme_font_size_override("font_size", 19)
	ttl.add_theme_color_override("font_color", Color(0.80, 0.78, 1.0))
	hdr.add_child(ttl)
	var cls := Button.new()
	cls.text = "✕"; cls.custom_minimum_size = Vector2(30, 30)
	cls.add_theme_font_size_override("font_size", 13)
	cls.add_theme_color_override("font_color", Color.WHITE)
	var cs := StyleBoxFlat.new()
	cs.bg_color = Color(0.22, 0.07, 0.07); cs.border_color = Color(0.55, 0.18, 0.18)
	cs.set_border_width_all(1); cs.set_corner_radius_all(6)
	cls.add_theme_stylebox_override("normal", cs)
	cls.pressed.connect(_close)
	hdr.add_child(cls)

	var sub := Label.new()
	var safety := "🔒 безопасно" if crime <= 0.02 else ("⚠ риск кражи" if crime <= 0.2 else "🦹 опасно — могут обокрасть")
	sub.text = "%s  •  качество сна: %.0f эн/час  •  %s" % [housing_name, e_per, safety]
	sub.add_theme_font_size_override("font_size", 12)
	sub.add_theme_color_override("font_color", Color(0.65, 0.68, 0.78))
	sub.autowrap_mode = TextServer.AUTOWRAP_WORD
	_list.add_child(sub)

	# Предупреждение перед сном: при низких еде/воде сон отнимет здоровье — можно не проснуться
	if _gm.hunger <= 25.0 or _gm.thirst <= 25.0:
		var warn := Label.new()
		if _gm.hunger <= 0.0 or _gm.thirst <= 0.0:
			warn.text = "💀 Опасно спать! Голод/жажда на нуле — во сне будешь терять здоровье. Поешь и попей до сна!"
		else:
			warn.text = "⚠ Мало еды (%d) и воды (%d). Долгий сон может оставить тебя голодным и без здоровья — пополни запасы." % [int(_gm.hunger), int(_gm.thirst)]
		warn.add_theme_font_size_override("font_size", 12)
		warn.add_theme_color_override("font_color", Color(1.0, 0.55, 0.45))
		warn.autowrap_mode = TextServer.AUTOWRAP_WORD
		_list.add_child(warn)

	var sep := ColorRect.new()
	sep.custom_minimum_size = Vector2(0, 1)
	sep.color = Color(0.30, 0.30, 0.45, 0.6)
	_list.add_child(sep)

	for hours in SLEEP_HOURS:
		var e_gain: float = minf(e_per * hours, 100.0 - _gm.energy)
		# Во сне расход еды/воды вдвое меньше обычного (3/4 в час → 1.5/2)
		var hunger_cost: float = _gm.get_hourly_hunger_drain() * hours * _gm.SLEEP_DRAIN_MULT
		var thirst_cost: float = _gm.get_hourly_thirst_drain() * hours * _gm.SLEEP_DRAIN_MULT
		var hp_delta: float = hp_per * hours

		var card := PanelContainer.new()
		var card_s := StyleBoxFlat.new()
		card_s.bg_color = Color(0.08, 0.08, 0.14, 0.9)
		card_s.border_color = Color(0.35, 0.32, 0.58, 0.7)
		card_s.set_border_width_all(1); card_s.set_corner_radius_all(8)
		card_s.content_margin_left = 12; card_s.content_margin_right = 12
		card_s.content_margin_top = 7; card_s.content_margin_bottom = 7
		card.add_theme_stylebox_override("panel", card_s)
		_list.add_child(card)

		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 10)
		card.add_child(row)

		var hlbl := Label.new()
		hlbl.text = "%d ч" % hours
		hlbl.custom_minimum_size = Vector2(46, 0)
		hlbl.add_theme_font_size_override("font_size", 18)
		hlbl.add_theme_color_override("font_color", Color(0.85, 0.82, 1.0))
		row.add_child(hlbl)

		var info := VBoxContainer.new()
		info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(info)
		var e_lbl := Label.new()
		e_lbl.text = "⚡ +%d энергии" % int(round(e_gain))
		e_lbl.add_theme_font_size_override("font_size", 14)
		e_lbl.add_theme_color_override("font_color", Color(0.40, 0.85, 0.40) if e_gain > 0.5 else Color(0.6, 0.6, 0.5))
		info.add_child(e_lbl)
		var cost_lbl := Label.new()
		var hp_str := ""
		if absf(hp_delta) >= 0.5:
			hp_str = "   ❤ %+d" % int(round(hp_delta))
		cost_lbl.text = "🍖 -%d   💧 -%d%s" % [int(round(hunger_cost)), int(round(thirst_cost)), hp_str]
		cost_lbl.add_theme_font_size_override("font_size", 11)
		cost_lbl.add_theme_color_override("font_color", Color(0.62, 0.62, 0.70))
		info.add_child(cost_lbl)

		var go := Button.new()
		go.text = "Спать"
		go.custom_minimum_size = Vector2(92, 38)
		go.add_theme_font_size_override("font_size", 13)
		var bs := StyleBoxFlat.new()
		bs.bg_color = Color(0.14, 0.12, 0.28); bs.border_color = Color(0.45, 0.40, 0.75, 0.85)
		bs.set_border_width_all(1); bs.set_corner_radius_all(6)
		go.add_theme_stylebox_override("normal", bs)
		var bsh := bs.duplicate() as StyleBoxFlat
		bsh.bg_color = bs.bg_color.lightened(0.14)
		go.add_theme_stylebox_override("hover", bsh)
		go.add_theme_color_override("font_color", Color(0.85, 0.82, 1.0))
		var h: int = hours
		go.pressed.connect(func(): _do_sleep(h))
		row.add_child(go)

	var note := Label.new()
	note.text = "Энергия восстанавливается только сном. Сон тратит игровое время."
	note.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	note.add_theme_font_size_override("font_size", 10)
	note.add_theme_color_override("font_color", Color(0.45, 0.45, 0.55))
	note.autowrap_mode = TextServer.AUTOWRAP_WORD
	_list.add_child(note)

func _do_sleep(hours: int) -> void:
	var am := get_node_or_null("/root/AudioManager")
	var res: Dictionary = _gm.sleep_hours(hours)
	if am: am.play_buy()
	# Лёгкая «затемняющая» вспышка сна
	var flash := ColorRect.new()
	flash.set_anchors_preset(Control.PRESET_FULL_RECT)
	flash.color = Color(0, 0, 0, 0.0)
	flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(flash)
	var tw := flash.create_tween()
	tw.tween_property(flash, "color:a", 0.85, 0.25)
	tw.tween_property(flash, "color:a", 0.0, 0.35)
	tw.tween_callback(flash.queue_free)
	_close()
