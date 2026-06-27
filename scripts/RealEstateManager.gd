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

# Коммерческая недвижимость (Фаза 6): выше доходность, но аренда зависит от
# экономического цикла (бум/рецессия). cycle — чувствительность к циклу 0..1.
const COMMERCIAL_TYPES: Array = [
	{"id":"office",    "name":"Офис",            "price":10_000_000,  "rent":11_000,  "min_title":5, "icon":"🏢", "cycle":0.6,  "desc":"Офис под аренду бизнесу."},
	{"id":"retail",    "name":"Торговая площадь", "price":30_000_000,  "rent":34_000,  "min_title":5, "icon":"🏪", "cycle":0.7,  "desc":"Ритейл в проходном месте."},
	{"id":"warehouse", "name":"Склад",           "price":60_000_000,  "rent":58_000,  "min_title":6, "icon":"📦", "cycle":0.25, "desc":"Логистика — стабильный доход."},
	{"id":"hotel",     "name":"Отель",           "price":150_000_000, "rent":190_000, "min_title":6, "icon":"🏨", "cycle":1.0,  "desc":"Отель — высокий доход, цикличен."},
	{"id":"bizcenter", "name":"Бизнес-центр",     "price":500_000_000, "rent":600_000, "min_title":7, "icon":"🏬", "cycle":0.8,  "desc":"Бизнес-центр класса А."},
]

const CYCLE_SWING: float = 0.5   # ±50% аренды на пике цикла при cycle=1

# ── Девелопмент / застройка (Фаза 7) ──────────────────────────────────────────
# Строишь объект дешевле готового, но он возводится время и рискует задержками.
const BUILD_COST_RATIO: float = 0.60      # стройка = 60% цены готового
const BUILD_OVERRUN_MONTHLY: float = 0.20 # шанс задержки стройки за месяц
const PROJECT_CANCEL_REFUND: float = 0.50 # возврат при отмене стройки
var projects: Array = []   # {type_id, days_left, total_days, invested}

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

# ── Ипотека ───────────────────────────────────────────────────────────────────
const MORTGAGE_DOWN: float = 0.30    # первый взнос 30%
const MORTGAGE_MONTHS: int = 60      # срок 5 лет
const MORTGAGE_SPREAD: float = 0.03  # спред ипотеки над ключевой ставкой
const MORTGAGE_MISS_LIMIT: int = 3   # просрочек до взыскания

# ── Ремонт / класс объекта ────────────────────────────────────────────────────
const MAX_RENO_LEVEL: int = 3
const LEVEL_RENT_BONUS: float = 0.20   # +20% аренды за уровень
const LEVEL_VALUE_BONUS: float = 0.15  # +15% стоимости за уровень
const RENO_COST_FACTOR: float = 0.20   # цена ремонта = база × индекс × фактор × (ур+1)

# ── Управление и риски (Фаза 5) ───────────────────────────────────────────────
# Объект может простаивать (нет жильца → нет аренды), требует обслуживания,
# а плохой жилец иногда съезжает с ущербом. Управляющий снижает все риски за %.
const MAINT_RATE_MONTHLY: float = 0.004   # обслуживание = 0.4%/мес от стоимости
const VACANCY_MONTHLY: float = 0.10       # шанс сдан → простой за месяц
const FILL_MONTHLY: float = 0.55          # шанс найти жильца на простаивающий
const BAD_TENANT_MONTHLY: float = 0.05    # шанс плохого жильца (ущерб + простой)
const MANAGER_FEE_RATE: float = 0.12      # управляющий берёт 12% от аренды
const MGR_VACANCY_MULT: float = 0.40      # ×0.40 к шансу простоя
const MGR_FILL_MULT: float = 1.35         # ×1.35 к шансу заселения
const MGR_BAD_MULT: float = 0.30          # ×0.30 к шансу плохого жильца
const NEW_GRACE_MONTHS: int = 2           # новый объект не простаивает первые месяцы
const LEVEL_OCCUPANCY: float = 0.12       # каждый уровень ремонта улучшает заселяемость

var has_manager: bool = false

# Портфель: массив словарей {type_id, mortgage, mort_orig, missed, level, vacant}
var properties: Array = []

var gm: Node

func _ready() -> void:
	gm = get_node("/root/GameManager")

func _get_type(type_id: String) -> Dictionary:
	for p in PROPERTY_TYPES:
		if p.id == type_id: return p
	for p in COMMERCIAL_TYPES:
		if p.id == type_id: return p
	return {}

func is_commercial(type_id: String) -> bool:
	for p in COMMERCIAL_TYPES:
		if p.id == type_id: return true
	return false

