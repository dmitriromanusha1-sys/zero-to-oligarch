extends Node

signal business_changed()
signal bank_changed(amount: float)
signal security_event(event: Dictionary)

const MAX_BIZ_LEVEL  : int   = 5
const LVL_COST_MULT  : float = 0.40
const LVL_INCOME_MULT: float = 0.30
const LOAN_RATE_DAILY: float = 0.01

# ── Филиалы / франшизы ────────────────────────────────────────────────────────
# Каждый следующий филиал ОДНОГО типа дешевле (экономия на масштабе), а бренд
# (число точек этого типа) повышает доход каждой точки.
const FRANCHISE_DISCOUNT_STEP : float = 0.15   # −15% к цене за каждый уже открытый филиал
const FRANCHISE_MIN_RATIO     : float = 0.40   # но не дешевле 40% базовой цены
const BRAND_BONUS_STEP        : float = 0.08   # +8% к доходу точки за каждый филиал сверх первого
const BRAND_BONUS_MAX         : float = 0.50   # максимум +50% от бренда

const SECURITY_LEVELS: Array = [
	{"name": "Нет охраны",       "cost_per_day": 0,      "install_cost": 0,        "event_chance": 0.25, "icon": "⚠️",  "desc": "Бизнес не защищён."},
	{"name": "Охранник",         "cost_per_day": 500,    "install_cost": 15000,    "event_chance": 0.16, "icon": "👮",  "desc": "Один охранник на входе."},
	{"name": "Пост охраны",      "cost_per_day": 2000,   "install_cost": 60000,    "event_chance": 0.09, "icon": "🏠",  "desc": "Оборудованный пост, журнал посещений."},
	{"name": "Видеонаблюдение",  "cost_per_day": 6000,   "install_cost": 200000,   "event_chance": 0.04, "icon": "📷",  "desc": "Камеры по периметру, тревожная кнопка."},
	{"name": "Частная охрана",   "cost_per_day": 18000,  "install_cost": 700000,   "event_chance": 0.015,"icon": "🛡️",  "desc": "Вооружённая группа быстрого реагирования."},
	{"name": "Полная защита",    "cost_per_day": 50000,  "install_cost": 2500000,  "event_chance": 0.003,"icon": "🔒",  "desc": "Периметр, биометрия, ЧОП 24/7."},
]

const NEGATIVE_EVENTS: Array = [
	{"id":"theft",   "name":"Кража",              "icon":"🦹", "desc":"Воры вскрыли кассу.",            "loss_type":"income_pct",  "loss_min":0.10, "loss_max":0.35},
	{"id":"vandal",  "name":"Вандализм",           "icon":"🔨", "desc":"Разбиты витрины и вывеска.",     "loss_type":"income_pct",  "loss_min":0.05, "loss_max":0.15},
	{"id":"fire",    "name":"Пожар",               "icon":"🔥", "desc":"Потушили, но урон нанесён.",     "loss_type":"income_pct",  "loss_min":0.30, "loss_max":0.80},
	{"id":"audit",   "name":"Налоговая проверка",  "icon":"📋", "desc":"Инспектор выписал штраф.",       "loss_type":"biz_val_pct", "loss_min":0.04, "loss_max":0.12},
	{"id":"raid",    "name":"Рейдерство",          "icon":"⚖️", "desc":"Силовой захват. Отстояли активы.","loss_type":"bank_pct",  "loss_min":0.10, "loss_max":0.30},
]

