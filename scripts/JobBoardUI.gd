extends CanvasLayer
# Биржа труда — экран «Вакансии». Показывает работодателей и их должности,
# отмечая, на что игрок подходит (по профессии и образованию) и где есть места.
# Трудоустройство (занять позицию) подключается следующей фазой.

var gm: Node
var em: Node
var pm: Node
var jm: Node
var zm: Node
var _panel: PanelContainer
var _vb: VBoxContainer

func _ready() -> void:
	layer = 22
	visible = false
	add_to_group("jobboard_ui")
	_resolve()
	_build_shell()
	if jm and jm.has_signal("employment_changed"):
		jm.employment_changed.connect(func(): if visible: _rebuild())

func _resolve() -> void:
	gm = get_node_or_null("/root/GameManager")
	em = get_node_or_null("/root/EducationManager")
	pm = get_node_or_null("/root/ProfessionManager")
	jm = get_node_or_null("/root/EmploymentManager")
	zm = get_node_or_null("/root/ZoneManager")

func _build_shell() -> void:
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.55)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.gui_input.connect(func(e):
		if e is InputEventMouseButton and e.pressed: close())
	add_child(dim)

	_panel = PanelContainer.new()
	_panel.set_anchors_preset(Control.PRESET_CENTER)
	_panel.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_panel.grow_vertical = Control.GROW_DIRECTION_BOTH
	_panel.add_theme_stylebox_override("panel", UITheme.panel_box())
	add_child(_panel)

	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(540, 560)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_panel.add_child(scroll)

	_vb = VBoxContainer.new()
	_vb.add_theme_constant_override("separation", 6)
	_vb.custom_minimum_size = Vector2(520, 0)
	scroll.add_child(_vb)

func open() -> void:
	_resolve()
	_rebuild()
	visible = true
	var fit: float = UITheme.fit_scale(_panel)
	_panel.pivot_offset = _panel.size * 0.5
	_panel.modulate.a = 0.0
	_panel.scale = Vector2(fit, fit) * 0.95
	var tw := create_tween()
	tw.set_parallel(true)
	tw.tween_property(_panel, "modulate:a", 1.0, 0.15)
	tw.tween_property(_panel, "scale", Vector2(fit, fit), 0.15).set_ease(Tween.EASE_OUT)

func close() -> void:
	visible = false

func _zone_name(z: int) -> String:
	if zm and "ZONE_META" in zm and z >= 0 and z < zm.ZONE_META.size():
		return String(zm.ZONE_META[z].get("name", "Зона %d" % z))
	return "Зона %d" % z

func _why_locked(pos: Dictionary) -> String:
	var lvl: int = em.level if em else 0
	var need_edu: int = int(pos.get("min_edu", 0))
	if lvl < need_edu and em:
		return "нужно образование: " + String(em.LEVELS[need_edu].name)
	var need_prof: String = String(pos.get("prof", ""))
	if need_prof != "" and pm:
		if pm.profession != need_prof:
			return "нужна профессия: " + String(pm.data(need_prof).get("name", need_prof))
	return ""

func _rebuild() -> void:
	for c in _vb.get_children():
		c.queue_free()
	if jm == null:
		return

	_title("🧑‍💼 Биржа труда")

	# Твой статус
	var prof_txt: String = (pm.current_icon() + " " + pm.current_name()) if (pm and pm.has_profession()) else "👤 Без профессии"
	var edu_txt: String = (em.get_level_icon() + " " + em.get_level_name()) if em else ""
	_lbl(_vb, "Твоя квалификация:  %s   ·   %s" % [prof_txt, edu_txt], Color(0.82, 0.84, 0.92), 13)
	_lbl(_vb, "Подбери вакансию под себя — или выучи профессию, чтобы открыть новые.", Color(0.62, 0.64, 0.72), 11)
	_sep()

	# Текущая работа
	if jm.is_employed():
		_current_job_card()
		_sep()

	# Работодатели по возрастанию зоны
	var ids: Array = jm.employer_ids()
	ids.sort_custom(func(a, b): return int(jm.employer(a).get("zone", 0)) < int(jm.employer(b).get("zone", 0)))
	for eid in ids:
		var emp: Dictionary = jm.employer(eid)
		_header("%s %s" % [emp.get("icon", "🏢"), emp.get("name", eid)], _zone_name(int(emp.get("zone", 0))))
		var ps: Array = jm.positions(eid)
		for i in ps.size():
			_position_row(eid, i, ps[i])
		_sep()

	# Кнопка закрытия
	var close_btn := Button.new()
	close_btn.text = "Закрыть"
	close_btn.add_theme_font_size_override("font_size", 14)
	UITheme.style_button(close_btn, "ghost")
	close_btn.pressed.connect(close)
	_vb.add_child(close_btn)

