extends CanvasLayer

signal finished(multiplier: float)

const BAR_W:       float = 520.0
const BAR_H:       float = 56.0
const NUM_SECTIONS: int  = 8
const HITS_NEEDED:  int  = 3
const NUM_STICKS:   int  = 100   # полоска рисуется как N палочек, закрашенных по зонам
const STICK_GAP:    float = 1.0

# Ускорение курсора при отскоке от стенки: +30% плавно за 2-2.6 сек, с потолком
const BOUNCE_MULT_STEP: float = 1.3
const BOUNCE_MULT_MAX:  float = 2.6
var _bounce_speed_mult: float = 1.0

const ZONE_COLORS: Array = [
	Color(0.70, 0.10, 0.10),   # 0 miss    — тёмно-красный
	Color(0.72, 0.60, 0.05),   # 1 ok      — жёлтый
	Color(0.12, 0.65, 0.18),   # 2 good    — зелёный
	Color(0.90, 0.72, 0.02),   # 3 perfect — золотой
]
const ZONE_NAMES:  Array = ["МИМО",   "ОК",     "ХОРОШО", "ИДЕАЛ!"]
const ZONE_MULTS:  Array = [0.0,       1.0,      1.5,      2.0]
const ZONE_EMOJIS: Array = ["💀",     "👍",     "✅",     "⭐"]

# Состояние
var _sections:    Array = []
var _cursor_x:    float = 0.0
var _cursor_dir:  float = 1.0
var _speed:       float = 240.0
var _base_speed:  float = 240.0
var _input_delay: float = 0.35
var _stopped:     bool  = false
var _hit_count:   int   = 0
var _hit_zones:   Array = []   # зоны трёх ударов
var _flash_timer: float = 0.0  # таймер вспышки после удара

# UI узлы
var _bar:          Control
var _panel:        Panel
var _title_lbl:    Label
var _edu_lbl:      Label
var _hint_lbl:     Label
var _result_lbl:   Label
var _hits_row:     HBoxContainer
var _hit_labels:   Array = []
var _zone_labels:  Array = []  # Label-узлы над секциями

func _ready() -> void:
	layer = 12
	visible = false
	add_to_group("minigame")
	_build_ui()

func _build_ui() -> void:
	var dimmer := ColorRect.new()
	dimmer.set_anchors_preset(Control.PRESET_FULL_RECT)
	dimmer.color = Color(0, 0, 0, 0.65)
	dimmer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(dimmer)

	_panel = Panel.new()
	var panel: Panel = _panel
	panel.set_anchors_preset(Control.PRESET_CENTER)
	panel.position = Vector2(-310, -155)
	panel.size = Vector2(620, 310)
	var ps := StyleBoxFlat.new()
	ps.bg_color = Color(0.04, 0.04, 0.08, 0.97)
	ps.border_color = Color(0.35, 0.55, 0.90, 0.85)
	for side in [SIDE_LEFT, SIDE_RIGHT, SIDE_TOP, SIDE_BOTTOM]:
		ps.set_border_width(side, 2)
		ps.set_corner_radius(side, 10)
	panel.add_theme_stylebox_override("panel", ps)
	add_child(panel)

	# Заголовок
	_title_lbl = Label.new()
	_title_lbl.position = Vector2(0, 10)
	_title_lbl.size = Vector2(620, 28)
	_title_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_title_lbl.add_theme_font_size_override("font_size", 18)
	_title_lbl.add_theme_color_override("font_color", Color(1.0, 0.88, 0.25))
	_title_lbl.add_theme_constant_override("outline_size", 3)
	_title_lbl.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.75))
	panel.add_child(_title_lbl)

	# Образование
	_edu_lbl = Label.new()
	_edu_lbl.position = Vector2(0, 36)
	_edu_lbl.size = Vector2(620, 18)
	_edu_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_edu_lbl.add_theme_font_size_override("font_size", 11)
	_edu_lbl.add_theme_color_override("font_color", Color(0.55, 0.80, 1.0))
	panel.add_child(_edu_lbl)

	# Ряд кружков ударов (○ → заполняются после каждого удара)
	_hits_row = HBoxContainer.new()
	_hits_row.position = Vector2(0, 56)
	_hits_row.size = Vector2(620, 24)
	_hits_row.alignment = BoxContainer.ALIGNMENT_CENTER
	_hits_row.add_theme_constant_override("separation", 12)
	panel.add_child(_hits_row)

	for i in HITS_NEEDED:
		var lbl := Label.new()
		lbl.text = "○"
		lbl.add_theme_font_size_override("font_size", 20)
		lbl.add_theme_color_override("font_color", Color(0.4, 0.4, 0.4))
		_hits_row.add_child(lbl)
		_hit_labels.append(lbl)

	# Полоска (расположена с отступом 50 px слева для центровки в panel 620)
	_bar = Control.new()
	_bar.position = Vector2(50, 90)
	_bar.size = Vector2(BAR_W, BAR_H)
	_bar.draw.connect(_on_bar_draw)
	panel.add_child(_bar)

	# Разделитель под полоской
	var sep := ColorRect.new()
	sep.color = Color(0.25, 0.30, 0.50, 0.50)
	sep.position = Vector2(40, 154)
	sep.size = Vector2(540, 1)
	panel.add_child(sep)

	# Подсказка
	_hint_lbl = Label.new()
	_hint_lbl.position = Vector2(0, 163)
	_hint_lbl.size = Vector2(620, 24)
	_hint_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_hint_lbl.add_theme_font_size_override("font_size", 13)
	_hint_lbl.add_theme_color_override("font_color", Color(0.70, 0.75, 0.90))
	_hint_lbl.text = "Нажми  [E]  или  [Пробел]  3 раза — попади в зелёную зону!"
	panel.add_child(_hint_lbl)

	# Результат (большой)
	_result_lbl = Label.new()
	_result_lbl.position = Vector2(0, 198)
	_result_lbl.size = Vector2(620, 80)
	_result_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_result_lbl.add_theme_font_size_override("font_size", 26)
	_result_lbl.add_theme_constant_override("outline_size", 4)
	_result_lbl.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.80))
	_result_lbl.visible = false
	panel.add_child(_result_lbl)

