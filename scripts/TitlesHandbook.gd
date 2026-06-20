extends CanvasLayer

# ── Справочник титулов ────────────────────────────────────────────────────────
# Открывается из HUD. Слева — список всех титулов (достигнутые подсвечены),
# справа — детальная карточка с описанием и фото выбранного.

var _panel: Panel
var _list: VBoxContainer
var _detail_icon: Label
var _detail_name: Label
var _detail_money: Label
var _detail_desc: Label
var _detail_photo: TextureRect
var _detail_photo_placeholder: Label
var _detail_photo_placeholder_panel: PanelContainer
var _detail_status: Label
var _progress_bar: ProgressBar
var _progress_lbl: Label
var _selected_index: int = -1
var _photo_map: Dictionary = {}   # idx -> полный путь к файлу

const PHOTO_DIR := "res://assets/titles/"

# Точные имена файлов на случай если DirAccess недоступен
const PHOTO_FALLBACK := {
	0:  "title_0_bomzh.png",
	1:  "title_1_brodyaga.png",
	2:  "title_2_nishiy.png",
	3:  "title_3_bezrabotny.png",
	4:  "title_4_bedny.png",
	5:  "title_5_rabotyaga.png",
	6:  "title_6_prostoy.png",
	7:  "title_7_sredniy_klass.png",
	8:  "title_8_spetsialist.png",
	9:  "title_9_menedzher.png",
	10: "title_10_bogatiy.png",
	11: "title_11_predprinimatel.png",
	12: "title_12_millioner.png",
	13: "title_13_biznesmen.png",
	14: "title_14_multimillioner.png",
	15: "title_15_magnat.png",
	16: "title_16_oligarh.png",
}

func _ready() -> void:
	layer = 9
	visible = false
	_scan_photos()
	_build_ui()

func _scan_photos() -> void:
	# Сначала пробуем DirAccess (работает в редакторе и в сборке с PCK)
	var dir := DirAccess.open(PHOTO_DIR)
	if dir != null:
		dir.list_dir_begin()
		var fname := dir.get_next()
		while fname != "":
			if not dir.current_is_dir() and fname.ends_with(".png"):
				var parts := fname.split("_", false, 2)
				if parts.size() >= 2 and parts[0] == "title":
					var idx := parts[1].to_int()
					_photo_map[idx] = PHOTO_DIR + fname
			fname = dir.get_next()
		dir.list_dir_end()

	# Если DirAccess не нашёл файлы — заполняем из константы
	if _photo_map.is_empty():
		for idx in PHOTO_FALLBACK:
			var full_path: String = PHOTO_DIR + PHOTO_FALLBACK[idx]
			if ResourceLoader.exists(full_path):
				_photo_map[idx] = full_path

