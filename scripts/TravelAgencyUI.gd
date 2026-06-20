extends CanvasLayer

var _zm: Node
var _gm: Node
var _em: Node
var _panel: Control
var _zone_list: VBoxContainer
var _detail_panel: PanelContainer
var _sub_title: Label        # прямая ссылка на подзаголовок шапки
var _selected_zone: int = -1

func _ready() -> void:
	layer = 20
	visible = false
	add_to_group("travel_agency_ui")
	_zm = get_node("/root/ZoneManager")
	_gm = get_node("/root/GameManager")
	_em = get_node_or_null("/root/EducationManager")
	_build_ui()

func _build_ui() -> void:
	var dimmer = ColorRect.new()
	dimmer.set_anchors_preset(Control.PRESET_FULL_RECT)
	dimmer.color = Color(0, 0, 0, 0.82)
	dimmer.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(dimmer)

	_panel = Panel.new()
	_panel.set_anchors_preset(Control.PRESET_CENTER)
	_panel.size     = Vector2(920, 630)
	_panel.position = Vector2(-460, -315)
	var ps = StyleBoxFlat.new()
	ps.bg_color     = Color(0.040, 0.047, 0.100, 0.98)
	ps.border_color = Color(0.22, 0.48, 0.80, 0.90)
	ps.set_border_width_all(2)
	ps.set_corner_radius_all(14)
	_panel.add_theme_stylebox_override("panel", ps)
	add_child(_panel)

	# ── Шапка ────────────────────────────────────────────────────────────────
	var hdr = PanelContainer.new()
	hdr.position = Vector2(0, 0)
	hdr.size     = Vector2(920, 58)
	var hps = StyleBoxFlat.new()
	hps.bg_color     = Color(0.055, 0.100, 0.210, 1.0)
	hps.border_color = Color(0.22, 0.48, 0.80, 0.50)
	hps.set_border_width(SIDE_BOTTOM, 2)
	hps.set_corner_radius(CORNER_TOP_LEFT,  14)
	hps.set_corner_radius(CORNER_TOP_RIGHT, 14)
	hps.content_margin_left   = 18
	hps.content_margin_right  = 12
	hps.content_margin_top    = 8
	hps.content_margin_bottom = 8
	hdr.add_theme_stylebox_override("panel", hps)
	_panel.add_child(hdr)

	var hdr_row = HBoxContainer.new()
	hdr_row.add_theme_constant_override("separation", 12)
	hdr.add_child(hdr_row)

	var plane_lbl = Label.new()
	plane_lbl.text = "✈"
	plane_lbl.add_theme_font_size_override("font_size", 28)
	plane_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	hdr_row.add_child(plane_lbl)

	var ttl_col = VBoxContainer.new()
	ttl_col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	ttl_col.add_theme_constant_override("separation", 0)
	hdr_row.add_child(ttl_col)

	var t1 = Label.new()
	t1.text = "Туристическая фирма «Новый горизонт»"
	t1.add_theme_font_size_override("font_size", 18)
	t1.add_theme_color_override("font_color", Color(1.0, 0.90, 0.28))
	t1.add_theme_constant_override("outline_size", 2)
	t1.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.70))
	ttl_col.add_child(t1)

	_sub_title = Label.new()
	_sub_title.add_theme_font_size_override("font_size", 11)
	_sub_title.add_theme_color_override("font_color", Color(0.52, 0.70, 0.92))
	ttl_col.add_child(_sub_title)

	var cls = Button.new()
	cls.text = "✖"
	cls.custom_minimum_size = Vector2(36, 36)
	cls.add_theme_font_size_override("font_size", 14)
	cls.add_theme_color_override("font_color", Color.WHITE)
	var cbs = StyleBoxFlat.new()
	cbs.bg_color = Color(0.22, 0.07, 0.07)
	cbs.border_color = Color(0.55, 0.18, 0.18)
	cbs.set_border_width_all(1); cbs.set_corner_radius_all(6)
	cls.add_theme_stylebox_override("normal", cbs)
	var cbh = cbs.duplicate() as StyleBoxFlat
	cbh.bg_color = Color(0.40, 0.10, 0.10)
	cls.add_theme_stylebox_override("hover", cbh)
	cls.pressed.connect(func(): visible = false)
	hdr_row.add_child(cls)

	# ── Тело: split left + right ──────────────────────────────────────────────
	var body = HBoxContainer.new()
	body.position = Vector2(0, 58)
	body.size     = Vector2(920, 572)
	body.add_theme_constant_override("separation", 0)
	_panel.add_child(body)

	# Левая колонка
	var left_bg = PanelContainer.new()
	left_bg.custom_minimum_size = Vector2(375, 0)
	left_bg.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var lbgs = StyleBoxFlat.new()
	lbgs.bg_color     = Color(0.028, 0.035, 0.075, 0.96)
	lbgs.border_color = Color(0.14, 0.24, 0.40, 0.50)
	lbgs.set_border_width(SIDE_RIGHT, 2)
	lbgs.content_margin_left   = 10
	lbgs.content_margin_right  = 8
	lbgs.content_margin_top    = 10
	lbgs.content_margin_bottom = 10
	lbgs.set_corner_radius(CORNER_BOTTOM_LEFT, 14)
	left_bg.add_theme_stylebox_override("panel", lbgs)
	body.add_child(left_bg)

	var scroll = ScrollContainer.new()
	scroll.size_flags_vertical   = Control.SIZE_EXPAND_FILL
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	left_bg.add_child(scroll)

	_zone_list = VBoxContainer.new()
	_zone_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_zone_list.add_theme_constant_override("separation", 4)
	scroll.add_child(_zone_list)

	# Правая колонка
	_detail_panel = PanelContainer.new()
	_detail_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_detail_panel.size_flags_vertical   = Control.SIZE_EXPAND_FILL
	var dps = StyleBoxFlat.new()
	dps.bg_color = Color(0, 0, 0, 0)
	dps.content_margin_left   = 22
	dps.content_margin_right  = 22
	dps.content_margin_top    = 16
	dps.content_margin_bottom = 16
	dps.set_corner_radius(CORNER_BOTTOM_RIGHT, 14)
	_detail_panel.add_theme_stylebox_override("panel", dps)
	body.add_child(_detail_panel)

