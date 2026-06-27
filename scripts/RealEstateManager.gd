extends Node
# Империя недвижимости. Доходные объекты (отдельно от жилья, где живёт игрок):
# покупаешь под сдачу → пассивный доход с аренды. Фаза 1: портфель + аренда.

signal portfolio_changed

# Типы доходных объектов: цена, аренда/день, требуемый титул.
const PROPERTY_TYPES: Array = [
	{"id":"room",      "name":"Комната под сдачу", "price":300_000,     "rent":240,    "min_title":2, "icon":"🚪", "desc":"Сдаёшь комнату — первый шаг рантье."},
	{"id":"studio",    "name":"Студия",            "price":1_500_000,   "rent":1_200,  "min_title":3, "icon":"🏠", "desc":"Компактная студия в спальном районе."},
	{"id":"apartment", "name":"Квартира",          "price":5_000_000,   "rent":4_000,  "min_title":4, "icon":"🏢", "desc":"Полноценная квартира под аренду."},
	{"id":"house",     "name":"Дом",               "price":20_000_000,  "rent":16_000, "min_title":5, "icon":"🏡", "desc":"Загородный дом с участком."},
	{"id":"building",  "name":"Доходный дом",      "price":80_000_000,  "rent":64_000, "min_title":6, "icon":"🏬", "desc":"Целый доходный дом — десятки арендаторов."},
	{"id":"complex",   "name":"ЖК / комплекс",     "price":400_000_000, "rent":320_000,"min_title":7, "icon":"🏗", "desc":"Жилой комплекс — масштаб застройщика."},
]

const SELL_RATIO: float = 0.90   # при продаже возвращается 90% стоимости

# Портфель: массив словарей {type_id}
var properties: Array = []

var gm: Node

func _ready() -> void:
	gm = get_node("/root/GameManager")

func _get_type(type_id: String) -> Dictionary:
	for p in PROPERTY_TYPES:
		if p.id == type_id: return p
	return {}

func property_count() -> int:
	return properties.size()

func count_of(type_id: String) -> int:
	var n: int = 0
	for p in properties:
		if String(p.get("type_id", "")) == type_id: n += 1
	return n

func can_buy(type_id: String) -> bool:
	var t := _get_type(type_id)
	return not t.is_empty() and gm.current_title_index >= int(t.min_title) and gm.money >= float(t.price)

func buy_property(type_id: String) -> bool:
	var t := _get_type(type_id)
	if t.is_empty(): return false
	if gm.current_title_index < int(t.min_title): return false
	if not gm.spend_money(t.price): return false
	properties.append({"type_id": type_id})
	emit_signal("portfolio_changed")
	gm.save_game()
	return true

func sell_property(index: int) -> float:
	if index < 0 or index >= properties.size(): return 0.0
	var t := _get_type(String(properties[index].get("type_id", "")))
	var value: float = float(t.get("price", 0)) * SELL_RATIO
	gm.add_money(value)
	properties.remove_at(index)
	emit_signal("portfolio_changed")
	gm.save_game()
	return value

# Суммарная аренда в день.
func rental_income() -> float:
	var total: float = 0.0
	for p in properties:
		var t := _get_type(String(p.get("type_id", "")))
		total += float(t.get("rent", 0))
	return total

# Стоимость портфеля (для капитала / net worth).
func portfolio_value() -> float:
	var total: float = 0.0
	for p in properties:
		var t := _get_type(String(p.get("type_id", "")))
		total += float(t.get("price", 0))
	return total

# Ежедневно: зачисляем доход с аренды.
func process_day() -> void:
	var inc := rental_income()
	if inc > 0.0:
		gm.add_money(inc)

func reset() -> void:
	properties.clear()

func save(cfg: ConfigFile) -> void:
	cfg.set_value("realestate", "properties", properties)

func load_data(cfg: ConfigFile) -> void:
	properties = cfg.get_value("realestate", "properties", [])
