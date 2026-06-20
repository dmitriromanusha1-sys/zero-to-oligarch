extends CharacterBody2D

const BASE_SPEED = 200.0

# Speed multiplier per title index (Бомж→Нищий→Бедный→Средний→Богатый→Миллионер→Мультимиллионер)
const TRANSPORT := [
	{"name": "🚶 Пешком",    "mult": 1.0},
	{"name": "🚶 Пешком",    "mult": 1.0},
	{"name": "🚲 Велосипед", "mult": 1.4},
	{"name": "🚲 Велосипед", "mult": 1.4},
	{"name": "🚗 Машина",    "mult": 2.0},
	{"name": "🚗 Машина",    "mult": 2.0},
	{"name": "🚙 Лимузин",   "mult": 2.8},
]

# Цвет модуляции спрайта по титулу (визуальное "одевание" персонажа)
const TITLE_COLORS := [
	Color(0.55, 0.45, 0.35),   # 0  Бомж           — серо-коричневый
	Color(0.60, 0.50, 0.40),   # 1  Бродяга         — тёмный беж
	Color(0.65, 0.55, 0.45),   # 2  Нищий           — беж
	Color(0.75, 0.65, 0.50),   # 3  Безработный      — светлый беж
	Color(0.80, 0.70, 0.55),   # 4  Бедный           — бежевый
	Color(0.70, 0.80, 0.65),   # 5  Работяга         — зелёная рабочая
	Color(0.60, 0.75, 0.60),   # 6  Простой          — зелёная рубашка
	Color(0.55, 0.70, 0.80),   # 7  Средний класс    — голубая рубашка
	Color(0.50, 0.60, 0.85),   # 8  Специалист       — синий костюм
	Color(0.45, 0.55, 0.90),   # 9  Менеджер         — насыщенный синий
	Color(0.40, 0.50, 0.95),   # 10 Богатый          — тёмно-синий
	Color(0.70, 0.55, 0.85),   # 11 Предприниматель  — фиолетовый
	Color(0.85, 0.75, 0.30),   # 12 Миллионер        — золотой пиджак
	Color(0.90, 0.80, 0.25),   # 13 Бизнесмен        — ярче-золотой
	Color(1.00, 0.95, 0.60),   # 14 Мультимиллионер  — светло-золотой
	Color(1.00, 0.85, 0.20),   # 15 Магнат           — янтарный
	Color(1.00, 0.75, 0.10),   # 16 Олигарх          — оранжево-золотой
]

const PLAYER_PHOTOS := [
	"res://assets/players/title_0_bomzh.png",
	"res://assets/players/title_1_brodyaga.png",
	"res://assets/players/title_2_nishiy.png",
	"res://assets/players/title_3_bezrabotny.png",
	"res://assets/players/title_4_bedny.png",
	"res://assets/players/title_5_rabotyaga.png",
	"res://assets/players/title_6_prostoy.png",
	"res://assets/players/title_7_sredniy_klass.png",
	"res://assets/players/title_8_spetsialist.png",
	"res://assets/players/title_9_menedzher.png",
	"res://assets/players/title_10_bogatiy.png",
	"res://assets/players/title_11_predprinimatel.png",
	"res://assets/players/title_12_millioner.png",
	"res://assets/players/title_13_biznesmen.png",
	"res://assets/players/title_14_multimillioner.png",
	"res://assets/players/title_15_magnat.png",
	"res://assets/players/title_16_oligarh.png",
]

var _speed_mult: float = 1.0
var _gm: Node
var _sprite: Sprite2D
var _sprite_base_scale: Vector2 = Vector2.ONE
var _walk_phase: float = 0.0
var _step_timer: float = 0.0
var _streak_timer: float = 0.0
var _was_moving_fast: bool = false