const BUSINESS_TYPES: Array = [
	{"id":"latok",      "name":"Уличный лоток",  "cost":8000,        "income_per_day":150,      "max_employees":1,   "min_title":0, "icon":"🥤",  "sector":"food",     "desc":"Лимонад и семечки. Первые шаги в бизнесе."},
	{"id":"ip",         "name":"ИП / Ларёк",     "cost":50000,       "income_per_day":600,      "max_employees":3,   "min_title":1, "icon":"🏪",  "sector":"retail",   "desc":"Зарегистрировал ИП. Небольшой ларёк у метро."},
	{"id":"cafe",       "name":"Кафе",           "cost":280000,      "income_per_day":3000,     "max_employees":6,   "min_title":2, "icon":"☕",  "sector":"food",     "desc":"Уютное кафе в спальном районе. Постоянные клиенты."},
	{"id":"shop",       "name":"Магазин",        "cost":1200000,     "income_per_day":10000,    "max_employees":10,  "min_title":2, "icon":"🏬",  "sector":"retail",   "desc":"Полноценный магазин. Ассортимент, витрины, поставщики."},
	{"id":"restaurant", "name":"Ресторан",       "cost":5000000,     "income_per_day":40000,    "max_employees":15,  "min_title":3, "icon":"🍽",  "sector":"food",     "desc":"Банкеты, корпоративы, постоянные гости. Хорошая прибыль."},
	{"id":"factory",    "name":"Мини-завод",     "cost":20000000,    "income_per_day":150000,   "max_employees":30,  "min_title":3, "icon":"🏭",  "sector":"industry", "desc":"Производство → дистрибуция напрямую. Серьёзный бизнес."},
	{"id":"chain",      "name":"Торговая сеть",  "cost":80000000,    "income_per_day":600000,   "max_employees":60,  "min_title":4, "icon":"🏢",  "sector":"retail",   "desc":"Несколько точек по городу. Бренд растёт."},
	{"id":"holding",    "name":"Холдинг",        "cost":300000000,   "income_per_day":2500000,  "max_employees":150, "min_title":5, "icon":"🏦",  "sector":"finance",  "desc":"Группа компаний с активами в разных секторах."},
	{"id":"corporation","name":"Корпорация",     "cost":1200000000,  "income_per_day":12000000, "max_employees":500, "min_title":6, "icon":"🌐",  "sector":"finance",  "desc":"Международная корпорация. Вершина делового мира."},
]

const SECTOR_NAMES: Dictionary = {
	"food": "🍔 Питание", "retail": "🛍 Ретейл", "industry": "🏭 Промышленность", "finance": "🏦 Финансы",
}

const EMPLOYEE_TYPES: Array = [
	{"id":"worker",     "name":"Разнорабочий", "cost":5000,   "salary_per_day":200,  "income_bonus":500,   "icon":"👷", "desc":"Базовый персонал. Минимальный вклад."},
	{"id":"manager",    "name":"Менеджер",     "cost":40000,  "salary_per_day":800,  "income_bonus":2000,  "icon":"👔", "desc":"Организует работу, улучшает логистику."},
	{"id":"marketer",   "name":"Маркетолог",   "cost":80000,  "salary_per_day":1400, "income_bonus":4500,  "icon":"📊", "desc":"Привлекает клиентов. Отличный ROI."},
	{"id":"accountant", "name":"Бухгалтер",    "cost":120000, "salary_per_day":2200, "income_bonus":7500,  "icon":"🧾", "desc":"Оптимизирует налоги и издержки."},
	{"id":"director",   "name":"Директор",     "cost":350000, "salary_per_day":5500, "income_bonus":18000, "icon":"🤵", "desc":"Стратегическое управление. Максимальный вклад."},
]

# Топ-менеджмент уровня ИМПЕРИИ: повышает «ёмкость управления». Если бизнесов
# больше, чем ёмкость, эффективность всей империи падает.
const EXECUTIVE_TYPES: Array = [
	{"id":"office_mgr", "name":"Офис-менеджер",        "capacity":2,  "salary":3000,  "cost":80000,    "icon":"📋", "desc":"Берёт рутину одного-двух бизнесов."},
	{"id":"coo",        "name":"COO (операционный)",   "capacity":5,  "salary":18000, "cost":700000,   "icon":"🧑‍💼", "desc":"Операционное управление группой компаний."},
	{"id":"ceo",        "name":"CEO (генеральный)",    "capacity":12, "salary":70000, "cost":4000000,  "icon":"👑", "desc":"Стратег во главе всей империи."},
]
const BASE_MGMT_CAPACITY: int = 2

# Рецепт синергии: набор сотрудников (по типам), который определяет
# 100%-ную комплектацию команды. "bonus" — максимальный бонус к прибыли
# (получаемый на корпорации; для бизнесов поменьше масштабируется вниз).
const SYNERGY_RECIPES: Dictionary = {
	"latok":       {"recipe": {"worker":1},                                                            "bonus": 0.10},
	"ip":          {"recipe": {"worker":1, "manager":1, "marketer":1},                                  "bonus": 0.20},
	"cafe":        {"recipe": {"worker":2, "manager":1, "marketer":1, "accountant":1},                  "bonus": 0.35},
	"shop":        {"recipe": {"worker":2, "manager":2, "marketer":2, "accountant":1, "director":1},    "bonus": 0.55},
	"restaurant":  {"recipe": {"worker":3, "manager":2, "marketer":2, "accountant":2, "director":1},    "bonus": 0.80},
	"factory":     {"recipe": {"worker":5, "manager":4, "marketer":4, "accountant":3, "director":2},    "bonus": 1.20},
	"chain":       {"recipe": {"worker":10,"manager":8, "marketer":8, "accountant":6, "director":4},    "bonus": 1.60},
	"holding":     {"recipe": {"worker":25,"manager":20,"marketer":20,"accountant":15,"director":10},   "bonus": 2.00},
	"corporation": {"recipe": {"worker":80,"manager":70,"marketer":70,"accountant":50,"director":30},   "bonus": 2.50},
}

