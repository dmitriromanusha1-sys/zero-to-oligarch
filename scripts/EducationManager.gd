extends Node

signal education_changed(level: int)

const LEVELS: Array = [
	{"name": "Без образования",  "icon": "🚫", "price": 0,          "desc": "Ничего не умеешь. Сбор бутылок, дворник, ларёк."},
	{"name": "Чтение",           "icon": "📖", "price": 150,        "desc": "Умеешь читать. Грузчик, шаурмячная."},
	{"name": "3 класса",         "icon": "✏️",  "price": 500,        "desc": "Начальная школа. Разнорабочий на стройке, продавец на рынке."},
	{"name": "9 классов",        "icon": "📝", "price": 5000,       "desc": "Неполное среднее. Завод, стройка, склад."},
	{"name": "ПТУ",              "icon": "🔧", "price": 20000,      "desc": "Рабочая специальность. Автомеханик, кассир, бариста, курьер."},
	{"name": "Колледж",          "icon": "📋", "price": 80000,      "desc": "Среднее специальное. Киномеханик, ресторан, менеджер по продажам."},
	{"name": "ВУЗ (Бакалавр)",   "icon": "🎓", "price": 350000,     "desc": "Высшее. Инвест-банк, офис, трейдер, бизнес-кафе, конференции."},
	{"name": "ВУЗ (Магистр)",    "icon": "🏫", "price": 1200000,    "desc": "Управленец. Технопарк, венчурный фонд, яхт-клуб."},
	{"name": "ВУЗ (Аспирант)",   "icon": "🔬", "price": 4000000,    "desc": "Эксперт. Аэропорт, опера, дворец, нефтевышка."},
	{"name": "Доктор наук",      "icon": "🧑‍🔬", "price": 15000000,   "desc": "Учёный. Частный аэропорт, советник."},
	{"name": "Гений",            "icon": "🧠", "price": 80000000,   "desc": "Вершина. Доступно всё, максимум удачи в мини-игре."},
]

# Веса зон [miss, ok, good, perfect] для каждого уровня образования
const ZONE_WEIGHTS: Array = [
	[60, 28,  9,  3],  # 0 — без образования
	[50, 30, 15,  5],  # 1 — чтение
	[42, 32, 18,  8],  # 2 — 3 класса
	[33, 35, 22, 10],  # 3 — 9 классов
	[25, 37, 26, 12],  # 4 — ПТУ
	[18, 35, 30, 17],  # 5 — колледж
	[12, 30, 35, 23],  # 6 — бакалавр
	[ 8, 25, 38, 29],  # 7 — магистр
	[ 5, 20, 40, 35],  # 8 — аспирант
	[ 3, 15, 40, 42],  # 9 — доктор наук
	[ 2, 10, 35, 53],  # 10 — гений
]

var level: int = 0

func get_level_name() -> String:
	return LEVELS[level].name

func get_level_icon() -> String:
	return LEVELS[level].icon

func can_work_at(edu_req: int) -> bool:
	return level >= edu_req

func get_zone_weights() -> Array:
	return ZONE_WEIGHTS[level]

# Скидка на обучение от интеллекта: умным проще учиться (до -20%, до +10% «тяжело»).
func tuition_mult() -> float:
	var life := get_node_or_null("/root/LifeManager")
	if life and life.has_method("skill"):
		return clampf(1.0 - (life.skill("intellect") - 50.0) / 50.0 * 0.20, 0.80, 1.10)
	return 1.0

# Итоговая цена уровня с учётом инфляции и скидки за интеллект.
func price_for(next_i: int) -> int:
	if next_i <= 0 or next_i >= LEVELS.size():
		return 0
	var gm: Node = get_node("/root/GameManager")
	var base: float = float(LEVELS[next_i].price) * tuition_mult()
	return gm.shop_price(int(base)) if gm.has_method("shop_price") else int(base)

func next_price() -> int:
	return price_for(level + 1)

func buy_next() -> bool:
	if level >= LEVELS.size() - 1:
		return false
	var gm: Node = get_node("/root/GameManager")
	var price: int = next_price()
	if not gm.spend_money(price):
		return false
	level += 1
	emit_signal("education_changed", level)
	# Диплом развивает личные навыки: учёба делает умнее, высшее — ещё и общительнее.
	var life := get_node_or_null("/root/LifeManager")
	if life and life.has_method("gain_skill"):
		life.gain_skill("intellect", 4.0)
		if level >= 6:
			life.gain_skill("charisma", 2.0)
	var qm: Node = get_node_or_null("/root/QuestManager")
	if qm: qm.add_diary_entry("🎓 Получено: " + LEVELS[level].name)
	return true

func save(cfg: ConfigFile) -> void:
	cfg.set_value("education", "level", level)

func load_data(cfg: ConfigFile) -> void:
	level = cfg.get_value("education", "level", 0)
