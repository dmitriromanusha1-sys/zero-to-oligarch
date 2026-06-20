extends Node

signal business_changed()
signal bank_changed(amount: float)
signal security_event(event: Dictionary)

const MAX_BIZ_LEVEL  : int   = 5
const LVL_COST_MULT  : float = 0.40
const LVL_INCOME_MULT: float = 0.30
const LOAN_RATE_DAILY: float = 0.01

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
	{"id":"latok",      "name":"Уличный лоток",  "cost":8000,        "income_per_day":150,      "max_employees":1,   "min_title":0, "icon":"🥤",  "desc":"Лимонад и семечки. Первые шаги в бизнесе."},
	{"id":"ip",         "name":"ИП / Ларёк",     "cost":50000,       "income_per_day":600,      "max_employees":3,   "min_title":1, "icon":"🏪",  "desc":"Зарегистрировал ИП. Небольшой ларёк у метро."},
	{"id":"cafe",       "name":"Кафе",           "cost":280000,      "income_per_day":3000,     "max_employees":6,   "min_title":2, "icon":"☕",  "desc":"Уютное кафе в спальном районе. Постоянные клиенты."},
	{"id":"shop",       "name":"Магазин",        "cost":1200000,     "income_per_day":10000,    "max_employees":10,  "min_title":2, "icon":"🏬",  "desc":"Полноценный магазин. Ассортимент, витрины, поставщики."},
	{"id":"restaurant", "name":"Ресторан",       "cost":5000000,     "income_per_day":40000,    "max_employees":15,  "min_title":3, "icon":"🍽",  "desc":"Банкеты, корпоративы, постоянные гости. Хорошая прибыль."},
	{"id":"factory",    "name":"Мини-завод",     "cost":20000000,    "income_per_day":150000,   "max_employees":30,  "min_title":3, "icon":"🏭",  "desc":"Производство → дистрибуция напрямую. Серьёзный бизнес."},
	{"id":"chain",      "name":"Торговая сеть",  "cost":80000000,    "income_per_day":600000,   "max_employees":60,  "min_title":4, "icon":"🏢",  "desc":"Несколько точек по городу. Бренд растёт."},
	{"id":"holding",    "name":"Холдинг",        "cost":300000000,   "income_per_day":2500000,  "max_employees":150, "min_title":5, "icon":"🏦",  "desc":"Группа компаний с активами в разных секторах."},
	{"id":"corporation","name":"Корпорация",     "cost":1200000000,  "income_per_day":12000000, "max_employees":500, "min_title":6, "icon":"🌐",  "desc":"Международная корпорация. Вершина делового мира."},
]

