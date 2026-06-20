extends Control

var gm: Node
var qm: Node

var quest_vbox: VBoxContainer
var diary_vbox: VBoxContainer
var popup_layer: CanvasLayer
var popup_label: Label
var _panel: Panel
var _popup_tween: Tween = null

func _ready() -> void:
	gm = get_node("/root/GameManager")
	qm = get_node("/root/QuestManager")
	add_to_group("quest_ui")
	_build_ui()
	qm.quest_completed.connect(_on_quest_completed)
	qm.quest_added.connect(func(_q): _refresh_quests())
	qm.diary_entry_added.connect(_on_diary_entry)
	visible = false

func _build_ui() -> void:
	anchor_right = 1.0
	anchor_bottom = 1.0

	var dimmer = ColorRect.new()
	dimmer.set_anchors_preset(Control.PRESET_FULL_RECT)
	dimmer.color = Color(0, 0, 0, 0.6)
	add_child(dimmer)

	_panel = Panel.new()
	var panel: Panel = _panel
	panel.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	panel.size = Vector2(860, 560)
	panel.position = Vector2(-430, -280)
	var ps := StyleBoxFlat.new()
	ps.bg_color = Color(0.05, 0.05, 0.09, 0.97)
	ps.border_color = Color(0.20, 0.55, 0.28, 0.90)
	for side in [SIDE_LEFT, SIDE_RIGHT, SIDE_TOP, SIDE_BOTTOM]:
		ps.set_border_width(side, 2)
		ps.set_corner_radius(side, 10)
	panel.add_theme_stylebox_override("panel", ps)
	add_child(panel)

	var title = Label.new()
	title.text = "📋 Цели и дневник"
	title.position = Vector2(12, 8)
	title.add_theme_font_size_override("font_size", 20)
	title.add_theme_color_override("font_color", Color(1.0, 0.88, 0.25))
	title.add_theme_constant_override("outline_size", 3)
	title.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.70))
	panel.add_child(title)

	var close_btn = Button.new()
	close_btn.text = "✖"
	close_btn.position = Vector2(818, 8)
	close_btn.size = Vector2(34, 34)
	close_btn.add_theme_font_size_override("font_size", 14)
	var cs := StyleBoxFlat.new()
	cs.bg_color = Color(0.22, 0.07, 0.07, 0.90)
	cs.border_color = Color(0.55, 0.18, 0.18, 0.80)
	for s in [SIDE_LEFT, SIDE_RIGHT, SIDE_TOP, SIDE_BOTTOM]:
		cs.set_border_width(s, 1)
		cs.set_corner_radius(s, 6)
	close_btn.add_theme_stylebox_override("normal", cs)
	close_btn.pressed.connect(func(): visible = false)
	panel.add_child(close_btn)

	var tabs = TabContainer.new()
	tabs.position = Vector2(5, 48)
	tabs.size = Vector2(850, 505)
	panel.add_child(tabs)

	# Вкладка Цели
	var quest_scroll = ScrollContainer.new()
	quest_scroll.name = "Цели"
	quest_vbox = VBoxContainer.new()
	quest_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	quest_scroll.add_child(quest_vbox)
	tabs.add_child(quest_scroll)

	# Вкладка Дневник
	var diary_scroll = ScrollContainer.new()
	diary_scroll.name = "Дневник"
	diary_vbox = VBoxContainer.new()
	diary_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	diary_scroll.add_child(diary_vbox)
	tabs.add_child(diary_scroll)

	# Popup уведомление
	popup_layer = CanvasLayer.new()
	popup_layer.layer = 10
	popup_label = Label.new()
	popup_label.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP)
	popup_label.offset_top = 80.0
	popup_label.offset_bottom = 130.0
	popup_label.offset_left = -300.0
	popup_label.offset_right = 300.0
	popup_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	popup_label.add_theme_font_size_override("font_size", 17)
	popup_label.add_theme_color_override("font_color", Color(1.0, 0.9, 0.2))
	popup_label.add_theme_constant_override("outline_size", 4)
	popup_label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.80))
	popup_label.visible = false
	popup_layer.add_child(popup_label)
	get_tree().root.call_deferred("add_child", popup_layer)

	_refresh_quests()

