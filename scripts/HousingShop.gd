extends Control

@onready var item_list: VBoxContainer = $Panel/Scroll/ItemList
@onready var close_btn: Button = $Panel/CloseBtn
@onready var title_lbl: Label = $Panel/TitleLabel

var gm: Node
var _tooltip: PanelContainer = null
var _tooltip_timer: Timer = null
var _tooltip_target: int = -1

const TIER_COLORS := [
	Color(0.45, 0.45, 0.50),  # 0 — серый (улица/коробка)
	Color(0.40, 0.55, 0.40),  # 1 — зелёный (палатка/подвал/чердак)
	Color(0.35, 0.55, 0.65),  # 2 — синий (общага/комната)
	Color(0.45, 0.45, 0.80),  # 3 — индиго (однушка)
	Color(0.55, 0.40, 0.80),  # 4 — фиолетовый (квартира)
	Color(0.70, 0.40, 0.70),  # 5 — пурпурный (дом)
	Color(0.80, 0.50, 0.30),  # 6 — оранжевый (коттедж)
	Color(0.80, 0.50, 0.30),
	Color(0.85, 0.70, 0.20),  # 8 — золотой (вилла)
	Color(0.95, 0.80, 0.30),  # 9 — яркое золото (пентхаус)
	Color(0.30, 0.90, 0.90),  # 10 — бирюза (остров)
]

func _ready() -> void:
	gm = get_node("/root/GameManager")
	close_btn.pressed.connect(_close)
	visible = false
	_style_ui()
	_build_tooltip()

	_tooltip_timer = Timer.new()
	_tooltip_timer.wait_time = 0.7
	_tooltip_timer.one_shot = true
	_tooltip_timer.timeout.connect(_show_tooltip_for_target)
	add_child(_tooltip_timer)

func _style_ui() -> void:
	var ps := StyleBoxFlat.new()
	ps.bg_color = Color(0.05, 0.05, 0.09, 0.97)
	ps.border_color = Color(0.48, 0.36, 0.10, 0.90)
	for side in [SIDE_LEFT, SIDE_RIGHT, SIDE_TOP, SIDE_BOTTOM]:
		ps.set_border_width(side, 2)
		ps.set_corner_radius(side, 10)
	$Panel.add_theme_stylebox_override("panel", ps)

	title_lbl.add_theme_font_size_override("font_size", 20)
	title_lbl.add_theme_color_override("font_color", Color(1.0, 0.88, 0.25))

	var cs := StyleBoxFlat.new()
	cs.bg_color = Color(0.22, 0.07, 0.07)
	cs.border_color = Color(0.55, 0.18, 0.18)
	for s in [SIDE_LEFT, SIDE_RIGHT, SIDE_TOP, SIDE_BOTTOM]:
		cs.set_border_width(s, 1)
		cs.set_corner_radius(s, 6)
	close_btn.add_theme_stylebox_override("normal", cs)
	var csh := cs.duplicate() as StyleBoxFlat
	csh.bg_color = Color(0.32, 0.10, 0.10)
	close_btn.add_theme_stylebox_override("hover", csh)
	close_btn.add_theme_color_override("font_color", Color.WHITE)

func _build_tooltip() -> void:
	_tooltip = PanelContainer.new()
	_tooltip.visible = false
	_tooltip.z_index = 100
	var ts := StyleBoxFlat.new()
	ts.bg_color = Color(0.04, 0.04, 0.08, 0.97)
	ts.border_color = Color(0.50, 0.40, 0.10, 0.90)
	for s in [SIDE_LEFT, SIDE_RIGHT, SIDE_TOP, SIDE_BOTTOM]:
		ts.set_border_width(s, 1)
		ts.set_corner_radius(s, 8)
	ts.content_margin_left = 10
	ts.content_margin_right = 10
	ts.content_margin_top = 8
	ts.content_margin_bottom = 8
	_tooltip.add_theme_stylebox_override("panel", ts)
	_tooltip.custom_minimum_size = Vector2(220, 0)
	add_child(_tooltip)

func open() -> void:
	visible = true
	_build_list()
	$Panel.modulate.a = 0.0
	var tw := create_tween()
	tw.tween_property($Panel, "modulate:a", 1.0, 0.20)

