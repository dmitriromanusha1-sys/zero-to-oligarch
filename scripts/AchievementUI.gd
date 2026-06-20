extends CanvasLayer

var _panel: Panel
var _scroll: ScrollContainer
var _list: VBoxContainer
var _am: Node

func _ready() -> void:
	layer = 8
	visible = false
	_am = get_node("/root/AchievementManager")
	_am.achievement_unlocked.connect(_on_unlocked)
	_build_ui()

func _build_ui() -> void:
	var dimmer = ColorRect.new()
	dimmer.set_anchors_preset(Control.PRESET_FULL_RECT)
	dimmer.color = Color(0, 0, 0, 0.75)
	dimmer.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(dimmer)

	_panel = Panel.new()
	_panel.set_anchors_preset(Control.PRESET_CENTER)
	_panel.position = Vector2(-320, -260)
	_panel.size     = Vector2(640, 520)
	var ps := StyleBoxFlat.new()
	ps.bg_color = Color(0.05, 0.05, 0.09, 0.97)
	ps.border_color = Color(0.55, 0.42, 0.10, 0.90)
	for side in [SIDE_LEFT, SIDE_RIGHT, SIDE_TOP, SIDE_BOTTOM]:
		ps.set_border_width(side, 2)
		ps.set_corner_radius(side, 10)
	_panel.add_theme_stylebox_override("panel", ps)
	add_child(_panel)

	var vbox = VBoxContainer.new()
	vbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	vbox.add_theme_constant_override("separation", 6)
	_panel.add_child(vbox)

	var header = HBoxContainer.new()
	vbox.add_child(header)

	var title_lbl = Label.new()
	title_lbl.text = "🏆 Достижения"
	title_lbl.add_theme_font_size_override("font_size", 22)
	title_lbl.add_theme_color_override("font_color", Color(1.0, 0.88, 0.25))
	title_lbl.add_theme_constant_override("outline_size", 3)
	title_lbl.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.70))
	title_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(title_lbl)

	var close_btn = Button.new()
	close_btn.text = "✕"
	close_btn.custom_minimum_size = Vector2(34, 34)
	close_btn.add_theme_font_size_override("font_size", 14)
	var cs := StyleBoxFlat.new()
	cs.bg_color = Color(0.22, 0.07, 0.07, 0.90)
	cs.border_color = Color(0.55, 0.18, 0.18, 0.80)
	for s in [SIDE_LEFT, SIDE_RIGHT, SIDE_TOP, SIDE_BOTTOM]:
		cs.set_border_width(s, 1)
		cs.set_corner_radius(s, 6)
	close_btn.add_theme_stylebox_override("normal", cs)
	close_btn.pressed.connect(func(): visible = false)
	header.add_child(close_btn)

	_scroll = ScrollContainer.new()
	_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(_scroll)

	_list = VBoxContainer.new()
	_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_scroll.add_child(_list)

func open() -> void:
	visible = true
	_panel.modulate.a = 0.0
	_panel.scale = Vector2(0.92, 0.92)
	var tw := create_tween()
	tw.set_parallel(true)
	tw.tween_property(_panel, "modulate:a", 1.0, 0.22)
	tw.tween_property(_panel, "scale", Vector2(1.0, 1.0), 0.22).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	_rebuild_list()

func _rebuild_list() -> void:
	for c in _list.get_children():
		c.queue_free()

	var unlocked_count: int = _am.unlocked_ids.size()
	var total: int = _am.ALL.size()

	var summary = Label.new()
	summary.text = "Открыто: %d / %d" % [unlocked_count, total]
	summary.add_theme_font_size_override("font_size", 13)
	summary.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
	_list.add_child(summary)

	for ach in _am.ALL:
		var unlocked: bool = ach.id in _am.unlocked_ids

		var card := PanelContainer.new()
		var card_style := StyleBoxFlat.new()
		if unlocked:
			card_style.bg_color = Color(0.10, 0.09, 0.04, 0.90)
			card_style.border_color = Color(0.55, 0.42, 0.10, 0.80)
		else:
			card_style.bg_color = Color(0.07, 0.07, 0.07, 0.80)
			card_style.border_color = Color(0.22, 0.22, 0.22, 0.60)
		for s in [SIDE_LEFT, SIDE_RIGHT, SIDE_TOP, SIDE_BOTTOM]:
			card_style.set_border_width(s, 1)
			card_style.set_corner_radius(s, 5)
		card_style.content_margin_left   = 8
		card_style.content_margin_right  = 8
		card_style.content_margin_top    = 5
		card_style.content_margin_bottom = 5
		card.add_theme_stylebox_override("panel", card_style)

		var row = HBoxContainer.new()
		row.add_theme_constant_override("separation", 10)
		card.add_child(row)

		var icon_lbl = Label.new()
		icon_lbl.text = ach.icon if unlocked else "🔒"
		icon_lbl.custom_minimum_size = Vector2(36, 0)
		icon_lbl.add_theme_font_size_override("font_size", 20)
		if not unlocked:
			icon_lbl.modulate = Color(0.35, 0.35, 0.35)
		row.add_child(icon_lbl)

		var info = VBoxContainer.new()
		info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(info)

		var name_lbl = Label.new()
		name_lbl.text = ach.title if unlocked else "???"
		name_lbl.add_theme_font_size_override("font_size", 14)
		name_lbl.add_theme_color_override("font_color",
			Color(1.0, 0.85, 0.2) if unlocked else Color(0.35, 0.35, 0.35))
		if unlocked:
			name_lbl.add_theme_constant_override("outline_size", 2)
			name_lbl.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.50))
		info.add_child(name_lbl)

		var desc_lbl = Label.new()
		desc_lbl.text = ach.desc if unlocked else "Выполни условие"
		desc_lbl.add_theme_font_size_override("font_size", 11)
		desc_lbl.add_theme_color_override("font_color",
			Color(0.72, 0.72, 0.65) if unlocked else Color(0.28, 0.28, 0.28))
		info.add_child(desc_lbl)

		_list.add_child(card)

