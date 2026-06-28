extends Node
# Должности (вакансии) на предприятиях. Один работодатель — несколько позиций под
# разные квалификации, как в реальной жизни: столовая = посудомойщик + повар +
# администратор. Игрок занимает позицию, под которую подходит по профессии и
# образованию и где есть свободное место.
#
# Позиция: {prof, title, min_edu, salary, slots, taken}
#   prof    — требуемая профессия ("" = любая, гейт только по образованию)
#   min_edu — минимальный уровень образования (индекс LEVELS)
#   salary  — базовый МЕСЯЧНЫЙ оклад (индексируется зарплатами при выдаче)
#   slots   — всего мест;  taken — занято NPC (часть мест уже не свободна)
#
# Это стартовый набор работодателей — полную карту по всем 9 зонам распишем дальше.
const EMPLOYERS := {
	# ── Зона 0 — Трущобы ──────────────────────────────────────────────────────
	"canteen": {
		"name": "Столовая «Уют»", "icon": "🍲", "zone": 0,
		"positions": [
			{"prof":"",        "title":"Посудомойщик",  "min_edu":0, "salary":30000,  "slots":3, "taken":1},
			{"prof":"cook",    "title":"Повар",          "min_edu":4, "salary":60000,  "slots":2, "taken":1},
			{"prof":"manager", "title":"Администратор",  "min_edu":5, "salary":95000,  "slots":1, "taken":0},
		],
	},
	"market": {
		"name": "Рынок «Развал»", "icon": "🛒", "zone": 0,
		"positions": [
			{"prof":"",        "title":"Грузчик",       "min_edu":0, "salary":28000,  "slots":4, "taken":2},
			{"prof":"driver",  "title":"Развозчик",     "min_edu":2, "salary":46000,  "slots":2, "taken":0},
			{"prof":"service", "title":"Продавец",      "min_edu":5, "salary":72000,  "slots":2, "taken":1},
		],
	},
	# ── Зона 1 — Рабочий квартал ──────────────────────────────────────────────
	"autoservice": {
		"name": "Автосервис «Гараж»", "icon": "🔧", "zone": 1,
		"positions": [
			{"prof":"",          "title":"Подсобник",    "min_edu":0, "salary":36000,  "slots":2, "taken":1},
			{"prof":"mechanic",  "title":"Автомеханик",  "min_edu":4, "salary":85000,  "slots":2, "taken":0},
			{"prof":"accountant","title":"Бухгалтер",    "min_edu":6, "salary":130000, "slots":1, "taken":0},
		],
	},
	"factory": {
		"name": "Завод «Молот»", "icon": "🏭", "zone": 1,
		"positions": [
			{"prof":"worker",  "title":"Рабочий",        "min_edu":0, "salary":44000,  "slots":5, "taken":2},
			{"prof":"mechanic","title":"Наладчик",       "min_edu":4, "salary":98000,  "slots":3, "taken":1},
			{"prof":"manager", "title":"Начальник смены","min_edu":5, "salary":160000, "slots":1, "taken":0},
		],
	},
	# ── Зона 2 — Спальный район ───────────────────────────────────────────────
	"supermarket": {
		"name": "Супермаркет «Берёзка»", "icon": "🏪", "zone": 2,
		"positions": [
			{"prof":"",        "title":"Кассир",         "min_edu":2, "salary":50000,  "slots":4, "taken":2},
			{"prof":"driver",  "title":"Водитель",       "min_edu":2, "salary":64000,  "slots":2, "taken":0},
			{"prof":"service", "title":"Менеджер зала",  "min_edu":5, "salary":92000,  "slots":2, "taken":1},
			{"prof":"manager", "title":"Директор",       "min_edu":5, "salary":150000, "slots":1, "taken":0},
		],
	},
	"clinic": {
		"name": "Поликлиника №7", "icon": "🏥", "zone": 2,
		"positions": [
			{"prof":"",          "title":"Регистратор",  "min_edu":3, "salary":56000,  "slots":2, "taken":1},
			{"prof":"doctor",    "title":"Врач",          "min_edu":7, "salary":270000, "slots":2, "taken":0},
			{"prof":"accountant","title":"Бухгалтер",    "min_edu":6, "salary":170000, "slots":1, "taken":0},
		],
	},
	# ── Зона 3 — Средний класс ────────────────────────────────────────────────
	"restaurant": {
		"name": "Ресторан «Веранда»", "icon": "🍽", "zone": 3,
		"positions": [
			{"prof":"service",   "title":"Официант",     "min_edu":5, "salary":95000,  "slots":3, "taken":1},
			{"prof":"cook",      "title":"Шеф-повар",     "min_edu":4, "salary":130000, "slots":2, "taken":0},
			{"prof":"manager",   "title":"Управляющий",  "min_edu":5, "salary":210000, "slots":1, "taken":0},
			{"prof":"accountant","title":"Бухгалтер",    "min_edu":6, "salary":185000, "slots":1, "taken":0},
		],
	},
	"school": {
		"name": "Гимназия №1", "icon": "🏫", "zone": 3,
		"positions": [
			{"prof":"",          "title":"Охранник",     "min_edu":2, "salary":62000,  "slots":2, "taken":1},
			{"prof":"programmer","title":"IT-специалист","min_edu":6, "salary":180000, "slots":1, "taken":0},
			{"prof":"accountant","title":"Бухгалтер",    "min_edu":6, "salary":160000, "slots":1, "taken":0},
		],
	},
	# ── Зона 4 — Бизнес-квартал ───────────────────────────────────────────────
	"office": {
		"name": "Бизнес-центр «Меридиан»", "icon": "🏢", "zone": 4,
		"positions": [
			{"prof":"manager",   "title":"Менеджер по продажам", "min_edu":5, "salary":170000, "slots":3, "taken":1},
			{"prof":"accountant","title":"Бухгалтер",            "min_edu":6, "salary":220000, "slots":2, "taken":0},
			{"prof":"programmer","title":"Программист",          "min_edu":6, "salary":330000, "slots":2, "taken":0},
			{"prof":"lawyer",    "title":"Юрист",                "min_edu":7, "salary":520000, "slots":1, "taken":0},
		],
	},
	"bank": {
		"name": "Банк «Капитал»", "icon": "🏦", "zone": 4,
		"positions": [
			{"prof":"service",   "title":"Операционист", "min_edu":5, "salary":160000, "slots":3, "taken":1},
			{"prof":"accountant","title":"Бухгалтер",    "min_edu":6, "salary":280000, "slots":2, "taken":0},
			{"prof":"financier", "title":"Финансист",    "min_edu":7, "salary":620000, "slots":2, "taken":0},
			{"prof":"manager",   "title":"Управляющий",  "min_edu":5, "salary":320000, "slots":1, "taken":0},
		],
	},
	# ── Зона 5 — Элитный район ─────────────────────────────────────────────────
	"lawfirm": {
		"name": "Юр. фирма «Право»", "icon": "⚖️", "zone": 5,
		"positions": [
			{"prof":"",          "title":"Помощник",     "min_edu":6, "salary":210000,  "slots":2, "taken":1},
			{"prof":"lawyer",    "title":"Юрист",         "min_edu":7, "salary":820000,  "slots":3, "taken":0},
			{"prof":"accountant","title":"Бухгалтер",    "min_edu":6, "salary":360000,  "slots":1, "taken":0},
		],
	},
	"privateclinic": {
		"name": "Частная клиника «Аврора»", "icon": "🩺", "zone": 5,
		"positions": [
			{"prof":"",       "title":"Медсестра",       "min_edu":5, "salary":190000,  "slots":2, "taken":1},
			{"prof":"doctor", "title":"Врач",             "min_edu":7, "salary":1050000, "slots":3, "taken":0},
			{"prof":"manager","title":"Главврач",         "min_edu":5, "salary":420000,  "slots":1, "taken":0},
		],
	},
	# ── Зона 6 — Район олигархов ──────────────────────────────────────────────
	"corp": {
		"name": "Корпорация «Атлант»", "icon": "🏙", "zone": 6,
		"positions": [
			{"prof":"manager",   "title":"Топ-менеджер", "min_edu":5, "salary":520000,  "slots":2, "taken":1},
			{"prof":"programmer","title":"Ведущий разработчик", "min_edu":6, "salary":950000, "slots":2, "taken":0},
			{"prof":"financier", "title":"Финансовый директор", "min_edu":7, "salary":1600000, "slots":2, "taken":0},
			{"prof":"lawyer",    "title":"Главный юрист", "min_edu":7, "salary":1850000, "slots":1, "taken":0},
		],
	},
	# ── Зона 7 — Правительственный квартал ────────────────────────────────────
	"ministry": {
		"name": "Министерство", "icon": "🏛", "zone": 7,
		"positions": [
			{"prof":"",          "title":"Делопроизводитель","min_edu":6, "salary":320000,  "slots":3, "taken":1},
			{"prof":"lawyer",    "title":"Советник по праву", "min_edu":7, "salary":1600000, "slots":2, "taken":0},
			{"prof":"accountant","title":"Аудитор",            "min_edu":6, "salary":850000,  "slots":2, "taken":0},
			{"prof":"financier", "title":"Эксперт по бюджету", "min_edu":7, "salary":2600000, "slots":1, "taken":0},
		],
	},
	# ── Зона 8 — Высший свет ──────────────────────────────────────────────────
	"institute": {
		"name": "НИИ «Прорыв»", "icon": "🔬", "zone": 8,
		"positions": [
			{"prof":"",          "title":"Лаборант",     "min_edu":7, "salary":1000000, "slots":2, "taken":1},
			{"prof":"scientist", "title":"Учёный",        "min_edu":8, "salary":4200000, "slots":3, "taken":0},
			{"prof":"programmer","title":"Инженер ИИ",   "min_edu":6, "salary":2600000, "slots":2, "taken":0},
			{"prof":"financier", "title":"Директор фонда","min_edu":7, "salary":6000000, "slots":1, "taken":0},
		],
	},
}