func open() -> void:
	_selected_zone = -1
	_refresh()
	visible = true
	_panel.modulate.a = 0.0
	_panel.scale      = Vector2(0.93, 0.93)
	var tw = create_tween()
	tw.set_parallel(true)
	tw.tween_property(_panel, "modulate:a", 1.0, 0.20)
	tw.tween_property(_panel, "scale", Vector2(1.0, 1.0), 0.22).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)

func _refresh() -> void:
	_sub_title.text = "Вы сейчас: %s  ·  Зона %d из %d" % [
		_zm.get_zone_name(), _zm.current_zone + 1, _zm.ZONE_META.size()
	]
	for c in _zone_list.get_children(): c.queue_free()

	# Секция «Пройдено / открыто» — всё, что уже было разблокировано (память
	# прогресса max_zone_reached), независимо от того, где игрок физически
	# стоит прямо сейчас.
	var opened: Array = []
	for i in _zm.max_zone_reached + 1:
		if i != _zm.current_zone:
			opened.append(i)
	if not opened.is_empty():
		_zone_list.add_child(_section_lbl("✅  ОТКРЫТО"))
		for i in opened:
			_zone_list.add_child(_make_zone_card(i))

	# Текущая (физическое положение игрока)
	_zone_list.add_child(_section_lbl("📍  ТЕКУЩАЯ ЗОНА"))
	_zone_list.add_child(_make_zone_card(_zm.current_zone))

	# Следующие / заблокированные
	var remaining_start = _zm.max_zone_reached + 1
	if remaining_start < _zm.ZONE_META.size():
		_zone_list.add_child(_section_lbl("🔜  ВПЕРЕДИ"))
		for i in range(remaining_start, _zm.ZONE_META.size()):
			_zone_list.add_child(_make_zone_card(i))

	# Остров (если финальная зона)
	if _zm.is_final_zone():
		_zone_list.add_child(_section_lbl("🏝  ФИНАЛ"))
		_zone_list.add_child(_make_island_card())

	_refresh_detail()

