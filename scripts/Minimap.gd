extends Control

var player: Node2D = null

const DISTRICTS = [
	{"name": "Промзона",        "x_min": -1200, "x_max": 100,  "color": Color(0.40, 0.28, 0.15)},
	{"name": "Рабочий квартал", "x_min": 100,   "x_max": 1400, "color": Color(0.25, 0.38, 0.25)},
]

@onready var district_label: Label = $DistrictLabel

func _ready() -> void:
	await get_tree().process_frame
	player = get_tree().get_first_node_in_group("player")

func _process(_delta: float) -> void:
	if player == null:
		player = get_tree().get_first_node_in_group("player")
		return
	var zm = get_node_or_null("/root/ZoneManager")
	if zm:
		district_label.text = "📍 " + zm.get_zone_name()