signal employment_changed

# ── Текущее трудоустройство (контракт) ────────────────────────────────────────
var employer_id: String = ""    # где работаю ("" — безработный)
var pos_index: int = -1         # индекс должности у работодателя
var occupancy: String = "full"  # "full" (полный день) | "half" (полдня)
var accrued: float = 0.0        # накопленный за месяц оклад (выплата раз в 30 дней)
var days_worked: int = 0        # отработано дней в текущем месяце
var work_mode: String = "auto"  # "auto" (случайный коэф.) | "active" (мини-игра)
var coefficient: float = 1.0    # текущий коэффициент эффективности (0.5–2.5)

const COEF_MIN := 0.5
const COEF_MAX := 2.5

# Грейд (карьера внутри компании): растёт со стажем на текущем месте, повышает оклад.
var tenure_days: int = 0   # дней отработано на текущей должности (сбрасывается при смене)
const GRADE_NAMES := ["Стажёр", "Младший", "Специалист", "Старший", "Руководитель"]
const GRADE_DAYS := [0, 24, 60, 120, 240]
const GRADE_MULT := [1.00, 1.10, 1.22, 1.36, 1.55]

const WORK_ENERGY_FULL := 16.0  # энергия за полный рабочий день (полдня — вдвое меньше)
const OCCUPANCY := {"full": 1.0, "half": 0.5}