# Всплывающее уведомление при получении ачивки
func _on_unlocked(ach: Dictionary) -> void:
	var sm := get_node_or_null("/root/SettingsManager")
	if sm and not sm.notify_achievements:
		return
	var popup = CanvasLayer.new()
	popup.layer = 15
	get_tree().root.add_child(popup)

	var panel = Panel.new()
	panel.position = Vector2(900, 680)
	panel.size     = Vector2(340, 72)
	var nps := StyleBoxFlat.new()
	nps.bg_color = Color(0.07, 0.06, 0.02, 0.96)
	nps.border_color = Color(0.65, 0.50, 0.10, 0.95)
	for s in [SIDE_LEFT, SIDE_RIGHT, SIDE_TOP, SIDE_BOTTOM]:
		nps.set_border_width(s, 2)
		nps.set_corner_radius(s, 8)
	nps.content_margin_left   = 10
	nps.content_margin_right  = 10
	nps.content_margin_top    = 6
	nps.content_margin_bottom = 6
	panel.add_theme_stylebox_override("panel", nps)
	popup.add_child(panel)

	var hbox = HBoxContainer.new()
	hbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	hbox.add_theme_constant_override("separation", 10)
	panel.add_child(hbox)

	var icon_lbl = Label.new()
	icon_lbl.text = ach.icon
	icon_lbl.add_theme_font_size_override("font_size", 28)
	icon_lbl.custom_minimum_size = Vector2(44, 0)
	icon_lbl.scale = Vector2(0.3, 0.3)
	hbox.add_child(icon_lbl)

	var vbox = VBoxContainer.new()
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hbox.add_child(vbox)

	var top = Label.new()
	top.text = "🏆 Достижение разблокировано!"
	top.add_theme_font_size_override("font_size", 10)
	top.add_theme_color_override("font_color", Color(1.0, 0.85, 0.2))
	top.add_theme_constant_override("outline_size", 2)
	top.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.60))
	vbox.add_child(top)

	var name_lbl = Label.new()
	name_lbl.text = ach.title
	name_lbl.add_theme_font_size_override("font_size", 15)
	name_lbl.add_theme_color_override("font_color", Color(1.0, 0.95, 0.75))
	name_lbl.add_theme_constant_override("outline_size", 2)
	name_lbl.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.60))
	vbox.add_child(name_lbl)

	var am = get_node_or_null("/root/AudioManager")
	if am: am.play_level_up()

	# Анимация: слайд вверх + pop иконки + fade out
	panel.modulate.a = 0.0
	var tween = popup.create_tween()
	tween.set_parallel(true)
	tween.tween_property(panel, "modulate:a", 1.0, 0.30)
	tween.tween_property(panel, "position:y", 600.0, 0.30).set_ease(Tween.EASE_OUT)
	tween.tween_property(icon_lbl, "scale", Vector2(1.0, 1.0), 0.38).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK).set_delay(0.25)
	tween.set_parallel(false)
	tween.tween_interval(3.2)
	tween.tween_property(panel, "modulate:a", 0.0, 0.50)
	tween.tween_callback(popup.queue_free)

	# Золотые частицы-конфетти
	for i in 10:
		var p = ColorRect.new()
		p.size = Vector2(randf_range(3.0, 7.0), randf_range(3.0, 7.0))
		p.color = Color(1.0, 0.85, 0.18, 0.92)
		p.position = Vector2(randf_range(910.0, 1210.0), randf_range(600.0, 660.0))
		popup.add_child(p)
		var sc := Vector2(randf_range(-75, 75), randf_range(-95, -10))
		var ptw := popup.create_tween()
		ptw.set_parallel(true)
		ptw.tween_property(p, "position", p.position + sc, 0.60).set_ease(Tween.EASE_OUT).set_delay(0.22)
		ptw.tween_property(p, "modulate:a", 0.0, 0.50).set_delay(0.32)
		ptw.set_parallel(false)
		ptw.tween_callback(p.queue_free)