# Множитель аренды от экономического цикла (только для коммерции).
func cycle_mult(type_id: String) -> float:
	var cyc: float = float(_get_type(type_id).get("cycle", 0.0))
	if cyc <= 0.0: return 1.0
	var cb := get_node_or_null("/root/CentralBankManager")
	if cb:
		if cb.has_method("is_boom") and cb.is_boom(): return 1.0 + cyc * CYCLE_SWING
		elif cb.has_method("is_recession") and cb.is_recession(): return 1.0 - cyc * CYCLE_SWING
	return 1.0

# Текущие рыночные цены (база × индекс рынка).
func current_price(type_id: String) -> int:
	return int(float(_get_type(type_id).get("price", 0)) * market_index)

func current_value(type_id: String) -> float:
	return float(_get_type(type_id).get("price", 0)) * market_index

func current_rent(type_id: String) -> float:
	return float(_get_type(type_id).get("rent", 0)) * market_index

# ── Стоимость/аренда конкретного объекта (с учётом ремонта) ──────────────────
func property_level(index: int) -> int:
	if index < 0 or index >= properties.size(): return 0
	return int(properties[index].get("level", 0))

func property_rent(index: int) -> float:
	if index < 0 or index >= properties.size(): return 0.0
	var tid := String(properties[index].get("type_id", ""))
	return current_rent(tid) * (1.0 + property_level(index) * LEVEL_RENT_BONUS) * cycle_mult(tid)

func property_value(index: int) -> float:
	if index < 0 or index >= properties.size(): return 0.0
	var tid := String(properties[index].get("type_id", ""))
	return current_value(tid) * (1.0 + property_level(index) * LEVEL_VALUE_BONUS)

func reno_cost(index: int) -> int:
	if index < 0 or index >= properties.size(): return 0
	var t := _get_type(String(properties[index].get("type_id", "")))
	return int(float(t.get("price", 0)) * market_index * RENO_COST_FACTOR * (property_level(index) + 1))

func can_renovate(index: int) -> bool:
	return index >= 0 and index < properties.size() \
		and property_level(index) < MAX_RENO_LEVEL and gm.money >= float(reno_cost(index))

func renovate(index: int) -> bool:
	if index < 0 or index >= properties.size(): return false
	if property_level(index) >= MAX_RENO_LEVEL: return false
	if not gm.spend_money(reno_cost(index)): return false
	properties[index]["level"] = property_level(index) + 1
	emit_signal("portfolio_changed")
	gm.save_game()
	return true

# ── Заселённость / простой ────────────────────────────────────────────────────
func is_vacant(index: int) -> bool:
	if index < 0 or index >= properties.size(): return false
	return bool(properties[index].get("vacant", false))

func occupied_count() -> int:
	var n: int = 0
	for p in properties:
		if not bool(p.get("vacant", false)): n += 1
	return n

func occupancy_rate() -> float:
	if properties.is_empty(): return 0.0
	return float(occupied_count()) / float(properties.size())

# Обслуживание объектов в день (от рыночной стоимости портфеля).
func maintenance_cost() -> float:
	var total: float = 0.0
	for i in range(properties.size()):
		total += property_value(i) * MAINT_RATE_MONTHLY / 30.0
	return total

# Комиссия управляющего в день (% от собранной аренды).
func manager_fee() -> float:
	if not has_manager: return 0.0
	return rental_income() * MANAGER_FEE_RATE

# Чистый денежный поток с недвижимости в день.
func net_daily_income() -> float:
	return rental_income() - maintenance_cost() - manager_fee()

func set_manager(on: bool) -> void:
	if has_manager == on: return
	has_manager = on
	emit_signal("portfolio_changed")
	gm.save_game()

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
	properties.append({"type_id": type_id, "mortgage": 0.0, "mort_orig": 0.0, "missed": 0, "level": 0, "vacant": false, "grace": NEW_GRACE_MONTHS})
	emit_signal("portfolio_changed")
	gm.save_game()
	return true

# ── Ипотека ───────────────────────────────────────────────────────────────────
func mortgage_monthly_rate() -> float:
	var cb := get_node_or_null("/root/CentralBankManager")
	var kr: float = cb.key_rate if cb else 0.16
	# Закон «Заморозка ставки ЦБ» (лобби) ограничивает ключевую ставку сверху
	var inf := get_node_or_null("/root/InfluenceManager")
	if inf and inf.has_method("law_rate_cap"):
		var cap: float = inf.law_rate_cap()
		if cap < 1.0:
			kr = minf(kr, cap)
	return (kr + MORTGAGE_SPREAD) / 12.0

func mortgage_down_payment(type_id: String) -> int:
	return int(current_price(type_id) * MORTGAGE_DOWN)

func can_buy_mortgage(type_id: String) -> bool:
	var t := _get_type(type_id)
	return not t.is_empty() and gm.current_title_index >= int(t.min_title) and gm.money >= float(mortgage_down_payment(type_id))

