extends CanvasLayer

# Overlays a semi-transparent color rect that shifts with time of day.
# Day 1-5 = morning; 6-8 = afternoon; 9-10 = evening; 11+ cycles modulo 10.
# Rain appears randomly when player has outdoor housing and penalises health.

signal weather_changed(is_raining: bool)

const RAIN_CHANCE  := 0.18        # 18% per day

var _overlay: ColorRect
var _weather_label: Label
var _weather_panel: PanelContainer
const RAIN_POOL_SIZE := 30
var _rain_pool: Array = []     # пул капель [{n: ColorRect, sp: float}], переиспользуется
var _vw: float = 1280.0
var _vh: float = 720.0

var is_raining: bool = false
var _gm: Node

var _stars: Array[ColorRect] = []
var _stars_visible: bool = false
var _lightning_timer: Timer = null
var _meteor_timer: Timer = null

func _ready() -> void:
	layer = 5   # above world, below HUD (HUD is layer 0 default, but our HUD uses CanvasLayer too)

	_overlay = ColorRect.new()
	_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_overlay.color = Color(0, 0, 0, 0)
	add_child(_overlay)

	var weather_panel := PanelContainer.new()
	weather_panel.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	weather_panel.offset_left   = -140.0
	weather_panel.offset_top    = 52.0
	weather_panel.offset_right  = -8.0
	weather_panel.offset_bottom = 84.0
	var wps := StyleBoxFlat.new()
	wps.bg_color = Color(0.05, 0.10, 0.18, 0.82)
	wps.border_color = Color(0.28, 0.52, 0.82, 0.70)
	for s in [SIDE_LEFT, SIDE_RIGHT, SIDE_TOP, SIDE_BOTTOM]:
		wps.set_border_width(s, 1)
		wps.set_corner_radius(s, 6)
	wps.content_margin_left   = 10
	wps.content_margin_right  = 10
	wps.content_margin_top    = 4
	wps.content_margin_bottom = 4
	weather_panel.add_theme_stylebox_override("panel", wps)
	weather_panel.visible = false
	add_child(weather_panel)
	_weather_panel = weather_panel

	_weather_label = Label.new()
	_weather_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_weather_label.add_theme_font_size_override("font_size", 14)
	_weather_label.add_theme_color_override("font_color", Color(0.72, 0.90, 1.0))
	_weather_label.add_theme_constant_override("outline_size", 2)
	_weather_label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.70))
	weather_panel.add_child(_weather_label)

	var vp := get_viewport().get_visible_rect().size
	_vw = vp.x
	_vh = vp.y
	# Пул капель дождя: создаётся один раз и переиспользуется. Анимируется в _process
	# только когда идёт дождь — никаких аллокаций узлов/твинов в кадре.
	for i in RAIN_POOL_SIZE:
		var drop := ColorRect.new()
		drop.size = Vector2(1.5, randf_range(14.0, 28.0))
		drop.rotation = deg_to_rad(-18.0)
		drop.color = Color(0.55, 0.72, 1.0, randf_range(0.30, 0.55))
		drop.mouse_filter = Control.MOUSE_FILTER_IGNORE
		drop.position = Vector2(randf_range(0.0, _vw), randf_range(0.0, _vh))
		drop.visible = false
		add_child(drop)
		_rain_pool.append({"n": drop, "sp": randf_range(760.0, 1050.0)})
	set_process(false)

	_gm = get_node("/root/GameManager")
	_gm.day_changed.connect(_on_day_changed)
	_gm.time_changed.connect(_on_time_changed)
	_update_cycle(_gm.current_hour)
	weather_changed.connect(_on_weather_changed)

	_lightning_timer = Timer.new()
	_lightning_timer.one_shot = true
	_lightning_timer.timeout.connect(_spawn_lightning)
	add_child(_lightning_timer)
	_lightning_timer.wait_time = randf_range(8.0, 20.0)
	_lightning_timer.start()

	_meteor_timer = Timer.new()
	_meteor_timer.one_shot = true
	_meteor_timer.timeout.connect(_spawn_meteor)
	add_child(_meteor_timer)
	_meteor_timer.wait_time = randf_range(12.0, 28.0)
	_meteor_timer.start()

func _on_weather_changed(raining: bool) -> void:
	# На время погодного дождя глушим сезонные частицы (SeasonFX), чтобы не
	# рендерить две системы дождя/частиц разом.
	var sfx := get_tree().get_first_node_in_group("season_fx")
	if sfx and sfx.has_method("set_suppressed"):
		sfx.set_suppressed(raining)
	var am: Node = get_node_or_null("/root/AudioManager")
	if am == null:
		return
	if raining:
		am.play_rain()
	else:
		am.stop_rain()

func _on_day_changed(day: int) -> void:
	_roll_weather(day)

func _on_time_changed(hour: int, _minute: int) -> void:
	_update_cycle(hour)

func _update_cycle(hour: int) -> void:
	var alpha: float
	var tint: Color

	if hour < 6:         # ночь
		alpha = 0.45
		tint  = Color(0.02, 0.02, 0.15, alpha)
	elif hour < 9:       # рассвет
		alpha = 0.08
		tint  = Color(0.9, 0.6, 0.2, alpha)
	elif hour < 18:      # день
		alpha = 0.0
		tint  = Color(0, 0, 0, 0)
	elif hour < 21:      # закат
		alpha = 0.18
		tint  = Color(0.6, 0.3, 0.1, alpha)
	else:                # вечер
		alpha = 0.32
		tint  = Color(0.05, 0.05, 0.2, alpha)

	if is_raining:
		tint = Color(0.05, 0.08, 0.18, max(alpha, 0.18))

	var tween := create_tween()
	tween.tween_property(_overlay, "color", tint, 2.0)

	# Звёзды ночью
	var is_night: bool = (hour < 6 or hour >= 21)
	if is_night and not _stars_visible:
		_spawn_stars()
	elif not is_night and _stars_visible:
		_clear_stars()

