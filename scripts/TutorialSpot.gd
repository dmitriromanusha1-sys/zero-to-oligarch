extends Control
# Рисует «прожектор»: затемняет экран, оставляя светлое окно вокруг цели,
# и пульсирующую рамку. Если target_rect пустой — просто затемнение всего экрана.

var target_rect: Rect2 = Rect2()
var pulse: float = 0.0
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
