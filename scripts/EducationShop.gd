extends CanvasLayer

var _em: Node
var _gm: Node
var _content: VBoxContainer
var _panel: Panel
var _max_level: int = 9

func _ready() -> void:
	layer = 11
	visible = false
	_em = get_node("/root/EducationManager")
	_gm = get_node("/root/GameManager")
	_em.education_changed.connect(func(_l): if visible: _refresh())
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
	panel.position = Vector2(-300, -300)
	panel.size = Vector2(600, 600)
	var ps := StyleBoxFlat.new()
	ps.bg_color = UITheme.PANEL
	ps.border_color = UITheme.GOLD_DIM
	for side in [SIDE_LEFT, SIDE_RIGHT, SIDE_TOP, SIDE_BOTTOM]:
		ps.set_border_width(side, 2)
		ps.set_corner_radius(side, 10)
	panel.add_theme_stylebox_override("panel", ps)
	add_child(panel)

	var vbox := VBoxContainer.new()
	vbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	vbox.add_theme_constant_override("separation", 8)
	panel.add_child(vbox)

	var header := HBoxContainer.new()
	vbox.add_child(header)
	var ttl := Label.new()
	ttl.text = "🏫 Система образования"
	ttl.add_theme_font_size_override("font_size", 22)
	ttl.add_theme_color_override("font_color", Color(1.0, 0.88, 0.25))
	ttl.add_theme_constant_override("outline_size", 3)
	ttl.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.70))
	ttl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(ttl)
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
	header.add_child(cls)

	var hint := Label.new()
	hint.text = "Уровень образования — через экзамен (мини-игра). Ниже можно выучить профессию (квалификацию): она открывает должности на бирже труда и даёт бонус на всю игру."
	hint.add_theme_font_size_override("font_size", 11)
	hint.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6))
	hint.autowrap_mode = TextServer.AUTOWRAP_WORD
	vbox.add_child(hint)

	vbox.add_child(HSeparator.new())

	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(scroll)

	_content = VBoxContainer.new()
	_content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_content.add_theme_constant_override("separation", 10)
	scroll.add_child(_content)

func open(max_lv: int = 9) -> void:
	_max_level = max_lv
	visible = true
	_panel.modulate.a = 0.0
	_panel.scale = Vector2(0.92, 0.92)
	var tw := create_tween()
	tw.set_parallel(true)
	tw.tween_property(_panel, "modulate:a", 1.0, 0.22)
	tw.tween_property(_panel, "scale", Vector2(1.0, 1.0), 0.22).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	_refresh()