func _build_ui() -> void:
	var vp   := get_viewport().get_visible_rect().size
	var sc   := clampf(vp.x / 1920.0, 0.58, 1.0)
	var px   := vp.x * 0.045
	var py   := vp.y * 0.055

	# ── Затемнение ──
	var dimmer := ColorRect.new()
	dimmer.set_anchors_preset(Control.PRESET_FULL_RECT)
	dimmer.color = Color(0.0, 0.0, 0.04, 0.82)
	dimmer.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(dimmer)

	var root_ctrl := Control.new()
	root_ctrl.set_anchors_preset(Control.PRESET_FULL_RECT)
	root_ctrl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root_ctrl)

	# ── Главная панель (якоря) ──
	_panel = Panel.new()
	_panel.anchor_left = 0.0;  _panel.anchor_right  = 1.0
	_panel.anchor_top  = 0.0;  _panel.anchor_bottom = 1.0
	_panel.offset_left =  px;  _panel.offset_right  = -px
	_panel.offset_top  =  py;  _panel.offset_bottom = -py
	var ps := StyleBoxFlat.new()
	ps.bg_color     = Color(0.055, 0.055, 0.09, 0.98)
	ps.border_color = Color(0.70, 0.58, 0.10, 1.0)
	for side in [SIDE_LEFT, SIDE_RIGHT, SIDE_TOP, SIDE_BOTTOM]:
		ps.set_border_width(side, 2)
		ps.set_corner_radius(side, 10)
	ps.content_margin_left   = 14
	ps.content_margin_right  = 14
	ps.content_margin_top    = 10
	ps.content_margin_bottom = 10
	_panel.add_theme_stylebox_override("panel", ps)
	root_ctrl.add_child(_panel)

	var root_vbox := VBoxContainer.new()
	root_vbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	root_vbox.add_theme_constant_override("separation", 8)
	_panel.add_child(root_vbox)

	# ═══ ШАПКА ═══════════════════════════════════════════════════════════════
	var hdr_bg := PanelContainer.new()
	var hdr_sty := StyleBoxFlat.new()
	hdr_sty.bg_color     = Color(0.10, 0.08, 0.02, 0.95)
	hdr_sty.border_color = Color(0.70, 0.58, 0.10, 0.70)
	hdr_sty.set_border_width(SIDE_BOTTOM, 1)
	for s in [SIDE_LEFT, SIDE_RIGHT, SIDE_TOP, SIDE_BOTTOM]:
		hdr_sty.set_corner_radius(s, 6)
	hdr_sty.content_margin_left   = 12
	hdr_sty.content_margin_right  = 8
	hdr_sty.content_margin_top    = 6
	hdr_sty.content_margin_bottom = 6
	hdr_bg.add_theme_stylebox_override("panel", hdr_sty)
	root_vbox.add_child(hdr_bg)

	var hdr_row := HBoxContainer.new()
	hdr_row.add_theme_constant_override("separation", 10)
	hdr_bg.add_child(hdr_row)

	var hdr_lbl := Label.new()
	hdr_lbl.text = "👑  Справочник титулов"
	hdr_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hdr_lbl.add_theme_font_size_override("font_size", int(20 * sc))
	hdr_lbl.add_theme_color_override("font_color", Color(1.0, 0.88, 0.22))
	hdr_lbl.add_theme_constant_override("outline_size", 2)
	hdr_lbl.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.80))
	hdr_row.add_child(hdr_lbl)

	# Прогресс в шапке (компактный)
	_progress_lbl = Label.new()
	_progress_lbl.add_theme_font_size_override("font_size", int(11 * sc))
	_progress_lbl.add_theme_color_override("font_color", Color(0.70, 0.70, 0.58))
	_progress_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	hdr_row.add_child(_progress_lbl)

	_progress_bar = ProgressBar.new()
	_progress_bar.custom_minimum_size       = Vector2(clampf(vp.x * 0.10, 80.0, 160.0), 10)
	_progress_bar.size_flags_vertical       = Control.SIZE_SHRINK_CENTER
	_progress_bar.show_percentage           = false
	var pb_bg := StyleBoxFlat.new()
	pb_bg.bg_color = Color(0.14, 0.11, 0.03);  pb_bg.set_corner_radius_all(5)
	var pb_fill := StyleBoxFlat.new()
	pb_fill.bg_color = Color(0.82, 0.66, 0.12); pb_fill.set_corner_radius_all(5)
	_progress_bar.add_theme_stylebox_override("background", pb_bg)
	_progress_bar.add_theme_stylebox_override("fill", pb_fill)
	hdr_row.add_child(_progress_bar)

	var close_btn := Button.new()
	close_btn.text = "✕"
	close_btn.custom_minimum_size = Vector2(30, 30)
	close_btn.add_theme_font_size_override("font_size", 14)
	var cs := StyleBoxFlat.new()
	cs.bg_color = Color(0.20, 0.06, 0.06, 0.90); cs.border_color = Color(0.55, 0.16, 0.16, 0.80)
	for s in [SIDE_LEFT, SIDE_RIGHT, SIDE_TOP, SIDE_BOTTOM]:
		cs.set_border_width(s, 1); cs.set_corner_radius(s, 6)
	var cs_h := cs.duplicate() as StyleBoxFlat
	cs_h.bg_color = Color(0.38, 0.08, 0.08, 0.95)
	close_btn.add_theme_stylebox_override("normal", cs)
	close_btn.add_theme_stylebox_override("hover",  cs_h)
	close_btn.pressed.connect(func(): _close())
	hdr_row.add_child(close_btn)

	# ═══ ОСНОВНОЙ КОНТЕНТ ════════════════════════════════════════════════════
	var content := HBoxContainer.new()
	content.size_flags_vertical = Control.SIZE_EXPAND_FILL
	content.add_theme_constant_override("separation", 10)
	root_vbox.add_child(content)

	# ── Левая колонка — список ──────────────────────────────────────────────
	var list_w := clampf(vp.x * 0.20, 185.0, 260.0)
	var left_wrap := PanelContainer.new()
	left_wrap.custom_minimum_size = Vector2(list_w, 0)
	var lps := StyleBoxFlat.new()
	lps.bg_color     = Color(0.06, 0.06, 0.10, 0.90)
	lps.border_color = Color(0.28, 0.28, 0.46, 0.55)
	for s in [SIDE_LEFT, SIDE_RIGHT, SIDE_TOP, SIDE_BOTTOM]:
		lps.set_border_width(s, 1); lps.set_corner_radius(s, 8)
	lps.content_margin_left = 3; lps.content_margin_right  = 3
	lps.content_margin_top  = 4; lps.content_margin_bottom = 4
	left_wrap.add_theme_stylebox_override("panel", lps)
	content.add_child(left_wrap)

	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	left_wrap.add_child(scroll)

	_list = VBoxContainer.new()
	_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_list.add_theme_constant_override("separation", 4)
	scroll.add_child(_list)

	# ── Правая панель (фото слева + инфо справа) ───────────────────────────
	var right_wrap := PanelContainer.new()
	right_wrap.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var rps := StyleBoxFlat.new()
	rps.bg_color     = Color(0.06, 0.06, 0.10, 0.90)
	rps.border_color = Color(0.46, 0.38, 0.10, 0.55)
	for s in [SIDE_LEFT, SIDE_RIGHT, SIDE_TOP, SIDE_BOTTOM]:
		rps.set_border_width(s, 1); rps.set_corner_radius(s, 8)
	rps.content_margin_left   = 12
	rps.content_margin_right  = 12
	rps.content_margin_top    = 12
	rps.content_margin_bottom = 12
	right_wrap.add_theme_stylebox_override("panel", rps)
	right_wrap.clip_contents = true
	content.add_child(right_wrap)

	# Вертикальный контейнер: [фото-баннер сверху | инфо-колонка снизу].
	# Фото — широкоформатное (landscape), поэтому раскладка по высоте, а не
	# по горизонтали, подходит ему естественно и не требует обрезки.
	var right_vbox := VBoxContainer.new()
	right_vbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	right_vbox.add_theme_constant_override("separation", 12)
	right_wrap.add_child(right_vbox)

	# ── Блок фото (сверху) — высота считается из ширины панели по фиксированному
	# соотношению сторон 3:2, чтобы картинка целиком влезала без обрезки ──
	var ph_panel := PanelContainer.new()
	ph_panel.custom_minimum_size = Vector2(0, clampf(vp.x * 0.42 * (2.0 / 3.0), 160.0, 340.0))
	ph_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	ph_panel.clip_contents = true
	var phps := StyleBoxFlat.new()
	phps.bg_color     = Color(0.08, 0.08, 0.12, 0.90)
	phps.border_color = Color(0.24, 0.24, 0.36, 0.55)
	for s in [SIDE_LEFT, SIDE_RIGHT, SIDE_TOP, SIDE_BOTTOM]:
		phps.set_border_width(s, 1); phps.set_corner_radius(s, 6)
	ph_panel.add_theme_stylebox_override("panel", phps)
	right_vbox.add_child(ph_panel)
	_detail_photo_placeholder_panel = ph_panel

	_detail_photo = TextureRect.new()
	_detail_photo.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	# Без этого TextureRect требует себе место по полному пиксельному размеру
	# текстуры (expand_mode по умолчанию = EXPAND_KEEP_SIZE), и PanelContainer
	# наследует этот огромный минимальный размер, раздувая баннер на весь экран.
	_detail_photo.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_detail_photo.visible = false
	ph_panel.add_child(_detail_photo)

	_detail_photo_placeholder = Label.new()
	_detail_photo_placeholder.text = "📷\nФото появится\nпозже"
	_detail_photo_placeholder.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_detail_photo_placeholder.vertical_alignment   = VERTICAL_ALIGNMENT_CENTER
	_detail_photo_placeholder.add_theme_font_size_override("font_size", int(12 * sc))
	_detail_photo_placeholder.add_theme_color_override("font_color", Color(0.35, 0.35, 0.46))
	ph_panel.add_child(_detail_photo_placeholder)

	# ── Инфо-колонка (снизу) ──
	var info_col := VBoxContainer.new()
	info_col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info_col.size_flags_vertical   = Control.SIZE_EXPAND_FILL
	info_col.add_theme_constant_override("separation", int(6 * sc))
	right_vbox.add_child(info_col)

	# Большая иконка + статус рядом
	var top_row := HBoxContainer.new()
	top_row.add_theme_constant_override("separation", 10)
	info_col.add_child(top_row)

	_detail_icon = Label.new()
	_detail_icon.add_theme_font_size_override("font_size", int(52 * sc))
	_detail_icon.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_detail_icon.custom_minimum_size = Vector2(int(60 * sc), 0)
	top_row.add_child(_detail_icon)

	var top_texts := VBoxContainer.new()
	top_texts.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top_texts.add_theme_constant_override("separation", 2)
	top_row.add_child(top_texts)

	_detail_status = Label.new()
	_detail_status.add_theme_font_size_override("font_size", int(11 * sc))
	top_texts.add_child(_detail_status)

	_detail_name = Label.new()
	_detail_name.add_theme_font_size_override("font_size", int(26 * sc))
	_detail_name.add_theme_color_override("font_color", Color(1.0, 0.88, 0.22))
	_detail_name.add_theme_constant_override("outline_size", 3)
	_detail_name.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.80))
	top_texts.add_child(_detail_name)

	_detail_money = Label.new()
	_detail_money.add_theme_font_size_override("font_size", int(12 * sc))
	_detail_money.add_theme_color_override("font_color", Color(0.55, 0.88, 0.50))
	top_texts.add_child(_detail_money)

	# Разделитель
	var dsep := HSeparator.new()
	dsep.add_theme_color_override("color", Color(0.50, 0.40, 0.10, 0.40))
	info_col.add_child(dsep)

	# Описание в скролле
	var desc_scroll := ScrollContainer.new()
	desc_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	desc_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info_col.add_child(desc_scroll)

	_detail_desc = Label.new()
	_detail_desc.add_theme_font_size_override("font_size", int(13 * sc))
	_detail_desc.add_theme_color_override("font_color", Color(0.83, 0.83, 0.76))
	_detail_desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_detail_desc.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	desc_scroll.add_child(_detail_desc)

	# Подсказка (пока ничего не выбрано)
	var hint := Label.new()
	hint.text = "← выбери титул из списка"
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.add_theme_font_size_override("font_size", int(11 * sc))
	hint.add_theme_color_override("font_color", Color(0.32, 0.32, 0.42))
	info_col.add_child(hint)