# ── Отрисовка ──────────────────────────────────────────────────────────────

func _zone_at_x(x: float) -> int:
	for s in _sections:
		if x >= s.x_start and x <= s.x_end:
			return s.zone
	return 0

func _on_bar_draw() -> void:
	# 1. Полоска из палочек — каждая закрашена цветом своей зоны (вид эквалайзера)
	var stick_w: float = BAR_W / float(NUM_STICKS)
	for i in NUM_STICKS:
		var sx: float = i * stick_w
		var mid: float = sx + stick_w * 0.5
		var zone: int = _zone_at_x(mid)
		var col: Color = ZONE_COLORS[zone]
		if _flash_timer > 0.0 and _cursor_x >= sx and _cursor_x <= sx + stick_w:
			col = col.lightened(_flash_timer * 0.65)
		_bar.draw_rect(Rect2(sx + STICK_GAP * 0.5, 2.0, stick_w - STICK_GAP, BAR_H - 4.0), col)

	# 2. Рамка
	_bar.draw_rect(Rect2(0, 0, BAR_W, BAR_H), Color(1, 1, 1, 0.6), false, 2.0)

	# 4. Курсор
	if not _stopped:
		var cx: float = _cursor_x
		# Вертикальная линия
		_bar.draw_line(Vector2(cx, -2), Vector2(cx, BAR_H + 2), Color(1, 1, 1, 0.95), 4.0)
		# Треугольник сверху
		var tri := PackedVector2Array([
			Vector2(cx,      -16),
			Vector2(cx - 9,  -4),
			Vector2(cx + 9,  -4),
		])
		_bar.draw_colored_polygon(tri, Color(1, 1, 1, 0.95))
		# Треугольник снизу
		var tri2 := PackedVector2Array([
			Vector2(cx,      BAR_H + 16),
			Vector2(cx - 9,  BAR_H + 4),
			Vector2(cx + 9,  BAR_H + 4),
		])
		_bar.draw_colored_polygon(tri2, Color(1, 1, 1, 0.85))

# ── Логика ─────────────────────────────────────────────────────────────────

func start(action_name: String, speed_mult: float = 1.0) -> void:
	_stopped    = false
	_hit_count  = 0
	_hit_zones.clear()
	_cursor_x   = 0.0
	_cursor_dir = 1.0
	_base_speed = 200.0 + speed_mult * 60.0
	_speed      = _base_speed
	_input_delay = 0.35
	_flash_timer = 0.0
	_bounce_speed_mult = 1.0

	_title_lbl.text = "⚡ " + action_name
	_result_lbl.visible = false
	_hint_lbl.visible = true

	# Сброс кружков
	for lbl in _hit_labels:
		lbl.text = "○"
		lbl.add_theme_color_override("font_color", Color(0.4, 0.4, 0.4))

	# Подпись образования
	var em: Node = get_node_or_null("/root/EducationManager")
	if em:
		_edu_lbl.text = em.get_level_icon() + " " + em.get_level_name() + " — влияет на зоны"
	else:
		_edu_lbl.text = ""

	_generate_sections()
	visible = true
	_panel.modulate.a = 0.0
	_panel.scale = Vector2(0.88, 0.88)
	var tw := create_tween()
	tw.set_parallel(true)
	tw.tween_property(_panel, "modulate:a", 1.0, 0.20)
	tw.tween_property(_panel, "scale", Vector2(1.0, 1.0), 0.20).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	_bar.queue_redraw()