func _section_lbl(text: String) -> Label:
	var lbl = Label.new()
	lbl.text = text
	lbl.add_theme_font_size_override("font_size", 10)
	lbl.add_theme_color_override("font_color", Color(0.35, 0.42, 0.55))
	lbl.add_theme_constant_override("outline_size", 0)
	var m = StyleBoxEmpty.new()
	m.content_margin_top    = 6
	m.content_margin_bottom = 2
	m.content_margin_left   = 4
	lbl.add_theme_stylebox_override("normal", m)
	return lbl

# ── Карточка зоны ─────────────────────────────────────────────────────────────
func _make_zone_card(i: int) -> PanelContainer:
	var meta       = _zm.ZONE_META[i]
	var is_current = (i == _zm.current_zone)
	var is_past    = (not is_current) and (i <= _zm.max_zone_reached)
	var is_next    = (i == _zm.max_zone_reached + 1)
	var zone_ok    = _zm.is_zone_complete()
	var is_sel     = (i == _selected_zone)
	var is_locked  = (not is_past and not is_current and not is_next)

	var card = PanelContainer.new()
	var cs   = _card_style(is_sel, is_current, is_past, is_next)
	card.add_theme_stylebox_override("panel", cs)
	card.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	card.gui_input.connect(_on_card_input.bind(i))
	card.mouse_entered.connect(_on_card_hover.bind(card, cs, true))
	card.mouse_exited.connect(_on_card_hover.bind(card, cs, false))

	var row = HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	card.add_child(row)

	# Статус + номер
	var num_col = VBoxContainer.new()
	num_col.custom_minimum_size = Vector2(32, 0)
	num_col.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_child(num_col)

	var st_lbl = Label.new()
	if is_current:               st_lbl.text = "📍"
	elif is_past:                st_lbl.text = "✅"
	elif is_next and zone_ok:    st_lbl.text = "🟢"
	elif is_next:                st_lbl.text = "⏳"
	else:                        st_lbl.text = "🔒"
	st_lbl.add_theme_font_size_override("font_size", 15)
	st_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	num_col.add_child(st_lbl)

	var num_lbl = Label.new()
	num_lbl.text = str(i + 1)
	num_lbl.add_theme_font_size_override("font_size", 9)
	num_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	num_lbl.add_theme_color_override("font_color", Color(0.35, 0.40, 0.52))
	num_col.add_child(num_lbl)

	# Иконка
	var zone_ico = Label.new()
	zone_ico.text = meta.icon
	zone_ico.add_theme_font_size_override("font_size", 20)
	zone_ico.vertical_alignment  = VERTICAL_ALIGNMENT_CENTER
	zone_ico.custom_minimum_size = Vector2(30, 34)
	zone_ico.modulate.a = 0.28 if is_locked else 1.0
	row.add_child(zone_ico)

	# Текст
	var info_col = VBoxContainer.new()
	info_col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info_col.add_theme_constant_override("separation", 1)
	row.add_child(info_col)

	var name_lbl = Label.new()
	name_lbl.text = meta.name
	name_lbl.add_theme_font_size_override("font_size", 13)
	var nc: Color
	if is_sel:                       nc = Color(0.75, 0.92, 1.00)
	elif is_current:                 nc = Color(0.38, 1.00, 0.58)
	elif is_past:                    nc = Color(0.48, 0.72, 0.52)
	elif is_next:                    nc = Color(1.00, 0.87, 0.38)
	else:                            nc = Color(0.26, 0.26, 0.34)
	name_lbl.add_theme_color_override("font_color", nc)
	info_col.add_child(name_lbl)

	var sub_lbl = Label.new()
	sub_lbl.add_theme_font_size_override("font_size", 10)
	if is_current:
		sub_lbl.text = "← Вы здесь"
		sub_lbl.add_theme_color_override("font_color", Color(0.30, 0.80, 0.50))
	elif is_past:
		sub_lbl.text = "Вернуться"
		sub_lbl.add_theme_color_override("font_color", Color(0.32, 0.52, 0.38))
	elif is_next and zone_ok:
		sub_lbl.text = "✅ Готово к переезду"
		sub_lbl.add_theme_color_override("font_color", Color(0.38, 0.90, 0.48))
	elif is_next:
		sub_lbl.text = "Выполни условия"
		sub_lbl.add_theme_color_override("font_color", Color(0.72, 0.55, 0.16))
	else:
		sub_lbl.text = "Заблокировано"
		sub_lbl.add_theme_color_override("font_color", Color(0.24, 0.24, 0.32))
	info_col.add_child(sub_lbl)

	if is_sel:
		var arr = Label.new()
		arr.text = "▶"
		arr.add_theme_font_size_override("font_size", 15)
		arr.add_theme_color_override("font_color", Color(0.48, 0.80, 1.00))
		arr.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		row.add_child(arr)

	return card