func employer(id: String) -> Dictionary:
	return EMPLOYERS.get(id, {})

func employer_ids() -> Array:
	return EMPLOYERS.keys()

func positions(id: String) -> Array:
	return employer(id).get("positions", [])

func free_slots(pos: Dictionary) -> int:
	return maxi(0, int(pos.get("slots", 0)) - int(pos.get("taken", 0)))

func is_open(pos: Dictionary) -> bool:
	return free_slots(pos) > 0

# Доступен ли район работодателя (нельзя устроиться в ещё не открытую зону).
func zone_open(eid: String) -> bool:
	var zm := get_node_or_null("/root/ZoneManager")
	if zm == null:
		return true
	return int(employer(eid).get("zone", 0)) <= zm.max_zone_reached

# Подходит ли игрок: образование не ниже требуемого и (если нужна профессия) —
# именно эта профессия.
func qualifies(pos: Dictionary) -> bool:
	var em := get_node_or_null("/root/EducationManager")
	var lvl: int = em.level if em else 0
	if lvl < int(pos.get("min_edu", 0)):
		return false
	var need: String = String(pos.get("prof", ""))
	if need != "":
		var pm := get_node_or_null("/root/ProfessionManager")
		if pm == null or pm.profession != need:
			return false
	return true

# Месячный оклад с учётом индексации зарплат и профильной надбавки профессии.
func monthly_salary(pos: Dictionary) -> int:
	var gm := get_node_or_null("/root/GameManager")
	var wf: float = gm.wage_factor() if gm and gm.has_method("wage_factor") else 1.0
	var prof_mult: float = 1.0
	var pm := get_node_or_null("/root/ProfessionManager")
	if pm and pm.has_method("work_pay_mult"):
		prof_mult = pm.work_pay_mult(String(pos.get("prof", "")))
	return int(float(pos.get("salary", 0)) * wf * prof_mult)

# Позиции работодателя, которые игрок может занять прямо сейчас (подходит + есть место).
func available_for_player(id: String) -> Array:
	var out: Array = []
	if not zone_open(id):
		return out
	for pos in positions(id):
		if qualifies(pos) and is_open(pos):
			out.append(pos)
	return out

