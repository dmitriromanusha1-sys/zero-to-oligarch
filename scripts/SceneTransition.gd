extends CanvasLayer

# Глобальный fade-переход между сценами.
# Использование: SceneTransition.go("res://scenes/World.tscn")

const FADE_OUT: float = 0.30
const FADE_IN:  float = 0.35

var _overlay: ColorRect
var _busy: bool = false

func _ready() -> void:
	layer = 200
	process_mode = Node.PROCESS_MODE_ALWAYS
	_overlay = ColorRect.new()
	_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	_overlay.color = Color(0, 0, 0, 0)
	_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_overlay)

func go(scene_path: String) -> void:
	if _busy:
		return
	_busy = true
	_overlay.mouse_filter = Control.MOUSE_FILTER_STOP

	var tw := create_tween()
	tw.tween_property(_overlay, "color:a", 1.0, FADE_OUT).set_ease(Tween.EASE_IN)
	await tw.finished

	get_tree().change_scene_to_file(scene_path)

	# Ждём следующий кадр чтобы сцена успела загрузиться
	await get_tree().process_frame
	await get_tree().process_frame

	var tw2 := create_tween()
	tw2.tween_property(_overlay, "color:a", 0.0, FADE_IN).set_ease(Tween.EASE_OUT)
	await tw2.finished

	_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_busy = false
