extends Node

signal quest_completed(quest: Dictionary)
signal quest_added(quest: Dictionary)
signal diary_entry_added(text: String)

# Формат квеста:
# id, title, desc, type (money/housing/title/business/day), target, reward_money, reward_health, completed
const ALL_QUESTS = [
	# Стартовые
	{"id":"q01","title":"Первые деньги",        "desc":"Заработай 500 ₽",             "type":"money",    "target":500,          "reward_money":200,    "reward_health":0},
	{"id":"q02","title":"Крыша над головой",     "desc":"Купи палатку",                "type":"housing",  "target":2,            "reward_money":1000,   "reward_health":10},
	{"id":"q03","title":"Нищий, но гордый",      "desc":"Накопи 5 000 ₽",             "type":"money",    "target":5000,         "reward_money":2000,   "reward_health":5},
	{"id":"q04","title":"Своя комната",          "desc":"Сними комнату",               "type":"housing",  "target":6,            "reward_money":5000,   "reward_health":10},
	# Средний уровень
	{"id":"q05","title":"Первые 50 тысяч",       "desc":"Накопи 50 000 ₽",            "type":"money",    "target":50000,        "reward_money":10000,  "reward_health":0},
	{"id":"q06","title":"Предприниматель",        "desc":"Открой ИП или ООО",           "type":"business", "target":1,            "reward_money":20000,  "reward_health":5},
	{"id":"q07","title":"Работодатель",           "desc":"Найми первого сотрудника",    "type":"employees","target":1,            "reward_money":15000,  "reward_health":0},
	{"id":"q08","title":"Своя однушка",          "desc":"Купи однушку",                "type":"housing",  "target":7,            "reward_money":50000,  "reward_health":15},
	{"id":"q09","title":"Выживший",              "desc":"Проживи 100 дней",            "type":"day",      "target":100,          "reward_money":30000,  "reward_health":20},
	# Высокий уровень
	{"id":"q10","title":"Полмиллиона",           "desc":"Накопи 500 000 ₽",           "type":"money",    "target":500000,       "reward_money":100000, "reward_health":0},
	{"id":"q11","title":"Квартира есть",         "desc":"Купи свою квартиру",          "type":"housing",  "target":8,            "reward_money":200000, "reward_health":20},
	{"id":"q12","title":"Богач",                 "desc":"Накопи 5 000 000 ₽",         "type":"money",    "target":5000000,      "reward_money":500000, "reward_health":0},
	{"id":"q13","title":"Большой штат",          "desc":"Найми 5 сотрудников",         "type":"employees","target":5,            "reward_money":300000, "reward_health":0},
	{"id":"q14","title":"Вкладчик",              "desc":"Положи 1 000 000 ₽ в банк",  "type":"bank",     "target":1000000,      "reward_money":200000, "reward_health":0},
	{"id":"q15","title":"Долгожитель",           "desc":"Проживи 365 дней",            "type":"day",      "target":365,          "reward_money":500000, "reward_health":30},
	# Топ
	{"id":"q16","title":"Миллионер",             "desc":"Накопи 50 000 000 ₽",        "type":"money",    "target":50000000,     "reward_money":2000000,"reward_health":0},
	{"id":"q17","title":"Собственный дом",       "desc":"Купи дом",                    "type":"housing",  "target":9,            "reward_money":1000000,"reward_health":20},
	{"id":"q18","title":"Корпорация",            "desc":"Открой корпорацию",           "type":"biz_level","target":4,            "reward_money":5000000,"reward_health":0},
	{"id":"q19","title":"Олигарх",               "desc":"Накопи 1 000 000 000 ₽",     "type":"money",    "target":1000000000,   "reward_money":0,      "reward_health":100},
	{"id":"q20","title":"Везунчик",             "desc":"Выиграй в казино",            "type":"casino_win","target":1,           "reward_money":50000,  "reward_health":0},
	{"id":"q21","title":"Игрок",                "desc":"Выиграй в казино 5 раз",      "type":"casino_win","target":5,           "reward_money":200000, "reward_health":0},
	# Обучение — цепочка "найди школу, получи образование"
	{"id":"q22","title":"Найти школу",          "desc":"Получи начальное образование (3 класса)", "type":"education","target":1, "reward_money":1000,   "reward_health":5},
	{"id":"q23","title":"Школьник",             "desc":"Закончи 9 классов",            "type":"education","target":2,           "reward_money":4000,   "reward_health":5},
	{"id":"q24","title":"Студент",              "desc":"Получи ПТУ или колледж",       "type":"education","target":4,           "reward_money":15000,  "reward_health":10},
	{"id":"q25","title":"Дипломированный",      "desc":"Закончи ВУЗ (бакалавр)",       "type":"education","target":5,           "reward_money":60000,  "reward_health":10},
]

