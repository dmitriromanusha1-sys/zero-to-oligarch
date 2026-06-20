extends Node

const PasserbyScript = preload("res://scripts/Passerby.gd")

var _spawn_timer: Timer
var _gm: Node

# Спаун каждые 12-25 секунд
const MIN_INTERVAL := 12.0
const MAX_INTERVAL := 25.0

# Шанс типов [Helpful, Thief, Drunk, Vendor]
const TYPE_WEIGHTS := [40, 25, 20, 15]

func _ready() -> void:
	_gm = get_node("/root/GameManager")
	_spawn_timer = Timer.new()
	_spawn_timer.one_shot = true
	_spawn_timer.timeout.connect(_spawn_passerby)
	add_child(_spawn_timer)
	_schedule_next()

func _schedule_next() -> void:
	_spawn_timer.wait_time = randf_range(MIN_INTERVAL, MAX_INTERVAL)
	_spawn_timer.start()

func _spawn_passerby() -> void:
	var player = get_tree().get_first_node_in_group("player")
	if player == null:
		_schedule_next()
		return

	# Не спауним если уже 6 прохожих
	if get_tree().get_nodes_in_group("passerby").size() >= 6:
		_schedule_next()
		return

	# Спауним рядом с игроком, вне его поля зрения (~700px)
	var side: float = 1.0 if randf() > 0.5 else -1.0
	var offset_x := randf_range(680, 900) * side
	var spawn_x: float = clamp(player.global_position.x + offset_x, -3600.0, 3600.0)
	var spawn_y: float = player.global_position.y + randf_range(-250, 250)
	var dir: float = -side

	var ptype := _pick_type()

	var buildings_node = get_tree().get_root().find_child("Buildings", true, false)

	var npc = Area2D.new()
	npc.set_script(PasserbyScript)
	if buildings_node:
		buildings_node.add_child(npc)
	else:
		get_tree().root.add_child(npc)

	npc.setup(ptype, Vector2(spawn_x, spawn_y), dir)

	_schedule_next()

func _pick_type() -> int:
	var total := 0
	for w in TYPE_WEIGHTS: total += w
	var roll := randi() % total
	var acc := 0
	for i in TYPE_WEIGHTS.size():
		acc += TYPE_WEIGHTS[i]
		if roll < acc:
			return i
	return 0