const EMPLOYEE_TYPES: Array = [
	{"id":"worker",     "name":"Разнорабочий", "cost":5000,   "salary_per_day":200,  "income_bonus":500,   "icon":"👷", "desc":"Базовый персонал. Минимальный вклад."},
	{"id":"manager",    "name":"Менеджер",     "cost":40000,  "salary_per_day":800,  "income_bonus":2000,  "icon":"👔", "desc":"Организует работу, улучшает логистику."},
	{"id":"marketer",   "name":"Маркетолог",   "cost":80000,  "salary_per_day":1400, "income_bonus":4500,  "icon":"📊", "desc":"Привлекает клиентов. Отличный ROI."},
	{"id":"accountant", "name":"Бухгалтер",    "cost":120000, "salary_per_day":2200, "income_bonus":7500,  "icon":"🧾", "desc":"Оптимизирует налоги и издержки."},
	{"id":"director",   "name":"Директор",     "cost":350000, "salary_per_day":5500, "income_bonus":18000, "icon":"🤵", "desc":"Стратегическое управление. Максимальный вклад."},
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

var owned_business_id: String = ""
var business_level   : int    = 0
var employees        : Array  = []
var bank_deposit     : float  = 0.0
var active_loan      : float  = 0.0
var total_earned     : float  = 0.0
var business_days    : int    = 0
var security_level   : int    = 0
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
	return maxf(0.0, get_business_value() + bank_deposit * 0.5)

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
func open_business(type_id: String) -> bool:
	if owned_business_id != "": return false
	var bt := _get_type(type_id)
	if bt.is_empty(): return false
	if not gm.spend_money(bt.cost): return false
	owned_business_id = type_id
	business_level = 0
	business_days  = 0
	employees.clear()
	emit_signal("business_changed")
	gm.save_game()
	return true

func upgrade_business(new_type_id: String) -> bool:
	if owned_business_id == "": return false
	var bt := _get_type(new_type_id)
	if bt.is_empty(): return false
	if not gm.spend_money(bt.cost): return false
	owned_business_id = new_type_id
	business_level = 0
	emit_signal("business_changed")
	gm.save_game()
	return true

func upgrade_level() -> bool:
	if business_level >= MAX_BIZ_LEVEL: return false
	var cost := get_upgrade_cost()
	if not gm.spend_money(cost): return false
	business_level += 1
	emit_signal("business_changed")
	gm.save_game()
	return true

func sell_business() -> float:
	var value := get_business_value() * 0.50
	gm.add_money(value)
	owned_business_id = ""
	business_level    = 0
	employees.clear()
	emit_signal("business_changed")
	gm.save_game()
	return value

func get_business() -> Dictionary:
	if owned_business_id == "": return {}
	return _get_type(owned_business_id)

func get_daily_income() -> float:
	if owned_business_id == "": return 0.0
	var bt := get_business()
	var income: float = bt.income_per_day * get_level_income_mult()
	for e in employees:
		var et := _get_employee_type(e.type_id)
		income += et.income_bonus - et.salary_per_day
	income *= get_synergy_mult()
	return income

func can_open(type_id: String) -> bool:
	var bt := _get_type(type_id)
	if bt.is_empty(): return false
	return gm.money >= bt.cost and gm.current_title_index >= bt.min_title

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
	var syn := get_synergy_recipe()
	if syn.is_empty(): return 1.0
	if employees.is_empty(): return 1.0  # без команды штраф синергии не действует
	var max_bonus: float = syn.bonus
	var penalty_max: float = max_bonus * SYN_PENALTY_RATIO
	var mid_bonus  : float = max_bonus * SYN_MID_RATIO
	var r := get_synergy_fulfillment()
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
	if gm.day % 30 == 0 and bank_deposit > 0:
		var interest := bank_deposit * get_tiered_rate()
		bank_deposit += interest
		emit_signal("bank_changed", bank_deposit)
		gm.recheck_net_worth()
	if active_loan > 0:
		active_loan += active_loan * LOAN_RATE_DAILY
		emit_signal("bank_changed", bank_deposit)
	if owned_business_id != "":
		var sec_cost = SECURITY_LEVELS[security_level].cost_per_day
		if sec_cost > 0:
			gm.spend_money(sec_cost)
		if randf() < SECURITY_LEVELS[security_level].event_chance:
			_trigger_negative_event()
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
func save(cfg: ConfigFile) -> void:
	cfg.set_value("business", "owned_id",      owned_business_id)
	cfg.set_value("business", "biz_level",     business_level)
	cfg.set_value("business", "employees",     employees)
	cfg.set_value("business", "bank_deposit",  bank_deposit)
	cfg.set_value("business", "active_loan",   active_loan)
	cfg.set_value("business", "total_earned",  total_earned)
	cfg.set_value("business", "business_days", business_days)
	cfg.set_value("business", "security_level", security_level)

func load(cfg: ConfigFile) -> void:
	owned_business_id = cfg.get_value("business", "owned_id",      "")
	business_level    = cfg.get_value("business", "biz_level",     0)
	employees         = cfg.get_value("business", "employees",     [])
	bank_deposit      = cfg.get_value("business", "bank_deposit",  0.0)
	active_loan       = cfg.get_value("business", "active_loan",   0.0)
	total_earned      = cfg.get_value("business", "total_earned",  0.0)
	business_days     = cfg.get_value("business", "business_days", 0)
	security_level    = cfg.get_value("business", "security_level", 0)

func _get_type(type_id: String) -> Dictionary:
	for bt in BUSINESS_TYPES:
		if bt.id == type_id: return bt
	return {}

func _get_employee_type(type_id: String) -> Dictionary:
	for et in EMPLOYEE_TYPES:
		if et.id == type_id: return et
	return {}
