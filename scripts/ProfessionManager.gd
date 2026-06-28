extends Node
# Профессия (квалификация) игрока — вторая ось карьеры рядом с образованием.
# Образование = «как далеко учился» (потолок), профессия = «кем работаешь».
# Игрок выбирает одну специализацию, учится ей (нужен уровень образования и
# деньги) и может переучиться. Профессия даёт профильный бонус на «своей» работе,
# а её «родственный» навык усиливает эффективность (применяется в фазах далее).

signal profession_changed(id: String)

# Каждая профессия: id, имя, иконка, требуемый уровень образования (индекс LEVELS
# в EducationManager), родственный навык (intellect/charisma/willpower/fitness),
# стоимость обучения, профильная надбавка к оплате и краткое описание.
const PROFESSIONS: Array = [
	{"id":"worker",     "name":"Разнорабочий",  "icon":"🧹", "min_edu":0, "skill":"fitness",   "cost":0,        "bonus":1.20, "desc":"Грузчик, дворник, уборка, подсобка."},
	{"id":"driver",     "name":"Водитель",      "icon":"🚚", "min_edu":2, "skill":"fitness",   "cost":3000,     "bonus":1.22, "desc":"Курьер, такси, доставка, дальнобой."},
	{"id":"mechanic",   "name":"Механик",       "icon":"🔧", "min_edu":4, "skill":"willpower", "cost":12000,    "bonus":1.25, "desc":"Автосервис, ремонт, наладка оборудования."},
	{"id":"cook",       "name":"Повар",         "icon":"🍳", "min_edu":4, "skill":"fitness",   "cost":12000,    "bonus":1.25, "desc":"Кухня, общепит, рестораны."},
	{"id":"service",    "name":"Сфера услуг",   "icon":"💇", "min_edu":5, "skill":"charisma",  "cost":40000,    "bonus":1.26, "desc":"Бариста, продавец, официант, стилист."},
	{"id":"manager",    "name":"Менеджер",      "icon":"💼", "min_edu":5, "skill":"charisma",  "cost":60000,    "bonus":1.28, "desc":"Продажи, администрирование, управление."},
	{"id":"accountant", "name":"Бухгалтер",     "icon":"🧮", "min_edu":6, "skill":"intellect", "cost":150000,   "bonus":1.30, "desc":"Учёт, финансы предприятий, аудит."},
	{"id":"programmer", "name":"Программист",   "icon":"💻", "min_edu":6, "skill":"intellect", "cost":220000,   "bonus":1.32, "desc":"Разработка, IT, технопарк."},
	{"id":"lawyer",     "name":"Юрист",         "icon":"⚖️", "min_edu":7, "skill":"intellect", "cost":800000,   "bonus":1.34, "desc":"Право, сделки, суды, консалтинг."},
	{"id":"doctor",     "name":"Врач",          "icon":"🩺", "min_edu":7, "skill":"intellect", "cost":1000000,  "bonus":1.34, "desc":"Медицина, клиники, диагностика."},
	{"id":"financier",  "name":"Финансист",     "icon":"📈", "min_edu":7, "skill":"intellect", "cost":1200000,  "bonus":1.36, "desc":"Инвестбанк, трейдинг, венчур."},
	{"id":"scientist",  "name":"Учёный",        "icon":"🔬", "min_edu":8, "skill":"intellect", "cost":3000000,  "bonus":1.40, "desc":"Наука, R&D, инженерия высоких технологий."},
]

var profession: String = ""   # id текущей профессии ("" — без специализации)

func data(id: String) -> Dictionary:
	for p in PROFESSIONS:
		if p.id == id:
			return p
	return {}

func has_profession() -> bool:
	return profession != ""

func current() -> Dictionary:
	return data(profession)

func current_name() -> String:
	var d := current()
	return d.get("name", "Без профессии")

func current_icon() -> String:
	var d := current()
	return d.get("icon", "👤")

# Доступна ли профессия по образованию (деньги проверяются при обучении).
func can_learn(id: String) -> bool:
	var d := data(id)
	if d.is_empty() or id == profession:
		return false
	var em := get_node_or_null("/root/EducationManager")
	var lvl: int = em.level if em else 0
	return lvl >= int(d.get("min_edu", 0))

# Итоговая стоимость обучения профессии с учётом инфляции.
func learn_cost(id: String) -> int:
	var d := data(id)
	if d.is_empty():
		return 0
	var gm := get_node_or_null("/root/GameManager")
	var base: int = int(d.get("cost", 0))
	return gm.shop_price(base) if gm and gm.has_method("shop_price") else base

# Выучить/сменить профессию: проверяет образование и списывает деньги.
func learn(id: String) -> bool:
	if not can_learn(id):
		return false
	var gm := get_node_or_null("/root/GameManager")
	var price: int = learn_cost(id)
	if gm and price > 0 and not gm.spend_money(price):
		return false
	profession = id
	emit_signal("profession_changed", profession)
	var qm := get_node_or_null("/root/QuestManager")
	if qm: qm.add_diary_entry("🧑‍🏭 Освоена профессия: " + current_name())
	return true

# Профильная надбавка к оплате, если работа совпадает с твоей профессией.
func work_pay_mult(job_profession: String) -> float:
	if job_profession == "" or job_profession != profession:
		return 1.0
	return float(current().get("bonus", 1.0))

func matches(job_profession: String) -> bool:
	return job_profession != "" and job_profession == profession

# ── Профильные баффы: профессия влияет на всю игру (не только на работе) ───────
func wage_tax_mult() -> float:        # ⚖️ юрист — меньше подоходного налога
	return 0.85 if profession == "lawyer" else 1.0

func deposit_rate_bonus() -> float:   # 📈 финансист — выше ставка по вкладу
	return 0.02 if profession == "financier" else 0.0

func medical_cost_mult() -> float:    # 🩺 врач — дешевле медицина
	return 0.80 if profession == "doctor" else 1.0

func nutrition_quality_bonus() -> float:  # 🍳 повар — питательнее рацион
	return 8.0 if profession == "cook" else 0.0

func business_income_mult() -> float:     # 💼 менеджер — выше доход бизнеса
	return 1.06 if profession == "manager" else 1.0

func tuition_perk_mult() -> float:        # 🔬 учёный — дешевле обучение
	return 0.85 if profession == "scientist" else 1.0

func reputation_gain_mult() -> float:     # 💇 сфера услуг — быстрее репутация
	return 1.25 if profession == "service" else 1.0

func skill_gain_mult() -> float:          # 💻 программист — быстрее прокачка навыков
	return 1.20 if profession == "programmer" else 1.0

func expense_mult() -> float:             # 🧮 бухгалтер / 🚚 водитель — ниже расходы
	if profession == "accountant": return 0.92
	if profession == "driver": return 0.95
	return 1.0

func work_energy_perk() -> float:         # 🧹 разнорабочий / 🔧 механик — меньше устаёшь
	return 0.06 if (profession == "worker" or profession == "mechanic") else 0.0

func save(cfg: ConfigFile) -> void:
	cfg.set_value("profession", "id", profession)

func load_data(cfg: ConfigFile) -> void:
	profession = cfg.get_value("profession", "id", "")

func reset() -> void:
	profession = ""