func _ready() -> void:
	add_to_group("player")
	_gm = get_node("/root/GameManager")
	_gm.title_changed.connect(_on_title_changed)
	_sprite = $Sprite2D
	_sprite_base_scale = _sprite.scale
	_add_shadow()
	var tm: Node = get_node_or_null("/root/TransportManager")
	if tm:
		tm.transport_changed.connect(_on_transport_changed)
	_update_speed()
	_update_appearance()
	_apply_view_zoom(_gm.view_zoom)
	_gm.view_zoom_changed.connect(_apply_view_zoom)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and Input.is_key_pressed(KEY_CTRL):
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			_gm.adjust_view_zoom(1.0)
			get_viewport().set_input_as_handled()
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			_gm.adjust_view_zoom(-1.0)
			get_viewport().set_input_as_handled()

func _apply_view_zoom(zoom: float) -> void:
	var cam: Camera2D = get_node_or_null("Camera2D")
	if cam:
		cam.zoom = Vector2(zoom, zoom)

func _add_shadow() -> void:
	var shadow := Sprite2D.new()
	# Эллипс-тень из простого квадрата с растяжением
	var img := Image.create(32, 12, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	var cx: float = 16.0; var cy: float = 6.0
	var rx: float = 15.0; var ry: float = 5.0
	for py in 12:
		for px in 32:
			var dx: float = (px - cx) / rx
			var dy: float = (py - cy) / ry
			if dx*dx + dy*dy <= 1.0:
				var edge: float = clampf(1.0 - (dx*dx + dy*dy) * 1.2, 0.0, 1.0)
				img.set_pixel(px, py, Color(0, 0, 0, 0.45 * edge))
	shadow.texture = ImageTexture.create_from_image(img)
	shadow.position = Vector2(0, 38)
	shadow.z_index = -1
	add_child(shadow)

func _physics_process(delta: float) -> void:
	var direction := Vector2.ZERO
	if Input.is_key_pressed(KEY_D) or Input.is_key_pressed(KEY_RIGHT):
		direction.x += 1
	if Input.is_key_pressed(KEY_A) or Input.is_key_pressed(KEY_LEFT):
		direction.x -= 1
	if Input.is_key_pressed(KEY_S) or Input.is_key_pressed(KEY_DOWN):
		direction.y += 1
	if Input.is_key_pressed(KEY_W) or Input.is_key_pressed(KEY_UP):
		direction.y -= 1
	if direction == Vector2.ZERO:
		# Тач-джойстик
		var joy_nodes := get_tree().get_nodes_in_group("virtual_joystick")
		if not joy_nodes.is_empty():
			direction = joy_nodes[0].direction
	if direction != Vector2.ZERO:
		direction = direction.normalized()
	velocity = direction * BASE_SPEED * _speed_mult
	move_and_slide()

	# Шаговая анимация: боб по Y
	if _sprite:
		if velocity.length() > 10.0:
			_walk_phase += delta * (6.0 + _speed_mult * 2.5)
			_sprite.position.y = sin(_walk_phase) * 3.2
			_sprite.position.x = sin(_walk_phase * 0.5) * 1.2
		else:
			_walk_phase = 0.0
			_sprite.position = _sprite.position.lerp(Vector2.ZERO, delta * 12.0)
	if _sprite and velocity.x != 0:
		_sprite.flip_h = velocity.x < 0

	if velocity.length() > 10.0:
		_step_timer += delta
		if _step_timer >= 0.20:
			_step_timer = 0.0
			_spawn_dust_puff()
	else:
		_step_timer = 0.0

	# Полосы скорости для машины и лимузина
	var moving_fast: bool = _speed_mult >= 2.0 and velocity.length() > 10.0
	if moving_fast:
		_streak_timer += delta
		if _streak_timer >= 0.06:
			_streak_timer = 0.0
			_spawn_speed_streak()
	else:
		_streak_timer = 0.0

	# Облако пыли при резком торможении с высокой скорости
	if _was_moving_fast and not moving_fast and _speed_mult >= 2.0:
		_spawn_skid_cloud()
	_was_moving_fast = moving_fast

	# Дыхание в покое
	if _sprite:
		if velocity.length() <= 10.0:
			var breath: float = sin(Time.get_ticks_msec() * 0.0014) * 0.014
			_sprite.scale = _sprite_base_scale * Vector2(1.0, 1.0 + breath)
		else:
			_sprite.scale = _sprite_base_scale

func _spawn_dust_puff() -> void:
	var puff := ColorRect.new()
	puff.size = Vector2(6, 3)
	puff.color = Color(0.70, 0.63, 0.50, 0.40)
	puff.position = global_position + Vector2(randf_range(-7, 7), 24)
	get_parent().add_child(puff)
	var tw := puff.create_tween()
	tw.set_parallel(true)
	tw.tween_property(puff, "scale", Vector2(2.4, 1.5), 0.38).set_ease(Tween.EASE_OUT)
	tw.tween_property(puff, "modulate:a", 0.0, 0.34).set_delay(0.06)
	tw.set_parallel(false)
	tw.tween_callback(puff.queue_free)

func _spawn_skid_cloud() -> void:
	for i in 5:
		var puff := ColorRect.new()
		var sz: float = randf_range(10.0, 22.0)
		puff.size = Vector2(sz, sz * 0.6)
		puff.color = Color(0.72, 0.66, 0.55, 0.55)
		puff.position = global_position + Vector2(randf_range(-18, 18), 18 + randf_range(-5, 5))
		get_parent().add_child(puff)
		var tw := puff.create_tween()
		tw.set_parallel(true)
		tw.tween_property(puff, "scale", Vector2(2.8, 1.6), 0.50).set_ease(Tween.EASE_OUT)
		tw.tween_property(puff, "modulate:a", 0.0, 0.45).set_delay(0.08)
		tw.set_parallel(false)
		tw.tween_callback(puff.queue_free)

func _spawn_speed_streak() -> void:
	var streak := ColorRect.new()
	var w: float = randf_range(60, 160)
	streak.size = Vector2(w, 1)
	var sign_x: float = sign(velocity.x) if velocity.x != 0 else 1.0
	streak.position = global_position + Vector2(-sign_x * w * 0.5 - sign_x * 30, randf_range(-18, 18))
	streak.color = Color(1.0, 1.0, 1.0, 0.22)
	streak.mouse_filter = Control.MOUSE_FILTER_IGNORE
	get_parent().add_child(streak)
	var tw := streak.create_tween()
	tw.set_parallel(true)
	tw.tween_property(streak, "modulate:a", 0.0, 0.16).set_ease(Tween.EASE_IN)
	tw.tween_property(streak, "position", streak.position + Vector2(-sign_x * 50, 0), 0.16)
	tw.set_parallel(false)
	tw.tween_callback(streak.queue_free)

func _on_title_changed(_title: String) -> void:
	_update_speed()
	_update_appearance()

func _on_transport_changed(_vname: String, mult: float) -> void:
	_speed_mult = mult

func _update_speed() -> void:
	var tm: Node = get_node_or_null("/root/TransportManager")
	if tm:
		_speed_mult = tm.get_speed_mult()
	else:
		_speed_mult = TRANSPORT[_gm.current_title_index].mult

func _update_appearance() -> void:
	var idx: int = clamp(_gm.current_title_index, 0, PLAYER_PHOTOS.size() - 1)
	if not _sprite:
		return
	var path: String = PLAYER_PHOTOS[idx]
	if ResourceLoader.exists(path):
		var tex: Texture2D = load(path)
		_sprite.texture = tex
		_sprite.modulate = Color.WHITE
	else:
		# Фото нет — показываем исходный спрайт с цветом по титулу
		_sprite.modulate = TITLE_COLORS[idx]

func get_transport_name() -> String:
	var tm: Node = get_node_or_null("/root/TransportManager")
	if tm:
		return tm.get_current_name()
	return TRANSPORT[clamp(_gm.current_title_index, 0, TRANSPORT.size() - 1)].name

func shake_camera(strength: float = 6.0, duration: float = 0.3) -> void:
	var cam: Camera2D = get_node_or_null("Camera2D")
	if cam == null:
		return
	var origin := cam.offset
	var tw := create_tween()
	tw.set_loops(int(duration / 0.05))
	tw.tween_property(cam, "offset",
		origin + Vector2(randf_range(-strength, strength), randf_range(-strength, strength)), 0.04)
	tw.tween_property(cam, "offset", origin, 0.01)
	await tw.finished
	cam.offset = Vector2.ZERO