# Кривая синергии строится по заполненности рецепта (0.0 .. 1.0):
#   r <  SYN_MIN_R               → штраф, линейно убывающий до 0 на SYN_MIN_R
#   SYN_MIN_R <= r < SYN_MID_R   → "минимум" снимает штраф, бонуса ещё нет
#   SYN_MID_R <= r < 1.0         → бонус растёт от SYN_MID_RATIO до 1.0 (макс. "bonus")
#   r == 1.0                     → полный бонус ("максимальная" синергия)
# Значения штрафа и средней ступени заданы как доля от максимального бонуса
# бизнеса — поэтому для мелких бизнесов (маленький max bonus) штраф и средний
# бонус автоматически получаются небольшими, а для корпорации соответствуют
# условию: минимум снимает штраф, средняя = +50%, максимум = +250%.
const SYN_MIN_R         : float = 0.50
const SYN_MID_R         : float = 0.75
const SYN_PENALTY_RATIO : float = 0.12   # corporation: 0.30 / 2.50 = 0.12 → штраф -30%
const SYN_MID_RATIO     : float = 0.20   # corporation: 0.50 / 2.50 = 0.20 → средний бонус +50%

# ── Портфель бизнесов (империя) ───────────────────────────────────────────────
# Каждый бизнес: {"type_id":String, "level":int, "employees":Array, "security_level":int}
var businesses: Array = []
var active_index: int = 0

# Активный бизнес — то, что редактирует классический «магазин бизнеса».
func active_business() -> Dictionary:
	if active_index >= 0 and active_index < businesses.size():
		return businesses[active_index]
	return {}

# Сколько бизнесов можно держать одновременно (растёт с титулом; Фаза 4 свяжет
# с управлением). Бомж — 1, дальше +1 каждые 3 титула.
func max_businesses() -> int:
	var t: int = gm.current_title_index if gm else 0
	return 1 + int(t / 3)

# Старые поля как вид на активный бизнес — чтобы существующий код/UI работал.
var owned_business_id: String:
	get: return String(active_business().get("type_id", ""))
var business_level: int:
	get: return int(active_business().get("level", 0))
	set(v):
		var a := active_business()
		if not a.is_empty(): a["level"] = v
var employees: Array:
	get:
		var a := active_business()
		return a["employees"] if a.has("employees") else []
var security_level: int:
	get: return int(active_business().get("security_level", 0))
	set(v):
		var a := active_business()
		if not a.is_empty(): a["security_level"] = v

var bank_deposit     : float  = 0.0
var active_loan      : float  = 0.0
var total_earned     : float  = 0.0
var business_days    : int    = 0
var month_income     : float  = 0.0   # доход бизнеса за месяц — база для налога
var total_tax_paid   : float  = 0.0

# Топ-менеджмент империи (список {type_id})
var executives: Array = []

# ── Доля рынка по секторам ────────────────────────────────────────────────────
# sector → твоя доля рынка 0..1. Конкуренты точат долю, доля влияет на доход.
var market_share: Dictionary = {}

const COMP_MULT_MIN    : float = 0.65   # доход при крошечной доле рынка
const COMP_MULT_MAX    : float = 1.35   # доход при доминировании
const MARKET_INVEST    : float = 0.12   # +доля за один маркетинговый вброс
const COMPETITOR_EROSION: float = 0.05  # конкуренты отъедают долю каждый месяц

# Базовая ставка налога на прибыль бизнеса (× множитель сложности)
const TAX_RATE: float = 0.13
var last_event       : Dictionary = {}

var gm: Node

func _ready() -> void:
	gm = get_node("/root/GameManager")

# ── Ставки ────────────────────────────────────────────────────────────────────
func get_tiered_rate() -> float:
	# Базовая ставка вклада = ключевая ставка ЦБ × 0.85.
	# Крупные вкладчики получают лучший множитель — как в реальном банке.
	var cb: Node = get_node_or_null("/root/CentralBankManager")
	var base: float = cb.get_deposit_rate() if cb else 0.0425
	if bank_deposit >= 10_000_000: return base * 2.40
	if bank_deposit >= 1_000_000:  return base * 1.80
	if bank_deposit >= 100_000:    return base * 1.20
	return base * 0.60

func get_loan_max() -> float:
	return maxf(0.0, get_empire_value() + bank_deposit * 0.5)

func get_business_value() -> float:
	var bt := get_business()
	if bt.is_empty(): return 0.0
	return bt.cost * (1.0 + business_level * 0.25)