func _refresh() -> void:
	for c in _content.get_children():
		c.queue_free()

	# Заголовок с лимитом учреждения
	var max_lbl := Label.new()
	var max_edu: Dictionary = _em.LEVELS[_max_level]
	max_lbl.text = "Это учреждение учит до:  %s %s" % [max_edu.icon, max_edu.name]
	max_lbl.add_theme_font_size_override("font_size", 12)
	max_lbl.add_theme_color_override("font_color", Color(1.0, 0.85, 0.3))
	_content.add_child(max_lbl)

	_content.add_child(HSeparator.new())

	# Текущий уровень
	var cur_lbl := Label.new()
	cur_lbl.text = "Текущий уровень: %s %s" % [_em.get_level_icon(), _em.get_level_name()]
	cur_lbl.add_theme_font_size_override("font_size", 16)
	cur_lbl.add_theme_color_override("font_color", Color(0.3, 1.0, 0.5))
	_content.add_child(cur_lbl)

	# Зоны мини-игры для текущего уровня
	var weights: Array = _em.get_zone_weights()
	var zone_info := Label.new()
	zone_info.text = "Мини-игра:  🔴 Мимо %d%%   🟡 ОК %d%%   🟢 Хорошо %d%%   🌟 Идеал %d%%" % [
		weights[0], weights[1], weights[2], weights[3]
	]
	zone_info.add_theme_font_size_override("font_size", 11)
	zone_info.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
	_content.add_child(zone_info)

	_content.add_child(HSeparator.new())

	# Все уровни
	for i in _em.LEVELS.size():
		var lvl: Dictionary = _em.LEVELS[i]
		var is_current: bool = i == _em.level
		var is_next: bool    = i == _em.level + 1
		var is_done: bool    = i < _em.level

		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 10)
		_content.add_child(row)

		var icon_lbl := Label.new()
		icon_lbl.text = lvl.icon
		icon_lbl.add_theme_font_size_override("font_size", 22)
		icon_lbl.custom_minimum_size = Vector2(32, 32)
		row.add_child(icon_lbl)

		var info := VBoxContainer.new()
		info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(info)

		var name_lbl := Label.new()
		name_lbl.text = lvl.name
		name_lbl.add_theme_font_size_override("font_size", 15)
		if is_current:
			name_lbl.add_theme_color_override("font_color", Color(0.3, 1.0, 0.5))
		elif is_done:
			name_lbl.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5))
		info.add_child(name_lbl)

		var desc_lbl := Label.new()
		desc_lbl.text = lvl.desc
		desc_lbl.add_theme_font_size_override("font_size", 11)
		desc_lbl.add_theme_color_override("font_color", Color(0.55, 0.55, 0.55))
		info.add_child(desc_lbl)

		# Веса зон этого уровня
		var w: Array = _em.ZONE_WEIGHTS[i]
		var wlbl := Label.new()
		wlbl.text = "🔴%d%% 🟡%d%% 🟢%d%% 🌟%d%%" % [w[0], w[1], w[2], w[3]]
		wlbl.add_theme_font_size_override("font_size", 10)
		wlbl.add_theme_color_override("font_color", Color(0.5, 0.7, 0.5))
		info.add_child(wlbl)

		if is_done:
			var done_lbl := Label.new()
			done_lbl.text = "✅ Получено"
			done_lbl.add_theme_color_override("font_color", Color(0.4, 0.7, 0.4))
			row.add_child(done_lbl)
		elif is_current:
			var cur_badge := Label.new()
			cur_badge.text = "◀ Сейчас"
			cur_badge.add_theme_color_override("font_color", Color(0.3, 1.0, 0.5))
			row.add_child(cur_badge)
		elif is_next:
			if i > _max_level:
				# За пределами лимита этого учреждения
				var limit_lbl := Label.new()
				limit_lbl.text = "🏫 Нужно\nдругое место"
				limit_lbl.add_theme_font_size_override("font_size", 10)
				limit_lbl.add_theme_color_override("font_color", Color(0.6, 0.4, 0.4))
				row.add_child(limit_lbl)
			else:
				var price: int = _em.next_price()   # с учётом скидки за интеллект
				var can_afford: bool = _gm.money >= price
				var buy_btn := Button.new()
				buy_btn.text = "📝 Сдать экзамен\n%s" % _gm.format_money(price)
				buy_btn.custom_minimum_size = Vector2(100, 44)
				buy_btn.add_theme_font_size_override("font_size", 11)
				if can_afford:
					buy_btn.add_theme_color_override("font_color", Color(0.55, 0.90, 1.0))
					var bbs := StyleBoxFlat.new()
					bbs.bg_color = Color(0.06, 0.14, 0.28)
					bbs.border_color = Color(0.22, 0.45, 0.70, 0.85)
					for s in [SIDE_LEFT, SIDE_RIGHT, SIDE_TOP, SIDE_BOTTOM]:
						bbs.set_border_width(s, 1)
						bbs.set_corner_radius(s, 6)
					buy_btn.add_theme_stylebox_override("normal", bbs)
					var bbsh := bbs.duplicate() as StyleBoxFlat
					bbsh.bg_color = Color(0.09, 0.20, 0.38)
					buy_btn.add_theme_stylebox_override("hover", bbsh)
				else:
					buy_btn.disabled = true
					buy_btn.modulate = Color(0.45, 0.45, 0.45)
				buy_btn.pressed.connect(_buy)
				row.add_child(buy_btn)
		else:
			var locked_lbl := Label.new()
			locked_lbl.text = "🔒" if i <= _max_level else "🚫"
			locked_lbl.add_theme_font_size_override("font_size", 18)
			if i > _max_level:
				locked_lbl.add_theme_color_override("font_color", Color(0.5, 0.2, 0.2))
				locked_lbl.tooltip_text = "Недоступно в этом учреждении"
			row.add_child(locked_lbl)

	_build_professions()

# ── Профессии (квалификация) ──────────────────────────────────────────────────
func _build_professions() -> void:
	var pm := get_node_or_null("/root/ProfessionManager")
	if pm == null:
		return
	_content.add_child(HSeparator.new())
	var hdr := Label.new()
	hdr.text = "🧑‍🏭 Профессии (квалификация)"
	hdr.add_theme_font_size_override("font_size", 17)
	hdr.add_theme_color_override("font_color", Color(1.0, 0.85, 0.3))
	_content.add_child(hdr)

	var cur := Label.new()
	cur.text = ("Твоя профессия: %s %s" % [pm.current_icon(), pm.current_name()]) if pm.has_profession() else "Твоя профессия: 👤 не выбрана"
	cur.add_theme_font_size_override("font_size", 13)
	cur.add_theme_color_override("font_color", Color(0.7, 0.85, 0.95))
	_content.add_child(cur)

	var note := Label.new()
	note.text = "Профессия открывает профильные должности на бирже труда и даёт бонус на всю игру. Можно переучиться в любой момент."
	note.add_theme_font_size_override("font_size", 11)
	note.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6))
	note.autowrap_mode = TextServer.AUTOWRAP_WORD
	_content.add_child(note)

	for prof in pm.PROFESSIONS:
		_profession_row(pm, prof)

