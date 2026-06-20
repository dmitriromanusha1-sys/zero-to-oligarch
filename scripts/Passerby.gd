extends Area2D

# Случайный прохожий: движется по карте, при контакте с игроком — событие

const FloatingText = preload("res://scripts/FloatingText.gd")

enum Type { HELPFUL, THIEF, DRUNK, VENDOR }

var passerby_type: Type = Type.HELPFUL
var speed: float = 60.0
var direction: float = 1.0   # 1 = вправо, -1 = влево
var _gm: Node
var _triggered: bool = false
var _label: Label
var _legs: Array[ColorRect] = []
var _shoes: Array[ColorRect] = []
var _walk_anim: float = 0.0
var _visual_root: Node2D = null

const HELPFUL_TIPS := [
	"💡 Совет: вкладывай деньги в банк!",
	"💡 Совет: здоровье восстанавливается в поликлинике",
	"💡 Совет: бизнес даёт пассивный доход каждый день",
	"💡 Совет: казино — это риск. Не ставь последнее!",
	"💡 Совет: чем лучше жильё — тем быстрее растёт здоровье",
	"💡 Совет: налоги платятся каждые 30 дней",
	"💡 Совет: репутация влияет на полицейские проверки",
]

const DRUNK_LINES := [
	"🍺 Ик... эй, дай денег...",
	"🍺 Я тут живу! Или нет...",
	"🍺 Главное — не сдаваться! Ик.",
	"🍺 Видал мэра? Жулик.",
]

func setup(ptype: Type, pos: Vector2, dir: float) -> void:
	passerby_type = ptype
	global_position = pos
	direction = dir
	_gm = get_node("/root/GameManager")
	_build_visuals()

func _ready() -> void:
	add_to_group("passerby")

	var shape := CollisionShape2D.new()
	var rect  := RectangleShape2D.new()
	rect.size = Vector2(40, 50)
	shape.shape = rect
	add_child(shape)

	body_entered.connect(_on_body_entered)

	var timer := Timer.new()
	timer.wait_time = 15.0
	timer.one_shot = true
	timer.timeout.connect(queue_free)
	add_child(timer)
	timer.start()

func _build_visuals() -> void:
	_visual_root = Node2D.new()
	add_child(_visual_root)

	# Цвета по типу прохожего
	var shirt: Color
	var pants: Color
	var hair: Color
	var skin := Color(0.90, 0.76, 0.60)
	match passerby_type:
		Type.HELPFUL:
			shirt = Color(0.30, 0.58, 0.88); pants = Color(0.20, 0.30, 0.60); hair = Color(0.35, 0.25, 0.15)
		Type.THIEF:
			shirt = Color(0.14, 0.14, 0.18); pants = Color(0.10, 0.10, 0.14); hair = Color(0.12, 0.10, 0.08)
		Type.DRUNK:
			shirt = Color(0.60, 0.30, 0.10); pants = Color(0.28, 0.20, 0.12); hair = Color(0.42, 0.32, 0.20)
		Type.VENDOR:
			shirt = Color(0.20, 0.58, 0.22); pants = Color(0.15, 0.38, 0.18); hair = Color(0.50, 0.35, 0.15)

	# Тень
	var shadow := ColorRect.new()
	shadow.size = Vector2(22, 6); shadow.position = Vector2(-11, 18)
	shadow.color = Color(0.0, 0.0, 0.0, 0.22)
	_visual_root.add_child(shadow)

	# Ботинки
	for sx: int in [-11, 4]:
		var shoe := ColorRect.new()
		shoe.size = Vector2(8, 6); shoe.position = Vector2(sx, 13)
		shoe.color = Color(0.12, 0.10, 0.08)
		_visual_root.add_child(shoe)
		_shoes.append(shoe)

	# Ноги
	for lx: int in [-10, 3]:
		var leg := ColorRect.new()
		leg.size = Vector2(6, 14); leg.position = Vector2(lx, 0)
		leg.color = pants
		_visual_root.add_child(leg)
		_legs.append(leg)

	# Тело
	var body := ColorRect.new()
	body.size = Vector2(22, 18); body.position = Vector2(-11, -16)
	body.color = shirt
	_visual_root.add_child(body)
	var collar := ColorRect.new()
	collar.size = Vector2(22, 2); collar.position = Vector2(-11, -16)
	collar.color = shirt.lightened(0.22)
	_visual_root.add_child(collar)

	# Голова
	var head := ColorRect.new()
	head.size = Vector2(18, 13); head.position = Vector2(-9, -29)
	head.color = skin
	_visual_root.add_child(head)

	# Волосы
	var hair_r := ColorRect.new()
	hair_r.size = Vector2(20, 6); hair_r.position = Vector2(-10, -35)
	hair_r.color = hair
	_visual_root.add_child(hair_r)

	# Глаза
	for ex: int in [-6, 3]:
		var eye := ColorRect.new()
		eye.size = Vector2(3, 3); eye.position = Vector2(ex, -25)
		eye.color = Color(0.10, 0.08, 0.06)
		_visual_root.add_child(eye)

	# Emoji-иконка над головой
	_label = Label.new()
	_label.position = Vector2(-12, -60)
	_label.add_theme_font_size_override("font_size", 16)
	_label.add_theme_constant_override("outline_size", 3)
	_label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.75))
	match passerby_type:
		Type.HELPFUL: _label.text = "😊"
		Type.THIEF:   _label.text = "🦹"
		Type.DRUNK:   _label.text = "🍺"
		Type.VENDOR:  _label.text = "🛒"
	_visual_root.add_child(_label)

	# Лёгкое покачивание (смещение Y визуала)
	var bob_tw := create_tween()
	bob_tw.set_loops()
	var phase: float = randf_range(0.0, TAU)
	bob_tw.tween_method(func(v: float): _visual_root.position.y = sin(v) * 2.0,
		phase, phase + TAU, randf_range(1.6, 2.4))