func get_level_income_mult() -> float:
	return 1.0 + business_level * LVL_INCOME_MULT

func get_upgrade_cost() -> float:
	var bt := get_business()
	if bt.is_empty(): return 0.0
	return bt.cost * LVL_COST_MULT * (business_level + 1)

# ── Бизнес ────────────────────────────────────────────────────────────────────
# Открыть новый бизнес — добавляет ещё одну компанию в портфель (в пределах лимита).
func open_business(type_id: String) -> bool:
	if businesses.size() >= max_businesses(): return false
	var bt := _get_type(type_id)
	if bt.is_empty(): return false
	if not gm.spend_money(franchise_cost(type_id)): return false
	businesses.append({"type_id": type_id, "level": 0, "employees": [], "security_level": 0})
	active_index = businesses.size() - 1
	emit_signal("business_changed")
	gm.save_game()
	return true

# Сменить тип активного бизнеса (на более крупный) — сбрасывает уровень.
func upgrade_business(new_type_id: String) -> bool:
	var a := active_business()
	if a.is_empty(): return false
	var bt := _get_type(new_type_id)
	if bt.is_empty(): return false
	if not gm.spend_money(bt.cost): return false
	a["type_id"] = new_type_id
	a["level"] = 0
	emit_signal("business_changed")
	gm.save_game()
	return true

# Переключить активный бизнес (для управления в магазине).
func set_active(index: int) -> void:
	if index >= 0 and index < businesses.size():
		active_index = index
		emit_signal("business_changed")

func business_count() -> int:
	return businesses.size()

func upgrade_level() -> bool:
	if business_level >= MAX_BIZ_LEVEL: return false
	var cost := get_upgrade_cost()
	if not gm.spend_money(cost): return false
	business_level += 1
	emit_signal("business_changed")
	gm.save_game()
	return true

func sell_business() -> float:
	var a := active_business()
	if a.is_empty(): return 0.0
	var value := get_business_value() * 0.50
	gm.add_money(value)
	businesses.remove_at(active_index)
	active_index = clampi(active_index, 0, maxi(0, businesses.size() - 1))
	emit_signal("business_changed")
	gm.save_game()
	return value

func get_business() -> Dictionary:
	if owned_business_id == "": return {}
	return _get_type(owned_business_id)

# Доход одного бизнеса (тип, уровень, сотрудники, синергия).
func _income_of(biz: Dictionary) -> float:
	if biz.is_empty(): return 0.0
	var bt := _get_type(String(biz.get("type_id", "")))
	if bt.is_empty(): return 0.0
	var lvl: int = int(biz.get("level", 0))
	var income: float = bt.income_per_day * (1.0 + lvl * LVL_INCOME_MULT)
	for e in biz.get("employees", []):
		var et := _get_employee_type(e.type_id)
		if et.is_empty(): continue
		income += et.income_bonus - et.salary_per_day
	income *= _synergy_mult_of(biz)
	# Бренд: чем больше филиалов этого типа, тем выше доход каждого
	income *= brand_mult(String(biz.get("type_id", "")))
	# Конкуренция: доля рынка в секторе бизнеса
	income *= sector_competition_mult(sector_of(String(biz.get("type_id", ""))))
	return income

# Доход активного бизнеса (для карточки в магазине).
func get_active_income() -> float:
	return _income_of(active_business())

# Суммарный доход всей империи в день (с учётом экономического цикла).
func get_daily_income() -> float:
	var total: float = 0.0
	for biz in businesses:
		total += _income_of(biz)
	if total != 0.0:
		var cb := get_node_or_null("/root/CentralBankManager")
		if cb and cb.has_method("business_mult"):
			total *= cb.business_mult()
	# Эффективность управления: перегруженная империя теряет доход
	total *= efficiency_mult()
	return total

# Суммарная стоимость всех бизнесов империи.
func get_empire_value() -> float:
	var total: float = 0.0
	for biz in businesses:
		var bt := _get_type(String(biz.get("type_id", "")))
		if not bt.is_empty():
			total += bt.cost * (1.0 + int(biz.get("level", 0)) * 0.25)
	return total

# Сколько точек (филиалов) данного типа в империи.
func branch_count(type_id: String) -> int:
	var n: int = 0
	for biz in businesses:
		if String(biz.get("type_id", "")) == type_id:
			n += 1
	return n

# Цена открытия следующего филиала этого типа (со скидкой за масштаб).
func franchise_cost(type_id: String) -> int:
	var bt := _get_type(type_id)
	if bt.is_empty(): return 0
	var ratio: float = maxf(FRANCHISE_MIN_RATIO, 1.0 - FRANCHISE_DISCOUNT_STEP * branch_count(type_id))
	return int(bt.cost * ratio)

