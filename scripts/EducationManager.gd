extends Node

signal education_changed(level: int)

const LEVELS: Array = [
	{"name": "Без образования",  "icon": "🚫", "price": 0,          "desc": "Ничего не умеешь. Доступны лишь сбор бутылок и подметание дворов."},
	{"name": "Чтение",           "icon": "📖", "price": 150,        "desc": "Умеешь читать. Открываются грузчик, продавец, разнорабочий."},
	{"name": "3 класса",         "icon": "✏️",  "price": 500,        "desc": "Начальная школа. Уборщик, дворник, мелкая торговля, стройка."},
	{"name": "9 классов",        "icon": "📝", "price": 5000,       "desc": "Неполное среднее. Завод, стройка, склад, рынок."},
	{"name": "ПТУ",              "icon": "🔧", "price": 20000,      "desc": "Рабочая специальность. Мастер, механик, электрик, автосервис."},
	{"name": "Колледж",          "icon": "📋", "price": 80000,      "desc": "Среднее специальное. Кафе, супермаркет, кинотеатр, автосалон."},
	{"name": "ВУЗ (Бакалавр)",   "icon": "🎓", "price": 350000,     "desc": "Высшее. Офис, биржа, инвест-банк, торговый зал."},
	{"name": "ВУЗ (Магистр)",    "icon": "🏫", "price": 1200000,    "desc": "Управленец. Технопарк, консалтинг, конгресс-холл."},
	{"name": "ВУЗ (Аспирант)",   "icon": "🔬", "price": 4000000,    "desc": "Эксперт. Яхт-клуб, аэропорт, элитный сектор."},
	{"name": "Доктор наук",      "icon": "🧑‍🔬", "price": 15000000,   "desc": "Учёный. Дворец, частный аэропорт, нефтевышка."},
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

func buy_next() -> bool:
	if level >= LEVELS.size() - 1:
		return false
	var gm: Node = get_node("/root/GameManager")
	var price: float = LEVELS[level + 1].price
	if not gm.spend_money(price):
		return false
	level += 1
	emit_signal("education_changed", level)
	var qm: Node = get_node_or_null("/root/QuestManager")
	if qm: qm.add_diary_entry("🎓 Получено: " + LEVELS[level].name)
	return true

func save(cfg: ConfigFile) -> void:
	cfg.set_value("education", "level", level)

func load_data(cfg: ConfigFile) -> void:
	level = cfg.get_value("education", "level", 0)
