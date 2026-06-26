extends CanvasLayer

# Выбор рабочей смены: 4/6/8/10/12 часов. Доход = ставка/час × часы × коэффициент
# мини-игры. Стоимость энергии/сытости/жажды растёт с длиной смены.

const SHIFT_HOURS := [4, 6, 8, 10, 12]

# Расход энергии/здоровья в час. ВАЖНО: должны совпадать с Building.gd
# (ENERGY_PER_H, HEALTH_PER_H_HEAVY) — это то, что реально списывается в
# _begin_shift. Еда/вода списываются через GameManager (× WORK_DRAIN_MULT).
const ENERGY_PER_H := {"light": 3.125, "heavy": 5.0}
const HEALTH_PER_H_HEAVY := 1.0

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
	dimmer.color = Color(0.02, 0.03, 0.06, 0.80)
	dimmer.mouse_filter = Control.MOUSE_FILTER_STOP
	dimmer.gui_input.connect(func(ev):
		if ev is InputEventMouseButton and ev.pressed and ev.button_index == MOUSE_BUTTON_LEFT:
			_close())
	add_child(dimmer)

	_panel = Panel.new()
	_panel.set_anchors_preset(Control.PRESET_CENTER)
	_panel.size = Vector2(440, 470)
	_panel.position = Vector2(-220, -235)
	_panel.add_theme_stylebox_override("panel", UITheme.panel_box())
	add_child(_panel)

	_list = VBoxContainer.new()
	_list.set_anchors_preset(Control.PRESET_FULL_RECT)
	_list.add_theme_constant_override("separation", 9)
	_panel.add_child(_list)

func _refresh(job_name: String, hourly_rate: float, is_heavy: bool) -> void:
	for c in _list.get_children():
		c.queue_free()

	# Заголовок
	var hdr := HBoxContainer.new()
	_list.add_child(hdr)
	var ttl := Label.new()
	ttl.text = job_name
	ttl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	ttl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	ttl.add_theme_font_override("font", UITheme.display_font())
	ttl.add_theme_font_size_override("font_size", 20)
	ttl.add_theme_color_override("font_color", UITheme.GOLD)
	hdr.add_child(ttl)
	var cls := Button.new()
	cls.text = "✕"; cls.custom_minimum_size = Vector2(34, 34)
	cls.add_theme_font_size_override("font_size", 14)
	UITheme.style_button(cls, "danger")
	cls.pressed.connect(_close)
	hdr.add_child(cls)

	_list.add_child(UITheme.gold_rule())

	var rate_lbl := Label.new()
	rate_lbl.text = "Ставка  %s / час      %s" % [
		_gm.format_money(hourly_rate),
		"💪 тяжёлый труд" if is_heavy else "🙂 обычная работа"]
	rate_lbl.add_theme_font_size_override("font_size", 12)
	rate_lbl.add_theme_color_override("font_color", UITheme.TEXT_DIM)
	_list.add_child(rate_lbl)

	var housing_bonus: float = _gm.get_housing_energy_drain_bonus() if _gm.has_method("get_housing_energy_drain_bonus") else 0.0

	for hours in SHIFT_HOURS:
		var base_pay: float = hourly_rate * hours
		var e_cost: float = energy_cost(hours, is_heavy, housing_bonus)
		var enough: bool = _gm.energy >= e_cost

		var card := PanelContainer.new()
		card.add_theme_stylebox_override("panel", UITheme.card_box(enough))
		_list.add_child(card)

		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 12)
		card.add_child(row)

		var hours_lbl := Label.new()
		hours_lbl.text = "%d ч" % hours
		hours_lbl.custom_minimum_size = Vector2(54, 0)
		hours_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		hours_lbl.add_theme_font_override("font", UITheme.display_font())
		hours_lbl.add_theme_font_size_override("font_size", 22)
		hours_lbl.add_theme_color_override("font_color", UITheme.GOLD if enough else UITheme.TEXT_DIM)
		row.add_child(hours_lbl)

		var info := VBoxContainer.new()
		info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(info)
		var pay_lbl := Label.new()
		pay_lbl.text = "≈ +%s" % _gm.format_money(base_pay)
		pay_lbl.add_theme_font_size_override("font_size", 15)
		pay_lbl.add_theme_color_override("font_color", UITheme.GREEN if enough else UITheme.TEXT_DIM)
		info.add_child(pay_lbl)
		var cost_lbl := Label.new()
		var hunger_cost: float = _gm.get_hourly_hunger_drain() * hours * _gm.WORK_DRAIN_MULT
		var thirst_cost: float = _gm.get_hourly_thirst_drain() * hours * _gm.WORK_DRAIN_MULT
		cost_lbl.text = "⚡ -%d    🍖 -%d    💧 -%d" % [
			int(round(e_cost)), int(round(hunger_cost)), int(round(thirst_cost))]
		if is_heavy:
			cost_lbl.text += "    ❤ -%d" % int(round(HEALTH_PER_H_HEAVY * hours))
		cost_lbl.add_theme_font_size_override("font_size", 11)
		cost_lbl.add_theme_color_override("font_color", UITheme.TEXT_DIM)
		info.add_child(cost_lbl)

		var go := Button.new()
		go.custom_minimum_size = Vector2(106, 38)
		go.add_theme_font_size_override("font_size", 13)
		if enough:
			go.text = "Работать"
			UITheme.style_button(go, "primary")
			var h: int = hours
			go.pressed.connect(func():
				_close()
				if _on_pick.is_valid(): _on_pick.call(h))
		else:
			go.text = "😴 мало сил"
			go.disabled = true
			UITheme.style_button(go, "ghost")
		row.add_child(go)

	_list.add_child(UITheme.gold_rule())

	var note := Label.new()
	note.text = "Итог = ставка × часы × бонус мини-игры"
	note.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	note.add_theme_font_size_override("font_size", 10)
	note.add_theme_color_override("font_color", UITheme.TEXT_DIM)
	_list.add_child(note)