# Бренд-множитель к доходу точки этого типа (чем больше точек, тем выше).
func brand_mult(type_id: String) -> float:
	var extra: int = maxi(0, branch_count(type_id) - 1)
	return 1.0 + minf(BRAND_BONUS_MAX, BRAND_BONUS_STEP * extra)

# ── Доля рынка / конкуренты ───────────────────────────────────────────────────
func sector_of(type_id: String) -> String:
	return String(_get_type(type_id).get("sector", ""))

func get_share(sector: String) -> float:
	return float(market_share.get(sector, 0.0))

# Множитель дохода от доли рынка: аутсайдер теряет, лидер выигрывает.
# Пока сектор только что занят (доля ещё не посчитана) — нейтрально (1.0).
func sector_competition_mult(sector: String) -> float:
	if sector == "" or not market_share.has(sector):
		return 1.0
	return lerpf(COMP_MULT_MIN, COMP_MULT_MAX, get_share(sector))

# Перечень секторов, где есть бизнес.
func active_sectors() -> Array:
	var seen: Dictionary = {}
	for biz in businesses:
		var s := sector_of(String(biz.get("type_id", "")))
		if s != "": seen[s] = true
	return seen.keys()

# Естественный потолок доли от присутствия (число точек и их уровни).
func _sector_target_share(sector: String) -> float:
	var pts: float = 0.0
	for biz in businesses:
		if sector_of(String(biz.get("type_id", ""))) == sector:
			pts += 1.0 + 0.5 * int(biz.get("level", 0))
	if pts <= 0.0:
		return 0.0
	return clampf(0.15 + 0.12 * pts, 0.15, 0.85)

# Ежемесячно: доля тянется к цели от присутствия, конкуренты её точат.
func _update_markets() -> void:
	var sectors := active_sectors()
	for s in sectors:
		var cur: float = get_share(s)
		var target: float = _sector_target_share(s)
		if cur <= 0.0:
			cur = target * 0.6   # выходишь на рынок небольшим игроком
		cur = lerpf(cur, target, 0.35) - COMPETITOR_EROSION
		market_share[s] = clampf(cur, 0.05, 0.92)
	# забываем секторы, где бизнеса больше нет
	for s in market_share.keys():
		if not (s in sectors):
			market_share.erase(s)

# Стоимость маркетингового захвата доли (~20 дней дохода сектора, минимум 50k).
func market_invest_cost(sector: String) -> int:
	var inc: float = 0.0
	for biz in businesses:
		if sector_of(String(biz.get("type_id", ""))) == sector:
			inc += _income_of(biz)
	return int(maxf(50000.0, inc * 20.0))

func invest_market_share(sector: String) -> bool:
	if sector == "": return false
	if not gm.spend_money(market_invest_cost(sector)): return false
	market_share[sector] = clampf(get_share(sector) + MARKET_INVEST, 0.05, 0.95)
	emit_signal("business_changed")
	gm.save_game()
	return true

# ── Управление империей ───────────────────────────────────────────────────────
func _get_executive_type(type_id: String) -> Dictionary:
	for et in EXECUTIVE_TYPES:
		if et.id == type_id: return et
	return {}

# Нагрузка на управление = число бизнесов в империи.
func management_load() -> int:
	return businesses.size()

# Ёмкость управления = база (сам) + вклад топ-менеджмента.
func management_capacity() -> int:
	var cap: int = BASE_MGMT_CAPACITY
	for e in executives:
		var et := _get_executive_type(String(e.get("type_id", "")))
		if not et.is_empty(): cap += int(et.capacity)
	return cap

# Множитель эффективности: если бизнесов больше ёмкости — штраф к доходу империи.
func efficiency_mult() -> float:
	var over: int = management_load() - management_capacity()
	if over <= 0:
		return 1.0
	return clampf(1.0 - 0.12 * over, 0.40, 1.0)

# Суммарная зарплата топ-менеджмента в день.
func get_executive_salary() -> float:
	var total: float = 0.0
	for e in executives:
		var et := _get_executive_type(String(e.get("type_id", "")))
		if not et.is_empty(): total += et.salary
	return total

func executive_counts() -> Dictionary:
	var counts: Dictionary = {}
	for e in executives:
		var tid := String(e.get("type_id", ""))
		counts[tid] = counts.get(tid, 0) + 1
	return counts

func hire_executive(type_id: String) -> bool:
	var et := _get_executive_type(type_id)
	if et.is_empty(): return false
	if not gm.spend_money(et.cost): return false
	executives.append({"type_id": type_id})
	emit_signal("business_changed")
	gm.save_game()
	return true