func _card_style(is_sel: bool, is_current: bool, is_past: bool, is_next: bool) -> StyleBoxFlat:
	var cs = StyleBoxFlat.new()
	if is_sel:
		cs.bg_color = Color(0.10, 0.18, 0.34, 0.98); cs.border_color = Color(0.42, 0.72, 1.00, 1.00); cs.set_border_width_all(2)
	elif is_current:
		cs.bg_color = Color(0.045, 0.130, 0.085, 0.92); cs.border_color = Color(0.22, 0.72, 0.38, 0.85); cs.set_border_width_all(2)
	elif is_past:
		cs.bg_color = Color(0.035, 0.065, 0.038, 0.68); cs.border_color = Color(0.16, 0.38, 0.20, 0.50); cs.set_border_width_all(1)
	elif is_next:
		cs.bg_color = Color(0.095, 0.082, 0.028, 0.80); cs.border_color = Color(0.62, 0.48, 0.10, 0.72); cs.set_border_width_all(1)
	else:
		cs.bg_color = Color(0.032, 0.032, 0.065, 0.48); cs.border_color = Color(0.10, 0.10, 0.18, 0.30); cs.set_border_width_all(1)
	cs.set_corner_radius_all(8)
	cs.content_margin_left = 10; cs.content_margin_right  = 10
	cs.content_margin_top  = 6;  cs.content_margin_bottom = 6
	return cs

func _on_card_hover(card: PanelContainer, base_style: StyleBoxFlat, entering: bool) -> void:
	var tw = create_tween()
	var target_alpha = base_style.bg_color.a + (0.18 if entering else -0.18)
	target_alpha = clampf(target_alpha, 0.0, 1.0)
	var new_col = Color(base_style.bg_color.r, base_style.bg_color.g,
						base_style.bg_color.b, target_alpha)
	var _card_ref := card
	var _cb := func(c: Color) -> void:
		if is_instance_valid(_card_ref):
			_card_ref.get_theme_stylebox("panel").bg_color = c
	tw.tween_method(_cb, base_style.bg_color, new_col, 0.10)

func _make_island_card() -> PanelContainer:
	var is_sel = (_selected_zone == 99)
	var card   = PanelContainer.new()
	var cs     = StyleBoxFlat.new()
	cs.bg_color     = Color(0.15, 0.12, 0.03, 0.92) if not is_sel else Color(0.20, 0.16, 0.05, 0.98)
	cs.border_color = Color(0.80, 0.65, 0.12, 0.85) if not is_sel else Color(1.00, 0.86, 0.22, 1.00)
	cs.set_border_width_all(2 if is_sel else 1)
	cs.set_corner_radius_all(8)
	cs.content_margin_left = 10; cs.content_margin_right  = 10
	cs.content_margin_top  = 6;  cs.content_margin_bottom = 6
	card.add_theme_stylebox_override("panel", cs)
	card.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	card.gui_input.connect(_on_card_input.bind(99))

	var row = HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	card.add_child(row)

	var ico = Label.new()
	ico.text = "🏝"; ico.add_theme_font_size_override("font_size", 22)
	ico.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	ico.custom_minimum_size = Vector2(34, 34)
	row.add_child(ico)

	var info = VBoxContainer.new()
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info.add_theme_constant_override("separation", 1)
	row.add_child(info)

	var nl = Label.new()
	nl.text = "Остров — Финал игры"
	nl.add_theme_font_size_override("font_size", 13)
	nl.add_theme_color_override("font_color", Color(1.00, 0.88, 0.28))
	info.add_child(nl)

	var sl = Label.new()
	sl.text = "Заслуженный отдых ждёт"
	sl.add_theme_font_size_override("font_size", 10)
	sl.add_theme_color_override("font_color", Color(0.68, 0.58, 0.22))
	info.add_child(sl)

	if is_sel:
		var arr = Label.new()
		arr.text = "▶"; arr.add_theme_font_size_override("font_size", 15)
		arr.add_theme_color_override("font_color", Color(1.00, 0.88, 0.25))
		arr.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		row.add_child(arr)
	return card

