extends CanvasLayer

# Выбор рабочей смены: 4/6/8/10/12 часов. Доход = ставка/час × часы × коэффициент
# мини-игры. Стоимость энергии/сытости/жажды растёт с длиной смены.

const SHIFT_HOURS := [4, 6, 8, 10, 12]

# Расход ресурсов в час (на 8-часовой смене ≈ старый баланс)
const ENERGY_PER_H := {"light": 1.25, "heavy": 2.0}
const HUNGER_PER_H := {"light": 0.5,  "heavy": 0.9}
const THIRST_PER_H := {"light": 0.6,  "heavy": 1.1}
const HEALTH_PER_H_HEAVY := 0.4

var _gm: Node
var _panel: Panel
var _list: VBoxContainer
var _on_pick: Callable

func _ready() -> void:
	layer = 20
	visible = false
	add_to_group("shift_ui")
	_gm = get_node_or_null("/root/GameManager")
	_build_ui()

# Статические расчёты стоимости смены — используются и в Building
static func energy_cost(hours: int, is_heavy: bool, housing_bonus: float) -> float:
	var per_h: float = ENERGY_PER_H["heavy"] if is_heavy else ENERGY_PER_H["light"]
	return per_h * hours * (1.0 - housing_bonus)

func open(job_name: String, hourly_rate: float, is_heavy: bool, on_pick: Callable) -> void:
	_on_pick = on_pick
	_refresh(job_name, hourly_rate, is_heavy)
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
	dimmer.color = Color(0, 0, 0, 0.70)
	dimmer.mouse_filter = Control.MOUSE_FILTER_STOP
	dimmer.gui_input.connect(func(ev):
		if ev is InputEventMouseButton and ev.pressed and ev.button_index == MOUSE_BUTTON_LEFT:
			_close())
	add_child(dimmer)

	_panel = Panel.new()
	_panel.set_anchors_preset(Control.PRESET_CENTER)
	_panel.size = Vector2(420, 440)
	_panel.position = Vector2(-210, -220)
	var ps := StyleBoxFlat.new()
	ps.bg_color = Color(0.045, 0.050, 0.090, 0.98)
	ps.border_color = Color(0.30, 0.62, 0.45, 0.90)
	ps.set_border_width_all(2); ps.set_corner_radius_all(12)
	ps.content_margin_left = 16; ps.content_margin_right = 16
	ps.content_margin_top = 14; ps.content_margin_bottom = 14
	_panel.add_theme_stylebox_override("panel", ps)
	add_child(_panel)

	_list = VBoxContainer.new()
	_list.set_anchors_preset(Control.PRESET_FULL_RECT)
	_list.add_theme_constant_override("separation", 8)
	_panel.add_child(_list)