func can_open(type_id: String) -> bool:
	var bt := _get_type(type_id)
	if bt.is_empty(): return false
	return businesses.size() < max_businesses() \
		and gm.money >= franchise_cost(type_id) \
		and gm.current_title_index >= bt.min_title

# ── Сотрудники ────────────────────────────────────────────────────────────────
func hire_employee(type_id: String) -> bool:
	return hire_employees(type_id, 1) > 0

# Нанимает до `count` сотрудников типа type_id, останавливаясь когда
# заканчиваются свободные слоты или деньги. Возвращает фактически нанятых.
func hire_employees(type_id: String, count: int) -> int:
	var bt := get_business()
	if bt.is_empty(): return 0
	var et := _get_employee_type(type_id)
	if et.is_empty(): return 0
	var hired := 0
	while hired < count and employees.size() < bt.max_employees:
		if not gm.spend_money(et.cost): break
		employees.append({"type_id": type_id})
		hired += 1
	if hired > 0:
		emit_signal("business_changed")
		gm.save_game()
	return hired

func fire_employee(index: int) -> void:
	if index < 0 or index >= employees.size(): return
	employees.remove_at(index)
	emit_signal("business_changed")
	gm.save_game()

func get_total_salary() -> float:
	var total: float = 0.0
	for e in employees:
		var et := _get_employee_type(e.type_id)
		total += et.salary_per_day
	return total

# ── Синергия ──────────────────────────────────────────────────────────────────
func get_employee_counts() -> Dictionary:
	var counts: Dictionary = {}
	for e in employees:
		counts[e.type_id] = counts.get(e.type_id, 0) + 1
	return counts

func get_synergy_recipe() -> Dictionary:
	if owned_business_id == "" or not SYNERGY_RECIPES.has(owned_business_id):
		return {}
	return SYNERGY_RECIPES[owned_business_id]

# Возвращает {type_id: {"have":int, "need":int}} для текущего бизнеса.
func get_synergy_progress() -> Dictionary:
	var syn := get_synergy_recipe()
	if syn.is_empty(): return {}
	var counts := get_employee_counts()
	var progress: Dictionary = {}
	for type_id in syn.recipe:
		progress[type_id] = {"have": counts.get(type_id, 0), "need": syn.recipe[type_id]}
	return progress

func is_synergy_active() -> bool:
	return get_synergy_fulfillment() >= 1.0

# Доля выполнения рецепта синергии (0.0 .. 1.0), взвешенная по требуемому
# количеству каждой роли: sum(min(have, need)) / sum(need).
func get_synergy_fulfillment() -> float:
	var syn := get_synergy_recipe()
	if syn.is_empty(): return 0.0
	var counts := get_employee_counts()
	var have_sum: float = 0.0
	var need_sum: float = 0.0
	for type_id in syn.recipe:
		var need: int = syn.recipe[type_id]
		need_sum += need
		have_sum += mini(counts.get(type_id, 0), need)
	if need_sum <= 0: return 0.0
	return have_sum / need_sum

# Возвращает текущий множитель к прибыли по кривой синергии:
# штраф ниже SYN_MIN_R → нейтрально до SYN_MID_R → бонус растёт до 100% рецепта.
func get_synergy_mult() -> float:
	return _synergy_mult_of(active_business())

# Множитель синергии для произвольного бизнеса (по его типу и сотрудникам).
func _synergy_mult_of(biz: Dictionary) -> float:
	var tid: String = String(biz.get("type_id", ""))
	if tid == "" or not SYNERGY_RECIPES.has(tid): return 1.0
	var emps: Array = biz.get("employees", [])
	if emps.is_empty(): return 1.0  # без команды штраф синергии не действует
	var syn: Dictionary = SYNERGY_RECIPES[tid]
	var counts: Dictionary = {}
	for e in emps:
		counts[e.type_id] = counts.get(e.type_id, 0) + 1
	var have_sum: float = 0.0
	var need_sum: float = 0.0
	for type_id in syn.recipe:
		var need: int = syn.recipe[type_id]
		need_sum += need
		have_sum += mini(counts.get(type_id, 0), need)
	var r: float = (have_sum / need_sum) if need_sum > 0.0 else 0.0
	var max_bonus: float = syn.bonus
	var penalty_max: float = max_bonus * SYN_PENALTY_RATIO
	var mid_bonus  : float = max_bonus * SYN_MID_RATIO
	if r >= 1.0:
		return 1.0 + max_bonus
	if r >= SYN_MID_R:
		var t := (r - SYN_MID_R) / (1.0 - SYN_MID_R)
		return 1.0 + mid_bonus + (max_bonus - mid_bonus) * t
	if r >= SYN_MIN_R:
		var t2 := (r - SYN_MIN_R) / (SYN_MID_R - SYN_MIN_R)
		return 1.0 + mid_bonus * t2
	var t3 := r / SYN_MIN_R
	return 1.0 - penalty_max * (1.0 - t3)