# Все работодатели заданной зоны.
func employers_in_zone(zone: int) -> Array:
	var out: Array = []
	for eid in EMPLOYERS:
		if int(EMPLOYERS[eid].get("zone", -1)) == zone:
			out.append(eid)
	return out

# ── Контракт: устройство, отработка, оклад, увольнение ────────────────────────
func is_employed() -> bool:
	return employer_id != "" and pos_index >= 0

func current_position() -> Dictionary:
	if not is_employed():
		return {}
	var ps: Array = positions(employer_id)
	if pos_index < ps.size():
		return ps[pos_index]
	return {}

func current_employer_name() -> String:
	return String(employer(employer_id).get("name", ""))

func occupancy_fraction() -> float:
	return float(OCCUPANCY.get(occupancy, 1.0))

# Устроиться на должность (сменив текущую, если была). Нужно подходить и иметь место.
func take_job(eid: String, idx: int, occ: String = "full") -> bool:
	var ps: Array = positions(eid)
	if idx < 0 or idx >= ps.size():
		return false
	var pos: Dictionary = ps[idx]
	if not qualifies(pos) or not is_open(pos) or not zone_open(eid):
		return false
	employer_id = eid
	pos_index = idx
	occupancy = occ if OCCUPANCY.has(occ) else "full"
	accrued = 0.0
	days_worked = 0
	tenure_days = 0   # стаж считается с нуля на новом месте
	emit_signal("employment_changed")
	var qm := get_node_or_null("/root/QuestManager")
	if qm: qm.add_diary_entry("📄 Устроился: %s, %s" % [current_employer_name(), pos.get("title", "")])
	return true

func set_occupancy(occ: String) -> void:
	if OCCUPANCY.has(occ):
		occupancy = occ
		emit_signal("employment_changed")

func quit_job() -> void:
	if not is_employed():
		return
	# При увольнении невыплаченный накопленный оклад выдаётся (расчёт при уходе)
	var gm := get_node_or_null("/root/GameManager")
	if gm and accrued > 0.0 and gm.has_method("add_work_income"):
		gm.add_work_income(accrued, false)
	employer_id = ""
	pos_index = -1
	accrued = 0.0
	days_worked = 0
	tenure_days = 0
	emit_signal("employment_changed")

# Один рабочий день: тратит энергию и копит дневной оклад. Возвращает true, если
# день отработан (хватило энергии). Вызывается из GameManager.next_day.
func process_workday() -> void:
	if not is_employed():
		return
	var gm := get_node_or_null("/root/GameManager")
	if gm == null:
		return
	var frac: float = occupancy_fraction()
	var relief: float = gm.get_housing_energy_drain_bonus() if gm.has_method("get_housing_energy_drain_bonus") else 0.0
	var e_cost: float = WORK_ENERGY_FULL * frac * (1.0 - relief)
	if gm.energy < e_cost:
		return   # прогул: слишком устал — день пропущен, без оклада
	gm.energy = clamp(gm.energy - e_cost, 0.0, gm.stat_max())
	gm.emit_signal("energy_changed", gm.energy)
	# Дорога до работы — ежедневные расходы (проезд)
	if gm.has_method("shop_price"):
		var commute: int = int(gm.shop_price(150) * frac)
		if commute > 0:
			gm.spend_money(commute)
	# Рабочий день занимает часы суток: с утра на 8 ч (полдня — 4 ч), при этом
	# идёт время и тратятся еда/вода. Так работа реально занимает день.
	var work_hours: int = int(round(8.0 * frac))
	if work_hours > 0 and gm.current_hour + work_hours < 24:
		gm.advance_time(work_hours, gm.WORK_DRAIN_MULT)
	# В авто-режиме коэффициент эффективности случаен (со сдвигом от навыка/выслуги);
	# в активном — задан последней мини-игрой (perform_shift) и держится.
	if work_mode == "auto":
		coefficient = _roll_auto_coeff()
	var daily: float = float(monthly_salary(current_position())) * frac * coefficient * grade_mult() / 30.0
	accrued += daily
	days_worked += 1
	if gm.has_method("add_work_xp"):
		gm.add_work_xp(8.0 * frac)   # выслуга растёт и на контракте
	# Стаж на этом месте → грейд (повышение по должности)
	var prev_grade: int = grade()
	tenure_days += 1
	if grade() > prev_grade:
		var qm := get_node_or_null("/root/QuestManager")
		if qm: qm.add_diary_entry("📈 Повышение: %s — %s" % [grade_name(), current_employer_name()])
		emit_signal("employment_changed")

