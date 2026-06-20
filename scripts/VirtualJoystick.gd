extends CanvasLayer

# Виртуальный джойстик для мобильных браузеров / touch-устройств.
# Показывается автоматически при первом касании экрана.
# Направление читается через get_direction() или переменную direction.

var direction: Vector2 = Vector2.ZERO

const DEAD_ZONE:   float = 12.0   # пикселей — игнор случайных микро-касаний
const KNOB_RADIUS: float = 50.0   # максимальный сдвиг ручки от центра
const BASE_RADIUS: float = 72.0   # радиус подложки (визуальный)

var _touch_index: int   = -1
var _base_pos:    Vector2 = Vector2.ZERO
var _base_node:   Control
var _knob_node:   Control
var _visible_joy: bool = false

func _ready() -> void:
	layer = 100
	visible = false
	add_to_group("virtual_joystick")
	_build()

func _build() -> void:
	# Подложка джойстика
	_base_node = _make_circle(BASE_RADIUS * 2.0, Color(1, 1, 1, 0.18), Color(1, 1, 1, 0.45))
	_base_node.pivot_offset = Vector2(BASE_RADIUS, BASE_RADIUS)
	add_child(_base_node)

	# Ручка
	var knob_size: float = BASE_RADIUS * 0.65
	_knob_node = _make_circle(knob_size * 2.0, Color(1, 1, 1, 0.52), Color(1, 1, 1, 0.80))
	_knob_node.pivot_offset = Vector2(knob_size, knob_size)
	add_child(_knob_node)

func _make_circle(diameter: float, fill: Color, border: Color) -> Control:
	var c := Panel.new()
	c.custom_minimum_size = Vector2(diameter, diameter)
	c.size = Vector2(diameter, diameter)
	var s := StyleBoxFlat.new()
	s.bg_color = fill
	s.border_color = border
	s.set_border_width_all(2)
	s.set_corner_radius_all(int(diameter / 2))
	c.add_theme_stylebox_override("panel", s)
	c.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return c

func _input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		if event.pressed and _touch_index < 0:
			# Принять касание только в левой половине экрана
			if event.position.x < get_viewport().get_visible_rect().size.x * 0.55:
				_touch_index = event.index
				_base_pos = event.position
				_show_at(_base_pos)
		elif not event.pressed and event.index == _touch_index:
			_release()

	elif event is InputEventScreenDrag:
		if event.index == _touch_index:
			var delta: Vector2 = event.position - _base_pos
			var delta_len: float = delta.length()
			if delta_len < DEAD_ZONE:
				direction = Vector2.ZERO
			else:
				direction = delta.normalized() if delta_len >= KNOB_RADIUS else delta / KNOB_RADIUS
			var clamped: Vector2 = delta.limit_length(KNOB_RADIUS)
			var knob_r: float = _knob_node.custom_minimum_size.x / 2.0
			_knob_node.position = _base_pos - Vector2(knob_r, knob_r) + clamped
			# Первый drag — показать joystick если ещё не видимый
			if not _visible_joy:
				visible = true
				_visible_joy = true

func _show_at(pos: Vector2) -> void:
	visible = true
	_visible_joy = true
	_base_node.position = pos - Vector2(BASE_RADIUS, BASE_RADIUS)
	var knob_r: float = _knob_node.custom_minimum_size.x / 2.0
	_knob_node.position = pos - Vector2(knob_r, knob_r)

func _release() -> void:
	_touch_index = -1
	direction = Vector2.ZERO
	visible = false
	_visible_joy = false