func _on_card_input(event: InputEvent, zone_idx: int) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		_selected_zone = zone_idx
		_refresh()

# ── Правая панель деталей ─────────────────────────────────────────────────────
func _refresh_detail() -> void:
	for c in _detail_panel.get_children(): c.queue_free()

	var vb = VBoxContainer.new()
	vb.set_anchors_preset(Control.PRESET_FULL_RECT)
	vb.add_theme_constant_override("separation", 10)
	_detail_panel.add_child(vb)

	if _selected_zone < 0:
		_build_placeholder(vb)
		return
	if _selected_zone == 99:
		_build_island_detail(vb)
		return

	var i         = _selected_zone
	var meta      = _zm.ZONE_META[i]
	var is_current= (i == _zm.current_zone)
	var is_past   = (not is_current) and (i <= _zm.max_zone_reached)
	var is_next   = (i == _zm.max_zone_reached + 1)
	var zone_ok   = _zm.is_zone_complete()

	# Hero-карточка
	var hero = PanelContainer.new()
	var hs   = StyleBoxFlat.new()
	if is_current:
		hs.bg_color = Color(0.04, 0.14, 0.08, 0.92); hs.border_color = Color(0.22, 0.72, 0.38, 0.85)
	elif is_past:
		hs.bg_color = Color(0.04, 0.10, 0.06, 0.88); hs.border_color = Color(0.20, 0.60, 0.32, 0.78)
	elif is_next and zone_ok:
		hs.bg_color = Color(0.05, 0.14, 0.07, 0.92); hs.border_color = Color(0.30, 0.85, 0.42, 0.90)
	elif is_next:
		hs.bg_color = Color(0.11, 0.09, 0.03, 0.90); hs.border_color = Color(0.72, 0.52, 0.10, 0.80)
	else:
		hs.bg_color = Color(0.06, 0.06, 0.10, 0.75); hs.border_color = Color(0.20, 0.20, 0.32, 0.55)
	hs.set_border_width_all(2); hs.set_corner_radius_all(10)
	hs.content_margin_left = 16; hs.content_margin_right  = 16
	hs.content_margin_top  = 14; hs.content_margin_bottom = 14
	hero.add_theme_stylebox_override("panel", hs)
	vb.add_child(hero)

	var hero_row = HBoxContainer.new()
	hero_row.add_theme_constant_override("separation", 14)
	hero.add_child(hero_row)

	var big_ico = Label.new()
	big_ico.text = meta.icon
	big_ico.add_theme_font_size_override("font_size", 56)
	big_ico.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	hero_row.add_child(big_ico)

	var hero_info = VBoxContainer.new()
	hero_info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hero_info.add_theme_constant_override("separation", 4)
	hero_row.add_child(hero_info)

	var zone_title = Label.new()
	zone_title.text = meta.name
	zone_title.add_theme_font_size_override("font_size", 22)
	if is_current:               zone_title.add_theme_color_override("font_color", Color(0.38, 1.00, 0.58))
	elif is_past:                zone_title.add_theme_color_override("font_color", Color(0.50, 0.92, 0.62))
	elif is_next and zone_ok:    zone_title.add_theme_color_override("font_color", Color(0.44, 1.00, 0.56))
	elif is_next:                zone_title.add_theme_color_override("font_color", Color(1.00, 0.84, 0.34))
	else:                        zone_title.add_theme_color_override("font_color", Color(0.36, 0.36, 0.48))
	hero_info.add_child(zone_title)

	var zone_sub = Label.new()
	zone_sub.text = "Зона %d из %d" % [i + 1, _zm.ZONE_META.size()]
	zone_sub.add_theme_font_size_override("font_size", 12)
	zone_sub.add_theme_color_override("font_color", Color(0.40, 0.48, 0.60))
	hero_info.add_child(zone_sub)

	# Статус-бейдж
	var badge_txt: String; var badge_col: Color
	if is_current:
		badge_txt = "📍  Вы живёте здесь сейчас";         badge_col = Color(0.18, 0.62, 0.30)
	elif is_past:
		badge_txt = "✅  Посещена — возврат доступен";     badge_col = Color(0.16, 0.55, 0.26)
	elif is_next and zone_ok:
		badge_txt = "🚀  Условия выполнены! Можно ехать"; badge_col = Color(0.14, 0.52, 0.24)
	elif is_next:
		badge_txt = "⏳  Выполни условия для переезда";   badge_col = Color(0.52, 0.36, 0.04)
	else:
		badge_txt = "🔒  Сначала доберись до пред. зон";  badge_col = Color(0.22, 0.18, 0.28)

	var badge = PanelContainer.new()
	var bcs   = StyleBoxFlat.new()
	bcs.bg_color = badge_col.darkened(0.28); bcs.border_color = badge_col
	bcs.set_border_width_all(1); bcs.set_corner_radius_all(6)
	bcs.content_margin_left = 10; bcs.content_margin_right  = 10
	bcs.content_margin_top  = 5;  bcs.content_margin_bottom = 5
	badge.add_theme_stylebox_override("panel", bcs)
	vb.add_child(badge)
	var bl = Label.new()
	bl.text = badge_txt; bl.add_theme_font_size_override("font_size", 13)
	bl.add_theme_color_override("font_color", badge_col.lightened(0.42))
	badge.add_child(bl)

	# Требования для следующей (или недоступной) зоны
	if is_next or (not is_past and not is_current):
		var info2 = _zm.get_unlock_info(i)
		if not info2.is_empty():
			var req_hdr = Label.new()
			req_hdr.text = "Требования для переезда:"
			req_hdr.add_theme_font_size_override("font_size", 12)
			req_hdr.add_theme_color_override("font_color", Color(0.48, 0.54, 0.65))
			vb.add_child(req_hdr)

			var t_cur = _gm.current_title_index
			var e_cur = _em.level if _em else 0
			vb.add_child(_make_req_card(
				"🏆  Титул",
				_gm.TITLES[t_cur].name if t_cur < _gm.TITLES.size() else "?",
				info2.title_name,
				t_cur, info2.title_req,
				info2.title_ok
			))
			vb.add_child(_make_req_card(
				"🎓  Образование",
				_em.LEVELS[e_cur].name if _em and e_cur < _em.LEVELS.size() else "?",
				info2.edu_name,
				e_cur, info2.edu_req,
				info2.edu_ok
			))

			if not is_next and info2.zones_away > 1:
				var away_lbl = Label.new()
				away_lbl.text = "📍 До этой зоны ещё %d шаг(а) — сначала двигайся по порядку" % info2.zones_away
				away_lbl.add_theme_font_size_override("font_size", 11)
				away_lbl.add_theme_color_override("font_color", Color(0.55, 0.55, 0.65))
				away_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD
				vb.add_child(away_lbl)

	var spacer = Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vb.add_child(spacer)

	# Кнопка переезда
	vb.add_child(_make_travel_btn(i, is_past, is_current, is_next, zone_ok, meta))

