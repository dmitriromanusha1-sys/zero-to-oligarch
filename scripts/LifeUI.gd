extends CanvasLayer
# Экран «Жизнь»: личное измерение — возраст, этап жизни, счастье и настроение.
# Открывается кнопкой 👤 в HUD. Фаза 1 — фундамент; разделы дополняются далее.

var gm
var life
var _panel: PanelContainer
var _vb: VBoxContainer

func _ready() -> void:
	layer = 22
	visible = false
	add_to_group("life_ui")
	gm = get_node_or_null("/root/GameManager")
	life = get_node_or_null("/root/LifeManager")
	_build_shell()
	if life and life.has_signal("life_changed"):
		life.life_changed.connect(func(): if visible: _rebuild())

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
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.09, 0.08, 0.12, 0.98)
	sb.border_color = Color(0.65, 0.55, 0.80, 0.9)
	sb.set_border_width_all(2)
	sb.set_corner_radius_all(14)
	sb.set_content_margin_all(18)
	_panel.add_theme_stylebox_override("panel", sb)
	add_child(_panel)

	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(460, 520)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_panel.add_child(scroll)

	_vb = VBoxContainer.new()
	_vb.add_theme_constant_override("separation", 6)
	_vb.custom_minimum_size = Vector2(440, 0)
	scroll.add_child(_vb)

func open() -> void:
	if gm == null: gm = get_node_or_null("/root/GameManager")
	if life == null: life = get_node_or_null("/root/LifeManager")
	_rebuild()
	visible = true
	_panel.modulate.a = 0.0
	_panel.scale = Vector2(0.95, 0.95)
	var tw := create_tween()
	tw.set_parallel(true)
	tw.tween_property(_panel, "modulate:a", 1.0, 0.15)
	tw.tween_property(_panel, "scale", Vector2.ONE, 0.15).set_ease(Tween.EASE_OUT)

func close() -> void:
	visible = false