# Название текущей ступени синергии для UI.
func get_synergy_tier_name() -> String:
	var r := get_synergy_fulfillment()
	if r >= 1.0: return "Максимальная"
	if r >= SYN_MID_R: return "Растущая"
	if r >= SYN_MIN_R: return "Минимум (без штрафа)"
	return "Штраф"

# Докупает недостающие для синергии роли (в рамках свободных слотов и денег).
# Возвращает количество фактически нанятых сотрудников.
func auto_fill_synergy() -> int:
	var bt := get_business()
	if bt.is_empty(): return 0
	var syn := get_synergy_recipe()
	if syn.is_empty(): return 0
	var counts := get_employee_counts()
	var total_hired := 0
	for type_id in syn.recipe:
		var missing: int = syn.recipe[type_id] - counts.get(type_id, 0)
		if missing <= 0: continue
		var free_slots: int = bt.max_employees - employees.size()
		if free_slots <= 0: break
		var hired := hire_employees(type_id, mini(missing, free_slots))
		total_hired += hired
	return total_hired

# ── Банк ──────────────────────────────────────────────────────────────────────
func deposit(amount: float) -> bool:
	if not gm.spend_money(amount): return false
	bank_deposit += amount
	emit_signal("bank_changed", bank_deposit)
	gm.recheck_net_worth()
	gm.save_game()
	return true

func withdraw(amount: float) -> bool:
	if bank_deposit < amount: return false
	bank_deposit -= amount
	gm.add_money(amount)
	emit_signal("bank_changed", bank_deposit)
	gm.save_game()
	return true

# ── Кредит ────────────────────────────────────────────────────────────────────
func take_loan(amount: float) -> bool:
	if amount <= 0: return false
	if amount > get_loan_max(): return false
	active_loan += amount
	gm.add_money(amount)
	emit_signal("bank_changed", bank_deposit)
	gm.save_game()
	return true

func repay_loan(amount: float) -> bool:
	if active_loan <= 0: return false
	var pay := minf(amount, active_loan)
	if not gm.spend_money(pay): return false
	active_loan -= pay
	if active_loan < 1.0: active_loan = 0.0
	emit_signal("bank_changed", bank_deposit)
	gm.save_game()
	return true

# ── Ежедневный тик ────────────────────────────────────────────────────────────
func process_day() -> void:
	var income := get_daily_income()
	if income > 0:
		var h_idx  : int   = gm.current_housing_index
		var h_mult : float = gm.HOUSINGS[h_idx].get("income_mult", 1.0)
		var net    : float = income * h_mult
		gm.add_money(net)
		total_earned  += net
		business_days += 1
		month_income  += net
	# Месячный налог на прибыль бизнеса (× множитель сложности)
	if gm.day % 30 == 0:
		if month_income > 0.0:
			var sm := get_node_or_null("/root/SettingsManager")
			var tax_mult: float = 1.0
			if sm and sm.has_method("get_diff"):
				tax_mult = sm.get_diff().get("tax", 1.0)
			var tax: float = month_income * TAX_RATE * tax_mult
			if tax > 0.0:
				gm.spend_money(tax)
				total_tax_paid += tax
				var es := get_node_or_null("/root/EventSystem")
				if es and (not sm or sm.notify_taxes):
					es.event_triggered.emit({
						"text": "🧾 Налог на прибыль: −%s (%.0f%% от дохода бизнеса за месяц)" % [gm.format_money(tax), TAX_RATE * tax_mult * 100.0],
						"money": -tax, "health": 0
					})
		month_income = 0.0
		_update_markets()   # конкуренты и доля рынка
	if gm.day % 30 == 0 and bank_deposit > 0:
		var interest := bank_deposit * get_tiered_rate()
		bank_deposit += interest
		emit_signal("bank_changed", bank_deposit)
		gm.recheck_net_worth()
	if active_loan > 0:
		active_loan += active_loan * LOAN_RATE_DAILY
		emit_signal("bank_changed", bank_deposit)
	# Охрана и негативные события — по каждому бизнесу империи
	for biz in businesses:
		var slv: int = int(biz.get("security_level", 0))
		var sec_cost = SECURITY_LEVELS[slv].cost_per_day
		if sec_cost > 0:
			gm.spend_money(sec_cost)
		if randf() < SECURITY_LEVELS[slv].event_chance:
			_trigger_negative_event()
	# Зарплата топ-менеджмента
	var exec_sal: float = get_executive_salary()
	if exec_sal > 0.0:
		gm.spend_money(exec_sal)
	gm.save_game()

