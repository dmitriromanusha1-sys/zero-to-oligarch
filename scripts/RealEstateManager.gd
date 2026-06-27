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

# ── Рынок недвижимости ────────────────────────────────────────────────────────
# Индекс рынка: множитель к ценам/аренде/стоимости. Колеблется со временем —
# инфляция, экономические циклы и случайность. Покупай дёшево, продавай дорого.
var market_index: float = 1.0
var _prev_index: float = 1.0

const RE_INDEX_MIN: float = 0.40
const RE_INDEX_MAX: float = 3.00
const RE_INFL_TRACK: float = 0.80   # недвижимость отслеживает ~80% инфляции
const RE_VOLATILITY: float = 0.04   # случайное колебание/мес

# Портфель: массив словарей {type_id}
var properties: Array = []

var gm: Node

func _ready() -> void:
	gm = get_node("/root/GameManager")

func _get_type(type_id: String) -> Dictionary:
	for p in PROPERTY_TYPES:
		if p.id == type_id: return p
	return {}

# Текущие рыночные цены (база × индекс рынка).
func current_price(type_id: String) -> int:
	return int(float(_get_type(type_id).get("price", 0)) * market_index)

func current_value(type_id: String) -> float:
	return float(_get_type(type_id).get("price", 0)) * market_index

func current_rent(type_id: String) -> float:
	return float(_get_type(type_id).get("rent", 0)) * market_index

# Тренд рынка: 1 рост, -1 спад, 0 стабильно.
func market_trend() -> int:
	if market_index > _prev_index + 0.005: return 1
	if market_index < _prev_index - 0.005: return -1
	return 0

func property_count() -> int:
	return properties.size()

func count_of(type_id: String) -> int:
	var n: int = 0
	for p in properties:
		if String(p.get("type_id", "")) == type_id: n += 1
	return n

func can_buy(type_id: String) -> bool:
	var t := _get_type(type_id)
	return not t.is_empty() and gm.current_title_index >= int(t.min_title) and gm.money >= float(current_price(type_id))

func buy_property(type_id: String) -> bool:
	var t := _get_type(type_id)
	if t.is_empty(): return false
	if gm.current_title_index < int(t.min_title): return false
	if not gm.spend_money(current_price(type_id)): return false
	properties.append({"type_id": type_id})
	emit_signal("portfolio_changed")
	gm.save_game()
	return true

func sell_property(index: int) -> float:
	if index < 0 or index >= properties.size(): return 0.0
	var tid := String(properties[index].get("type_id", ""))
	var value: float = current_value(tid) * SELL_RATIO
	gm.add_money(value)
	properties.remove_at(index)
	emit_signal("portfolio_changed")
	gm.save_game()
	return value

# Суммарная аренда в день (по текущему индексу рынка).
func rental_income() -> float:
	var total: float = 0.0
	for p in properties:
		total += current_rent(String(p.get("type_id", "")))
	return total

# Стоимость портфеля по рыночной цене (для капитала / net worth).
func portfolio_value() -> float:
	var total: float = 0.0
	for p in properties:
		total += current_value(String(p.get("type_id", "")))
	return total

# Ежедневно: зачисляем доход с аренды; раз в месяц двигаем рынок.
func process_day() -> void:
	var inc := rental_income()
	if inc > 0.0:
		gm.add_money(inc)
	if gm.day % 30 == 0:
		_update_market()

# Месячное движение рынка: инфляция + цикл + случайность.
func _update_market() -> void:
	_prev_index = market_index
	var cb := get_node_or_null("/root/CentralBankManager")
	var infl: float = cb.inflation if cb else 0.08
	var idx: float = market_index
	idx *= (1.0 + infl / 12.0 * RE_INFL_TRACK)
	if cb:
		if cb.has_method("is_boom") and cb.is_boom(): idx *= 1.02
		elif cb.has_method("is_recession") and cb.is_recession(): idx *= 0.975
	idx *= (1.0 + randf_range(-RE_VOLATILITY, RE_VOLATILITY))
	market_index = clampf(idx, RE_INDEX_MIN, RE_INDEX_MAX)
	var pct: float = (market_index / _prev_index - 1.0) * 100.0
	if absf(pct) >= 5.0:
		var es := get_node_or_null("/root/EventSystem")
		if es:
			es.event_triggered.emit({
				"text": "🏘 Рынок недвижимости %s на %.0f%%." % [("вырос" if pct > 0 else "просел"), absf(pct)],
				"money": 0, "health": 0})
	emit_signal("portfolio_changed")

func reset() -> void:
	properties.clear()
	market_index = 1.0
	_prev_index = 1.0

func save(cfg: ConfigFile) -> void:
	cfg.set_value("realestate", "properties", properties)
	cfg.set_value("realestate", "market_index", market_index)

func load_data(cfg: ConfigFile) -> void:
	properties = cfg.get_value("realestate", "properties", [])
	market_index = cfg.get_value("realestate", "market_index", 1.0)
	_prev_index = market_index