func _generate_sections() -> void:
	# Удаляем старые Label-узлы зон
	for lbl in _zone_labels:
		if is_instance_valid(lbl): lbl.queue_free()
	_zone_labels.clear()
	_sections.clear()

	var em: Node = get_node_or_null("/root/EducationManager")
	var weights: Array = [45, 30, 15, 10]
	if em: weights = em.get_zone_weights()

	# Пул типов зон по весам
	var pool: Array = []
	for z in 4:
		for _i in weights[z]:
			pool.append(z)
	pool.shuffle()

	# Ширины секций с рандомизацией ±30%
	var widths: Array = []
	var base_w: float = BAR_W / NUM_SECTIONS
	var remaining: float = BAR_W
	for i in NUM_SECTIONS:
		if i == NUM_SECTIONS - 1:
			widths.append(maxf(remaining, base_w * 0.4))
		else:
			var w: float = clampf(base_w + randf_range(-base_w * 0.3, base_w * 0.3), base_w * 0.4, base_w * 1.6)
			widths.append(w)
			remaining -= w

	var x: float = 0.0
	for i in NUM_SECTIONS:
		var zone_type: int = pool[i % pool.size()]
		_sections.append({"x_start": x, "x_end": x + widths[i], "zone": zone_type})

		# Создаём Label с именем зоны над секцией
		var zone_lbl := Label.new()
		var mid_x: float = x + widths[i] * 0.5
		zone_lbl.text = ZONE_NAMES[zone_type]
		zone_lbl.add_theme_font_size_override("font_size", 9)
		zone_lbl.add_theme_color_override("font_color", ZONE_COLORS[zone_type].lightened(0.55))
		zone_lbl.size = Vector2(widths[i], 16)
		# Позиция относительно panel: bar.position.x + mid_x - ширина/2
		zone_lbl.position = Vector2(50 + mid_x - widths[i] * 0.5, 75)
		zone_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		zone_lbl.clip_contents = true
		_bar.get_parent().add_child(zone_lbl)
		_zone_labels.append(zone_lbl)

		x += widths[i]

func _process(delta: float) -> void:
	if not visible or _stopped:
		return

	_cursor_x += _cursor_dir * _speed * _bounce_speed_mult * delta
	if _cursor_x >= BAR_W:
		_cursor_x = BAR_W
		_cursor_dir = -1.0
		_on_wall_bounce()
	elif _cursor_x <= 0.0:
		_cursor_x = 0.0
		_cursor_dir = 1.0
		_on_wall_bounce()

	if _flash_timer > 0.0:
		_flash_timer = maxf(_flash_timer - delta * 3.5, 0.0)
	_bar.queue_redraw()

	if _input_delay > 0.0:
		_input_delay -= delta
		return

	if Input.is_action_just_pressed("interact") or Input.is_action_just_pressed("ui_accept"):
		_register_hit()

func _on_wall_bounce() -> void:
	# Каждый отскок от стенки плавно разгоняет курсор на +30% за 2-2.6 сек (с потолком)
	var target: float = minf(_bounce_speed_mult * BOUNCE_MULT_STEP, BOUNCE_MULT_MAX)
	if target <= _bounce_speed_mult:
		return
	var btw := create_tween()
	btw.tween_property(self, "_bounce_speed_mult", target, randf_range(2.0, 2.6)).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_SINE)

func _spawn_hit_particles(zone: int) -> void:
	var col: Color = ZONE_COLORS[zone]
	var count: int = 3 + zone * 2
	var bx: float = 380.0 + _cursor_x
	var by: float = 310.0
	for i in count:
		var p := ColorRect.new()
		p.size = Vector2(randf_range(3.0, 6.5), randf_range(3.0, 6.5))
		p.color = col.lightened(randf_range(0.0, 0.35))
		p.position = Vector2(bx + randf_range(-10, 10), by + randf_range(-8, 8))
		add_child(p)
		var scatter := Vector2(randf_range(-55, 55), randf_range(-70, -4))
		var tw := p.create_tween()
		tw.set_parallel(true)
		tw.tween_property(p, "position", p.position + scatter, 0.48).set_ease(Tween.EASE_OUT)
		tw.tween_property(p, "scale", Vector2(0.2, 0.2), 0.48).set_ease(Tween.EASE_IN)
		tw.tween_property(p, "modulate:a", 0.0, 0.38).set_delay(0.12)
		tw.set_parallel(false)
		tw.tween_callback(p.queue_free)

