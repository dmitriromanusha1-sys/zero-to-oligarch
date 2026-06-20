extends Node

signal transport_changed(vehicle_name: String, mult: float)

const VEHICLES: Array = [
	{"id":"walk",    "name":"🚶 Пешком",      "price":0,          "mult":1.0,  "zone_req":0, "desc":"Стандартная ходьба"},
	{"id":"scooter", "name":"🛴 Самокат",     "price":500,        "mult":1.4,  "zone_req":0, "desc":"Быстрее пешком"},
	{"id":"bike",    "name":"🚲 Велосипед",   "price":3000,       "mult":1.7,  "zone_req":1, "desc":"Бесшумно и бодро"},
	{"id":"zhigul",  "name":"🚗 Жигуль",      "price":25000,      "mult":2.2,  "zone_req":2, "desc":"Надёжный советский автопром"},
	{"id":"foreign", "name":"🚙 Иномарка",    "price":350000,     "mult":3.0,  "zone_req":4, "desc":"Комфорт и скорость"},
	{"id":"luxury",  "name":"🏎 Роскошь авто","price":4000000,    "mult":4.0,  "zone_req":6, "desc":"Суперкар для элиты"},
	{"id":"plane",   "name":"✈ Самолёт",      "price":25000000,   "mult":6.0,  "zone_req":8, "desc":"Летаешь над городом"},
]

var current_vehicle_id: String = "walk"
var owned_vehicles: Array = ["walk"]

func _ready() -> void:
	pass

func get_speed_mult() -> float:
	for v in VEHICLES:
		if v.id == current_vehicle_id:
			return v.mult
	return 1.0

func get_current_name() -> String:
	for v in VEHICLES:
		if v.id == current_vehicle_id:
			return v.name
	return "🚶 Пешком"

func is_owned(id: String) -> bool:
	return id in owned_vehicles

func can_buy(v: Dictionary) -> bool:
	var gm: Node = get_node("/root/GameManager")
	var zm: Node = get_node("/root/ZoneManager")
	if is_owned(v.id):
		return true  # уже куплен, можно пересесть
	return zm.max_zone_reached >= v.zone_req and gm.money >= v.price

func buy_and_equip(id: String) -> bool:
	var gm: Node = get_node("/root/GameManager")
	var zm: Node = get_node("/root/ZoneManager")
	for v in VEHICLES:
		if v.id != id:
			continue
		if is_owned(id):
			current_vehicle_id = id
			emit_signal("transport_changed", v.name, v.mult)
			return true
		if zm.max_zone_reached < v.zone_req:
			return false
		if gm.money < v.price:
			return false
		gm.spend_money(v.price)
		owned_vehicles.append(id)
		current_vehicle_id = id
		emit_signal("transport_changed", v.name, v.mult)
		gm.save_game()
		return true
	return false

func save(cfg: ConfigFile) -> void:
	cfg.set_value("transport", "current", current_vehicle_id)
	cfg.set_value("transport", "owned", owned_vehicles)

func load_data(cfg: ConfigFile) -> void:
	current_vehicle_id = cfg.get_value("transport", "current", "walk")
	owned_vehicles     = cfg.get_value("transport", "owned",   ["walk"])