func _current_job_card() -> void:
	var card := PanelContainer.new()
	card.add_theme_stylebox_override("panel", UITheme.card_box(true))
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 3)
	card.add_child(box)

	var pos: Dictionary = jm.current_position()
	_lbl(box, "💼 Сейчас работаешь: %s — %s" % [jm.current_employer_name(), pos.get("title", "")], Color(0.92, 0.90, 0.78), 14)
	var occ_txt: String = "полный день" if jm.occupancy == "full" else "полдня"
	_lbl(box, "Занятость: %s · накоплено за месяц: %s ₽ · отработано: %d дн." % [
		occ_txt, gm.format_money(jm.accrued), jm.days_worked], Color(0.66, 0.7, 0.78), 11)
	var mode_txt: String = "🎲 Авто (случайный 0.5–2.5)" if jm.work_mode == "auto" else "🎯 Активный (мини-игра)"
	_lbl(box, "Режим: %s · эффективность: ×%.2f" % [mode_txt, jm.coefficient], Color(0.7, 0.78, 0.9), 11)

	var btns := HBoxContainer.new()
	btns.add_theme_constant_override("separation", 8)
	var occ_btn := Button.new()
	occ_btn.text = "Перейти на полдня" if jm.occupancy == "full" else "Перейти на полный день"
	occ_btn.add_theme_font_size_override("font_size", 12)
	UITheme.style_button(occ_btn, "ghost")
	occ_btn.pressed.connect(func(): jm.set_occupancy("half" if jm.occupancy == "full" else "full"))
	btns.add_child(occ_btn)
	var mode_btn := Button.new()
	mode_btn.text = "Режим: 🎯 Активный" if jm.work_mode == "auto" else "Режим: 🎲 Авто"
	mode_btn.add_theme_font_size_override("font_size", 12)
	UITheme.style_button(mode_btn, "ghost")
	mode_btn.pressed.connect(func(): jm.set_work_mode("active" if jm.work_mode == "auto" else "auto"))
	btns.add_child(mode_btn)
	var quit_btn := Button.new()
	quit_btn.text = "Уволиться"
	quit_btn.add_theme_font_size_override("font_size", 12)
	UITheme.style_button(quit_btn, "danger")
	quit_btn.pressed.connect(func(): jm.quit_job())
	btns.add_child(quit_btn)
	box.add_child(btns)

	# В активном режиме — выйти на смену и показать себя в мини-игре
	if jm.work_mode == "active":
		var perform := Button.new()
		perform.text = "🎯 Отработать смену (мини-игра)"
		perform.add_theme_font_size_override("font_size", 12)
		UITheme.style_button(perform, "primary")
		perform.pressed.connect(_perform_shift)
		box.add_child(perform)

	_vb.add_child(card)

func _perform_shift() -> void:
	var mg = get_tree().get_first_node_in_group("minigame")
	if mg == null or not mg.has_method("start"):
		# Резерв без мини-игры — средний результат
		jm.perform_shift(1.0)
		return
	var title_idx: int = gm.current_title_index if gm else 0
	if mg.finished.is_connected(_on_shift_minigame):
		mg.finished.disconnect(_on_shift_minigame)
	mg.finished.connect(_on_shift_minigame, CONNECT_ONE_SHOT)
	mg.start(jm.current_position().get("title", "Смена"), minf(1.0 + title_idx * 0.08, 1.60))

func _on_shift_minigame(mult: float) -> void:
	jm.perform_shift(mult)
	if visible:
		_rebuild()