# Повторяемые цели — выдаются, когда фиксированный список исчерпан, чтобы у игрока
# всегда было к чему стремиться на протяжении всей игры
var _repeat_counter: int = 0

var active_quests: Array = []
var completed_ids: Array = []
var diary: Array = []
var casino_wins: int = 0

var gm: Node
var bm: Node

func _ready() -> void:
	gm = get_node("/root/GameManager")
	bm = get_node("/root/BusinessManager")
	gm.money_changed.connect(_check_quests)
	gm.title_changed.connect(func(_t): _check_quests(gm.money))
	gm.day_changed.connect(func(_d): _check_quests(gm.money))
	gm.housing_changed.connect(func(_h): _check_quests(gm.money))
	bm.business_changed.connect(func(): _check_quests(gm.money))
	var em = get_node_or_null("/root/EducationManager")
	if em: em.education_changed.connect(func(_l): _check_quests(gm.money))
	_unlock_available()

func _on_casino_finished(delta: float) -> void:
	if delta > 0:
		casino_wins += 1
		_check_quests(gm.money)

func _unlock_available() -> void:
	for q in ALL_QUESTS:
		if not completed_ids.has(q.id) and not _is_active(q.id):
			if active_quests.size() < 4:
				active_quests.append(q.duplicate())
				emit_signal("quest_added", q)
	# Если фиксированные цели закончились — генерируем повторяемую цель,
	# чтобы список заданий никогда не пустел до конца игры
	while active_quests.size() < 3:
		var q := _make_repeat_quest()
		active_quests.append(q)
		emit_signal("quest_added", q)

func _make_repeat_quest() -> Dictionary:
	_repeat_counter += 1
	var target: float = maxf(gm.money * 1.5 + 5000.0, 5000.0 * _repeat_counter)
	var reward: float = target * 0.08
	return {
		"id": "rep_%d" % _repeat_counter,
		"title": "Цель: %s" % gm.format_money(target),
		"desc": "Накопи %s" % gm.format_money(target),
		"type": "money", "target": target,
		"reward_money": reward, "reward_health": 0,
		"repeatable": true,
	}

func _is_active(id: String) -> bool:
	for q in active_quests:
		if q.id == id: return true
	return false

func _check_quests(_val) -> void:
	var to_complete: Array = []
	for q in active_quests:
		if _is_quest_done(q):
			to_complete.append(q)
	for q in to_complete:
		_complete_quest(q)
	_unlock_available()

func _is_quest_done(q: Dictionary) -> bool:
	match q.type:
		"money":     return gm.money >= q.target
		"housing":   return gm.current_housing_index >= q.target
		"title":     return gm.current_title_index >= q.target
		"business":   return bm.owned_business_id != ""
		"biz_level":  return _biz_level() >= q.target
		"employees":  return bm.employees.size() >= q.target
		"bank":       return bm.bank_deposit >= q.target
		"day":        return gm.day >= q.target
		"casino_win": return casino_wins >= q.target
		"education":
			var em = get_node_or_null("/root/EducationManager")
			return em != null and em.level >= q.target
	return false

func _biz_level() -> int:
	if bm.owned_business_id == "": return -1
	for i in range(bm.BUSINESS_TYPES.size()):
		if bm.BUSINESS_TYPES[i].id == bm.owned_business_id:
			return i
	return 0

func _complete_quest(q: Dictionary) -> void:
	active_quests.erase(q)
	completed_ids.append(q.id)
	if q.reward_money > 0:
		gm.add_money(q.reward_money)
	if q.reward_health > 0:
		gm.health = minf(gm.health + q.reward_health, 100.0)
		gm.emit_signal("health_changed", gm.health)
	emit_signal("quest_completed", q)
	add_diary_entry("✅ Цель выполнена: «" + q.title + "»")
	gm.save_game()

func add_diary_entry(text: String) -> void:
	var entry = "День %d: %s" % [gm.day, text]
	diary.append(entry)
	if diary.size() > 100:
		diary.pop_front()
	emit_signal("diary_entry_added", entry)

func save(cfg: ConfigFile) -> void:
	cfg.set_value("quests", "completed_ids", completed_ids)
	cfg.set_value("quests", "diary", diary)
	cfg.set_value("quests", "casino_wins", casino_wins)

func load(cfg: ConfigFile) -> void:
	completed_ids = cfg.get_value("quests", "completed_ids", [])
	diary = cfg.get_value("quests", "diary", [])
	casino_wins = cfg.get_value("quests", "casino_wins", 0)
	active_quests.clear()
	_unlock_available()