func _rebuild() -> void:
	for c in _vb.get_children():
		c.queue_free()
	if life == null or gm == null:
		return
	_title("👤 Жизнь")

	var st: Dictionary = life.life_stage()
	_lbl(_vb, "%s  %d лет  ·  %s%s" % [st.get("icon", "🌱"), life.age(), st.get("name", ""),
		("   ·   👑 Поколение %d" % life.generation) if life.generation > 1 else ""],
		Color(0.86, 0.82, 0.96), 16)
	var yl: int = life.years_left()
	var ycol: Color = Color(0.95, 0.55, 0.5) if yl <= 5 else (Color(0.9, 0.8, 0.5) if yl <= 15 else Color(0.66, 0.7, 0.78))
	_lbl(_vb, "Ожидаемая продолжительность: ~%d лет · впереди ~%d %s" % [
		int(round(life.life_expectancy())), yl, _years_word(yl)], ycol, 11)
	_lbl(_vb, "До дня рождения: %d дн." % life.days_to_birthday(), Color(0.66, 0.64, 0.76), 11)
	_sep()

	# Счастье
	_header("🙂 Настроение")
	_lbl(_vb, "Счастье: %d%%  ·  %s" % [int(round(life.happiness)), life.mood_label()], life.mood_color(), 14)
	_vb.add_child(_bar(life.happiness / 100.0, life.mood_color()))
	_lbl(_vb, "Стремится к %d%% (статус и здоровье)" % int(round(life.happiness_baseline())), Color(0.64, 0.62, 0.72), 11)
	var pm: float = life.productivity_mult()
	var pcol: Color = Color(0.55, 0.9, 0.6) if pm >= 1.0 else Color(0.95, 0.55, 0.5)
	_lbl(_vb, "Продуктивность работы: ×%.2f" % pm, pcol, 12)
	_sep()

	# Тело и форма
	_header("💪 Тело и форма")
	_lbl(_vb, "Физическая форма: %d%%" % int(round(life.fitness)), Color(0.7, 0.85, 0.95), 12)
	_vb.add_child(_bar(life.fitness / 100.0, Color(0.45, 0.7, 0.95)))
	_lbl(_vb, "Стиль / уход: %d%%" % int(round(life.style)), Color(0.9, 0.8, 0.95), 12)
	_vb.add_child(_bar(life.style / 100.0, Color(0.75, 0.55, 0.9)))
	_lbl(_vb, "Внешность: %d%%" % int(round(life.appearance())), Color(0.95, 0.82, 0.62), 12)
	_vb.add_child(_bar(life.appearance() / 100.0, Color(0.9, 0.7, 0.4)))
	_vb.add_child(_action_card("workout"))
	_vb.add_child(_action_card("groom"))
	_sep()

	# Личные навыки
	_header("🧠 Личные навыки")
	if gm.day <= life._last_dev_day:
		_lbl(_vb, "Сегодня вы уже занимались саморазвитием.", Color(0.64, 0.62, 0.72), 11)
	else:
		_lbl(_vb, "Одно занятие в день · %s" % gm.format_money(life.dev_cost()), Color(0.64, 0.62, 0.72), 11)
	for sk in life.SKILLS:
		_vb.add_child(_skill_card(sk))
	_sep()

	# Личная жизнь
	_header("❤ Личная жизнь")
	if not life.is_single():
		var nm: String = String(life.partner.get("name", "?"))
		if life.is_married():
			_lbl(_vb, "В браке с %s 💍%s" % [nm, ("  (брачный договор)" if life.has_prenup() else "")], Color(0.95, 0.78, 0.6), 14)
		else:
			_lbl(_vb, "В отношениях с %s 💞" % nm, Color(0.95, 0.7, 0.78), 14)
		var rel: float = life.relationship()
		_lbl(_vb, "Отношения: %d%% · %s" % [int(round(rel)), life.relationship_label()], Color(0.9, 0.72, 0.78), 12)
		_vb.add_child(_bar(rel / 100.0, Color(0.9, 0.45, 0.55)))
		_vb.add_child(_love_card("pdate"))
		_vb.add_child(_love_card("gift"))
		if life.is_married():
			_vb.add_child(_love_card("divorce"))
		else:
			if life.can_marry():
				_vb.add_child(_love_card("marry"))
				_vb.add_child(_love_card("marry_prenup"))
			else:
				_lbl(_vb, "Брак доступен при отношениях ≥%d%%." % int(life.MARRY_THRESHOLD), Color(0.66, 0.62, 0.7), 11)
			_vb.add_child(_love_card("breakup"))
	elif life.has_prospect():
		var interest: float = float(life.prospect.get("interest", 0.0))
		_lbl(_vb, "Встречаетесь с %s" % life.prospect.get("name", "?"), Color(0.95, 0.8, 0.85), 14)
		_lbl(_vb, "Симпатия: %d%%" % int(round(interest)), Color(0.9, 0.7, 0.78), 12)
		_vb.add_child(_bar(interest / 100.0, Color(0.9, 0.45, 0.55)))
		_vb.add_child(_love_card("date"))
		if life.can_become_couple():
			_vb.add_child(_love_card("couple"))
		_vb.add_child(_love_card("stop"))
	else:
		_lbl(_vb, "Вы одиноки. Привлекательность: %d%%" % int(round(life.dating_appeal())), Color(0.8, 0.74, 0.82), 12)
		_vb.add_child(_love_card("meet"))
	_sep()

	# Семья
	_header("👨‍👩‍👧 Семья")
	if life.child_count() > 0:
		_lbl(_vb, "Детей: %d · содержание %s/день" % [life.child_count(), gm.format_money(life.children_upkeep())], Color(0.8, 0.85, 0.78), 12)
		for i in range(life.children.size()):
			_vb.add_child(_child_card(i))
		_vb.add_child(_parenting_card("family"))
		_vb.add_child(_parenting_card("develop"))
	if life.is_single() and life.child_count() == 0:
		_lbl(_vb, "Для детей нужен партнёр.", Color(0.64, 0.62, 0.7), 11)
	elif life.child_count() >= life.MAX_CHILDREN:
		_lbl(_vb, "Большая семья — больше детей некуда.", Color(0.64, 0.62, 0.7), 11)
	elif not life.is_single():
		_vb.add_child(_family_card())
	_sep()

	# Друзья
	_header("👥 Круг общения")
	if life.friend_count() > 0:
		_lbl(_vb, "Друзей: %d · близких: %d" % [life.friend_count(), life.close_friends()], Color(0.8, 0.82, 0.9), 12)
		for f in life.friends:
			var lv: int = int(round(float(f.get("level", 0.0))))
			var fc: Color = Color(0.6, 0.85, 0.7) if lv >= 60 else Color(0.78, 0.78, 0.86)
			_lbl(_vb, "🧑 %s — %d%%%s" % [f.get("name","?"), lv, ("  ⭐ близкий" if lv >= 60 else "")], fc, 11)
		_vb.add_child(_social_card("hangout"))
	else:
		_lbl(_vb, "У вас пока нет друзей.", Color(0.66, 0.64, 0.72), 11)
	if life.friend_count() < life.MAX_FRIENDS:
		_vb.add_child(_social_card("befriend"))
	_sep()

	# Положение в обществе
	_header("🎩 Положение в обществе")
	_lbl(_vb, "Статус: %d%% · %s" % [int(round(life.social_rep)), life.social_status_label()], Color(0.92, 0.85, 0.6), 12)
	_vb.add_child(_bar(life.social_rep / 100.0, Color(0.85, 0.72, 0.4)))
	_lbl(_vb, "Стремится к %d%% (внешность, харизма, друзья, статус, семья)" % int(round(life.social_baseline())), Color(0.66, 0.64, 0.7), 11)
	_vb.add_child(_social_card("outing"))
	_sep()

	# Хобби
	_header("🎯 Хобби и увлечения")
	_lbl(_vb, "Дают +%d%% к настроению%s" % [
		int(round(min(life.hobby_happiness(), 16.0))),
		(" · содержание %s/день" % gm.format_money(life.hobby_upkeep())) if life.hobby_upkeep() > 0 else ""],
		Color(0.8, 0.82, 0.7), 12)
	for h in life.HOBBIES:
		_vb.add_child(_hobby_card(h))
	_sep()

	# Роскошь и коллекции
	_header("💎 Роскошь и коллекции")
	_lbl(_vb, "В капитале: %s · статус +%d · настроение +%d" % [
		gm.format_money(life.collectibles_value()), int(life.luxury_prestige()), int(round(min(life.luxury_happiness(), 12.0)))],
		Color(0.92, 0.82, 0.6), 12)
	for l in life.LUXURIES:
		_vb.add_child(_luxury_card(l))
	_sep()

	# Пороки
	_header("🍷 Пороки и зависимости")
	if life.avg_addiction() > 1.0:
		_lbl(_vb, "⚠ Зависимости подтачивают счастье и здоровье.", Color(0.95, 0.55, 0.5), 11)
	else:
		_lbl(_vb, "Соблазны дают радость, но затягивают. Сила воли помогает.", Color(0.7, 0.66, 0.62), 11)
	for v in life.VICES:
		_vb.add_child(_vice_card(v))
	_sep()

	# Ментальное здоровье
	_header("🧠 Ментальное здоровье")
	_lbl(_vb, "Стресс: %d%% · %s" % [int(round(life.stress)), life.mental_label()], life.mental_color(), 12)
	_vb.add_child(_bar(life.stress / 100.0, life.mental_color()))
	_lbl(_vb, "Работа и пороки растят стресс; хобби, сила воли и отдых снижают.", Color(0.64, 0.66, 0.7), 11)
	_vb.add_child(_therapy_card())
	_sep()

	# Здоровье и медицина
	_header("🏥 Здоровье и медицина")
	var tier = life.MEDICAL_TIERS[life.medical_tier]
	_lbl(_vb, "Медицина: %s · долголетие +%d лет" % [tier.get("name",""), int(tier.get("longevity",0))], Color(0.7, 0.85, 0.82), 12)
	if life.illnesses.is_empty():
		_lbl(_vb, "Активных болезней нет. Риск заболеть: %.1f%%/день." % (life.illness_risk() * 100.0), Color(0.6, 0.82, 0.66), 11)
	else:
		_lbl(_vb, "⚠ Активные болезни:", Color(0.95, 0.6, 0.55), 11)
		for id in life.illnesses:
			_vb.add_child(_illness_card(id))
	if life.medical_tier + 1 < life.MEDICAL_TIERS.size():
		_vb.add_child(_medical_card())
	_sep()

	# Завещание и наследство
	_header("📜 Завещание и наследство")
	var plan = life.ESTATE_PLANS[life.estate_planning]
	_lbl(_vb, "Состояние: %s · налог на наследство %d%%" % [
		gm.format_money(life.estate_value()), int(life.inheritance_tax_rate() * 100.0)], Color(0.9, 0.85, 0.65), 12)
	if life.child_count() == 0:
		_lbl(_vb, "Наследство передаётся детям. Заведите наследника.", Color(0.66, 0.64, 0.7), 11)
	else:
		var hi: int = life.effective_heir_index()
		var hn: String = String(life.children[hi].get("name","?")) if hi >= 0 else "—"
		var auto: String = "" if life.heir_index >= 0 else " (авто — лучший)"
		_lbl(_vb, "Наследник: %s%s · качество %d%% · получит %s" % [
			hn, auto, int(round(life.heir_quality(hi))), gm.format_money(life.heir_inheritance())], Color(0.8, 0.86, 0.78), 12)
		for i in range(life.children.size()):
			_vb.add_child(_heir_card(i))
	if life.estate_planning + 1 < life.ESTATE_PLANS.size():
		_vb.add_child(_estate_card())
	_sep()

	# Наследие и память
	_header("🏛 Наследие и память")
	_lbl(_vb, "Наследие: %d · %s · поколение %d" % [int(life.legacy), life.legacy_rank(), life.generation],
		Color(0.95, 0.85, 0.55), 14)
	_lbl(_vb, "Благотворительность:", Color(0.66, 0.7, 0.66), 11)
	for c in life.CHARITY_TIERS:
		_vb.add_child(_charity_card(c))
	_lbl(_vb, "Монументы вашего имени:", Color(0.66, 0.7, 0.66), 11)
	for p in life.LEGACY_PROJECTS:
		_vb.add_child(_project_card(p))

	var spacer := Control.new()
	spacer.custom_minimum_size = Vector2(0, 8)
	_vb.add_child(spacer)
	var close_btn := Button.new()
	close_btn.text = "Закрыть"
	close_btn.add_theme_font_size_override("font_size", 16)
	_style(close_btn, Color(0.14, 0.12, 0.18), Color(0.45, 0.4, 0.6))
	close_btn.pressed.connect(close)
	_vb.add_child(close_btn)

