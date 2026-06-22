extends CanvasLayer

# Атмосфера времён года: падающие частицы (снег/листья/дождь), тёплый отсвет
# летом и баннер при смене сезона. Тонировка мира делается отдельно в World.

var _gm: Node
var _parts: Array = []   # {n, sp, sw, ph, rot}
var _fx: String = ""
var _vw: float = 1280.0
var _vh: float = 720.0
var _t: float = 0.0
var _warm: ColorRect = null
var _suppressed: bool = false   # глушится во время погодного дождя (DayNightCycle)

func _ready() -> void:
	layer = 1
	add_to_group("season_fx")
	_gm = get_node_or_null("/root/GameManager")
	var vp := get_viewport().get_visible_rect().size
	_vw = vp.x
	_vh = vp.y
	if _gm and _gm.has_signal("season_changed"):
		_gm.season_changed.connect(_on_season_changed)
	_rebuild()

func _on_season_changed(_idx: int) -> void:
	_rebuild()
	_show_banner()

func _rebuild() -> void:
	for c in get_children():
		c.queue_free()
	_parts.clear()
	_warm = null
	var s: Dictionary = _gm.get_season() if (_gm and _gm.has_method("get_season")) else {"fx": "snow"}
	_fx = s.get("fx", "")
	match _fx:
		"snow":   _make_snow()
		"rain":   _make_rain()
		"leaves": _make_leaves()
		"sun":    _make_sun()
	if _suppressed:
		set_suppressed(true)   # пересоздали частицы — вернуть скрытие, если идёт дождь

# Глушит сезонные частицы (вызывает DayNightCycle на время погодного дождя),
# чтобы не рендерить две системы частиц разом.
func set_suppressed(on: bool) -> void:
	_suppressed = on
	for d in _parts:
		if is_instance_valid(d.n):
			d.n.visible = not on
	if _warm and is_instance_valid(_warm):
		_warm.visible = not on
	set_process(not on)

# ── Генераторы частиц ─────────────────────────────────────────────────────────
func _make_snow() -> void:
	for i in 44:
		var p := ColorRect.new()
		var sz := randf_range(2.0, 5.0)
		p.size = Vector2(sz, sz)
		p.color = Color(1, 1, 1, randf_range(0.45, 0.9))
		p.position = Vector2(randf() * _vw, randf() * _vh)
		p.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(p)
		_parts.append({"n": p, "sp": randf_range(25.0, 60.0), "sw": randf_range(12.0, 34.0), "ph": randf() * TAU, "rot": 0.0})

func _make_rain() -> void:
	for i in 44:
		var p := ColorRect.new()
		p.size = Vector2(2.0, randf_range(10.0, 18.0))
		p.color = Color(0.6, 0.75, 1.0, randf_range(0.25, 0.5))
		p.rotation = 0.12
		p.position = Vector2(randf() * _vw, randf() * _vh)
		p.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(p)
		_parts.append({"n": p, "sp": randf_range(420.0, 640.0), "sw": 0.0, "ph": 0.0, "rot": 0.0})

func _make_leaves() -> void:
	var glyphs := ["🍂", "🍁", "🍃"]
	for i in 16:
		var p := Label.new()
		p.text = glyphs[randi() % glyphs.size()]
		p.add_theme_font_size_override("font_size", randi_range(16, 26))
		p.position = Vector2(randf() * _vw, randf() * _vh)
		p.pivot_offset = Vector2(12, 12)
		p.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(p)
		_parts.append({"n": p, "sp": randf_range(35.0, 80.0), "sw": randf_range(28.0, 60.0), "ph": randf() * TAU, "rot": randf_range(-1.5, 1.5)})

func _make_sun() -> void:
	# Тёплый отсвет на весь экран
	_warm = ColorRect.new()
	_warm.set_anchors_preset(Control.PRESET_FULL_RECT)
	_warm.color = Color(1.0, 0.85, 0.40, 0.05)
	_warm.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_warm)
	# Редкие парящие пылинки/блики
	for i in 12:
		var p := ColorRect.new()
		var sz := randf_range(2.0, 4.0)
		p.size = Vector2(sz, sz)
		p.color = Color(1.0, 0.95, 0.6, randf_range(0.15, 0.4))
		p.position = Vector2(randf() * _vw, randf() * _vh)
		p.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(p)
		# летят вверх, медленно
		_parts.append({"n": p, "sp": randf_range(-18.0, -6.0), "sw": randf_range(8.0, 20.0), "ph": randf() * TAU, "rot": 0.0})

func _process(delta: float) -> void:
	if _suppressed or _parts.is_empty():
		return
	_t += delta
	for d in _parts:
		var n: Control = d.n
		if not is_instance_valid(n):
			continue
		n.position.y += d.sp * delta
		if d.sw != 0.0:
			n.position.x += sin(d.ph + _t * 1.5) * d.sw * delta
		if d.rot != 0.0:
			n.rotation += d.rot * delta
		# Зацикливание
		if d.sp >= 0.0 and n.position.y > _vh + 20.0:
			n.position.y = -20.0
			n.position.x = randf() * _vw
		elif d.sp < 0.0 and n.position.y < -20.0:
			n.position.y = _vh + 20.0
			n.position.x = randf() * _vw
		if n.position.x < -30.0: n.position.x = _vw + 10.0
		elif n.position.x > _vw + 30.0: n.position.x = -10.0

# ── Баннер смены сезона ───────────────────────────────────────────────────────
func _show_banner() -> void:
	var s: Dictionary = _gm.get_season()
	var lbl := Label.new()
	lbl.text = "%s  %s" % [s.get("icon", ""), s.get("name", "")]
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.set_anchors_preset(Control.PRESET_CENTER_TOP)
	lbl.position = Vector2(_vw * 0.5 - 200.0, 120.0)
	lbl.size = Vector2(400.0, 60.0)
	lbl.add_theme_font_size_override("font_size", 40)
	lbl.add_theme_color_override("font_color", Color(1.0, 0.96, 0.85))
	lbl.add_theme_constant_override("outline_size", 6)
	lbl.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.9))
	lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	lbl.modulate.a = 0.0
	lbl.scale = Vector2(0.7, 0.7)
	add_child(lbl)
	var tw := create_tween()
	tw.set_parallel(true)
	tw.tween_property(lbl, "modulate:a", 1.0, 0.5)
	tw.tween_property(lbl, "scale", Vector2(1.0, 1.0), 0.5).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	tw.set_parallel(false)
	tw.tween_interval(2.0)
	tw.tween_property(lbl, "modulate:a", 0.0, 0.6)
	tw.tween_callback(lbl.queue_free)