func buy_property_mortgage(type_id: String) -> bool:
	var t := _get_type(type_id)
	if t.is_empty(): return false
	if gm.current_title_index < int(t.min_title): return false
	var price: int = current_price(type_id)
	var down: int = int(price * MORTGAGE_DOWN)
	if not gm.spend_money(down): return false
	var principal: float = float(price - down)
	properties.append({"type_id": type_id, "mortgage": principal, "mort_orig": principal, "missed": 0, "level": 0, "vacant": false, "grace": NEW_GRACE_MONTHS})
	emit_signal("portfolio_changed")
	gm.save_game()
	return true

func mortgage_debt() -> float:
	var total: float = 0.0
	for p in properties:
		total += float(p.get("mortgage", 0.0))
	return total

# Капитал в недвижимости = рыночная стоимость минус долг по ипотеке.
func equity_value() -> float:
	return maxf(0.0, portfolio_value() - mortgage_debt())

func sell_property(index: int) -> float:
	if index < 0 or index >= properties.size(): return 0.0
	var value: float = property_value(index) * SELL_RATIO
	# Гасим остаток ипотеки из выручки
	var mort: float = float(properties[index].get("mortgage", 0.0))
	var net: float = maxf(0.0, value - mort)
	gm.add_money(net)
	properties.remove_at(index)
	emit_signal("portfolio_changed")
	gm.save_game()
	return net

# ── Девелопмент / застройка ───────────────────────────────────────────────────
func build_cost(type_id: String) -> int:
	return int(current_price(type_id) * BUILD_COST_RATIO)

func build_days(type_id: String) -> int:
	var price: float = float(_get_type(type_id).get("price", 0))
	return clampi(int(30 + price / 5_000_000.0), 30, 180)

func can_build(type_id: String) -> bool:
	var t := _get_type(type_id)
	return not t.is_empty() and gm.current_title_index >= int(t.min_title) and gm.money >= float(build_cost(type_id))

func start_project(type_id: String) -> bool:
	var t := _get_type(type_id)
	if t.is_empty(): return false
	if gm.current_title_index < int(t.min_title): return false
	var cost: int = build_cost(type_id)
	if not gm.spend_money(cost): return false
	var days: int = build_days(type_id)
	projects.append({"type_id": type_id, "days_left": days, "total_days": days, "invested": float(cost)})
	emit_signal("portfolio_changed")
	gm.save_game()
	return true

func project_count() -> int:
	return projects.size()

# Отмена стройки: возвращается часть вложений.
func cancel_project(index: int) -> float:
	if index < 0 or index >= projects.size(): return 0.0
	var refund: float = float(projects[index].get("invested", 0.0)) * PROJECT_CANCEL_REFUND
	gm.add_money(refund)
	projects.remove_at(index)
	emit_signal("portfolio_changed")
	gm.save_game()
	return refund

# Вложенный в стройку капитал (для net worth — деньги не исчезают).
func projects_value() -> float:
	var total: float = 0.0
	for p in projects:
		total += float(p.get("invested", 0.0))
	return total

# Ежедневно двигаем стройки; завершённые превращаем в готовые объекты.
func _update_projects() -> void:
	if projects.is_empty(): return
	var changed: bool = false
	var es := get_node_or_null("/root/EventSystem")
	var done: Array = []
	for i in range(projects.size()):
		var p = projects[i]
		p["days_left"] = int(p.get("days_left", 0)) - 1
		if int(p["days_left"]) <= 0:
			done.append(i)
	done.reverse()
	for i in done:
		var tid: String = String(projects[i].get("type_id", ""))
		projects.remove_at(i)
		properties.append({"type_id": tid, "mortgage": 0.0, "mort_orig": 0.0, "missed": 0, "level": 0, "vacant": false, "grace": NEW_GRACE_MONTHS})
		changed = true
		if es:
			es.event_triggered.emit({
				"text": "🏗 Стройка завершена: «%s» сдан в эксплуатацию!" % _get_type(tid).get("name", "объект"),
				"money": 0, "health": 0})
	if changed:
		emit_signal("portfolio_changed")

# Ежемесячно: риск задержки стройки.
func _project_overruns() -> void:
	var es := get_node_or_null("/root/EventSystem")
	for p in projects:
		if int(p.get("days_left", 0)) > 0 and randf() < BUILD_OVERRUN_MONTHLY:
			var delay: int = randi_range(10, 25)
			p["days_left"] = int(p["days_left"]) + delay
			p["total_days"] = int(p.get("total_days", 0)) + delay
			if es:
				es.event_triggered.emit({
					"text": "🏗 Задержка стройки «%s»: +%d дн." % [_get_type(String(p.get("type_id", ""))).get("name", "объект"), delay],
					"money": 0, "health": 0})