func _charity_card(c: Dictionary) -> PanelContainer:
	var cid: String = c.id
	var card := PanelContainer.new()
	var cs := StyleBoxFlat.new()
	cs.bg_color = Color(0.09, 0.10, 0.09, 0.92)
	cs.border_color = Color(0.45, 0.5, 0.42, 0.65)
	cs.set_border_width_all(1); cs.set_corner_radius_all(8); cs.set_content_margin_all(10)
	card.add_theme_stylebox_override("panel", cs)
	var row := HBoxContainer.new(); row.add_theme_constant_override("separation", 10); card.add_child(row)
	var col := VBoxContainer.new(); col.size_flags_horizontal = Control.SIZE_EXPAND_FILL; row.add_child(col)
	_lbl(col, "🤲 %s" % c.get("name","?"), Color(0.86, 0.9, 0.84), 14)
	_lbl(col, "+%d наследия, +статус · %s" % [int(c.legacy), gm.format_money(int(c.cost))], Color(0.66, 0.72, 0.66), 11)
	var btn := Button.new()
	btn.text = "Пожертвовать"
	btn.add_theme_font_size_override("font_size", 11)
	btn.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	if life.can_donate_charity(cid):
		_style(btn, Color(0.12, 0.16, 0.12), Color(0.35, 0.5, 0.38))
		btn.pressed.connect(func(): life.donate_charity(cid))
	else:
		_style(btn, Color(0.09, 0.09, 0.13), Color(0.26, 0.26, 0.36, 0.55)); btn.disabled = true
	row.add_child(btn)
	return card

func _project_card(p: Dictionary) -> PanelContainer:
	var pid: String = p.id
	var owned: bool = life.has_project(pid)
	var card := PanelContainer.new()
	var cs := StyleBoxFlat.new()
	cs.bg_color = Color(0.11, 0.10, 0.06, 0.92) if owned else Color(0.09, 0.08, 0.07, 0.9)
	cs.border_color = Color(0.75, 0.62, 0.32, 0.85) if owned else Color(0.42, 0.38, 0.3, 0.6)
	cs.set_border_width_all(1); cs.set_corner_radius_all(8); cs.set_content_margin_all(10)
	card.add_theme_stylebox_override("panel", cs)
	var row := HBoxContainer.new(); row.add_theme_constant_override("separation", 10); card.add_child(row)
	var col := VBoxContainer.new(); col.size_flags_horizontal = Control.SIZE_EXPAND_FILL; row.add_child(col)
	_lbl(col, "🏛 %s%s" % [p.get("name","?"), ("  ✅" if owned else "")], Color(0.95, 0.88, 0.68), 14)
	_lbl(col, "%s · +%d наследия, +статус" % [p.get("desc",""), int(p.legacy)], Color(0.74, 0.7, 0.58), 11)
	var btn := Button.new()
	btn.add_theme_font_size_override("font_size", 11)
	btn.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	if owned:
		btn.text = "Построено"
		_style(btn, Color(0.12, 0.16, 0.10), Color(0.4, 0.55, 0.3)); btn.disabled = true
	elif life.can_build_project(pid):
		btn.text = "Построить (%s)" % gm.format_money(int(p.cost))
		_style(btn, Color(0.18, 0.14, 0.08), Color(0.6, 0.48, 0.26))
		btn.pressed.connect(func(): life.build_project(pid))
	else:
		btn.text = "Построить (%s)" % gm.format_money(int(p.cost))
		_style(btn, Color(0.09, 0.09, 0.13), Color(0.26, 0.26, 0.36, 0.55)); btn.disabled = true
	row.add_child(btn)
	return card

func _heir_card(i: int) -> PanelContainer:
	var ch = life.children[i]
	var is_heir: bool = life.effective_heir_index() == i
	var card := PanelContainer.new()
	var cs := StyleBoxFlat.new()
	cs.bg_color = Color(0.10, 0.10, 0.06, 0.92) if is_heir else Color(0.08, 0.08, 0.07, 0.9)
	cs.border_color = Color(0.7, 0.6, 0.32, 0.85) if is_heir else Color(0.4, 0.38, 0.3, 0.6)
	cs.set_border_width_all(1); cs.set_corner_radius_all(8); cs.set_content_margin_all(10)
	card.add_theme_stylebox_override("panel", cs)
	var row := HBoxContainer.new(); row.add_theme_constant_override("separation", 10); card.add_child(row)
	var gi: String = "👧" if String(ch.get("gender","m")) == "f" else "👦"
	var col := VBoxContainer.new(); col.size_flags_horizontal = Control.SIZE_EXPAND_FILL; row.add_child(col)
	_lbl(col, "%s %s · качество наследника %d%%%s" % [gi, ch.get("name","?"), int(round(life.heir_quality(i))), ("  👑" if is_heir else "")], Color(0.92, 0.86, 0.7), 13)
	var idx: int = i
	var btn := Button.new()
	btn.add_theme_font_size_override("font_size", 11)
	btn.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	if life.heir_index == i:
		btn.text = "✅ Наследник"
		_style(btn, Color(0.12, 0.16, 0.10), Color(0.4, 0.55, 0.3)); btn.disabled = true
	else:
		btn.text = "Назначить"
		_style(btn, Color(0.16, 0.14, 0.08), Color(0.55, 0.46, 0.26))
		btn.pressed.connect(func(): life.set_heir(idx))
	row.add_child(btn)
	return card