# ── Охрана ────────────────────────────────────────────────────────────────────
func upgrade_security() -> bool:
	if security_level >= SECURITY_LEVELS.size() - 1: return false
	var install_cost = SECURITY_LEVELS[security_level + 1].install_cost
	if not gm.spend_money(install_cost): return false
	security_level += 1
	emit_signal("business_changed")
	gm.save_game()
	return true

func get_security_event_chance() -> float:
	return SECURITY_LEVELS[security_level].event_chance

func _trigger_negative_event() -> void:
	var pool: Array = []
	for ev in NEGATIVE_EVENTS:
		if ev.id == "raid" and security_level >= 3: continue
		if ev.id == "fire" and security_level >= 2: continue
		pool.append(ev)
	if pool.is_empty(): return
	var ev = pool[randi() % pool.size()]
	var loss: float = 0.0
	var pct: float = randf_range(ev.loss_min, ev.loss_max)
	if ev.loss_type == "income_pct":
		loss = get_daily_income() * pct
		gm.spend_money(minf(loss, gm.money))
	elif ev.loss_type == "biz_val_pct":
		loss = get_business_value() * pct
		gm.spend_money(minf(loss, gm.money))
	elif ev.loss_type == "bank_pct":
		loss = bank_deposit * pct
		bank_deposit = maxf(0.0, bank_deposit - loss)
		emit_signal("bank_changed", bank_deposit)
	last_event = {"name": ev.name, "icon": ev.icon, "desc": ev.desc, "loss": loss}
	emit_signal("security_event", last_event)

# ── Сохранение ────────────────────────────────────────────────────────────────
func reset_empire() -> void:
	businesses.clear()
	active_index = 0
	market_share.clear()
	executives.clear()

func save(cfg: ConfigFile) -> void:
	cfg.set_value("business", "businesses",   businesses)
	cfg.set_value("business", "active_index", active_index)
	cfg.set_value("business", "market_share", market_share)
	cfg.set_value("business", "executives",   executives)
	cfg.set_value("business", "bank_deposit",  bank_deposit)
	cfg.set_value("business", "active_loan",   active_loan)
	cfg.set_value("business", "total_earned",  total_earned)
	cfg.set_value("business", "business_days", business_days)
	cfg.set_value("business", "month_income",  month_income)
	cfg.set_value("business", "total_tax_paid", total_tax_paid)

func load(cfg: ConfigFile) -> void:
	businesses   = cfg.get_value("business", "businesses", [])
	active_index = cfg.get_value("business", "active_index", 0)
	market_share = cfg.get_value("business", "market_share", {})
	executives   = cfg.get_value("business", "executives", [])
	# Миграция старого формата (один бизнес) → портфель
	if businesses.is_empty():
		var old_id := String(cfg.get_value("business", "owned_id", ""))
		if old_id != "":
			businesses = [{
				"type_id": old_id,
				"level": int(cfg.get_value("business", "biz_level", 0)),
				"employees": cfg.get_value("business", "employees", []),
				"security_level": int(cfg.get_value("business", "security_level", 0)),
			}]
	bank_deposit      = cfg.get_value("business", "bank_deposit",  0.0)
	active_loan       = cfg.get_value("business", "active_loan",   0.0)
	total_earned      = cfg.get_value("business", "total_earned",  0.0)
	business_days     = cfg.get_value("business", "business_days", 0)
	month_income      = cfg.get_value("business", "month_income",  0.0)
	total_tax_paid    = cfg.get_value("business", "total_tax_paid", 0.0)
	# Чистим бизнесы с неизвестным типом и нормализуем поля
	var valid: Array = []
	for b in businesses:
		if typeof(b) != TYPE_DICTIONARY: continue
		if _get_type(String(b.get("type_id", ""))).is_empty(): continue
		if not b.has("level"): b["level"] = 0
		if not b.has("employees"): b["employees"] = []
		if not b.has("security_level"): b["security_level"] = 0
		valid.append(b)
	businesses = valid
	active_index = clampi(active_index, 0, maxi(0, businesses.size() - 1))

func _get_type(type_id: String) -> Dictionary:
	for bt in BUSINESS_TYPES:
		if bt.id == type_id: return bt
	return {}

func _get_employee_type(type_id: String) -> Dictionary:
	for et in EMPLOYEE_TYPES:
		if et.id == type_id: return et
	return {}