func _close() -> void:
	_tooltip.visible = false
	visible = false

func _build_list() -> void:
	for child in item_list.get_children():
		child.queue_free()

	for i in range(gm.HOUSINGS.size()):
		var h = gm.HOUSINGS[i]
		var is_current: bool = (i == gm.current_housing_index)
		var tier: int = h.get("tier", 0) as int
		var tier_col: Color = TIER_COLORS[clamp(tier, 0, TIER_COLORS.size() - 1)]
		var cost: float = (h.price if h.price > 0 else h.monthly) as float
		var can_afford: bool = gm.money >= cost or cost == 0.0

		var row_wrap := PanelContainer.new()
		var rws := StyleBoxFlat.new()
		if is_current:
			rws.bg_color = Color(tier_col.r * 0.18, tier_col.g * 0.18, tier_col.b * 0.18, 0.90)
			rws.border_color = tier_col
		else:
			rws.bg_color = Color(0.07, 0.07, 0.11, 0.60)
			rws.border_color = Color(0.22, 0.22, 0.35, 0.60)
		for s in [SIDE_LEFT, SIDE_RIGHT, SIDE_TOP, SIDE_BOTTOM]:
			rws.set_border_width(s, 2 if is_current else 1)
			rws.set_corner_radius(s, 6)
		rws.content_margin_left   = 8
		rws.content_margin_right  = 8
		rws.content_margin_top    = 5
		rws.content_margin_bottom = 5
		row_wrap.add_theme_stylebox_override("panel", rws)
		item_list.add_child(row_wrap)

		var row := HBoxContainer.new()
		row_wrap.add_child(row)

		# Иконка
		var icon_lbl := Label.new()
		icon_lbl.text = h.get("icon", "🏠")
		icon_lbl.add_theme_font_size_override("font_size", 16)
		icon_lbl.custom_minimum_size = Vector2(28, 0)
		row.add_child(icon_lbl)

		# Название + цена
		var info_col := VBoxContainer.new()
		info_col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(info_col)

		var name_lbl := Label.new()
		name_lbl.text = h.name
		name_lbl.add_theme_font_size_override("font_size", 13)
		if is_current:
			name_lbl.add_theme_color_override("font_color", tier_col.lerp(Color.WHITE, 0.3))
		elif can_afford:
			name_lbl.add_theme_color_override("font_color", Color(0.92, 0.92, 0.95))
		else:
			name_lbl.add_theme_color_override("font_color", Color(0.40, 0.40, 0.45))
		info_col.add_child(name_lbl)

		var price_lbl := Label.new()
		if h.price > 0:
			price_lbl.text = "Купить: " + gm.format_money(h.price)
		elif h.monthly > 0:
			price_lbl.text = "Аренда: " + gm.format_money(h.monthly) + "/мес"
		else:
			price_lbl.text = "Бесплатно"
		price_lbl.add_theme_font_size_override("font_size", 10)
		price_lbl.add_theme_color_override("font_color",
			tier_col if (is_current or can_afford) else Color(0.35, 0.35, 0.38))
		info_col.add_child(price_lbl)

		# Краткая сводка бонусов — видна сразу, без наведения на тултип
		var perks_lbl := Label.new()
		perks_lbl.text = _perks_summary(h)
		perks_lbl.add_theme_font_size_override("font_size", 10)
		perks_lbl.add_theme_color_override("font_color", Color(0.60, 0.78, 0.62))
		info_col.add_child(perks_lbl)

		# Текущее / кнопка
		if is_current:
			var cur_lbl := Label.new()
			cur_lbl.text = "✅ Текущее"
			cur_lbl.add_theme_font_size_override("font_size", 11)
			cur_lbl.add_theme_color_override("font_color", Color(0.55, 1.0, 0.55))
			cur_lbl.custom_minimum_size = Vector2(110, 28)
			cur_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			row.add_child(cur_lbl)
		else:
			var btn := Button.new()
			btn.text = "Переехать"
			btn.custom_minimum_size = Vector2(110, 28)
			btn.add_theme_font_size_override("font_size", 12)
			var idx := i
			btn.pressed.connect(func(): _buy(idx))
			if can_afford:
				var bns := StyleBoxFlat.new()
				bns.bg_color = Color(tier_col.r * 0.20, tier_col.g * 0.20, tier_col.b * 0.20)
				bns.border_color = tier_col
				for s in [SIDE_LEFT, SIDE_RIGHT, SIDE_TOP, SIDE_BOTTOM]:
					bns.set_border_width(s, 1)
					bns.set_corner_radius(s, 5)
				btn.add_theme_stylebox_override("normal", bns)
				var bnh := bns.duplicate() as StyleBoxFlat
				bnh.bg_color = Color(tier_col.r * 0.35, tier_col.g * 0.35, tier_col.b * 0.35)
				btn.add_theme_stylebox_override("hover", bnh)
				btn.add_theme_color_override("font_color", tier_col.lerp(Color.WHITE, 0.4))
			else:
				var dis := StyleBoxFlat.new()
				dis.bg_color = Color(0.10, 0.10, 0.13)
				dis.border_color = Color(0.22, 0.22, 0.28, 0.50)
				for s in [SIDE_LEFT, SIDE_RIGHT, SIDE_TOP, SIDE_BOTTOM]:
					dis.set_border_width(s, 1)
					dis.set_corner_radius(s, 5)
				btn.add_theme_stylebox_override("normal", dis)
				btn.add_theme_stylebox_override("hover", dis)
				btn.add_theme_color_override("font_color", Color(0.32, 0.32, 0.35))
				btn.disabled = true
			row.add_child(btn)

		# Тултип при наведении
		var target_idx := i
		row_wrap.mouse_entered.connect(func(): _on_row_hover(target_idx))
		row_wrap.mouse_exited.connect(_on_row_exit)