func _build_placeholder(vb: VBoxContainer) -> void:
	var center = CenterContainer.new()
	center.size_flags_vertical   = Control.SIZE_EXPAND_FILL
	center.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vb.add_child(center)

	var col = VBoxContainer.new()
	col.add_theme_constant_override("separation", 10)
	center.add_child(col)

	var ico = Label.new()
	ico.text = "🗺"
	ico.add_theme_font_size_override("font_size", 52)
	ico.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	ico.modulate.a = 0.30
	col.add_child(ico)

	var hint = Label.new()
	hint.text = "Выберите район\nдля просмотра деталей"
	hint.add_theme_font_size_override("font_size", 15)
	hint.add_theme_color_override("font_color", Color(0.28, 0.32, 0.42))
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.autowrap_mode        = TextServer.AUTOWRAP_WORD
	col.add_child(hint)

func _build_island_detail(vb: VBoxContainer) -> void:
	var hero = PanelContainer.new()
	var hs   = StyleBoxFlat.new()
	hs.bg_color = Color(0.12, 0.10, 0.03, 0.92); hs.border_color = Color(0.85, 0.70, 0.15, 0.90)
	hs.set_border_width_all(2); hs.set_corner_radius_all(10)
	hs.content_margin_left = 16; hs.content_margin_right  = 16
	hs.content_margin_top  = 14; hs.content_margin_bottom = 14
	hero.add_theme_stylebox_override("panel", hs)
	vb.add_child(hero)

	var hv = VBoxContainer.new()
	hv.add_theme_constant_override("separation", 6)
	hero.add_child(hv)

	var il = Label.new()
	il.text = "🏝"; il.add_theme_font_size_override("font_size", 58)
	il.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hv.add_child(il)

	var tl = Label.new()
	tl.text = "Остров — Финал игры"
	tl.add_theme_font_size_override("font_size", 22)
	tl.add_theme_color_override("font_color", Color(1.00, 0.88, 0.28))
	tl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hv.add_child(tl)

	var dl = Label.new()
	dl.text = "Вы прошли весь путь от нуля до вершины.\nПора насладиться заслуженным отдыхом."
	dl.add_theme_font_size_override("font_size", 13)
	dl.add_theme_color_override("font_color", Color(0.78, 0.70, 0.36))
	dl.autowrap_mode = TextServer.AUTOWRAP_WORD
	dl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hv.add_child(dl)

	var spacer = Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vb.add_child(spacer)

	var btn = Button.new()
	btn.text = "🏝  Переехать на Остров!"
	btn.custom_minimum_size   = Vector2(0, 54)
	btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	btn.add_theme_font_size_override("font_size", 17)
	btn.add_theme_color_override("font_color", Color(1.00, 0.90, 0.22))
	var bbs = StyleBoxFlat.new()
	bbs.bg_color = Color(0.42, 0.32, 0.04); bbs.border_color = Color(0.85, 0.68, 0.12)
	bbs.set_border_width_all(2); bbs.set_corner_radius_all(10)
	btn.add_theme_stylebox_override("normal", bbs)
	var bbh = bbs.duplicate() as StyleBoxFlat
	bbh.bg_color = bbs.bg_color.lightened(0.14)
	btn.add_theme_stylebox_override("hover", bbh)
	btn.pressed.connect(func(): visible = false; _zm.trigger_island_ending())
	vb.add_child(btn)

