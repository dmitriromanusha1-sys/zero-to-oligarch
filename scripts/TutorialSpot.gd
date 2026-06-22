extends Control
# Рисует «прожектор»: затемняет экран, оставляя светлое окно вокруг цели,
# и пульсирующую рамку. Если target_rect пустой — просто затемнение всего экрана.

var target_rect: Rect2 = Rect2()
var pulse: float = 0.0
var show_arrow: bool = false
const DIM := Color(0.0, 0.0, 0.0, 0.60)

func _draw() -> void:
	var vp := get_viewport_rect().size
	if target_rect.size.x <= 1.0 or target_rect.size.y <= 1.0:
		draw_rect(Rect2(Vector2.ZERO, vp), DIM, true)
		return
	var r := target_rect.grow(10.0)
	# Затемняем всё, кроме окна r — четырьмя прямоугольниками
	draw_rect(Rect2(0, 0, vp.x, r.position.y), DIM, true)                            # верх
	draw_rect(Rect2(0, r.end.y, vp.x, vp.y - r.end.y), DIM, true)                    # низ
	draw_rect(Rect2(0, r.position.y, r.position.x, r.size.y), DIM, true)             # лево
	draw_rect(Rect2(r.end.x, r.position.y, vp.x - r.end.x, r.size.y), DIM, true)     # право
	# Пульсирующая рамка вокруг цели
	var glow: float = 0.5 + 0.5 * sin(pulse * 4.0)
	var col := Color(1.0, 0.84, 0.26, 0.55 + 0.45 * glow)
	var w: float = 3.0 + 2.0 * glow
	draw_rect(r, col, false, w)
	# Анимированная стрелка-указатель над целью
	if show_arrow:
		_draw_arrow(r)

func _draw_arrow(r: Rect2) -> void:
	var cx: float = r.position.x + r.size.x * 0.5
	var bob: float = 8.0 + 6.0 * sin(pulse * 3.0)
	var tip_y: float = r.position.y - bob
	var aw: float = 22.0
	var ah: float = 26.0
	var tip := Vector2(cx, tip_y)
	var left := Vector2(cx - aw, tip_y - ah)
	var right := Vector2(cx + aw, tip_y - ah)
	var arrow_col := Color(1.0, 0.82, 0.18, 0.95)
	# Тень для контраста на светлом фоне
	var sh := PackedVector2Array([tip + Vector2(2, 2), left + Vector2(2, 2), right + Vector2(2, 2)])
	draw_colored_polygon(sh, Color(0, 0, 0, 0.45))
	var tri := PackedVector2Array([tip, left, right])
	draw_colored_polygon(tri, arrow_col)
	draw_polyline(PackedVector2Array([left, tip, right]), Color(0.25, 0.18, 0.0, 0.9), 2.0)
	# Стебель стрелки
	draw_rect(Rect2(cx - 7.0, tip_y - ah - 14.0, 14.0, 16.0), arrow_col, true)