func _physics_process(delta: float) -> void:
	position.x += direction * speed * delta
	if position.x > 3700 or position.x < -3700:
		direction *= -1
	# Отражение спрайта по направлению движения
	if _visual_root:
		_visual_root.scale.x = direction
	# Анимация шага: ноги и ботинки чередуются вверх-вниз
	_walk_anim += delta * 8.5
	if _legs.size() >= 2:
		_legs[0].position.y  = sin(_walk_anim) * 3.5
		_legs[1].position.y  = sin(_walk_anim + PI) * 3.5
	if _shoes.size() >= 2:
		_shoes[0].position.y = 13.0 + sin(_walk_anim) * 3.5
		_shoes[1].position.y = 13.0 + sin(_walk_anim + PI) * 3.5

func _on_body_entered(body: Node) -> void:
	if body.name != "Player" or _triggered:
		return
	_triggered = true

	match passerby_type:
		Type.HELPFUL:
			var tip: String = HELPFUL_TIPS[randi() % HELPFUL_TIPS.size()]
			FloatingText.spawn(get_tree(), global_position, tip, Color(0.5, 0.8, 1.0))
			var rm = get_node_or_null("/root/ReputationManager")
			if rm: rm.add(1)
			_exit_hop()

		Type.THIEF:
			var rm = get_node_or_null("/root/ReputationManager")
			var steal_chance := 0.5
			if rm: steal_chance = clampf(0.5 - rm.reputation * 0.004, 0.0, 0.5)
			if randf() < steal_chance and _gm.money > 0:
				var stolen: float = min(_gm.money * 0.05, 5000.0)
				_gm.spend_money(stolen)
				FloatingText.spawn(get_tree(), global_position, "🦹 Украли " + _gm.format_money(stolen), Color(1.0, 0.3, 0.3))
				var am = get_node_or_null("/root/AudioManager")
				if am: am.play_negative()
				if rm: rm.add(-2)
			else:
				FloatingText.spawn(get_tree(), global_position, "🦹 Попытка кражи!", Color(1.0, 0.6, 0.2))
			_exit_flee()

		Type.DRUNK:
			var line: String = DRUNK_LINES[randi() % DRUNK_LINES.size()]
			FloatingText.spawn(get_tree(), global_position, line, Color(0.9, 0.7, 0.3))
			_exit_stagger()

		Type.VENDOR:
			var bonus: float = 50.0 * (1 + _gm.current_title_index)
			_gm.add_money(bonus)
			FloatingText.spawn(get_tree(), global_position, "🛒 +" + _gm.format_money(bonus), Color(0.6, 1.0, 0.4))
			_exit_hop()

func _exit_flee() -> void:
	speed *= 4.0
	var tw := create_tween()
	tw.tween_interval(0.45)
	tw.tween_property(self, "modulate:a", 0.0, 0.35)
	tw.tween_callback(queue_free)

func _exit_hop() -> void:
	if _label:
		var ltw := _label.create_tween()
		ltw.tween_property(_label, "scale", Vector2(1.6, 1.6), 0.12).set_ease(Tween.EASE_OUT)
		ltw.tween_property(_label, "scale", Vector2(1.0, 1.0), 0.20).set_ease(Tween.EASE_IN_OUT)
	if _visual_root:
		var htw := _visual_root.create_tween()
		htw.tween_property(_visual_root, "position:y", -12.0, 0.16).set_ease(Tween.EASE_OUT)
		htw.tween_property(_visual_root, "position:y", 0.0,   0.20).set_ease(Tween.EASE_IN)
	var tw := create_tween()
	tw.tween_interval(1.0)
	tw.tween_property(self, "modulate:a", 0.0, 0.40)
	tw.tween_callback(queue_free)

func _exit_stagger() -> void:
	if _visual_root:
		var stw := _visual_root.create_tween()
		stw.tween_property(_visual_root, "rotation_degrees", 18.0,  0.12)
		stw.tween_property(_visual_root, "rotation_degrees", -16.0, 0.14)
		stw.tween_property(_visual_root, "rotation_degrees", 12.0,  0.12)
		stw.tween_property(_visual_root, "rotation_degrees", 0.0,   0.18)
	var tw := create_tween()
	tw.tween_interval(0.70)
	tw.tween_property(self, "modulate:a", 0.0, 0.45)
	tw.tween_callback(queue_free)