# ── Карточка требования с прогресс-баром ─────────────────────────────────────
func _make_req_card(label: String, cur_name: String, req_name: String,
					cur_val: int, req_val: int, met: bool) -> PanelContainer:
	var card = PanelContainer.new()
	var cs   = StyleBoxFlat.new()
	cs.bg_color     = Color(0.05, 0.14, 0.06, 0.90) if met else Color(0.12, 0.07, 0.04, 0.85)
	cs.border_color = Color(0.28, 0.75, 0.35, 0.85) if met else Color(0.72, 0.35, 0.12, 0.75)
	cs.set_border_width_all(1); cs.set_corner_radius_all(8)
	cs.content_margin_left = 14; cs.content_margin_right  = 14
	cs.content_margin_top  = 9;  cs.content_margin_bottom = 9
	card.add_theme_stylebox_override("panel", cs)

	var row = HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	card.add_child(row)

	var check = Label.new()
	check.text = "✅" if met else "❌"
	check.add_theme_font_size_override("font_size", 20)
	check.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	row.add_child(check)

	var info = VBoxContainer.new()
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info.add_theme_constant_override("separation", 4)
	row.add_child(info)

	# Заголовок + название
	var top_row = HBoxContainer.new()
	top_row.add_theme_constant_override("separation", 6)
	info.add_child(top_row)

	var lbl_type = Label.new()
	lbl_type.text = label
	lbl_type.add_theme_font_size_override("font_size", 11)
	lbl_type.add_theme_color_override("font_color", Color(0.42, 0.52, 0.48))
	lbl_type.custom_minimum_size = Vector2(110, 0)
	top_row.add_child(lbl_type)

	var arrow = Label.new()
	arrow.text = "%s  →  %s" % [cur_name, req_name]
	arrow.add_theme_font_size_override("font_size", 13)
	arrow.add_theme_color_override("font_color",
		Color(0.44, 1.00, 0.54) if met else Color(1.00, 0.72, 0.40))
	top_row.add_child(arrow)

	# Прогресс-бар
	var pb = ProgressBar.new()
	pb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	pb.custom_minimum_size   = Vector2(0, 7)
	pb.max_value   = float(max(req_val, 1))
	pb.value       = float(min(cur_val, req_val))
	pb.show_percentage = false
	var fill = StyleBoxFlat.new()
	fill.bg_color = Color(0.30, 0.88, 0.38) if met else Color(0.90, 0.55, 0.15)
	fill.set_corner_radius_all(4)
	var pbg = StyleBoxFlat.new()
	pbg.bg_color = Color(0.08, 0.10, 0.08)
	pbg.set_corner_radius_all(4)
	pb.add_theme_stylebox_override("fill", fill)
	pb.add_theme_stylebox_override("background", pbg)
	info.add_child(pb)

	return card

