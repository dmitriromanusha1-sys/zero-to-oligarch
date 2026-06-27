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

# Пул названий фирм-конкурентов по секторам (для поглощений).
const COMPETITOR_NAMES: Dictionary = {
	"food":     ["Вкусно и точка", "Шаурма №1", "ЕдаЭкспресс", "Пельмешка", "ГастроХит"],
	"retail":   ["Магнитик", "Пятёрочка+", "ТоргСеть", "Всёмаркет", "Лавка у дома"],
	"industry": ["ПромЗавод", "СтальИндустрия", "ТехноФаб", "МашСтрой", "УралМет"],
	"finance":  ["БанкИнвест", "КапиталГрупп", "ФинХолдинг", "АктивКапитал", "ИнвестДом"],
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

# ── Международная экспансия ───────────────────────────────────────────────────
# Зарубежные рынки. income_mult — множитель к экспортному доходу, risk — шанс
# негативного события/мес, entry_cost — цена выхода на рынок.
const FOREIGN_MARKETS: Array = [
	{"id":"cis",     "name":"СНГ",        "flag":"🌍","entry_cost":20_000_000,    "income_mult":0.8, "risk":0.04, "desc":"Близкие рынки, низкий риск."},
	{"id":"asia",    "name":"Азия",       "flag":"🏯","entry_cost":100_000_000,   "income_mult":1.3, "risk":0.08, "desc":"Быстрый рост, высокая конкуренция."},
	{"id":"europe",  "name":"Европа",     "flag":"🏰","entry_cost":300_000_000,   "income_mult":1.6, "risk":0.06, "desc":"Премиальный рынок, строгие законы."},
	{"id":"america", "name":"Америка",    "flag":"🗽","entry_cost":800_000_000,   "income_mult":2.0, "risk":0.10, "desc":"Огромный рынок и большие риски."},
	{"id":"global",  "name":"Глобальный", "flag":"🌐","entry_cost":3_000_000_000, "income_mult":2.5, "risk":0.12, "desc":"Транснациональная корпорация."},
]
const FOREIGN_INCOME_FACTOR: float = 0.15   # доля внутреннего дохода на уровень присутствия

# ── Вертикальная интеграция ───────────────────────────────────────────────────
# Цепочка поставок: производство → дистрибуция → потребитель. Владея соседними
# звеньями, снабжаешь себя сам и получаешь бонус к доходу. Финансы — поддержка.
const SUPPLY_CHAIN: Array = ["industry", "retail", "food"]
const INTEGRATION_LINK_BONUS: float = 0.12   # за каждое связанное звено
const INTEGRATION_FINANCE_BONUS: float = 0.08 # за наличие финансов
const INTEGRATION_MAX: float = 0.40

# ── R&D / корпоративные технологии ────────────────────────────────────────────
# Постоянные бонусы всей империи. requires — id предшествующих исследований.
const TECHS: Array = [
	{"id":"automation","name":"Автоматизация",       "icon":"🤖","cost":2_000_000,  "requires":[],                  "income":0.10, "desc":"+10% к доходу всех бизнесов."},
	{"id":"logistics", "name":"Логистика",           "icon":"🚚","cost":8_000_000,  "requires":["automation"],      "income":0.15, "desc":"+15% к доходу всех бизнесов."},
	{"id":"crm",       "name":"CRM и маркетинг",      "icon":"📊","cost":15_000_000, "requires":["automation"],      "brand":0.20,  "desc":"+20% к силе бренда сетей."},
	{"id":"governance","name":"Корп. управление",     "icon":"🏛","cost":30_000_000, "requires":[],                  "capacity":3,  "desc":"+3 к ёмкости управления."},
	{"id":"taxopt",    "name":"Налоговая оптимизация","icon":"🧾","cost":50_000_000, "requires":["governance"],      "tax":0.30,    "desc":"−30% налога на прибыль."},
	{"id":"rnd_lab",   "name":"R&D-лаборатория",      "icon":"🔬","cost":120_000_000,"requires":["logistics","crm"], "income":0.25, "desc":"+25% к доходу всех бизнесов."},
	{"id":"expansion", "name":"Корп. экспансия",      "icon":"🌐","cost":200_000_000,"requires":["governance"],      "maxbiz":2,    "desc":"+2 к лимиту бизнесов."},
]

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
	return 1 + int(t / 3) + research_max_biz()

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

# IPO: публична ли компания и какой долей владеет игрок (1.0 = частная).
var is_public: bool = false
var owner_fraction: float = 1.0

# Изученные технологии (id → true)
var researched: Dictionary = {}

# Зарубежные рынки: market_id → {level:int}
var foreign: Dictionary = {}

# ── Доля рынка по секторам ────────────────────────────────────────────────────
# sector → твоя доля рынка 0..1. Конкуренты точат долю, доля влияет на доход.
var market_share: Dictionary = {}
# sector → Array of {name:String, share:float} — фирмы-конкуренты для поглощений.
var competitors: Dictionary = {}
# sector → антимонопольный «жар» (0..1.5); при ≥1 срабатывает расследование.
var antitrust_heat: Dictionary = {}
# sector → {mult:float, months:int} — активный отраслевой кризис.
var sector_crisis: Dictionary = {}

const COMP_MULT_MIN    : float = 0.65   # доход при крошечной доле рынка
const COMP_MULT_MAX    : float = 1.35   # доход при доминировании
const MARKET_INVEST    : float = 0.12   # +доля за один маркетинговый вброс

# ── Антимонополия и кризисы ───────────────────────────────────────────────────
const ANTITRUST_THRESHOLD : float = 0.55  # выше этой доли копится «жар»
const ANTITRUST_HEAT_GAIN : float = 0.30  # прирост жара/мес при максимальной доле
const ANTITRUST_HEAT_DECAY: float = 0.20  # спад жара/мес при невысокой доле
const ANTITRUST_FINE_PCT  : float = 0.06  # штраф = 6% капитализации
const ANTITRUST_DIVEST    : float = 0.25  # принудительная потеря доли
const CRISIS_CHANCE       : float = 0.06  # шанс отраслевого кризиса/мес

# ── IPO / публичная компания ──────────────────────────────────────────────────
const IPO_MIN_VALUATION : float = 50_000_000.0   # минимальная капитализация для IPO
const IPO_SELL_FRACTION : float = 0.30           # доля, продаваемая на IPO
const SECONDARY_FRACTION: float = 0.10           # шаг допэмиссии / выкупа
const OWNER_MIN_FRACTION: float = 0.50           # ниже контрольной доли не опускаемся
const PE_MULT           : float = 4.0            # мультипликатор годовой прибыли в оценке
const TOTAL_SHARES      : int   = 1_000_000      # всего акций (для курса)

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
	var sec: String = sector_of(String(biz.get("type_id", "")))
	income *= sector_competition_mult(sec)
	# Отраслевой кризис временно режет доход сектора
	income *= crisis_mult(sec)
	return income

# Доход активного бизнеса (для карточки в магазине).
func get_active_income() -> float:
	return _income_of(active_business())

# Внутренний (домашний) доход империи: бизнесы × цикл × эффективность × R&D.
func _domestic_income() -> float:
	var total: float = 0.0
	for biz in businesses:
		total += _income_of(biz)
	if total != 0.0:
		var cb := get_node_or_null("/root/CentralBankManager")
		if cb and cb.has_method("business_mult"):
			total *= cb.business_mult()
	total *= efficiency_mult()
	total *= research_income_mult()
	# Вертикальная интеграция: связанные звенья цепочки поставок дают бонус
	total *= (1.0 + integration_bonus())
	return total

# Доход одного зарубежного рынка (масштабируется внутренним доходом).
func market_income(id: String) -> float:
	var m := _get_market(id)
	if m.is_empty() or not is_in_market(id): return 0.0
	return _domestic_income() * FOREIGN_INCOME_FACTOR * float(m.income_mult) * market_level(id)

# Суммарный доход от зарубежной экспансии.
func foreign_income() -> float:
	var total: float = 0.0
	for id in foreign:
		total += market_income(String(id))
	return total

# Валовый доход всей империи в день (внутренний + зарубежный).
func get_gross_income() -> float:
	return _domestic_income() + foreign_income()

# ── Международная экспансия ───────────────────────────────────────────────────
func _get_market(id: String) -> Dictionary:
	for m in FOREIGN_MARKETS:
		if m.id == id: return m
	return {}

func is_in_market(id: String) -> bool:
	return foreign.has(id)

func market_level(id: String) -> int:
	return int((foreign.get(id, {}) as Dictionary).get("level", 0))

func can_enter(id: String) -> bool:
	var m := _get_market(id)
	return not m.is_empty() and not is_in_market(id) and businesses.size() > 0 and gm.money >= float(m.entry_cost)

func enter_market(id: String) -> bool:
	var m := _get_market(id)
	if m.is_empty() or is_in_market(id): return false
	if not gm.spend_money(m.entry_cost): return false
	foreign[id] = {"level": 1}
	emit_signal("business_changed")
	gm.save_game()
	return true

func market_upgrade_cost(id: String) -> int:
	var m := _get_market(id)
	if m.is_empty(): return 0
	return int(float(m.entry_cost) * 0.5 * (market_level(id) + 1))

func upgrade_market(id: String) -> bool:
	if not is_in_market(id): return false
	if not gm.spend_money(market_upgrade_cost(id)): return false
	foreign[id]["level"] = market_level(id) + 1
	emit_signal("business_changed")
	gm.save_game()
	return true

# Ежемесячные зарубежные риски: девальвация (потеря денег) или уход с рынка.
func _foreign_risk_tick() -> void:
	for id in foreign.keys():
		var m := _get_market(String(id))
		if m.is_empty(): continue
		if randf() >= float(m.risk):
			continue
		var es := get_node_or_null("/root/EventSystem")
		if randf() < 0.6:
			# Девальвация / штраф: теряем часть денег, привязанную к доходу рынка
			var loss: float = market_income(String(id)) * 60.0
			loss = minf(loss, gm.money)
			gm.spend_money(loss)
			if es:
				es.event_triggered.emit({"text": "💱 %s: валютный кризис на рынке «%s» — потеряно %s." % [m.flag, m.name, gm.format_money(loss)], "money": -loss, "health": 0})
		else:
			# Снижение присутствия (национализация/уход)
			var lv: int = market_level(String(id))
			if lv <= 1:
				foreign.erase(id)
			else:
				foreign[id]["level"] = lv - 1
			if es:
				es.event_triggered.emit({"text": "🏛 %s: на рынке «%s» национализировали часть активов — присутствие снижено." % [m.flag, m.name], "money": 0, "health": 0})

# Доход, который получает игрок: валовый × доля владения (после IPO < 100%).
func get_daily_income() -> float:
	var pol_mult: float = 1.0
	var inf := get_node_or_null("/root/InfluenceManager")
	if inf and inf.has_method("political_income_mult"):
		pol_mult = inf.political_income_mult()   # субсидия (лобби) × контроль районов
	elif inf and inf.has_method("law_business_mult"):
		pol_mult = inf.law_business_mult()
	return get_gross_income() * owner_fraction * pol_mult

# Суммарная стоимость всех бизнесов империи.
func get_empire_value() -> float:
	var total: float = 0.0
	for biz in businesses:
		var bt := _get_type(String(biz.get("type_id", "")))
		if not bt.is_empty():
			total += bt.cost * (1.0 + int(biz.get("level", 0)) * 0.25)
	# Зарубежные активы — по балансовой стоимости присутствия
	for id in foreign:
		var m := _get_market(String(id))
		if not m.is_empty():
			total += float(m.entry_cost) * 0.6 * market_level(String(id))
	return total

# ── IPO / публичная компания ──────────────────────────────────────────────────
# Капитализация = активы империи + капитализация годовой прибыли (P/E).
func company_valuation() -> float:
	return maxf(0.0, get_empire_value() + get_gross_income() * 365.0 * PE_MULT)

func share_price() -> float:
	return company_valuation() / float(TOTAL_SHARES)

func can_ipo() -> bool:
	return not is_public and businesses.size() > 0 and company_valuation() >= IPO_MIN_VALUATION

# Выходим на биржу: продаём долю публике, получаем разовый капитал.
func do_ipo() -> float:
	if not can_ipo(): return 0.0
	var proceeds: float = company_valuation() * IPO_SELL_FRACTION
	owner_fraction = 1.0 - IPO_SELL_FRACTION
	is_public = true
	gm.add_money(proceeds)
	emit_signal("business_changed")
	gm.save_game()
	return proceeds

func can_secondary() -> bool:
	return is_public and (owner_fraction - SECONDARY_FRACTION) >= OWNER_MIN_FRACTION - 0.0001

# Допэмиссия: продаём ещё долю за капитал (но не ниже контрольной).
func secondary_offering() -> float:
	if not can_secondary(): return 0.0
	var proceeds: float = company_valuation() * SECONDARY_FRACTION
	owner_fraction -= SECONDARY_FRACTION
	gm.add_money(proceeds)
	emit_signal("business_changed")
	gm.save_game()
	return proceeds

func buyback_cost() -> int:
	return int(company_valuation() * SECONDARY_FRACTION * 1.10)   # +10% премия за выкуп

func can_buyback() -> bool:
	return is_public and owner_fraction < 1.0 and gm.money >= buyback_cost()

# Выкуп акций: возвращаем долю; выкупив всё — снова частная компания.
func buyback() -> bool:
	if not is_public or owner_fraction >= 1.0: return false
	if not gm.spend_money(buyback_cost()): return false
	owner_fraction = minf(1.0, owner_fraction + SECONDARY_FRACTION)
	if owner_fraction >= 0.999:
		owner_fraction = 1.0
		is_public = false
	emit_signal("business_changed")
	gm.save_game()
	return true

# Вклад бизнеса в капитал игрока: публичная — доля × капитализация; частная — 70% активов.
func get_business_networth() -> float:
	if is_public:
		return owner_fraction * company_valuation()
	return get_empire_value() * 0.7

# ── R&D / технологии ──────────────────────────────────────────────────────────
func _get_tech(id: String) -> Dictionary:
	for t in TECHS:
		if t.id == id: return t
	return {}

func is_researched(id: String) -> bool:
	return researched.get(id, false)

func can_research(id: String) -> bool:
	if is_researched(id): return false
	var t := _get_tech(id)
	if t.is_empty(): return false
	for req in t.get("requires", []):
		if not is_researched(req): return false
	return true

func research(id: String) -> bool:
	if not can_research(id): return false
	var t := _get_tech(id)
	if not gm.spend_money(t.cost): return false
	researched[id] = true
	emit_signal("business_changed")
	gm.save_game()
	return true

func _tech_sum(key: String) -> float:
	var s: float = 0.0
	for t in TECHS:
		if is_researched(t.id):
			s += float(t.get(key, 0.0))
	return s

func research_income_mult() -> float:
	return 1.0 + _tech_sum("income")

func research_brand_bonus() -> float:
	return _tech_sum("brand")

func research_capacity() -> int:
	return int(_tech_sum("capacity"))

func research_tax_reduction() -> float:
	return minf(0.6, _tech_sum("tax"))

func research_max_biz() -> int:
	return int(_tech_sum("maxbiz"))

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
	return 1.0 + minf(BRAND_BONUS_MAX, BRAND_BONUS_STEP * extra) + research_brand_bonus()

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

func has_sector(sector: String) -> bool:
	for biz in businesses:
		if sector_of(String(biz.get("type_id", ""))) == sector:
			return true
	return false

# Число замкнутых соседних звеньев цепочки поставок (производство→дистрибуция→ретейл).
func integration_links() -> int:
	var links: int = 0
	for i in range(SUPPLY_CHAIN.size() - 1):
		if has_sector(SUPPLY_CHAIN[i]) and has_sector(SUPPLY_CHAIN[i + 1]):
			links += 1
	return links

# Бонус вертикальной интеграции к доходу империи.
func integration_bonus() -> float:
	var b: float = integration_links() * INTEGRATION_LINK_BONUS
	if has_sector("finance"):
		b += INTEGRATION_FINANCE_BONUS
	return minf(INTEGRATION_MAX, b)

# Присутствие игрока в секторе (число точек с учётом уровней).
func _presence_pts(sector: String) -> float:
	var pts: float = 0.0
	for biz in businesses:
		if sector_of(String(biz.get("type_id", ""))) == sector:
			pts += 1.0 + 0.5 * int(biz.get("level", 0))
	return pts

# ── Конкуренты / поглощения (M&A) ─────────────────────────────────────────────
# Создаёт фирмы-конкурентов при первом выходе в сектор (делят рынок между собой).
func _ensure_competitors(sector: String) -> void:
	if competitors.has(sector):
		return
	var pool: Array = COMPETITOR_NAMES.get(sector, [])
	var names: Array = pool.duplicate()
	names.shuffle()
	var rivals: Array = []
	for i in range(mini(3, names.size())):
		rivals.append({"name": names[i], "share": randf_range(0.18, 0.30)})
	competitors[sector] = rivals

func get_competitors(sector: String) -> Array:
	return competitors.get(sector, [])

func _rival_total(sector: String) -> float:
	var t: float = 0.0
	for r in get_competitors(sector):
		t += float(r.get("share", 0.0))
	return t

# Стоимость поглощения конкурента (по его доле и оценке дохода рынка сектора).
func acquisition_cost(sector: String, index: int) -> int:
	var rivals: Array = get_competitors(sector)
	if index < 0 or index >= rivals.size(): return 0
	var rshare: float = float(rivals[index].get("share", 0.0))
	var my_inc: float = 0.0
	for biz in businesses:
		if sector_of(String(biz.get("type_id", ""))) == sector:
			my_inc += _income_of(biz)
	var full_market: float = my_inc / maxf(get_share(sector), 0.08)
	return int(maxf(100000.0, rshare * full_market * 200.0))

func acquire_competitor(sector: String, index: int) -> bool:
	var rivals: Array = get_competitors(sector)
	if index < 0 or index >= rivals.size(): return false
	var cost: int = acquisition_cost(sector, index)
	if not gm.spend_money(cost): return false
	var rshare: float = float(rivals[index].get("share", 0.0))
	market_share[sector] = clampf(get_share(sector) + rshare, 0.05, 0.98)
	rivals.remove_at(index)
	emit_signal("business_changed")
	gm.save_game()
	return true

# ── Влияние СМИ (вызывается InfluenceManager) ─────────────────────────────────
# Компромат: бьёт по самому крупному конкуренту в активном секторе, перетягивая
# его долю игроку. Возвращает строку «имя (сектор)» или "" если некого бить.
func media_smear_competitor(power: float) -> String:
	var sectors := active_sectors()
	if sectors.is_empty(): return ""
	var target_sector := ""
	for s in sectors:
		_ensure_competitors(s)
		if get_competitors(s).size() > 0:
			target_sector = s
			break
	if target_sector == "": return ""
	var rivals: Array = get_competitors(target_sector)
	var idx: int = 0
	for i in range(rivals.size()):
		if float(rivals[i].get("share", 0.0)) > float(rivals[idx].get("share", 0.0)):
			idx = i
	var drop: float = minf(float(rivals[idx].get("share", 0.0)) - 0.05, power)
	if drop <= 0.0: return ""
	rivals[idx]["share"] = maxf(0.05, float(rivals[idx].get("share", 0.0)) - drop)
	market_share[target_sector] = clampf(get_share(target_sector) + drop, 0.03, 0.98)
	emit_signal("business_changed")
	return "%s (%s)" % [rivals[idx].get("name", "?"), target_sector]

# Управление повесткой: снижает антимонопольный жар во всех секторах.
func media_reduce_heat(amount: float) -> void:
	for s in antitrust_heat.keys():
		antitrust_heat[s] = maxf(0.0, float(antitrust_heat[s]) - amount)
	emit_signal("business_changed")

# ── Антимонополия ─────────────────────────────────────────────────────────────
func antitrust_risk(sector: String) -> float:
	return float(antitrust_heat.get(sector, 0.0))

func lobby_cost(sector: String) -> int:
	return int(maxf(200000.0, company_valuation() * 0.01))

# Лоббирование: снижает антимонопольный жар в секторе.
func lobby(sector: String) -> bool:
	if not gm.spend_money(lobby_cost(sector)): return false
	antitrust_heat[sector] = maxf(0.0, antitrust_risk(sector) - 0.5)
	emit_signal("business_changed")
	gm.save_game()
	return true

# Появление нового конкурента (после раздела монополии).
func _spawn_competitor(sector: String) -> void:
	var pool: Array = COMPETITOR_NAMES.get(sector, [])
	var existing: Array = []
	for r in get_competitors(sector):
		existing.append(r.get("name", ""))
	var avail: Array = []
	for n in pool:
		if not (n in existing):
			avail.append(n)
	if avail.is_empty(): return
	if not competitors.has(sector):
		competitors[sector] = []
	competitors[sector].append({"name": avail[randi() % avail.size()], "share": randf_range(0.15, 0.25)})

# Антимонопольное расследование: штраф + принудительный раздел доли + конкурент.
func _trigger_antitrust(sector: String) -> void:
	var fine: float = company_valuation() * ANTITRUST_FINE_PCT
	if fine > 0.0:
		gm.spend_money(minf(fine, gm.money))
	market_share[sector] = clampf(get_share(sector) - ANTITRUST_DIVEST, 0.05, 0.98)
	_spawn_competitor(sector)
	var es := get_node_or_null("/root/EventSystem")
	if es:
		var sname: String = SECTOR_NAMES.get(sector, sector)
		es.event_triggered.emit({
			"text": "⚖ Антимонопольное дело в секторе «%s»! Штраф %s и принудительный раздел доли рынка." % [sname, gm.format_money(fine)],
			"money": -fine, "health": 0
		})

# ── Отраслевые кризисы ────────────────────────────────────────────────────────
func crisis_mult(sector: String) -> float:
	if sector_crisis.has(sector):
		return float(sector_crisis[sector].get("mult", 1.0))
	return 1.0

func has_crisis(sector: String) -> bool:
	return sector_crisis.has(sector)

# Ежемесячно: доля органически растёт от присутствия к свободному рынку
# (1 − доля конкурентов), оставшиеся соперники слегка её точат. Поглощения
# навсегда поднимают потолок и ослабляют эрозию вплоть до монополии.
func _update_markets() -> void:
	var sectors := active_sectors()
	for s in sectors:
		_ensure_competitors(s)
		var rivals_n: int = get_competitors(s).size()
		var avail: float = clampf(1.0 - _rival_total(s), 0.05, 0.98)
		var cur: float = get_share(s)
		if cur <= 0.0:
			cur = minf(0.12, avail)
		var growth: float = 0.025 + 0.012 * _presence_pts(s)
		cur = minf(cur + growth, avail)
		cur -= 0.015 * rivals_n
		market_share[s] = clampf(cur, 0.03, avail)
		# Антимонопольный жар: копится при высокой доле
		var heat: float = antitrust_risk(s)
		var share_now: float = market_share[s]
		if share_now > ANTITRUST_THRESHOLD:
			heat += ANTITRUST_HEAT_GAIN * (share_now - ANTITRUST_THRESHOLD) / (1.0 - ANTITRUST_THRESHOLD)
		else:
			heat = maxf(0.0, heat - ANTITRUST_HEAT_DECAY)
		if heat >= 1.0:
			_trigger_antitrust(s)
			heat = 0.4   # после раздела жар спадает, но не до нуля
		antitrust_heat[s] = clampf(heat, 0.0, 1.5)
		# Отраслевой кризис: тик активного / шанс нового
		if sector_crisis.has(s):
			sector_crisis[s].months -= 1
			if sector_crisis[s].months <= 0:
				sector_crisis.erase(s)
				var es0 := get_node_or_null("/root/EventSystem")
				if es0:
					es0.event_triggered.emit({"text": "📈 Кризис в секторе «%s» миновал." % SECTOR_NAMES.get(s, s), "money": 0, "health": 0})
		elif randf() < CRISIS_CHANCE:
			var cm: float = randf_range(0.60, 0.80)
			sector_crisis[s] = {"mult": cm, "months": randi_range(2, 4)}
			var es1 := get_node_or_null("/root/EventSystem")
			if es1:
				es1.event_triggered.emit({"text": "📉 Кризис в секторе «%s»: доход −%d%% на несколько месяцев." % [SECTOR_NAMES.get(s, s), int(round((1.0 - cm) * 100.0))], "money": 0, "health": 0})
	# забываем секторы, где бизнеса больше нет
	for s in market_share.keys():
		if not (s in sectors):
			market_share.erase(s)
			competitors.erase(s)
			antitrust_heat.erase(s)
			sector_crisis.erase(s)

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
	var cap: int = BASE_MGMT_CAPACITY + research_capacity()
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
			var law_tax: float = 1.0
			var inf_t := get_node_or_null("/root/InfluenceManager")
			if inf_t and inf_t.has_method("law_tax_mult"):
				law_tax = inf_t.law_tax_mult()
			var tax: float = month_income * TAX_RATE * tax_mult * (1.0 - research_tax_reduction()) * law_tax
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
		_foreign_risk_tick()   # зарубежные риски
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
	competitors.clear()
	antitrust_heat.clear()
	sector_crisis.clear()
	executives.clear()
	is_public = false
	owner_fraction = 1.0
	researched.clear()
	foreign.clear()

func save(cfg: ConfigFile) -> void:
	cfg.set_value("business", "businesses",   businesses)
	cfg.set_value("business", "active_index", active_index)
	cfg.set_value("business", "market_share", market_share)
	cfg.set_value("business", "competitors",  competitors)
	cfg.set_value("business", "antitrust_heat", antitrust_heat)
	cfg.set_value("business", "sector_crisis", sector_crisis)
	cfg.set_value("business", "executives",   executives)
	cfg.set_value("business", "is_public",    is_public)
	cfg.set_value("business", "owner_fraction", owner_fraction)
	cfg.set_value("business", "researched",   researched)
	cfg.set_value("business", "foreign",      foreign)
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
	competitors  = cfg.get_value("business", "competitors", {})
	antitrust_heat = cfg.get_value("business", "antitrust_heat", {})
	sector_crisis  = cfg.get_value("business", "sector_crisis", {})
	executives   = cfg.get_value("business", "executives", [])
	is_public      = cfg.get_value("business", "is_public", false)
	owner_fraction = cfg.get_value("business", "owner_fraction", 1.0)
	researched     = cfg.get_value("business", "researched", {})
	foreign        = cfg.get_value("business", "foreign", {})
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