func _refresh(job_name: String, hourly_rate: float, is_heavy: bool) -> void:
	for c in _list.get_children():
		c.queue_free()

	# Заголовок
	var hdr := HBoxContainer.new()
	_list.add_child(hdr)
	var ttl := Label.new()
	ttl.text = "🕒  " + job_name
	ttl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	ttl.add_theme_font_size_override("font_size", 17)
	ttl.add_theme_color_override("font_color", Color(0.85, 1.0, 0.88))
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

	var rate_lbl := Label.new()
	rate_lbl.text = "Ставка: %s / час   %s" % [
		_gm.format_money(hourly_rate),
		"💪 тяжёлый труд" if is_heavy else "🙂 обычная работа"]
	rate_lbl.add_theme_font_size_override("font_size", 12)
	rate_lbl.add_theme_color_override("font_color", Color(0.65, 0.70, 0.78))
	_list.add_child(rate_lbl)

	var sep := ColorRect.new()
	sep.custom_minimum_size = Vector2(0, 1)
	sep.color = Color(0.30, 0.30, 0.42, 0.6)
	_list.add_child(sep)

	var housing_bonus: float = _gm.get_housing_energy_drain_bonus() if _gm.has_method("get_housing_energy_drain_bonus") else 0.0

	for hours in SHIFT_HOURS:
		var base_pay: float = hourly_rate * hours
		var e_cost: float = energy_cost(hours, is_heavy, housing_bonus)
		var enough: bool = _gm.energy >= e_cost

		var card := PanelContainer.new()
		var card_s := StyleBoxFlat.new()
		card_s.bg_color = Color(0.08, 0.13, 0.09, 0.9) if enough else Color(0.10, 0.08, 0.08, 0.85)
		card_s.border_color = Color(0.30, 0.60, 0.35, 0.8) if enough else Color(0.45, 0.25, 0.25, 0.6)
		card_s.set_border_width_all(1); card_s.set_corner_radius_all(8)
		card_s.content_margin_left = 12; card_s.content_margin_right = 12
		card_s.content_margin_top = 8; card_s.content_margin_bottom = 8
		card.add_theme_stylebox_override("panel", card_s)
		_list.add_child(card)

		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 10)
		card.add_child(row)

		var hours_lbl := Label.new()
		hours_lbl.text = "%d ч" % hours
		hours_lbl.custom_minimum_size = Vector2(48, 0)
		hours_lbl.add_theme_font_size_override("font_size", 18)
		hours_lbl.add_theme_color_override("font_color", Color(0.90, 0.95, 1.0) if enough else Color(0.5, 0.45, 0.45))
		row.add_child(hours_lbl)

		var info := VBoxContainer.new()
		info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(info)
		var pay_lbl := Label.new()
		pay_lbl.text = "≈ +%s" % _gm.format_money(base_pay)
		pay_lbl.add_theme_font_size_override("font_size", 14)
		pay_lbl.add_theme_color_override("font_color", Color(0.65, 1.0, 0.65) if enough else Color(0.55, 0.50, 0.50))
		info.add_child(pay_lbl)
		var cost_lbl := Label.new()
		cost_lbl.text = "⚡ -%d" % int(round(e_cost))
		if is_heavy:
			cost_lbl.text += "   ❤ -%d" % int(round(HEALTH_PER_H_HEAVY * hours))
		cost_lbl.add_theme_font_size_override("font_size", 11)
		cost_lbl.add_theme_color_override("font_color", Color(0.60, 0.60, 0.68))
		info.add_child(cost_lbl)

		var go := Button.new()
		go.custom_minimum_size = Vector2(96, 36)
		go.add_theme_font_size_override("font_size", 13)
		if enough:
			go.text = "Работать"
			var bs := StyleBoxFlat.new()
			bs.bg_color = Color(0.10, 0.22, 0.12); bs.border_color = Color(0.28, 0.60, 0.30, 0.85)
			bs.set_border_width_all(1); bs.set_corner_radius_all(6)
			go.add_theme_stylebox_override("normal", bs)
			var bsh := bs.duplicate() as StyleBoxFlat
			bsh.bg_color = bs.bg_color.lightened(0.12)
			go.add_theme_stylebox_override("hover", bsh)
			go.add_theme_color_override("font_color", Color(0.70, 1.0, 0.70))
			var h: int = hours
			go.pressed.connect(func():
				_close()
				if _on_pick.is_valid(): _on_pick.call(h))
		else:
			go.text = "😴 мало сил"
			go.disabled = true
			var ds := StyleBoxFlat.new()
			ds.bg_color = Color(0.09, 0.09, 0.12); ds.border_color = Color(0.22, 0.22, 0.28, 0.6)
			ds.set_border_width_all(1); ds.set_corner_radius_all(6)
			go.add_theme_stylebox_override("disabled", ds)
			go.add_theme_color_override("font_disabled_color", Color(0.45, 0.40, 0.40))
		row.add_child(go)

	var note := Label.new()
	note.text = "Итог = ставка × часы × бонус мини-игры"
	note.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	note.add_theme_font_size_override("font_size", 10)
	note.add_theme_color_override("font_color", Color(0.45, 0.45, 0.55))
	_list.add_child(note)
