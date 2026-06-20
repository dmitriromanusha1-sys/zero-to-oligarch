extends CanvasLayer

var shown: bool = false

func _ready() -> void:
	visible = false
	get_node("/root/GameManager").title_changed.connect(_on_title_changed)

func _on_title_changed(title: String) -> void:
	if title == "Мультимиллионер" and not shown:
		shown = true
		await get_tree().create_timer(1.5).timeout
		_show()

func _show() -> void:
	visible = true

	var dimmer = ColorRect.new()
	dimmer.set_anchors_preset(Control.PRESET_FULL_RECT)
	dimmer.color = Color(0, 0, 0, 0.92)
	dimmer.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(dimmer)

	# Декоративные звёзды на фоне
	for i in 30:
		var star := Label.new()
		star.text = ["✦", "·", "★"].pick_random()
		star.position = Vector2(randf_range(20, 1240), randf_range(20, 700))
		star.add_theme_font_size_override("font_size", randi_range(8, 18))
		star.add_theme_color_override("font_color", Color(1.0, 0.88, 0.25, randf_range(0.2, 0.6)))
		add_child(star)
		var st := create_tween().set_loops()
		var sp := randf_range(0.6, 1.8)
		st.tween_property(star, "modulate:a", randf_range(0.15, 0.55), sp)
		st.tween_property(star, "modulate:a", randf_range(0.55, 1.0), sp)

	var panel = Panel.new()
	panel.set_anchors_preset(Control.PRESET_CENTER)
	panel.position = Vector2(-340, -280)
	panel.size = Vector2(680, 560)
	var ps := StyleBoxFlat.new()
	ps.bg_color = Color(0.04, 0.04, 0.07, 0.98)
	ps.border_color = Color(0.70, 0.55, 0.10, 0.95)
	for side in [SIDE_LEFT, SIDE_RIGHT, SIDE_TOP, SIDE_BOTTOM]:
		ps.set_border_width(side, 3)
		ps.set_corner_radius(side, 14)
	panel.add_theme_stylebox_override("panel", ps)
	panel.modulate.a = 0.0
	add_child(panel)

	var vbox = VBoxContainer.new()
	vbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	vbox.add_theme_constant_override("separation", 8)
	panel.add_child(vbox)

	var gm = get_node("/root/GameManager")
	var qm = get_node_or_null("/root/QuestManager")

	# Заголовок с pop-анимацией
	var crown_lbl = Label.new()
	crown_lbl.text = "👑  ПОЗДРАВЛЯЕМ!"
	crown_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	crown_lbl.add_theme_font_size_override("font_size", 38)
	crown_lbl.add_theme_color_override("font_color", Color(1.0, 0.85, 0.0))
	crown_lbl.add_theme_constant_override("outline_size", 5)
	crown_lbl.add_theme_color_override("font_outline_color", Color(0.40, 0.25, 0.00, 0.80))
	crown_lbl.scale = Vector2(0.5, 0.5)
	crown_lbl.modulate.a = 0.0
	vbox.add_child(crown_lbl)

	_add_label(vbox, "Ты прошёл путь от бомжа до мультимиллионера!", 17, Color(0.95, 0.95, 0.85))
	vbox.add_child(HSeparator.new())

	_add_label(vbox, "💰 Наличные: " + gm.format_money(gm.money), 16, Color(0.55, 1.0, 0.55))
	_add_label(vbox, "📊 Чистые активы: " + gm.format_money(gm.get_net_worth()), 16, Color(0.55, 1.0, 0.55))
	_add_label(vbox, "📅 Прожито дней: " + str(gm.day), 15, Color(0.80, 0.85, 1.0))
	_add_label(vbox, "🏠 Жильё: " + gm.get_housing(), 15, Color(0.80, 0.85, 1.0))
	if qm:
		_add_label(vbox, "✅ Целей выполнено: %d / %d" % [qm.completed_ids.size(), qm.ALL_QUESTS.size()], 15, Color(0.55, 1.0, 0.65))

	vbox.add_child(HSeparator.new())
	_add_label(vbox, "Россия твоя. Но помни — всё это очень ненадолго.", 14, Color(0.55, 0.55, 0.55))

	var btn_row = HBoxContainer.new()
	btn_row.alignment = BoxContainer.ALIGNMENT_CENTER
	btn_row.add_theme_constant_override("separation", 16)
	vbox.add_child(btn_row)

	var continue_btn = Button.new()
	continue_btn.text = "▶ Продолжать играть"
	continue_btn.custom_minimum_size = Vector2(210, 46)
	continue_btn.add_theme_font_size_override("font_size", 15)
	continue_btn.add_theme_color_override("font_color", Color(0.55, 1.0, 0.60))
	var cbs := StyleBoxFlat.new()
	cbs.bg_color = Color(0.07, 0.20, 0.09)
	cbs.border_color = Color(0.22, 0.60, 0.28, 0.90)
	for s in [SIDE_LEFT, SIDE_RIGHT, SIDE_TOP, SIDE_BOTTOM]:
		cbs.set_border_width(s, 2)
		cbs.set_corner_radius(s, 8)
	continue_btn.add_theme_stylebox_override("normal", cbs)
	continue_btn.pressed.connect(func(): visible = false)
	btn_row.add_child(continue_btn)

	var new_game_btn = Button.new()
	new_game_btn.text = "🔄 Новая игра"
	new_game_btn.custom_minimum_size = Vector2(170, 46)
	new_game_btn.add_theme_font_size_override("font_size", 15)
	new_game_btn.add_theme_color_override("font_color", Color(1.0, 0.75, 0.35))
	var nbs := StyleBoxFlat.new()
	nbs.bg_color = Color(0.18, 0.12, 0.03)
	nbs.border_color = Color(0.60, 0.40, 0.10, 0.90)
	for s in [SIDE_LEFT, SIDE_RIGHT, SIDE_TOP, SIDE_BOTTOM]:
		nbs.set_border_width(s, 2)
		nbs.set_corner_radius(s, 8)
	new_game_btn.add_theme_stylebox_override("normal", nbs)
	new_game_btn.pressed.connect(_new_game)
	btn_row.add_child(new_game_btn)

	# Анимация появления панели + pop заголовка
	var tw := create_tween()
	tw.tween_property(panel, "modulate:a", 1.0, 0.50)
	tw.set_parallel(true)
	tw.tween_property(crown_lbl, "scale", Vector2(1.0, 1.0), 0.45).set_delay(0.3).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	tw.tween_property(crown_lbl, "modulate:a", 1.0, 0.30).set_delay(0.3)

func _add_label(parent: Node, text: String, font_size: int = 14, color: Color = Color.WHITE) -> void:
	var lbl = Label.new()
	lbl.text = text
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.add_theme_font_size_override("font_size", font_size)
	lbl.add_theme_color_override("font_color", color)
	parent.add_child(lbl)

func _new_game() -> void:
	var gm = get_node("/root/GameManager")
	var lb = get_node_or_null("/root/LeaderboardManager")
	if lb: lb.try_add_entry()
	gm.reset_game()
	SceneTransition.go("res://scenes/World.tscn")