func _spawn_stars() -> void:
	_stars_visible = true
	var rng := RandomNumberGenerator.new()
	rng.seed = 12345
	for i in 36:
		var star := ColorRect.new()
		var sz: float = rng.randf_range(1.0, 3.5)
		star.size = Vector2(sz, sz)
		star.position = Vector2(rng.randf_range(0, 1280), rng.randf_range(0, 300))
		var bright: float = rng.randf_range(0.65, 1.0)
		var blue_tint: float = rng.randf_range(0.0, 0.25)
		star.color = Color(bright - blue_tint * 0.3, bright - blue_tint * 0.1, bright + blue_tint * 0.2, 0.0)
		star.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(star)
		_stars.append(star)
		# Мерцание с рандомной задержкой
		var tw := star.create_tween()
		tw.set_loops()
		var delay: float = rng.randf_range(0.0, 3.0)
		var period: float = rng.randf_range(1.2, 3.5)
		tw.tween_interval(delay)
		tw.tween_property(star, "modulate:a", rng.randf_range(0.55, 1.0), period * 0.5)
		tw.tween_property(star, "modulate:a", rng.randf_range(0.10, 0.40), period * 0.5)

func _clear_stars() -> void:
	_stars_visible = false
	for s in _stars:
		if is_instance_valid(s):
			var tw := s.create_tween()
			tw.tween_property(s, "modulate:a", 0.0, 1.0)
			tw.tween_callback(s.queue_free)
	_stars.clear()

func _roll_weather(_day: int) -> void:
	var outdoor_housings: Array = ["Улица", "Коробка", "Палатка", "Подвал", "Чердак"]
	var housing: String = _gm.get_housing()
	var was_raining := is_raining

	# Rain more likely in early game / outdoor housing
	var chance := RAIN_CHANCE
	if housing in outdoor_housings:
		chance += 0.12

	is_raining = randf() < chance
	if is_raining != was_raining:
		weather_changed.emit(is_raining)

	var tw := create_tween()
	if is_raining:
		_weather_label.text = "🌧 Дождь"
		_weather_panel.visible = true
		_weather_panel.modulate.a = 0.0
		tw.tween_property(_weather_panel, "modulate:a", 1.0, 0.50)
		_set_rain_active(true)

		if housing in outdoor_housings:
			_gm.health = max(5.0, _gm.health - 8.0)
			_gm.health_changed.emit(_gm.health)
	else:
		tw.tween_property(_weather_panel, "modulate:a", 0.0, 0.40)
		await tw.finished
		_weather_panel.visible = false
		_set_rain_active(false)

func _set_rain_active(active: bool) -> void:
	for d in _rain_pool:
		d.n.visible = active
	set_process(active)

func _process(delta: float) -> void:
	if not is_raining:
		return
	# Двигаем капли пула; ушедшую за низ переносим наверх в случайную точку
	for d in _rain_pool:
		var n: ColorRect = d.n
		n.position.y += d.sp * delta
		n.position.x -= d.sp * 0.05 * delta   # лёгкий снос по наклону
		if n.position.y > _vh + 20.0:
			n.position.y = randf_range(-40.0, -10.0)
			n.position.x = randf_range(0.0, _vw + 30.0)
		elif n.position.x < -30.0:
			n.position.x = _vw + 10.0

func _spawn_meteor() -> void:
	_meteor_timer.wait_time = randf_range(12.0, 32.0)
	_meteor_timer.start()
	if _gm.current_hour >= 6 and _gm.current_hour < 21:
		return
	# Полоска метеора: длинный тонкий ColorRect по диагонали
	var meteor := ColorRect.new()
	var length: float = randf_range(55.0, 120.0)
	meteor.size = Vector2(length, 2)
	meteor.rotation = deg_to_rad(35.0 + randf_range(-8.0, 8.0))
	var start_x: float = randf_range(100.0, 1100.0)
	meteor.position = Vector2(start_x, randf_range(10.0, 180.0))
	meteor.color = Color(0.90, 0.95, 1.0, 0.0)
	meteor.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(meteor)
	var travel := Vector2(randf_range(220.0, 380.0), randf_range(110.0, 200.0))
	var duration: float = randf_range(0.45, 0.75)
	var tw := meteor.create_tween()
	tw.set_parallel(true)
	tw.tween_property(meteor, "modulate:a", 0.92, duration * 0.15)
	tw.tween_property(meteor, "position", meteor.position + travel, duration).set_ease(Tween.EASE_IN)
	tw.set_parallel(false)
	tw.tween_property(meteor, "modulate:a", 0.0, duration * 0.30).set_delay(duration * 0.65)
	tw.tween_callback(meteor.queue_free)

func _spawn_lightning() -> void:
	var next_wait: float = randf_range(7.0, 22.0)
	_lightning_timer.wait_time = next_wait
	_lightning_timer.start()
	if not is_raining:
		return
	var flash := ColorRect.new()
	flash.set_anchors_preset(Control.PRESET_FULL_RECT)
	flash.color = Color(0.92, 0.96, 1.0, 0.0)
	flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(flash)
	var tw := flash.create_tween()
	tw.tween_property(flash, "modulate:a", 0.88, 0.04)
	tw.tween_property(flash, "modulate:a", 0.0,  0.09)
	tw.tween_interval(0.07)
	tw.tween_property(flash, "modulate:a", 0.42, 0.03)
	tw.tween_property(flash, "modulate:a", 0.0,  0.14)
	tw.tween_callback(flash.queue_free)