func _estate_card() -> PanelContainer:
	var nxt = life.ESTATE_PLANS[life.estate_planning + 1]
	var card := PanelContainer.new()
	var cs := StyleBoxFlat.new()
	cs.bg_color = Color(0.10, 0.09, 0.06, 0.92)
	cs.border_color = Color(0.6, 0.52, 0.3, 0.7)
	cs.set_border_width_all(1); cs.set_corner_radius_all(8); cs.set_content_margin_all(10)
	card.add_theme_stylebox_override("panel", cs)
	var row := HBoxContainer.new(); row.add_theme_constant_override("separation", 10); card.add_child(row)
	var col := VBoxContainer.new(); col.size_flags_horizontal = Control.SIZE_EXPAND_FILL; row.add_child(col)
	_lbl(col, "⬆ %s" % nxt.get("name",""), Color(0.92, 0.86, 0.68), 14)
	_lbl(col, "Снизить налог на наследство до %d%%" % int(float(nxt.get("tax",0)) * 100.0), Color(0.74, 0.7, 0.58), 11)
	var btn := Button.new()
	btn.text = "Оформить (%s)" % gm.format_money(life.estate_next_cost())
	btn.add_theme_font_size_override("font_size", 11)
	btn.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	if life.can_upgrade_estate():
		_style(btn, Color(0.18, 0.14, 0.08), Color(0.6, 0.48, 0.26))
		btn.pressed.connect(func(): life.upgrade_estate())
	else:
		_style(btn, Color(0.09, 0.09, 0.13), Color(0.26, 0.26, 0.36, 0.55)); btn.disabled = true
	row.add_child(btn)
	return card

func _illness_card(id: String) -> PanelContainer:
	var d = life._illness(id)
	var card := PanelContainer.new()
	var cs := StyleBoxFlat.new()
	cs.bg_color = Color(0.13, 0.08, 0.08, 0.92)
	cs.border_color = Color(0.7, 0.4, 0.36, 0.8)
	cs.set_border_width_all(1); cs.set_corner_radius_all(8); cs.set_content_margin_all(10)
	card.add_theme_stylebox_override("panel", cs)
	var row := HBoxContainer.new(); row.add_theme_constant_override("separation", 10); card.add_child(row)
	var col := VBoxContainer.new(); col.size_flags_horizontal = Control.SIZE_EXPAND_FILL; row.add_child(col)
	_lbl(col, "🤒 %s" % d.get("name","?"), Color(0.95, 0.72, 0.68), 14)
	_lbl(col, "−%.1f здоровья/день, −%d к настроению" % [float(d.get("drain",0)), int(d.get("happy",0))], Color(0.78, 0.6, 0.58), 11)
	var btn := Button.new()
	btn.text = "Лечить (%s)" % gm.format_money(life.cure_cost(id))
	btn.add_theme_font_size_override("font_size", 11)
	btn.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	if life.can_cure(id):
		_style(btn, Color(0.10, 0.16, 0.14), Color(0.3, 0.55, 0.45))
		btn.pressed.connect(func(): life.cure(id))
	else:
		_style(btn, Color(0.09, 0.09, 0.13), Color(0.26, 0.26, 0.36, 0.55)); btn.disabled = true
	row.add_child(btn)
	return card

func _medical_card() -> PanelContainer:
	var nxt = life.MEDICAL_TIERS[life.medical_tier + 1]
	var card := PanelContainer.new()
	var cs := StyleBoxFlat.new()
	cs.bg_color = Color(0.08, 0.11, 0.12, 0.92)
	cs.border_color = Color(0.4, 0.55, 0.55, 0.7)
	cs.set_border_width_all(1); cs.set_corner_radius_all(8); cs.set_content_margin_all(10)
	card.add_theme_stylebox_override("panel", cs)
	var row := HBoxContainer.new(); row.add_theme_constant_override("separation", 10); card.add_child(row)
	var col := VBoxContainer.new(); col.size_flags_horizontal = Control.SIZE_EXPAND_FILL; row.add_child(col)
	_lbl(col, "⬆ %s" % nxt.get("name",""), Color(0.82, 0.9, 0.9), 14)
	_lbl(col, "Меньше болезней, +%d к долголетию · содержание %s/мес" % [
		int(nxt.get("longevity",0)), gm.format_money(int(nxt.get("upkeep",0)))], Color(0.66, 0.72, 0.74), 11)
	var btn := Button.new()
	btn.text = "Подключить (%s)" % gm.format_money(life.medical_next_cost())
	btn.add_theme_font_size_override("font_size", 11)
	btn.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	if life.can_upgrade_medical():
		_style(btn, Color(0.10, 0.16, 0.18), Color(0.3, 0.5, 0.55))
		btn.pressed.connect(func(): life.upgrade_medical())
	else:
		_style(btn, Color(0.09, 0.09, 0.13), Color(0.26, 0.26, 0.36, 0.55)); btn.disabled = true
	row.add_child(btn)
	return card

func _therapy_card() -> PanelContainer:
	var card := PanelContainer.new()
	var cs := StyleBoxFlat.new()
	cs.bg_color = Color(0.08, 0.11, 0.12, 0.92)
	cs.border_color = Color(0.4, 0.55, 0.55, 0.7)
	cs.set_border_width_all(1); cs.set_corner_radius_all(8); cs.set_content_margin_all(10)
	card.add_theme_stylebox_override("panel", cs)
	var row := HBoxContainer.new(); row.add_theme_constant_override("separation", 10); card.add_child(row)
	var col := VBoxContainer.new(); col.size_flags_horizontal = Control.SIZE_EXPAND_FILL; row.add_child(col)
	_lbl(col, "🛋 Сеанс терапии", Color(0.82, 0.9, 0.9), 14)
	_lbl(col, "Снижает стресс на %d%% · %s" % [int(life.THERAPY_RELIEF), gm.format_money(life.therapy_cost())], Color(0.66, 0.72, 0.74), 11)
	var btn := Button.new()
	btn.add_theme_font_size_override("font_size", 12)
	btn.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	if gm.day <= life._last_therapy_day:
		btn.text = "✅ Сегодня"
		_style(btn, Color(0.12, 0.16, 0.10), Color(0.4, 0.55, 0.3)); btn.disabled = true
	elif life.can_therapy():
		btn.text = "На сеанс"
		_style(btn, Color(0.10, 0.16, 0.18), Color(0.3, 0.5, 0.55))
		btn.pressed.connect(func(): life.therapy())
	else:
		btn.text = "Нет денег"
		_style(btn, Color(0.09, 0.09, 0.13), Color(0.26, 0.26, 0.36, 0.55)); btn.disabled = true
	row.add_child(btn)
	return card