func _position_row(eid: String, idx: int, pos: Dictionary) -> void:
	var card := PanelContainer.new()
	card.add_theme_stylebox_override("panel", UITheme.card_box(true))
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 2)
	card.add_child(box)

	var qualifies: bool = jm.qualifies(pos)
	var open_slot: bool = jm.is_open(pos)
	var free: int = jm.free_slots(pos)
	var here: bool = jm.is_employed() and jm.employer_id == eid and jm.pos_index == idx

	# Заголовок: должность + оклад
	var top := HBoxContainer.new()
	var name_lbl := Label.new()
	name_lbl.text = String(pos.get("title", "Должность"))
	name_lbl.add_theme_font_size_override("font_size", 14)
	name_lbl.add_theme_color_override("font_color", Color(0.92, 0.90, 0.78))
	name_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top.add_child(name_lbl)
	var sal_lbl := Label.new()
	sal_lbl.text = "%s ₽/мес" % gm.format_money(jm.monthly_salary(pos)) if gm else ""
	sal_lbl.add_theme_font_size_override("font_size", 14)
	sal_lbl.add_theme_color_override("font_color", UITheme.GREEN)
	top.add_child(sal_lbl)
	box.add_child(top)

	# Требования
	var need_prof: String = String(pos.get("prof", ""))
	var prof_req: String = "любая профессия"
	if need_prof != "" and pm:
		prof_req = String(pm.data(need_prof).get("icon", "")) + " " + String(pm.data(need_prof).get("name", need_prof))
	var edu_req: String = String(em.LEVELS[int(pos.get("min_edu", 0))].name) if em else ""
	_lbl(box, "Требуется: %s · 🎓 %s" % [prof_req, edu_req], Color(0.64, 0.66, 0.74), 11)

	# Статус: места + подходишь ли
	var status := HBoxContainer.new()
	var slots_lbl := Label.new()
	slots_lbl.text = ("🪑 свободно %d из %d" % [free, int(pos.get("slots", 0))]) if open_slot else "🪑 мест нет"
	slots_lbl.add_theme_font_size_override("font_size", 11)
	slots_lbl.add_theme_color_override("font_color", Color(0.6, 0.7, 0.6) if open_slot else Color(0.7, 0.5, 0.5))
	slots_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	status.add_child(slots_lbl)
	var st_lbl := Label.new()
	if here:
		st_lbl.text = "💼 ты здесь работаешь"
		st_lbl.add_theme_color_override("font_color", UITheme.GOLD)
	elif qualifies and open_slot:
		st_lbl.text = "✓ Подходишь"
		st_lbl.add_theme_color_override("font_color", UITheme.GREEN)
	elif not qualifies:
		st_lbl.text = "🔒 " + _why_locked(pos)
		st_lbl.add_theme_color_override("font_color", Color(0.85, 0.6, 0.45))
	else:
		st_lbl.text = "⛔ нет мест"
		st_lbl.add_theme_color_override("font_color", Color(0.75, 0.55, 0.55))
	st_lbl.add_theme_font_size_override("font_size", 11)
	status.add_child(st_lbl)
	box.add_child(status)

	# Кнопка «Устроиться» — если подходишь, есть место и это не текущая работа
	if qualifies and open_slot and not here:
		var apply := Button.new()
		apply.text = "📄 Устроиться"
		apply.add_theme_font_size_override("font_size", 12)
		UITheme.style_button(apply, "primary")
		apply.pressed.connect(func(): jm.take_job(eid, idx, "full"))
		box.add_child(apply)

	_vb.add_child(card)

# ── Мелкие хелперы ────────────────────────────────────────────────────────────
func _title(t: String) -> void:
	var l := Label.new()
	l.text = t
	l.add_theme_font_size_override("font_size", 20)
	l.add_theme_color_override("font_color", UITheme.GOLD)
	_vb.add_child(l)

func _header(t: String, zone: String) -> void:
	var row := HBoxContainer.new()
	var l := Label.new()
	l.text = t
	l.add_theme_font_size_override("font_size", 15)
	l.add_theme_color_override("font_color", Color(0.86, 0.88, 0.96))
	l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(l)
	var z := Label.new()
	z.text = "📍 " + zone
	z.add_theme_font_size_override("font_size", 11)
	z.add_theme_color_override("font_color", Color(0.6, 0.62, 0.72))
	row.add_child(z)
	_vb.add_child(row)

func _lbl(parent: Node, t: String, col: Color, size: int) -> void:
	var l := Label.new()
	l.text = t
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", col)
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	parent.add_child(l)

func _sep() -> void:
	_vb.add_child(UITheme.gold_rule())