func _spawn_perfect_rain() -> void:
	for i in 30:
		var p := ColorRect.new()
		p.size = Vector2(randf_range(3.0, 6.0), randf_range(3.0, 6.0))
		p.color = Color(1.0, 0.88, 0.20, 0.92)
		p.position = Vector2(randf_range(330.0, 950.0), randf_range(185.0, 215.0))
		add_child(p)
		var fall: float = randf_range(190.0, 330.0)
		var dur: float = randf_range(0.55, 1.10)
		var tw := p.create_tween()
		tw.set_parallel(true)
		tw.tween_property(p, "position:y", p.position.y + fall, dur).set_ease(Tween.EASE_IN)
		tw.tween_property(p, "modulate:a", 0.0, dur * 0.60).set_delay(dur * 0.38)
		tw.set_parallel(false)
		tw.tween_callback(p.queue_free)

func _register_hit() -> void:
	var zone: int = _zone_at_x(_cursor_x)

	_flash_timer = 1.0
	_spawn_hit_particles(zone)
	_hit_zones.append(zone)

	# Обновляем кружок удара
	var lbl: Label = _hit_labels[_hit_count]
	lbl.text = ZONE_EMOJIS[zone]
	lbl.add_theme_color_override("font_color", ZONE_COLORS[zone].lightened(0.25))

	_hit_count += 1

	var am: Node = get_node_or_null("/root/AudioManager")

	if _hit_count >= HITS_NEEDED:
		_finish_game(am)
	else:
		if am:
			if zone >= 2: am.play_coin()
			else: am.play_negative()
		if zone == 0:
			var ox: float = _panel.position.x
			var stw := create_tween()
			stw.tween_property(_panel, "position:x", ox + 10.0, 0.04)
			stw.tween_property(_panel, "position:x", ox - 9.0,  0.04)
			stw.tween_property(_panel, "position:x", ox + 5.0,  0.03)
			stw.tween_property(_panel, "position:x", ox,        0.03)
		# Перегенерируем секции и ускоряем
		_speed = _base_speed + _hit_count * 40.0
		_input_delay = 0.2
		_generate_sections()
		_bar.queue_redraw()
		_hint_lbl.text = "Удар %d из %d — продолжай!" % [_hit_count + 1, HITS_NEEDED]

func _finish_game(am: Node) -> void:
	_stopped = true
	_hint_lbl.visible = false

	# Скрываем label-подписи зон
	for lbl in _zone_labels:
		if is_instance_valid(lbl): lbl.visible = false

	# Считаем средний множитель
	var total: float = 0.0
	for z in _hit_zones:
		total += ZONE_MULTS[z]
	var avg_mult: float = total / HITS_NEEDED

	# Бонус комбо: если все 3 — perfect (2.5x итого)
	var all_perfect := _hit_zones.count(3) == HITS_NEEDED
	var all_good_plus := _hit_zones.count(0) == 0  # ни одного промаха
	if all_perfect:
		avg_mult = 2.5
	elif all_good_plus and avg_mult >= 1.5:
		avg_mult = minf(avg_mult * 1.1, 2.5)  # +10% бонус за чистую серию

	# Строим строку результата
	var hit_str := ""
	for z in _hit_zones:
		hit_str += ZONE_EMOJIS[z] + " "
	var mult_str := "×%.1f" % avg_mult
	if all_perfect:
		mult_str += " 🔥 КОМБО!"
	elif all_good_plus:
		mult_str += " 💪 Чисто!"

	_result_lbl.text = hit_str.strip_edges() + "\n" + mult_str
	var avg_zone: int = clampi(roundi(avg_mult), 0, 3)
	_result_lbl.add_theme_color_override("font_color", ZONE_COLORS[mini(avg_zone, 3)].lightened(0.3))
	_result_lbl.scale = Vector2(0.5, 0.5)
	_result_lbl.modulate.a = 0.0
	_result_lbl.visible = true
	var pop_tw := create_tween()
	pop_tw.set_parallel(true)
	pop_tw.tween_property(_result_lbl, "scale", Vector2(1.0, 1.0), 0.22).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	pop_tw.tween_property(_result_lbl, "modulate:a", 1.0, 0.18)
	if all_perfect:
		_spawn_perfect_rain()

	if am:
		if avg_mult >= 1.5: am.play_level_up()
		elif avg_mult >= 1.0: am.play_coin()
		else: am.play_negative()

	await get_tree().create_timer(1.8).timeout
	visible = false
	finished.emit(avg_mult)