func _vice_card(v: Dictionary) -> PanelContainer:
	var vid: String = v.id
	var addiction: float = life.vice_addiction(vid)
	var card := PanelContainer.new()
	var cs := StyleBoxFlat.new()
	cs.bg_color = Color(0.12, 0.08, 0.08, 0.92)
	cs.border_color = Color(0.7, 0.4, 0.35, 0.8) if addiction >= 50.0 else Color(0.45, 0.36, 0.34, 0.65)
	cs.set_border_width_all(1); cs.set_corner_radius_all(8); cs.set_content_margin_all(10)
	card.add_theme_stylebox_override("panel", cs)
	var top := HBoxContainer.new(); top.add_theme_constant_override("separation", 10)
	var outer := VBoxContainer.new(); outer.add_theme_constant_override("separation", 4); card.add_child(outer)
	outer.add_child(top)
	var icon := Label.new(); icon.text = v.get("icon", "🍷")
	icon.add_theme_font_size_override("font_size", 22); icon.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	top.add_child(icon)
	var col := VBoxContainer.new(); col.size_flags_horizontal = Control.SIZE_EXPAND_FILL; top.add_child(col)
	var acol: Color = Color(0.95, 0.55, 0.5) if addiction >= 50.0 else (Color(0.9, 0.78, 0.45) if addiction >= 20.0 else Color(0.7, 0.72, 0.7))
	_lbl(col, "%s · зависимость %d%%" % [v.get("name","?"), int(round(addiction))], acol, 14)
	_lbl(col, v.get("desc",""), Color(0.7, 0.62, 0.6), 11)
	# Кнопки
	var btns := HBoxContainer.new(); btns.add_theme_constant_override("separation", 6); outer.add_child(btns)
	var ib := Button.new()
	ib.text = "Поддаться (%s)" % gm.format_money(life.vice_cost(vid))
	ib.add_theme_font_size_override("font_size", 11)
	ib.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	if life.can_indulge(vid):
		_style(ib, Color(0.18, 0.11, 0.11), Color(0.55, 0.35, 0.32))
		ib.pressed.connect(func(): life.indulge(vid))
	else:
		_style(ib, Color(0.09, 0.09, 0.13), Color(0.26, 0.26, 0.36, 0.55)); ib.disabled = true
	btns.add_child(ib)
	if addiction > 0.0:
		var rb := Button.new()
		rb.text = "Лечиться (%s)" % gm.format_money(life.rehab_cost())
		rb.add_theme_font_size_override("font_size", 11)
		rb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		if life.can_rehab(vid):
			_style(rb, Color(0.10, 0.16, 0.14), Color(0.3, 0.55, 0.45))
			rb.pressed.connect(func(): life.rehab(vid))
		else:
			_style(rb, Color(0.09, 0.09, 0.13), Color(0.26, 0.26, 0.36, 0.55)); rb.disabled = true
		btns.add_child(rb)
	return card

func _luxury_card(l: Dictionary) -> PanelContainer:
	var lid: String = l.id
	var owned: bool = life.owns_luxury(lid)
	var locked: bool = gm.current_title_index < int(l.min_title)
	var card := PanelContainer.new()
	var cs := StyleBoxFlat.new()
	cs.bg_color = Color(0.12, 0.10, 0.07, 0.92) if owned else Color(0.09, 0.08, 0.07, 0.9)
	cs.border_color = Color(0.7, 0.58, 0.32, 0.85) if owned else Color(0.4, 0.36, 0.28, 0.6)
	cs.set_border_width_all(1); cs.set_corner_radius_all(8); cs.set_content_margin_all(10)
	card.add_theme_stylebox_override("panel", cs)
	var row := HBoxContainer.new(); row.add_theme_constant_override("separation", 10); card.add_child(row)
	var icon := Label.new(); icon.text = l.get("icon", "💎")
	icon.add_theme_font_size_override("font_size", 22); icon.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	row.add_child(icon)
	var col := VBoxContainer.new(); col.size_flags_horizontal = Control.SIZE_EXPAND_FILL; row.add_child(col)
	_lbl(col, "%s%s" % [l.get("name","?"), ("  ✅" if owned else "")], Color(0.95, 0.88, 0.7), 14)
	_lbl(col, "%s · статус +%d · настроение +%d" % [l.get("desc",""), int(l.prestige), int(l.happy)], Color(0.74, 0.68, 0.56), 11)
	var btn := Button.new()
	btn.add_theme_font_size_override("font_size", 12)
	btn.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	if owned:
		btn.text = "В коллекции"
		_style(btn, Color(0.12, 0.16, 0.10), Color(0.4, 0.55, 0.3)); btn.disabled = true
	elif locked:
		btn.text = "🔒 Титул %d" % int(l.min_title)
		_style(btn, Color(0.09, 0.09, 0.13), Color(0.26, 0.26, 0.36, 0.55)); btn.disabled = true
	elif life.can_buy_luxury(lid):
		btn.text = "Купить (%s)" % gm.format_money(int(l.cost))
		_style(btn, Color(0.18, 0.14, 0.08), Color(0.6, 0.48, 0.26))
		btn.pressed.connect(func(): life.buy_luxury(lid))
	else:
		btn.text = "Купить (%s)" % gm.format_money(int(l.cost))
		_style(btn, Color(0.09, 0.09, 0.13), Color(0.26, 0.26, 0.36, 0.55)); btn.disabled = true
	row.add_child(btn)
	return card

func _hobby_card(h: Dictionary) -> PanelContainer:
	var hid: String = h.id
	var owned: bool = life.has_hobby(hid)
	var card := PanelContainer.new()
	var cs := StyleBoxFlat.new()
	cs.bg_color = Color(0.08, 0.11, 0.09, 0.92)
	cs.border_color = Color(0.4, 0.55, 0.42, 0.8) if owned else Color(0.34, 0.4, 0.35, 0.6)
	cs.set_border_width_all(1); cs.set_corner_radius_all(8); cs.set_content_margin_all(10)
	card.add_theme_stylebox_override("panel", cs)
	var row := HBoxContainer.new(); row.add_theme_constant_override("separation", 10); card.add_child(row)
	var icon := Label.new(); icon.text = h.get("icon", "🎯")
	icon.add_theme_font_size_override("font_size", 22); icon.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	row.add_child(icon)
	var col := VBoxContainer.new(); col.size_flags_horizontal = Control.SIZE_EXPAND_FILL; row.add_child(col)
	var extra: String = ""
	if String(h.get("stat","")) != "": extra = " · растит %s" % _stat_ru(String(h.stat))
	if int(h.get("upkeep",0)) > 0: extra += " · содержание"
	_lbl(col, "%s  (+%d наст.%s)" % [h.get("name","?"), int(h.happy), extra], Color(0.85, 0.9, 0.84), 14)
	_lbl(col, h.get("desc",""), Color(0.64, 0.72, 0.66), 11)
	var btn := Button.new()
	btn.add_theme_font_size_override("font_size", 12)
	btn.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	if owned:
		btn.text = "✅ Увлечение"
		_style(btn, Color(0.12, 0.16, 0.10), Color(0.4, 0.55, 0.3)); btn.disabled = true
	elif life.can_take_hobby(hid):
		btn.text = "Заняться (%s)" % gm.format_money(gm.shop_price(int(h.cost)))
		_style(btn, Color(0.12, 0.18, 0.13), Color(0.35, 0.55, 0.4))
		btn.pressed.connect(func(): life.take_hobby(hid))
	else:
		btn.text = "Заняться (%s)" % gm.format_money(gm.shop_price(int(h.cost)))
		_style(btn, Color(0.09, 0.09, 0.13), Color(0.26, 0.26, 0.36, 0.55)); btn.disabled = true
	row.add_child(btn)
	return card