# Суммарная аренда в день (только заселённые объекты: рынок × ремонт).
func rental_income() -> float:
	var total: float = 0.0
	for i in range(properties.size()):
		if not bool(properties[i].get("vacant", false)):
			total += property_rent(i)
	return total

# Стоимость портфеля по рыночной цене с учётом ремонта (+ вложения в стройку).
func portfolio_value() -> float:
	var total: float = 0.0
	for i in range(properties.size()):
		total += property_value(i)
	total += projects_value()
	return total

# Ежедневно: чистый поток (аренда − обслуживание − управляющий);
# раз в месяц — ипотека, заселённость и движение рынка.
func process_day() -> void:
	# Личное благополучие владельца влияет на собранную аренду
	var wb: float = 1.0
	var life := get_node_or_null("/root/LifeManager")
	if life and life.has_method("wellbeing_mult"):
		wb = life.wellbeing_mult()
	var net := rental_income() * wb - maintenance_cost() - manager_fee()
	if net != 0.0:
		gm.add_money(net)
	_update_projects()
	if gm.day % 30 == 0:
		_pay_mortgages()
		_update_occupancy()
		_project_overruns()
		_update_market()

# Ежемесячно: простаивающие ищут жильца, заселённые рискуют простоем/плохим жильцом.
func _update_occupancy() -> void:
	if properties.is_empty(): return
	var changed: bool = false
	var es := get_node_or_null("/root/EventSystem")
	for i in range(properties.size()):
		var p = properties[i]
		var t := _get_type(String(p.get("type_id", "")))
		var class_bonus: float = 1.0 + property_level(i) * LEVEL_OCCUPANCY
		if bool(p.get("vacant", false)):
			var fill: float = FILL_MONTHLY * (MGR_FILL_MULT if has_manager else 1.0) * class_bonus
			if randf() < fill:
				p["vacant"] = false
				changed = true
		else:
			# Новый объект первые месяцы гарантированно сдан
			var grace: int = int(p.get("grace", 0))
			if grace > 0:
				p["grace"] = grace - 1
				continue
			var bad: float = BAD_TENANT_MONTHLY * (MGR_BAD_MULT if has_manager else 1.0)
			if randf() < bad:
				var dmg: float = property_value(i) * randf_range(0.01, 0.03)
				gm.add_money(-dmg)
				p["vacant"] = true
				changed = true
				if es:
					es.event_triggered.emit({
						"text": "🚪 Плохой жилец съехал из «%s» — ремонт −%s." % [
							t.get("name", "объект"), gm.format_money(dmg)],
						"money": 0, "health": 0})
			else:
				var vac: float = VACANCY_MONTHLY * (MGR_VACANCY_MULT if has_manager else 1.0) / class_bonus
				if randf() < vac:
					p["vacant"] = true
					changed = true
	if changed:
		emit_signal("portfolio_changed")

# Ежемесячные платежи по ипотеке; при просрочках — взыскание объекта.
func _pay_mortgages() -> void:
	var rate: float = mortgage_monthly_rate()
	var foreclose: Array = []
	for i in range(properties.size()):
		var p = properties[i]
		var rem_m: float = float(p.get("mortgage", 0.0))
		if rem_m <= 0.0:
			continue
		var orig: float = float(p.get("mort_orig", rem_m))
		var principal_pay: float = orig / float(MORTGAGE_MONTHS)
		var payment: float = rem_m * rate + principal_pay
		if gm.spend_money(payment):
			p["mortgage"] = maxf(0.0, rem_m - principal_pay)
			p["missed"] = 0
		else:
			p["missed"] = int(p.get("missed", 0)) + 1
			if int(p["missed"]) >= MORTGAGE_MISS_LIMIT:
				foreclose.append(i)
	foreclose.reverse()
	var es := get_node_or_null("/root/EventSystem")
	for i in foreclose:
		var t := _get_type(String(properties[i].get("type_id", "")))
		properties.remove_at(i)
		if es:
			es.event_triggered.emit({
				"text": "🏦 Банк изъял объект «%s» за неуплату ипотеки!" % t.get("name", "недвижимость"),
				"money": 0, "health": 0})
	if not foreclose.is_empty():
		emit_signal("portfolio_changed")

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
	projects.clear()
	market_index = 1.0
	_prev_index = 1.0
	has_manager = false

func save(cfg: ConfigFile) -> void:
	cfg.set_value("realestate", "properties", properties)
	cfg.set_value("realestate", "projects", projects)
	cfg.set_value("realestate", "market_index", market_index)
	cfg.set_value("realestate", "has_manager", has_manager)

func load_data(cfg: ConfigFile) -> void:
	properties = cfg.get_value("realestate", "properties", [])
	projects = cfg.get_value("realestate", "projects", [])
	market_index = cfg.get_value("realestate", "market_index", 1.0)
	_prev_index = market_index
	has_manager = cfg.get_value("realestate", "has_manager", false)