# ── Кнопка переезда ───────────────────────────────────────────────────────────
func _make_travel_btn(i: int, is_past: bool, is_current: bool,
					  is_next: bool, zone_ok: bool, meta: Dictionary) -> Button:
	var btn = Button.new()
	btn.custom_minimum_size   = Vector2(0, 54)
	btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	btn.add_theme_font_size_override("font_size", 17)

	var enabled = false
	var bc: Color; var fc: Color

	if is_current:
		btn.text = "📍  Вы уже здесь"
		bc = Color(0.10, 0.10, 0.14); fc = Color(0.40, 0.40, 0.50)
	elif is_past:
		enabled = true
		btn.text = "↩  Вернуться в «%s»" % meta.name
		bc = Color(0.14, 0.26, 0.50); fc = Color(0.68, 0.86, 1.00)
	elif is_next and zone_ok:
		enabled = true
		btn.text = "🚀  Переехать в «%s»" % meta.name
		bc = Color(0.10, 0.42, 0.18); fc = Color(0.70, 1.00, 0.70)
	elif is_next:
		btn.text = "🔒  Условия не выполнены"
		bc = Color(0.12, 0.12, 0.16); fc = Color(0.35, 0.35, 0.42)
	else:
		btn.text = "🔒  Зона недоступна"
		bc = Color(0.12, 0.12, 0.16); fc = Color(0.35, 0.35, 0.42)

	btn.disabled = not enabled
	btn.add_theme_color_override("font_color", fc)
	var bbs = StyleBoxFlat.new()
	bbs.bg_color     = bc
	bbs.border_color = bc.lightened(0.30) if enabled else Color(0.20, 0.20, 0.28)
	bbs.set_border_width_all(2); bbs.set_corner_radius_all(10)
	btn.add_theme_stylebox_override("normal", bbs)
	if enabled:
		var bbh = bbs.duplicate() as StyleBoxFlat
		bbh.bg_color = bc.lightened(0.13)
		btn.add_theme_stylebox_override("hover", bbh)
		var zi = i
		btn.pressed.connect(func():
			visible = false
			_zm.travel_to(zi)
			var world = get_tree().get_first_node_in_group("world")
			if world and world.has_method("teleport_to_zone"):
				world.teleport_to_zone(zi)
		)
		# Пульсация бордера если кнопка активна
		if is_next and zone_ok:
			_pulse_btn(btn, bbs)
	return btn

func _pulse_btn(btn: Button, style: StyleBoxFlat) -> void:
	var tw = btn.create_tween().set_loops()
	tw.tween_method(func(v: float):
		if not is_instance_valid(btn):
			tw.stop(); return
		style.border_color = Color(0.28, 0.80, 0.35, v)
		btn.add_theme_stylebox_override("normal", style),
		0.55, 1.00, 0.75)
	tw.tween_method(func(v: float):
		if not is_instance_valid(btn):
			tw.stop(); return
		style.border_color = Color(0.28, 0.80, 0.35, v)
		btn.add_theme_stylebox_override("normal", style),
		1.00, 0.55, 0.75)