func _profession_row(pm: Node, prof: Dictionary) -> void:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	_content.add_child(row)

	var icon := Label.new()
	icon.text = String(prof.icon)
	icon.add_theme_font_size_override("font_size", 20)
	icon.custom_minimum_size = Vector2(30, 30)
	row.add_child(icon)

	var info := VBoxContainer.new()
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(info)
	var name_l := Label.new()
	name_l.text = String(prof.name)
	name_l.add_theme_font_size_override("font_size", 14)
	info.add_child(name_l)
	var req_edu: String = String(_em.LEVELS[int(prof.min_edu)].name)
	var sub := Label.new()
	sub.text = "%s · нужно: 🎓 %s · цена: %s" % [prof.desc, req_edu, _gm.format_money(pm.learn_cost(prof.id))]
	sub.add_theme_font_size_override("font_size", 10)
	sub.add_theme_color_override("font_color", Color(0.6, 0.6, 0.62))
	sub.autowrap_mode = TextServer.AUTOWRAP_WORD
	info.add_child(sub)
	var perk := Label.new()
	perk.text = "✨ Бонус: " + pm.perk_text(prof.id)
	perk.add_theme_font_size_override("font_size", 10)
	perk.add_theme_color_override("font_color", Color(0.55, 0.80, 0.62))
	info.add_child(perk)

	if pm.profession == prof.id:
		var cur_b := Label.new()
		cur_b.text = "✓ Текущая"
		cur_b.add_theme_color_override("font_color", Color(0.4, 1.0, 0.6))
		cur_b.add_theme_font_size_override("font_size", 13)
		row.add_child(cur_b)
	elif pm.can_learn(prof.id):
		var price: int = pm.learn_cost(prof.id)
		var can_afford: bool = _gm.money >= price
		var btn := Button.new()
		btn.text = "Выучить" if can_afford else "Нет денег"
		btn.custom_minimum_size = Vector2(110, 36)
		btn.add_theme_font_size_override("font_size", 12)
		var bs := StyleBoxFlat.new()
		bs.bg_color = Color(0.06, 0.14, 0.10) if can_afford else Color(0.12, 0.10, 0.10)
		bs.border_color = Color(0.25, 0.58, 0.30, 0.85) if can_afford else Color(0.4, 0.3, 0.3)
		for s in [SIDE_LEFT, SIDE_RIGHT, SIDE_TOP, SIDE_BOTTOM]:
			bs.set_border_width(s, 1)
			bs.set_corner_radius(s, 6)
		btn.add_theme_stylebox_override("normal", bs)
		if can_afford:
			btn.pressed.connect(_learn_profession.bind(prof.id))
		else:
			btn.disabled = true
			btn.modulate = Color(0.6, 0.6, 0.6)
		row.add_child(btn)
	else:
		var lock := Label.new()
		lock.text = "🔒"
		lock.add_theme_font_size_override("font_size", 18)
		lock.tooltip_text = "Нужно образование: " + req_edu
		row.add_child(lock)

func _learn_profession(id: String) -> void:
	var am: Node = get_node_or_null("/root/AudioManager")
	var pm := get_node_or_null("/root/ProfessionManager")
	if pm and pm.learn(id):
		if am: am.play_level_up()
		_refresh()
	else:
		if am: am.play_negative()

func _buy() -> void:
	var am: Node = get_node_or_null("/root/AudioManager")
	var next_i: int = _em.level + 1
	if next_i >= _em.LEVELS.size() or next_i > _max_level:
		if am: am.play_negative()
		return
	var price: int = _em.next_price()   # с учётом скидки за интеллект
	if _gm.money < price:
		if am: am.play_negative()
		return
	# Экзамен — запускаем викторину; уровень выдаётся только при сдаче
	var exam = get_tree().get_first_node_in_group("exam_ui")
	if exam == null:
		# Резерв: без экзамена
		if _em.buy_next():
			if am: am.play_level_up()
			_refresh()
		return
	if exam.finished.is_connected(_on_exam_done):
		exam.finished.disconnect(_on_exam_done)
	exam.finished.connect(_on_exam_done, CONNECT_ONE_SHOT)
	exam.start(_em.LEVELS[next_i].name, next_i)

func _on_exam_done(mult: float) -> void:
	var am: Node = get_node_or_null("/root/AudioManager")
	# mult >= 1.0 — экзамен сдан (тогда списывается оплата и выдаётся уровень)
	if mult >= 1.0:
		if _em.buy_next():
			if am: am.play_level_up()
			# Отличная сдача — небольшой бонус к репутации
			if mult >= 1.5:
				var rm = get_node_or_null("/root/ReputationManager")
				if rm: rm.add(3)
	else:
		if am: am.play_negative()
	if visible:
		_refresh()
