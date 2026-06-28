extends Node

signal inventory_changed

const ITEMS: Dictionary = {
	# ─── Еда ──────────────────────────────────────────────────────────────────
	"bread":       {"name":"Хлеб",          "icon":"🍞", "type":"food",  "hunger":20, "thirst":0,   "health":0,  "price":50,  "quality":45},
	"hotdog":      {"name":"Хот-дог",       "icon":"🌭", "type":"food",  "hunger":40, "thirst":3,   "health":0,  "price":150, "quality":25},
	"pie":         {"name":"Пирожок",       "icon":"🥧", "type":"food",  "hunger":35, "thirst":0,   "health":0,  "price":120, "quality":30},
	"soup":        {"name":"Суп",           "icon":"🍲", "type":"food",  "hunger":50, "thirst":5,   "health":0,  "price":200, "quality":70},
	"shawarma":    {"name":"Шаурма",        "icon":"🌯", "type":"food",  "hunger":55, "thirst":5,   "health":0,  "price":280, "quality":35},
	"burger":      {"name":"Бургер",        "icon":"🍔", "type":"food",  "hunger":65, "thirst":5,   "health":0,  "price":350, "quality":28},
	"pizza":       {"name":"Пицца",         "icon":"🍕", "type":"food",  "hunger":75, "thirst":5,   "health":0,  "price":600, "quality":32},
	# ─── Пиццерия «Итальяно» (фирменное меню) ──────────────────────────────────
	"pizza_margherita":  {"name":"Пицца «Маргарита»", "icon":"🍕", "type":"food", "hunger":60, "thirst":5,  "health":0, "price":350, "quality":40},
	"pizza_pepperoni":   {"name":"Пицца «Пепперони»", "icon":"🍕", "type":"food", "hunger":75, "thirst":8,  "health":0, "price":550, "quality":32},
	"pizza_hawaii":      {"name":"Пицца «Гавайская»", "icon":"🍕", "type":"food", "hunger":70, "thirst":10, "health":0, "price":650, "quality":40},
	"pizza_quattro":     {"name":"Пицца «4 сыра»",    "icon":"🍕", "type":"food", "hunger":85, "thirst":12, "health":0, "price":750, "quality":35},
	"lunch":       {"name":"Бизнес-ланч",   "icon":"🍱", "type":"food",  "hunger":75, "thirst":15,  "health":0,  "price":900,  "quality":72},
	"sushi":       {"name":"Суши-сет",      "icon":"🍣", "type":"food",  "hunger":85, "thirst":10,  "health":0,  "price":1500, "quality":82},
	"steak":       {"name":"Стейк",         "icon":"🥩", "type":"food",  "hunger":90, "thirst":5,   "health":0,  "price":3000, "quality":76},
	# ─── Напитки ──────────────────────────────────────────────────────────────
	"water":       {"name":"Вода",          "icon":"💧", "type":"drink", "hunger":0,  "thirst":35,  "health":0,  "price":30,  "quality":92},
	"kvas":        {"name":"Квас",          "icon":"🍺", "type":"drink", "hunger":5,  "thirst":45,  "health":0,  "price":70,  "quality":35},
	"tea":         {"name":"Чай",           "icon":"🍵", "type":"drink", "hunger":0,  "thirst":40,  "health":3,  "price":60,  "quality":78},
	"coffee":      {"name":"Кофе",          "icon":"☕", "type":"drink", "hunger":0,  "thirst":30,  "health":5,  "price":80,  "quality":55},
	"juice":       {"name":"Сок",           "icon":"🧃", "type":"drink", "hunger":0,  "thirst":50,  "health":0,  "price":90,  "quality":72},
	"smoothie":    {"name":"Смузи",         "icon":"🥤", "type":"drink", "hunger":0,  "thirst":55,  "health":10, "price":250, "quality":90},
	"cocktail":    {"name":"Коктейль",      "icon":"🍹", "type":"drink", "hunger":10, "thirst":60,  "health":0,  "price":500, "quality":20},
	# ─── Лечение ──────────────────────────────────────────────────────────────
	"vitamins":    {"name":"Витамины",      "icon":"💉", "type":"heal",  "hunger":0,  "thirst":0,   "health":15, "price":200},
	"bandage":     {"name":"Бинт",          "icon":"🩹", "type":"heal",  "hunger":0,  "thirst":0,   "health":20, "price":300},
	"pills":       {"name":"Таблетки",      "icon":"💊", "type":"heal",  "hunger":0,  "thirst":0,   "health":25, "price":450},
	"medkit":      {"name":"Аптечка",       "icon":"➕", "type":"heal",  "hunger":0,  "thirst":0,   "health":35, "price":600},
	"antibiotic":  {"name":"Антибиотик",    "icon":"🧪", "type":"heal",  "hunger":0,  "thirst":0,   "health":50, "price":1500},
	"elite_medkit":{"name":"Элит. аптечка","icon":"🏥", "type":"heal",  "hunger":0,  "thirst":0,   "health":75, "price":5000},
	# ─── Обеды (потребляются сразу в ресторане, снижают расход сытости/жажды на N дней) ──
	# Чем дальше зона — тем выше бонус и дольше эффект (раскладка по зонам в World.gd)
	"meal_cheap":      {"name":"Комплексный обед",     "icon":"🥗", "type":"meal", "hunger":100,"thirst":100,"health":0,"price":500,      "drain_bonus":0.10, "buff_days":2,  "quality":60},
	"meal_canteen":    {"name":"Рабочий обед",         "icon":"🍲", "type":"meal", "hunger":100,"thirst":100,"health":0,"price":900,      "drain_bonus":0.15, "buff_days":4,  "quality":66},
	"meal_cafe":       {"name":"Обед в кафе",          "icon":"🍽", "type":"meal", "hunger":100,"thirst":100,"health":0,"price":1500,     "drain_bonus":0.20, "buff_days":5,  "quality":72},
	"meal_restaurant": {"name":"Обед в ресторане",     "icon":"🥘", "type":"meal", "hunger":100,"thirst":100,"health":0,"price":5000,     "drain_bonus":0.35, "buff_days":9,  "quality":78},
	"meal_business":   {"name":"Деловой обед",         "icon":"🍱", "type":"meal", "hunger":100,"thirst":100,"health":0,"price":60000,    "drain_bonus":0.45, "buff_days":12, "quality":80},
	"meal_elite":      {"name":"Гастрономический ужин","icon":"🍾", "type":"meal", "hunger":100,"thirst":100,"health":0,"price":150000,   "drain_bonus":0.55, "buff_days":15, "quality":83},
	"meal_michelin":   {"name":"Ужин от шефа",         "icon":"👨‍🍳","type":"meal", "hunger":100,"thirst":100,"health":0,"price":400000,   "drain_bonus":0.65, "buff_days":19, "quality":88},
	"meal_reception":  {"name":"Банкетный обед",       "icon":"🍽", "type":"meal", "hunger":100,"thirst":100,"health":0,"price":1000000,  "drain_bonus":0.72, "buff_days":24, "quality":86},
	"meal_imperial":   {"name":"Императорский ужин",   "icon":"🥂", "type":"meal", "hunger":100,"thirst":100,"health":0,"price":2500000,  "drain_bonus":0.80, "buff_days":30, "quality":92},
}