func _sleep_energy_per_h(h: Dictionary) -> float:
	var tier: int = h.get("tier", 0) as int
	return lerpf(4.0, 16.0, clampf(tier / 10.0, 0.0, 1.0))

func _perks_summary(h: Dictionary) -> String:
	var parts: Array = []
	parts.append("😴%.0f эн/ч" % _sleep_energy_per_h(h))
	var h_regen: float = h.get("health_regen", 0.0) as float
	if h_regen != 0.0:
		parts.append("❤%+.1f/д" % h_regen)
	var hunger_d: float = h.get("hunger_drain", 1.0) as float
	if hunger_d != 1.0:
		parts.append("🍖×%.2f" % hunger_d)
	var rep_d: float = h.get("rep_per_day", 0.0) as float
	if rep_d != 0.0:
		parts.append("⭐%+.1f/д" % rep_d)
	var income_m: float = h.get("income_mult", 1.0) as float
	if income_m != 1.0:
		parts.append("💰×%.2f" % income_m)
	var skill_m: float = h.get("skill_xp_mult", 1.0) as float
	if skill_m != 1.0:
		parts.append("📚×%.2f" % skill_m)
	if parts.is_empty():
		return "— без бонусов"
	return " • ".join(parts)

func _on_row_hover(idx: int) -> void:
	_tooltip_target = idx
	_tooltip_timer.start()
	var panel_rect: Rect2 = $Panel.get_global_rect()
	var viewport_w: float = get_viewport_rect().size.x
	var tooltip_w: float = _tooltip.custom_minimum_size.x
	var mouse_y: float = get_global_mouse_position().y
	var x: float
	if panel_rect.end.x + 6 + tooltip_w <= viewport_w:
		x = panel_rect.end.x + 6
	elif panel_rect.position.x - 6 - tooltip_w >= 0:
		x = panel_rect.position.x - 6 - tooltip_w
	else:
		x = maxf(0.0, viewport_w - tooltip_w - 6)
	_tooltip.global_position = Vector2(x, mouse_y)

func _on_row_exit() -> void:
	_tooltip_timer.stop()
	_tooltip.visible = false
	_tooltip_target = -1

