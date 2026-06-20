extends Area2D

var stop_name: String = "Остановка"
var _hint: Label
var _player_inside: bool = false
var _e_was: bool = false

func _ready() -> void:
	add_to_group("bus_stop")

	# Столб
	var post := ColorRect.new()
	post.size = Vector2(6, 48)
	post.position = Vector2(-3, -48)
	post.color = Color(0.65, 0.55, 0.10)
	add_child(post)

	# Табличка
	var stop_sign := ColorRect.new()
	stop_sign.size = Vector2(52, 28)
	stop_sign.position = Vector2(-26, -76)
	stop_sign.color = Color(0.12, 0.28, 0.72)
	add_child(stop_sign)

	var sign_lbl := Label.new()
	sign_lbl.text = "🚌"
	sign_lbl.position = Vector2(-16, -76)
	sign_lbl.add_theme_font_size_override("font_size", 18)
	add_child(sign_lbl)

	# Название остановки
	var name_lbl := Label.new()
	name_lbl.text = stop_name
	name_lbl.position = Vector2(-70, -98)
	name_lbl.add_theme_font_size_override("font_size", 10)
	name_lbl.add_theme_color_override("font_color", Color(0.75, 0.85, 1.0))
	add_child(name_lbl)

	# Подсказка
	_hint = Label.new()
	_hint.text = "[E] Автобус — 50 ₽"
	_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_hint.position = Vector2(-80, 30)
	_hint.add_theme_font_size_override("font_size", 11)
	_hint.add_theme_color_override("font_color", Color(0.95, 0.90, 0.40))
	_hint.visible = false
	add_child(_hint)

	var shape := CollisionShape2D.new()
	var rect  := RectangleShape2D.new()
	rect.size = Vector2(64, 64)
	shape.shape = rect
	add_child(shape)

	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

func _process(_delta: float) -> void:
	var e_now := Input.is_key_pressed(KEY_E)
	if _player_inside and e_now and not _e_was:
		var ui = get_tree().get_first_node_in_group("bus_stop_ui")
		if ui: ui.open(self)
	_e_was = e_now

func _on_body_entered(body: Node) -> void:
	if body.name == "Player":
		_player_inside = true
		_hint.visible = true

func _on_body_exited(body: Node) -> void:
	if body.name == "Player":
		_player_inside = false
		_hint.visible = false