func open() -> void:
	_rebuild_list()
	visible = true
	_panel.modulate.a = 0.0
	_panel.scale = Vector2(0.92, 0.92)
	var tw := create_tween()
	tw.set_parallel(true)
	tw.tween_property(_panel, "modulate:a", 1.0, 0.22)
	tw.tween_property(_panel, "scale", Vector2(1.0, 1.0), 0.22) \
		.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	# Выбрать текущий титул сразу
	var gm: Node = get_node_or_null("/root/GameManager")
	if gm:
		_select(gm.current_title_index)

func _close() -> void:
	var tw := create_tween()
	tw.set_parallel(true)
	tw.tween_property(_panel, "modulate:a", 0.0, 0.16)
	tw.tween_property(_panel, "scale", Vector2(0.94, 0.94), 0.16)
	tw.set_parallel(false)
	tw.tween_callback(func(): visible = false)

func _rebuild_list() -> void:
	for c in _list.get_children():
		c.queue_free()

	var gm: Node = get_node_or_null("/root/GameManager")
	var current_idx: int = gm.current_title_index if gm else 0
	var titles: Array = gm.TITLES if gm else []

	# Прогресс
	_progress_lbl.text = "Прогресс: %d / %d" % [current_idx + 1, titles.size()]
	_progress_bar.max_value = titles.size()
	_progress_bar.value     = current_idx + 1

	for i in titles.size():
		var t: Dictionary = titles[i]
		var is_current:  bool = (i == current_idx)
		var is_reached:  bool = (i <= current_idx)
		var is_next:     bool = (i == current_idx + 1)

		var btn := Button.new()
		btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		btn.custom_minimum_size = Vector2(0, 32)
		btn.clip_text = true
		btn.focus_mode = Control.FOCUS_NONE
		btn.alignment = HORIZONTAL_ALIGNMENT_LEFT

		# Стиль кнопки
		var bs := StyleBoxFlat.new()
		if is_current:
			bs.bg_color     = Color(0.22, 0.18, 0.04, 0.95)
			bs.border_color = Color(1.0, 0.82, 0.18, 0.90)
		elif is_reached:
			bs.bg_color     = Color(0.10, 0.14, 0.08, 0.85)
			bs.border_color = Color(0.35, 0.55, 0.20, 0.70)
		elif is_next:
			bs.bg_color     = Color(0.10, 0.10, 0.16, 0.85)
			bs.border_color = Color(0.35, 0.42, 0.60, 0.60)
		else:
			bs.bg_color     = Color(0.07, 0.07, 0.10, 0.70)
			bs.border_color = Color(0.18, 0.18, 0.25, 0.50)
		for s in [SIDE_LEFT, SIDE_RIGHT, SIDE_TOP, SIDE_BOTTOM]:
			bs.set_border_width(s, 1)
			bs.set_corner_radius(s, 5)
		bs.content_margin_left   = 8
		bs.content_margin_right  = 6
		bs.content_margin_top    = 5
		bs.content_margin_bottom = 5
		btn.add_theme_stylebox_override("normal", bs)
		btn.add_theme_stylebox_override("hover",  _hover_style(bs))
		btn.add_theme_stylebox_override("pressed", bs)

		# Содержимое кнопки
		var hb := HBoxContainer.new()
		hb.set_anchors_preset(Control.PRESET_FULL_RECT)
		hb.add_theme_constant_override("separation", 6)
		btn.add_child(hb)

		# Иконка статуса
		var status_icon := Label.new()
		status_icon.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		if is_current:
			status_icon.text = "▶"
			status_icon.add_theme_color_override("font_color", Color(1.0, 0.85, 0.18))
		elif is_reached:
			status_icon.text = "✓"
			status_icon.add_theme_color_override("font_color", Color(0.40, 0.85, 0.40))
		else:
			status_icon.text = "○"
			status_icon.add_theme_color_override("font_color", Color(0.30, 0.30, 0.40))
		var sc := clampf(get_viewport().get_visible_rect().size.x / 1920.0, 0.60, 1.0)
		status_icon.add_theme_font_size_override("font_size", int(11 * sc))
		status_icon.custom_minimum_size = Vector2(14, 0)
		hb.add_child(status_icon)

		# Иконка титула
		var icon_lbl := Label.new()
		icon_lbl.text = t.icon
		icon_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		icon_lbl.add_theme_font_size_override("font_size", int(15 * sc))
		if not is_reached:
			icon_lbl.modulate = Color(0.35, 0.35, 0.40)
		hb.add_child(icon_lbl)

		# Название
		var name_lbl := Label.new()
		name_lbl.text = t.name
		name_lbl.clip_text = true
		name_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		name_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		name_lbl.add_theme_font_size_override("font_size", int(12 * sc))
		if is_current:
			name_lbl.add_theme_color_override("font_color", Color(1.0, 0.88, 0.22))
			name_lbl.add_theme_constant_override("outline_size", 2)
			name_lbl.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.50))
		elif is_reached:
			name_lbl.add_theme_color_override("font_color", Color(0.75, 0.90, 0.65))
		else:
			name_lbl.add_theme_color_override("font_color", Color(0.35, 0.35, 0.45))
		hb.add_child(name_lbl)

		var idx := i
		btn.pressed.connect(func(): _select(idx))
		_list.add_child(btn)