func _stat_ru(st: String) -> String:
	match st:
		"intellect": return "интеллект"
		"charisma": return "харизму"
		"willpower": return "силу воли"
		"fitness": return "форму"
	return st

func _social_card(kind: String) -> PanelContainer:
	var card := PanelContainer.new()
	var cs := StyleBoxFlat.new()
	cs.bg_color = Color(0.08, 0.10, 0.13, 0.92)
	cs.border_color = Color(0.4, 0.45, 0.58, 0.7)
	cs.set_border_width_all(1); cs.set_corner_radius_all(8); cs.set_content_margin_all(10)
	card.add_theme_stylebox_override("panel", cs)
	var row := HBoxContainer.new(); row.add_theme_constant_override("separation", 10); card.add_child(row)
	var col := VBoxContainer.new(); col.size_flags_horizontal = Control.SIZE_EXPAND_FILL; row.add_child(col)
	if kind == "hangout":
		_lbl(col, "🍻 Встретиться с друзьями", Color(0.85, 0.88, 0.95), 14)
		_lbl(col, "Укрепляет дружбу и настроение · %s" % gm.format_money(life.hangout_cost()), Color(0.66, 0.68, 0.78), 11)
	elif kind == "befriend":
		_lbl(col, "🤝 Завести друга", Color(0.85, 0.88, 0.95), 14)
		_lbl(col, "Новое знакомство (харизма помогает) · %s" % gm.format_money(life.friend_meet_cost()), Color(0.66, 0.68, 0.78), 11)
	else:
		_lbl(col, "🥂 Светский выход", Color(0.92, 0.85, 0.6), 14)
		_lbl(col, "Поднять положение в обществе · %s" % gm.format_money(life.social_outing_cost()), Color(0.78, 0.72, 0.6), 11)
	var btn := Button.new()
	btn.add_theme_font_size_override("font_size", 12)
	btn.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var ok: bool
	var done: bool = false
	if kind == "hangout":
		ok = life.can_hangout(); done = gm.day <= life._last_hangout_day
	elif kind == "befriend":
		ok = life.can_make_friend()
	else:
		ok = life.can_social_outing(); done = gm.day <= life._last_social_day
	if done:
		btn.text = "✅ Сегодня"
		_style(btn, Color(0.12, 0.16, 0.10), Color(0.4, 0.55, 0.3)); btn.disabled = true
	elif ok:
		btn.text = {"hangout":"Встретиться", "befriend":"Познакомиться", "outing":"Выйти в свет"}[kind]
		_style(btn, Color(0.12, 0.15, 0.22), Color(0.35, 0.45, 0.62))
		match kind:
			"hangout": btn.pressed.connect(func(): life.hangout())
			"befriend": btn.pressed.connect(func(): life.make_friend())
			"outing": btn.pressed.connect(func(): life.social_outing())
	else:
		btn.text = "Нет денег"
		_style(btn, Color(0.09, 0.09, 0.13), Color(0.26, 0.26, 0.36, 0.55)); btn.disabled = true
	row.add_child(btn)
	return card

func _child_card(i: int) -> PanelContainer:
	var ch = life.children[i]
	var gi: String = "👧" if String(ch.get("gender","m")) == "f" else "👦"
	var card := PanelContainer.new()
	var cs := StyleBoxFlat.new()
	cs.bg_color = Color(0.07, 0.10, 0.12, 0.92)
	cs.border_color = Color(0.38, 0.5, 0.55, 0.7)
	cs.set_border_width_all(1); cs.set_corner_radius_all(8); cs.set_content_margin_all(10)
	card.add_theme_stylebox_override("panel", cs)
	var row := HBoxContainer.new(); row.add_theme_constant_override("separation", 10); card.add_child(row)
	var col := VBoxContainer.new(); col.size_flags_horizontal = Control.SIZE_EXPAND_FILL; row.add_child(col)
	_lbl(col, "%s %s · %d лет" % [gi, ch.get("name","?"), life.child_age(i)], Color(0.86, 0.9, 0.94), 14)
	_lbl(col, "Связь %d%% · воспитание %d%% · образование %d%%" % [
		int(round(life.child_bond(i))), int(round(life.child_upbringing(i))), int(round(life.child_education(i)))],
		Color(0.68, 0.74, 0.8), 11)
	var ns = life.next_edu_stage(i)
	var idx: int = i
	if not ns.is_empty():
		var btn := Button.new()
		btn.add_theme_font_size_override("font_size", 11)
		btn.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		if life.can_enroll_child(i):
			btn.text = "%s (%s)" % [ns.get("name",""), gm.format_money(life.edu_stage_cost(i))]
			_style(btn, Color(0.12, 0.16, 0.20), Color(0.35, 0.5, 0.6))
			btn.pressed.connect(func(): life.enroll_child(idx))
		elif life.child_age(i) < int(ns.min_age):
			btn.text = "🔒 с %d лет" % int(ns.min_age)
			_style(btn, Color(0.09, 0.09, 0.13), Color(0.26, 0.26, 0.36, 0.55)); btn.disabled = true
		else:
			btn.text = "%s (%s)" % [ns.get("name",""), gm.format_money(life.edu_stage_cost(i))]
			_style(btn, Color(0.09, 0.09, 0.13), Color(0.26, 0.26, 0.36, 0.55)); btn.disabled = true
		row.add_child(btn)
	else:
		_lbl(col, "🎓 Образование завершено", Color(0.6, 0.82, 0.66), 11)
	return card

