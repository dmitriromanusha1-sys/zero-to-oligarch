extends Node

signal district_unlocked(district_name: String)

const DISTRICTS = [
	{
		"name": "Промзона",
		"min_title": 0,
		"x_min": -1200, "x_max": 100,
		"color": Color(0.22, 0.16, 0.10),
		"label_pos": Vector2(-1100, -680),
		"label": "🏚  ПРОМЗОНА / СВАЛКА",
	},
	{
		"name": "Рабочий квартал",
		"min_title": 1,
		"x_min": 100, "x_max": 1500,
		"color": Color(0.16, 0.20, 0.16),
		"label_pos": Vector2(200, -680),
		"label": "🏗  РАБОЧИЙ КВАРТАЛ",
	},
	{
		"name": "Спальный район",
		"min_title": 2,
		"x_min": 1500, "x_max": 2800,
		"color": Color(0.14, 0.18, 0.22),
		"label_pos": Vector2(1600, -680),
		"label": "🏘  СПАЛЬНЫЙ РАЙОН",
	},
	{
		"name": "Район среднего класса",
		"min_title": 3,
		"x_min": 2800, "x_max": 4200,
		"color": Color(0.16, 0.20, 0.18),
		"label_pos": Vector2(2900, -680),
		"label": "🏙  РАЙОН СРЕДНЕГО КЛАССА",
	},
	{
		"name": "Бизнес-квартал",
		"min_title": 4,
		"x_min": 4200, "x_max": 5600,
		"color": Color(0.12, 0.15, 0.20),
		"label_pos": Vector2(4300, -680),
		"label": "🏢  БИЗНЕС-КВАРТАЛ",
	},
	{
		"name": "Элитный район",
		"min_title": 5,
		"x_min": 5600, "x_max": 7000,
		"color": Color(0.18, 0.16, 0.10),
		"label_pos": Vector2(5700, -680),
		"label": "💎  ЭЛИТНЫЙ РАЙОН",
	},
	{
		"name": "Район олигархов",
		"min_title": 6,
		"x_min": 7000, "x_max": 8800,
		"color": Color(0.15, 0.13, 0.08),
		"label_pos": Vector2(7100, -680),
		"label": "👑  РАЙОН ОЛИГАРХОВ",
	},
]

var gm: Node
var unlocked: Array = []

func _ready() -> void:
	gm = get_node("/root/GameManager")
	gm.title_changed.connect(_on_title_changed)
	_update_unlocked()

func _update_unlocked() -> void:
	for d in DISTRICTS:
		if d.min_title <= gm.current_title_index and not unlocked.has(d.name):
			unlocked.append(d.name)

func is_unlocked(district_name: String) -> bool:
	return unlocked.has(district_name)

func _on_title_changed(_title: String) -> void:
	for d in DISTRICTS:
		if d.min_title <= gm.current_title_index and not unlocked.has(d.name):
			unlocked.append(d.name)
			emit_signal("district_unlocked", d.name)

func get_current_district(x: float) -> String:
	for d in DISTRICTS:
		if x >= d.x_min and x < d.x_max:
			return d.name
	return "Неизвестно"