func _show_tooltip_for_target() -> void:
	if _tooltip_target < 0 or _tooltip_target >= gm.HOUSINGS.size():
		return
	var h = gm.HOUSINGS[_tooltip_target]
	var tier: int = h.get("tier", 0) as int
	var col: Color = TIER_COLORS[clamp(tier, 0, TIER_COLORS.size() - 1)]

	# Очищаем старое содержимое
	for c in _tooltip.get_children():
		c.queue_free()

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 4)
	_tooltip.add_child(vbox)

	# Заголовок
	var title := Label.new()
	title.text = h.get("icon", "") + " " + h.name
	title.add_theme_font_size_override("font_size", 14)
	title.add_theme_color_override("font_color", col.lerp(Color.WHITE, 0.3))
	vbox.add_child(title)

	# Описание
	var desc := Label.new()
	desc.text = h.get("desc", "")
	desc.add_theme_font_size_override("font_size", 10)
	desc.add_theme_color_override("font_color", Color(0.65, 0.65, 0.70))
	desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc.custom_minimum_size = Vector2(200, 0)
	vbox.add_child(desc)

	vbox.add_child(_sep())

	# Бонусы
	var h_regen: float = h.get("health_regen", 0.0) as float
	var hunger_d: float = h.get("hunger_drain", 1.0) as float
	var income_m: float = h.get("income_mult", 1.0) as float
	var expense_m: float = h.get("expense_mult", 1.0) as float
	var rep_d: float = h.get("rep_per_day", 0.0) as float
	var skill_m: float = h.get("skill_xp_mult", 1.0) as float
	var crime: float = h.get("crime_risk", 0.0) as float
	var happy: float = h.get("happiness", 0.0) as float

	_add_stat(vbox, "😴 Сон", "%.0f эн/час" % _sleep_energy_per_h(h), true)
	_add_stat(vbox, "❤ Здоровье", "%+.1f/день" % h_regen, h_regen >= 0)
	_add_stat(vbox, "🍖 Голод", "×%.2f" % hunger_d, hunger_d <= 1.0)
	if income_m != 1.0:
		_add_stat(vbox, "💰 Доход", "×%.2f" % income_m, income_m > 1.0)
	if expense_m != 1.0:
		_add_stat(vbox, "💸 Расходы", "×%.2f" % expense_m, expense_m < 1.0)
	if rep_d != 0.0:
		_add_stat(vbox, "⭐ Репутация", "%+.1f/день" % rep_d, rep_d > 0)
	if skill_m != 1.0:
		_add_stat(vbox, "📚 Опыт", "×%.2f" % skill_m, skill_m > 1.0)
	if crime > 0.0:
		_add_stat(vbox, "🔪 Криминал", "%.0f%%" % (crime * 100), false)
	if happy != 0.0:
		_add_stat(vbox, "😊 Счастье", "%+.0f" % happy, happy > 0)

	_tooltip.visible = true
	await get_tree().process_frame
	var viewport_h: float = get_viewport_rect().size.y
	var th: float = _tooltip.size.y
	if _tooltip.global_position.y + th > viewport_h:
		_tooltip.global_position.y = maxf(0.0, viewport_h - th - 6)

func _sep() -> HSeparator:
	var s := HSeparator.new()
	s.add_theme_color_override("separator_color", Color(0.25, 0.25, 0.35))
	return s

func _add_stat(parent: VBoxContainer, label: String, value: String, positive: bool) -> void:
	var row := HBoxContainer.new()
	parent.add_child(row)
	var lbl := Label.new()
	lbl.text = label
	lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	lbl.add_theme_font_size_override("font_size", 11)
	lbl.add_theme_color_override("font_color", Color(0.70, 0.70, 0.75))
	row.add_child(lbl)
	var val := Label.new()
	val.text = value
	val.add_theme_font_size_override("font_size", 11)
	val.add_theme_color_override("font_color",
		Color(0.45, 1.0, 0.55) if positive else Color(1.0, 0.45, 0.45))
	row.add_child(val)

func _buy(index: int) -> void:
	var h = gm.HOUSINGS[index]
	var result = gm.buy_housing(index)
	var am = get_node_or_null("/root/AudioManager")
	if result:
		if am: am.play_buy()
		_tooltip.visible = false
		_build_list()
	else:
		if am: am.play_negative()
		var price: float = h.price if h.price > 0 else h.monthly
		_show_error("Недостаточно денег! Нужно " + gm.format_money(price))

func _show_error(msg: String) -> void:
	title_lbl.text = msg
	await get_tree().create_timer(2.0).timeout
	title_lbl.text = "🏠 Выбери жильё"