# ── Грейд внутри компании ─────────────────────────────────────────────────────
func grade() -> int:
	var g: int = 0
	for i in GRADE_DAYS.size():
		if tenure_days >= GRADE_DAYS[i]:
			g = i
	return g

func grade_name() -> String:
	return GRADE_NAMES[grade()]

func grade_mult() -> float:
	return GRADE_MULT[grade()]

# Дней до следующего грейда (0 — потолок)
func days_to_next_grade() -> int:
	var g: int = grade()
	if g >= GRADE_DAYS.size() - 1:
		return 0
	return GRADE_DAYS[g + 1] - tenure_days

# Качество работника 0..1: профильный навык + выслуга. Сдвигает авто-коэффициент вверх.
func efficiency_quality() -> float:
	var q: float = 0.40
	var prof: String = String(current_position().get("prof", ""))
	var life := get_node_or_null("/root/LifeManager")
	if prof != "" and life:
		var pm := get_node_or_null("/root/ProfessionManager")
		var skill_id: String = String(pm.data(prof).get("skill", "")) if pm else ""
		if skill_id != "":
			var v: float = life.fitness if skill_id == "fitness" else life.skill(skill_id)
			q += (v / 100.0) * 0.40
	var gm := get_node_or_null("/root/GameManager")
	if gm and gm.has_method("career_progress"):
		q += gm.career_progress() * 0.20
	return clampf(q, 0.0, 1.0)

# Авто-коэффициент: случайный в [0.5, 2.5], смещённый качеством работника.
func _roll_auto_coeff() -> float:
	var center: float = efficiency_quality() + randf_range(-0.30, 0.30)
	return lerpf(COEF_MIN, COEF_MAX, clampf(center, 0.0, 1.0))

func set_work_mode(m: String) -> void:
	if m == "auto" or m == "active":
		work_mode = m
		if m == "active":
			coefficient = maxf(coefficient, 1.0)   # активный режим стартует не ниже базы
		emit_signal("employment_changed")

# Результат мини-игры (≈0.x–1.6) задаёт коэффициент для активного режима.
func perform_shift(mult: float) -> void:
	coefficient = clampf(mult * 1.6, COEF_MIN, COEF_MAX)
	emit_signal("employment_changed")

# Выплата месячного оклада (вызывается в месячном блоке next_day).
func process_payday() -> void:
	if not is_employed() or accrued <= 0.0:
		return
	var gm := get_node_or_null("/root/GameManager")
	if gm and gm.has_method("add_work_income"):
		gm.add_work_income(accrued, false)   # деньги + база НДФЛ (без продуктивности — она уже в коэффициенте)
	accrued = 0.0
	days_worked = 0

# Ожидаемый дневной заработок по контракту (для экрана «Финансы»; без случайного
# коэффициента — оценочно, с учётом занятости и грейда).
func expected_daily_wage() -> float:
	if not is_employed():
		return 0.0
	return float(monthly_salary(current_position())) * occupancy_fraction() * grade_mult() / 30.0

# Дневные расходы на проезд до работы.
func daily_commute() -> float:
	if not is_employed():
		return 0.0
	var gm := get_node_or_null("/root/GameManager")
	if gm == null or not gm.has_method("shop_price"):
		return 0.0
	return float(gm.shop_price(150)) * occupancy_fraction()

func save(cfg: ConfigFile) -> void:
	cfg.set_value("employment", "employer_id", employer_id)
	cfg.set_value("employment", "pos_index", pos_index)
	cfg.set_value("employment", "occupancy", occupancy)
	cfg.set_value("employment", "accrued", accrued)
	cfg.set_value("employment", "days_worked", days_worked)
	cfg.set_value("employment", "work_mode", work_mode)
	cfg.set_value("employment", "coefficient", coefficient)
	cfg.set_value("employment", "tenure_days", tenure_days)

func load_data(cfg: ConfigFile) -> void:
	employer_id = cfg.get_value("employment", "employer_id", "")
	pos_index = cfg.get_value("employment", "pos_index", -1)
	occupancy = cfg.get_value("employment", "occupancy", "full")
	accrued = cfg.get_value("employment", "accrued", 0.0)
	days_worked = cfg.get_value("employment", "days_worked", 0)
	work_mode = cfg.get_value("employment", "work_mode", "auto")
	coefficient = cfg.get_value("employment", "coefficient", 1.0)
	tenure_days = cfg.get_value("employment", "tenure_days", 0)

func reset() -> void:
	employer_id = ""
	pos_index = -1
	occupancy = "full"
	accrued = 0.0
	days_worked = 0
	work_mode = "auto"
	coefficient = 1.0
	tenure_days = 0