func _parenting_card(kind: String) -> PanelContainer:
	var is_fam: bool = kind == "family"
	var card := PanelContainer.new()
	var cs := StyleBoxFlat.new()
	cs.bg_color = Color(0.08, 0.11, 0.10, 0.92)
	cs.border_color = Color(0.4, 0.55, 0.45, 0.7)
	cs.set_border_width_all(1); cs.set_corner_radius_all(8); cs.set_content_margin_all(10)
	card.add_theme_stylebox_override("panel", cs)
	var row := HBoxContainer.new(); row.add_theme_constant_override("separation", 10); card.add_child(row)
	var col := VBoxContainer.new(); col.size_flags_horizontal = Control.SIZE_EXPAND_FILL; row.add_child(col)
	if is_fam:
		_lbl(col, "👪 Время с семьёй", Color(0.85, 0.92, 0.85), 14)
		_lbl(col, "Бесплатно · укрепляет связь и настроение", Color(0.66, 0.74, 0.68), 11)
	else:
		_lbl(col, "🎨 Развивающие занятия", Color(0.85, 0.92, 0.85), 14)
		_lbl(col, "Растят воспитание детей · %s" % gm.format_money(life.develop_cost()), Color(0.66, 0.74, 0.68), 11)
	var btn := Button.new()
	btn.add_theme_font_size_override("font_size", 12)
	btn.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var ok: bool = life.can_family_time() if is_fam else life.can_develop_children()
	var done: bool = (gm.day <= life._last_family_day) if is_fam else (gm.day <= life._last_develop_day)
	if done:
		btn.text = "✅ Сегодня"
		_style(btn, Color(0.12, 0.16, 0.10), Color(0.4, 0.55, 0.3)); btn.disabled = true
	elif ok:
		btn.text = "Заняться"
		_style(btn, Color(0.12, 0.18, 0.13), Color(0.35, 0.55, 0.4))
		if is_fam: btn.pressed.connect(func(): life.family_time())
		else: btn.pressed.connect(func(): life.develop_children())
	else:
		btn.text = "Нет денег"
		_style(btn, Color(0.09, 0.09, 0.13), Color(0.26, 0.26, 0.36, 0.55)); btn.disabled = true
	row.add_child(btn)
	return card

func _family_card() -> PanelContainer:
	var card := PanelContainer.new()
	var cs := StyleBoxFlat.new()
	cs.bg_color = Color(0.08, 0.11, 0.10, 0.92)
	cs.border_color = Color(0.4, 0.55, 0.45, 0.7)
	cs.set_border_width_all(1); cs.set_corner_radius_all(8); cs.set_content_margin_all(10)
	card.add_theme_stylebox_override("panel", cs)
	var row := HBoxContainer.new(); row.add_theme_constant_override("separation", 10); card.add_child(row)
	var col := VBoxContainer.new(); col.size_flags_horizontal = Control.SIZE_EXPAND_FILL; row.add_child(col)
	_lbl(col, "👶 Завести ребёнка", Color(0.85, 0.92, 0.85), 14)
	_lbl(col, "Радость в семье, но и расходы · %s" % gm.format_money(life.child_init_cost()), Color(0.66, 0.74, 0.68), 11)
	var btn := Button.new()
	btn.text = "Завести"
	btn.add_theme_font_size_override("font_size", 12)
	btn.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	if life.can_have_child():
		_style(btn, Color(0.12, 0.18, 0.13), Color(0.35, 0.55, 0.4))
		btn.pressed.connect(func(): life.have_child())
	else:
		_style(btn, Color(0.09, 0.09, 0.13), Color(0.26, 0.26, 0.36, 0.55)); btn.disabled = true
	row.add_child(btn)
	return card

func _love_card(kind: String) -> PanelContainer:
	var titles := {"meet":"Найти пару", "date":"Сходить на свидание", "couple":"Начать отношения", "stop":"Перестать встречаться",
		"pdate":"Свидание вдвоём", "gift":"Подарок", "breakup":"Расстаться",
		"marry":"Свадьба 💍", "marry_prenup":"Свадьба с договором 💍📜", "divorce":"Развод"}
	var descs := {
		"meet":"Познакомиться · %s" % gm.format_money(gm.shop_price(life.MEET_COST)),
		"date":"Поднять симпатию · %s" % gm.format_money(gm.shop_price(life.DATE_COST)),
		"couple":"Стать парой 💞",
		"stop":"Разойтись с текущим увлечением",
		"pdate":"+отношения · %s" % gm.format_money(gm.shop_price(life.PARTNER_DATE_COST)),
		"gift":"+отношения · %s" % gm.format_money(gm.shop_price(life.GIFT_COST)),
		"breakup":"Закончить отношения 💔",
		"marry":"Пожениться · %s" % gm.format_money(life.wedding_cost()),
		"marry_prenup":"Защита капитала при разводе · %s" % gm.format_money(life.wedding_cost() + life.prenup_cost()),
		"divorce":"Развод · раздел %s" % gm.format_money(life.divorce_cost())}
	var card := PanelContainer.new()
	var cs := StyleBoxFlat.new()
	cs.bg_color = Color(0.13, 0.08, 0.11, 0.92)
	cs.border_color = Color(0.6, 0.35, 0.45, 0.7) if kind != "stop" else Color(0.45, 0.35, 0.4, 0.6)
	cs.set_border_width_all(1); cs.set_corner_radius_all(8); cs.set_content_margin_all(10)
	card.add_theme_stylebox_override("panel", cs)
	var row := HBoxContainer.new(); row.add_theme_constant_override("separation", 10); card.add_child(row)
	var col := VBoxContainer.new(); col.size_flags_horizontal = Control.SIZE_EXPAND_FILL; row.add_child(col)
	_lbl(col, titles[kind], Color(0.95, 0.82, 0.88), 14)
	_lbl(col, descs[kind], Color(0.74, 0.64, 0.70), 11)
	var btn := Button.new()
	btn.add_theme_font_size_override("font_size", 12)
	btn.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var ok: bool = true
	var label: String = "Сделать"
	if kind == "meet":
		ok = life.can_meet()
	elif kind == "date":
		ok = life.can_date()
		if gm.day <= life._last_date_day: label = "✅ Сегодня"
	elif kind == "couple":
		label = "💞 Сойтись"; ok = life.can_become_couple()
	elif kind == "stop":
		label = "Разойтись"
	elif kind == "pdate":
		ok = life.can_partner_date()
		if gm.day <= life._last_pdate_day: label = "✅ Сегодня"
	elif kind == "gift":
		ok = life.can_gift()
		if gm.day <= life._last_gift_day: label = "✅ Сегодня"
	elif kind == "breakup":
		label = "Расстаться"
	elif kind == "marry":
		label = "💍 Свадьба"; ok = life.can_marry() and gm.money >= float(life.wedding_cost())
	elif kind == "marry_prenup":
		label = "💍📜 Свадьба"; ok = life.can_marry() and gm.money >= float(life.wedding_cost() + life.prenup_cost())
	elif kind == "divorce":
		label = "Развод"
	if ok:
		_style(btn, Color(0.20, 0.12, 0.16), Color(0.6, 0.38, 0.48))
		match kind:
			"meet": btn.pressed.connect(func(): life.meet_someone())
			"date": btn.pressed.connect(func(): life.go_on_date())
			"couple": btn.pressed.connect(func(): life.become_couple())
			"stop": btn.pressed.connect(func(): life.stop_seeing())
			"pdate": btn.pressed.connect(func(): life.partner_date())
			"gift": btn.pressed.connect(func(): life.give_gift())
			"breakup": btn.pressed.connect(func(): life.breakup())
			"marry": btn.pressed.connect(func(): life.marry(false))
			"marry_prenup": btn.pressed.connect(func(): life.marry(true))
			"divorce": btn.pressed.connect(func(): life.divorce())
	else:
		_style(btn, Color(0.09, 0.09, 0.13), Color(0.26, 0.26, 0.36, 0.55)); btn.disabled = true
	btn.text = label
	row.add_child(btn)
	return card