func open() -> void:
	visible = true
	_panel.modulate.a = 0.0
	_panel.scale = Vector2(0.92, 0.92)
	var tw := create_tween()
	tw.set_parallel(true)
	tw.tween_property(_panel, "modulate:a", 1.0, 0.22)
	tw.tween_property(_panel, "scale", Vector2(1.0, 1.0), 0.22).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	_refresh_quests()
	_refresh_diary()

func _refresh_quests() -> void:
	if quest_vbox == null: return
	for c in quest_vbox.get_children(): c.queue_free()

	var active = qm.active_quests
	var done_count = qm.completed_ids.size()

	var prog = Label.new()
	prog.text = "✅ Выполнено: %d / %d" % [done_count, qm.ALL_QUESTS.size()]
	prog.add_theme_font_size_override("font_size", 14)
	quest_vbox.add_child(prog)
	quest_vbox.add_child(HSeparator.new())

	if active.is_empty():
		var lbl = Label.new()
		lbl.text = "Все доступные цели выполнены!"
		quest_vbox.add_child(lbl)
		return

	for q in active:
		var card = PanelContainer.new()
		var card_style := StyleBoxFlat.new()
		card_style.bg_color = Color(0.07, 0.12, 0.08, 0.92)
		card_style.border_color = Color(0.22, 0.60, 0.30, 0.85)
		for s in [SIDE_LEFT, SIDE_RIGHT, SIDE_TOP, SIDE_BOTTOM]:
			card_style.set_border_width(s, 1)
			card_style.set_corner_radius(s, 6)
		card_style.content_margin_left   = 10
		card_style.content_margin_right  = 10
		card_style.content_margin_top    = 6
		card_style.content_margin_bottom = 6
		card.add_theme_stylebox_override("panel", card_style)

		var vb = VBoxContainer.new()
		card.add_child(vb)

		var title_lbl = Label.new()
		title_lbl.text = "🎯 " + q.title
		title_lbl.add_theme_font_size_override("font_size", 15)
		title_lbl.add_theme_color_override("font_color", Color(0.95, 0.95, 0.80))
		title_lbl.add_theme_constant_override("outline_size", 2)
		title_lbl.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.60))
		vb.add_child(title_lbl)

		var desc_lbl = Label.new()
		desc_lbl.text = q.desc
		desc_lbl.add_theme_color_override("font_color", Color(0.70, 0.75, 0.70))
		vb.add_child(desc_lbl)

		var reward_lbl = Label.new()
		var reward_parts: Array = []
		if q.reward_money > 0:
			reward_parts.append("💰 +" + gm.format_money(q.reward_money))
		if q.reward_health > 0:
			reward_parts.append("❤ +%d здоровья" % q.reward_health)
		reward_lbl.text = "Награда: " + ", ".join(reward_parts) if reward_parts.size() > 0 else "Награда: слава"
		reward_lbl.add_theme_color_override("font_color", Color(0.45, 1.0, 0.55))
		reward_lbl.add_theme_font_size_override("font_size", 12)
		vb.add_child(reward_lbl)

		quest_vbox.add_child(card)

func _refresh_diary() -> void:
	if diary_vbox == null: return
	for c in diary_vbox.get_children(): c.queue_free()
	var entries = qm.diary
	for i in range(entries.size() - 1, -1, -1):
		var lbl = Label.new()
		lbl.text = entries[i]
		lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		diary_vbox.add_child(lbl)

func _on_quest_completed(q: Dictionary) -> void:
	_refresh_quests()
	var reward_parts: Array = []
	if q.reward_money > 0:
		reward_parts.append("💰 +" + gm.format_money(q.reward_money))
	if q.reward_health > 0:
		reward_parts.append("❤ +%d здоровья" % q.reward_health)
	var reward_str := ", ".join(reward_parts) if not reward_parts.is_empty() else "слава!"
	_show_popup("🎯 Цель выполнена: «" + q.title + "»!\n" + reward_str)

func _on_diary_entry(_entry: String) -> void:
	if visible: _refresh_diary()

func _show_popup(text: String) -> void:
	if _popup_tween and _popup_tween.is_valid():
		_popup_tween.kill()
	popup_label.text = text
	popup_label.modulate.a = 0.0
	popup_label.visible = true
	_popup_tween = create_tween()
	_popup_tween.tween_property(popup_label, "modulate:a", 1.0, 0.25)
	_popup_tween.tween_interval(3.5)
	_popup_tween.tween_property(popup_label, "modulate:a", 0.0, 0.40)
	await _popup_tween.finished
	popup_label.visible = false