func _hover_style(base: StyleBoxFlat) -> StyleBoxFlat:
	var h := base.duplicate() as StyleBoxFlat
	h.bg_color = h.bg_color.lightened(0.10)
	return h

func _select(idx: int) -> void:
	_selected_index = idx
	var gm: Node = get_node_or_null("/root/GameManager")
	if gm == null:
		return
	var titles: Array = gm.TITLES
	if idx < 0 or idx >= titles.size():
		return
	var t: Dictionary = titles[idx]
	var current_idx: int = gm.current_title_index
	var is_current: bool  = (idx == current_idx)
	var is_reached: bool  = (idx <= current_idx)

	_detail_icon.text = t.icon

	if is_current:
		_detail_status.text = "★ Текущий титул"
		_detail_status.add_theme_color_override("font_color", Color(1.0, 0.82, 0.18))
	elif is_reached:
		_detail_status.text = "✓ Достигнут"
		_detail_status.add_theme_color_override("font_color", Color(0.40, 0.85, 0.40))
	else:
		_detail_status.text = "🔒 Не достигнут"
		_detail_status.add_theme_color_override("font_color", Color(0.45, 0.45, 0.55))

	_detail_name.text = t.name
	_detail_name.add_theme_color_override("font_color",
		Color(1.0, 0.88, 0.22) if is_reached else Color(0.45, 0.45, 0.55))

	if t.min_money == 0:
		_detail_money.text = "💰 Начальный титул"
	else:
		_detail_money.text = "💰 От %s" % _fmt_money(t.min_money)

	_detail_desc.text = t.get("desc", "")

	# Загружаем фото по индексу (title_{idx}_*.png)
	# Сама панель-рамка (_detail_photo_placeholder_panel) остаётся видимой всегда —
	# переключаем только то, что внутри: фото или текст-плейсхолдер.
	if _photo_map.has(idx):
		var tex: Texture2D = load(_photo_map[idx])
		_detail_photo.texture  = tex
		_detail_photo.visible  = true
		_detail_photo_placeholder.visible = false
	else:
		_detail_photo.visible = false
		_detail_photo_placeholder.visible = true

	# Анимация появления карточки
	var detail_root := _detail_icon.get_parent()
	detail_root.modulate.a = 0.0
	var tw := create_tween()
	tw.tween_property(detail_root, "modulate:a", 1.0, 0.18)

func _fmt_money(amount: float) -> String:
	if amount >= 1_000_000_000:
		return "%.1f млрд ₽" % (amount / 1_000_000_000.0)
	if amount >= 1_000_000:
		return "%.1f млн ₽" % (amount / 1_000_000.0)
	if amount >= 1_000:
		return "%.0f тыс. ₽" % (amount / 1_000.0)
	return "%.0f ₽" % amount

func _input(event: InputEvent) -> void:
	if not visible:
		return
	if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		_close()
		get_viewport().set_input_as_handled()