var inventory: Dictionary = {}   # item_id -> count

func add_item(item_id: String, count: int = 1) -> void:
	if not ITEMS.has(item_id):
		return
	if not inventory.has(item_id):
		inventory[item_id] = 0
	inventory[item_id] += count
	emit_signal("inventory_changed")

func use_item(item_id: String) -> bool:
	if not inventory.has(item_id) or inventory[item_id] <= 0:
		return false
	var item: Dictionary = ITEMS[item_id]
	var gm: Node = get_node("/root/GameManager")
	if item.type == "meal":
		apply_meal_effect(item, gm)
	else:
		if item.hunger > 0:
			gm.hunger = clamp(gm.hunger + item.hunger, 0.0, gm.stat_max())
			gm.emit_signal("hunger_changed", gm.hunger)
		if item.thirst > 0:
			gm.thirst = clamp(gm.thirst + item.thirst, 0.0, gm.stat_max())
			gm.emit_signal("thirst_changed", gm.thirst)
		if item.health > 0:
			gm.health = clamp(gm.health + item.health, 0.0, gm.stat_max())
			gm.emit_signal("health_changed", gm.health)
	# Рацион: что именно съедено/выпито смещает качество питания
	if item.type in ["food", "drink", "meal"] and gm.has_method("record_meal"):
		var w: float = 0.22
		if item.type == "meal": w = 0.32
		elif item.type == "drink": w = 0.10
		gm.record_meal(item.get("quality", 50.0), w)
	inventory[item_id] -= 1
	if inventory[item_id] <= 0:
		inventory.erase(item_id)
	emit_signal("inventory_changed")
	return true

func apply_meal_effect(item: Dictionary, gm: Node = null) -> void:
	if gm == null:
		gm = get_node("/root/GameManager")
	gm.hunger = gm.stat_max()
	gm.emit_signal("hunger_changed", gm.hunger)
	gm.thirst = gm.stat_max()
	gm.emit_signal("thirst_changed", gm.thirst)
	var bonus: float = item.get("drain_bonus", 0.0)
	var days: int = item.get("buff_days", 0)
	if bonus >= gm.meal_drain_bonus:
		# Новый обед не слабее текущего — полностью заменяем бонус и срок
		gm.meal_drain_bonus = bonus
		gm.meal_buff_days = days
	elif days > gm.meal_buff_days:
		# Обед слабее, но продлевает остаток срока текущего бонуса
		gm.meal_buff_days = days

func get_count(item_id: String) -> int:
	return inventory.get(item_id, 0)

func has_any() -> bool:
	return not inventory.is_empty()

func save(cfg: ConfigFile) -> void:
	cfg.set_value("inventory", "items", inventory)

func load_data(cfg: ConfigFile) -> void:
	inventory = cfg.get_value("inventory", "items", {})