func _skill_card(sk: Dictionary) -> PanelContainer:
	var sid: String = sk.id
	var val: float = life.skill(sid)
	var card := PanelContainer.new()
	var cs := StyleBoxFlat.new()
	cs.bg_color = Color(0.09, 0.09, 0.13, 0.92)
	cs.border_color = Color(0.42, 0.42, 0.55, 0.65)
	cs.set_border_width_all(1); cs.set_corner_radius_all(8); cs.set_content_margin_all(10)
	card.add_theme_stylebox_override("panel", cs)
	var row := HBoxContainer.new(); row.add_theme_constant_override("separation", 10); card.add_child(row)
	var icon := Label.new(); icon.text = sk.get("icon", "🧠")
	icon.add_theme_font_size_override("font_size", 22); icon.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	row.add_child(icon)
	var col := VBoxContainer.new(); col.size_flags_horizontal = Control.SIZE_EXPAND_FILL; row.add_child(col)
	_lbl(col, "%s — %d%%" % [sk.get("name", "?"), int(round(val))], Color(0.86, 0.86, 0.94), 14)
	col.add_child(_bar(val / 100.0, Color(0.55, 0.6, 0.85)))
	_lbl(col, sk.get("desc", ""), Color(0.64, 0.62, 0.74), 11)
	var btn := Button.new()
	btn.text = sk.get("action", "Развивать")
	btn.add_theme_font_size_override("font_size", 11)
	btn.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	if life.can_train():
		_style(btn, Color(0.16, 0.13, 0.22), Color(0.5, 0.42, 0.68))
		btn.pressed.connect(func(): life.train_skill(sid))
	else:
		_style(btn, Color(0.09, 0.09, 0.13), Color(0.26, 0.26, 0.36, 0.55)); btn.disabled = true
	row.add_child(btn)
	return card

func _action_card(kind: String) -> PanelContainer:
	var titles := {"workout":"🏋 Тренировка", "groom":"💇 Уход за собой"}
	var descs := {
		"workout":"+форма, +здоровье, +настроение · %s" % gm.format_money(life.workout_cost()),
		"groom":"+стиль и внешность · %s" % gm.format_money(life.groom_cost())}
	var card := PanelContainer.new()
	var cs := StyleBoxFlat.new()
	cs.bg_color = Color(0.10, 0.09, 0.13, 0.92)
	cs.border_color = Color(0.45, 0.40, 0.58, 0.7)
	cs.set_border_width_all(1); cs.set_corner_radius_all(8); cs.set_content_margin_all(10)
	card.add_theme_stylebox_override("panel", cs)
	var row := HBoxContainer.new(); row.add_theme_constant_override("separation", 10); card.add_child(row)
	var col := VBoxContainer.new(); col.size_flags_horizontal = Control.SIZE_EXPAND_FILL; row.add_child(col)
	_lbl(col, titles[kind], Color(0.88, 0.84, 0.96), 14)
	_lbl(col, descs[kind], Color(0.66, 0.64, 0.76), 11)
	var btn := Button.new()
	btn.add_theme_font_size_override("font_size", 12)
	btn.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var ok: bool = life.can_workout() if kind == "workout" else life.can_groom()
	var done_today: bool = (gm.day <= life._last_workout_day) if kind == "workout" else (gm.day <= life._last_groom_day)
	if done_today:
		btn.text = "✅ Сегодня"
		_style(btn, Color(0.12, 0.16, 0.10), Color(0.4, 0.55, 0.3)); btn.disabled = true
	elif ok:
		btn.text = "Сделать"
		_style(btn, Color(0.16, 0.13, 0.22), Color(0.5, 0.42, 0.68))
		if kind == "workout": btn.pressed.connect(func(): life.workout())
		else: btn.pressed.connect(func(): life.groom())
	else:
		btn.text = "Нет денег"
		_style(btn, Color(0.09, 0.09, 0.13), Color(0.26, 0.26, 0.36, 0.55)); btn.disabled = true
	row.add_child(btn)
	return card

# ── helpers ───────────────────────────────────────────────────────────────────
func _years_word(n: int) -> String:
	var m: int = n % 10
	var d: int = n % 100
	if m == 1 and d != 11: return "год"
	if m >= 2 and m <= 4 and (d < 12 or d > 14): return "года"
	return "лет"

func _bar(frac: float, col: Color) -> Control:
	var pb := ProgressBar.new()
	pb.min_value = 0.0; pb.max_value = 1.0
	pb.value = clampf(frac, 0.0, 1.0)
	pb.show_percentage = false
	pb.custom_minimum_size = Vector2(0, 12)
	var bg := StyleBoxFlat.new()
	bg.bg_color = Color(0.16, 0.15, 0.20); bg.set_corner_radius_all(5)
	pb.add_theme_stylebox_override("background", bg)
	var fg := StyleBoxFlat.new()
	fg.bg_color = col; fg.set_corner_radius_all(5)
	pb.add_theme_stylebox_override("fill", fg)
	return pb

func _title(t: String) -> void:
	var l := Label.new(); l.text = t
	l.add_theme_font_size_override("font_size", 24)
	l.add_theme_color_override("font_color", Color(1, 1, 1))
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_vb.add_child(l)

func _header(t: String) -> void:
	var s := Control.new(); s.custom_minimum_size = Vector2(0, 4); _vb.add_child(s)
	var l := Label.new(); l.text = t
	l.add_theme_font_size_override("font_size", 15)
	l.add_theme_color_override("font_color", Color(0.72, 0.62, 0.92))
	_vb.add_child(l)

func _lbl(parent: Node, t: String, c: Color, sz: int) -> Label:
	var l := Label.new(); l.text = t
	l.add_theme_font_size_override("font_size", sz)
	l.add_theme_color_override("font_color", c)
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	parent.add_child(l)
	return l

func _sep() -> void:
	var line := ColorRect.new()
	line.color = Color(0.35, 0.32, 0.45, 0.5)
	line.custom_minimum_size = Vector2(0, 1)
	_vb.add_child(line)

func _style(b: Button, bg: Color, border: Color) -> void:
	var sb := StyleBoxFlat.new()
	sb.bg_color = bg; sb.border_color = border
	sb.set_border_width_all(1); sb.set_corner_radius_all(8); sb.set_content_margin_all(8)
	b.add_theme_stylebox_override("normal", sb)
	var hov := sb.duplicate(); hov.bg_color = bg.lightened(0.10)
	b.add_theme_stylebox_override("hover", hov)
	b.add_theme_color_override("font_color", Color(0.92, 0.9, 0.96))
