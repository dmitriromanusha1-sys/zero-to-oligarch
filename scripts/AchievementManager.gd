extends Node

signal achievement_unlocked(ach: Dictionary)

# Формат: id, icon, title, desc, unlocked
const ALL := [
	# Деньги
	{"id":"a01","icon":"💵","title":"Первая сотня",       "desc":"Заработай 100 ₽"},
	{"id":"a02","icon":"💰","title":"Тысячник",           "desc":"Накопи 1 000 ₽"},
	{"id":"a03","icon":"💳","title":"Полтинник",          "desc":"Накопи 50 000 ₽"},
	{"id":"a04","icon":"🏦","title":"Миллион!",           "desc":"Накопи 1 000 000 ₽"},
	{"id":"a05","icon":"💎","title":"Миллиардер",         "desc":"Накопи 1 000 000 000 ₽"},
	# Выживание
	{"id":"a06","icon":"📅","title":"Неделя",             "desc":"Проживи 7 дней"},
	{"id":"a07","icon":"🗓","title":"Месяц",              "desc":"Проживи 30 дней"},
	{"id":"a08","icon":"🏆","title":"Год прошёл",         "desc":"Проживи 365 дней"},
	{"id":"a09","icon":"⚰️","title":"Нет, не умер",       "desc":"Упади до 1 здоровья и выживи"},
	# Жильё
	{"id":"a10","icon":"📦","title":"Коробочник",         "desc":"Ночуй в коробке"},
	{"id":"a11","icon":"⛺","title":"Турист поневоле",    "desc":"Купи палатку"},
	{"id":"a12","icon":"🏠","title":"Хозяин",             "desc":"Купи свою квартиру"},
	{"id":"a13","icon":"🏡","title":"Загородный дом",     "desc":"Купи коттедж"},
	{"id":"a14","icon":"🏰","title":"Вилла мечты",        "desc":"Купи виллу"},
	{"id":"a35","icon":"🏙","title":"Пентхаус",           "desc":"Купи пентхаус"},
	{"id":"a36","icon":"🌴","title":"Личный остров",      "desc":"Купи личный остров"},
	# Бизнес
	{"id":"a15","icon":"📝","title":"ИПшник",             "desc":"Открой первый бизнес"},
	{"id":"a16","icon":"👔","title":"Работодатель",       "desc":"Найми 10 сотрудников"},
	{"id":"a17","icon":"🏢","title":"Корпорат",           "desc":"Владей корпорацией"},
	# Казино
	{"id":"a18","icon":"🎰","title":"Удача новичка",      "desc":"Выиграй в казино"},
	{"id":"a19","icon":"💸","title":"Игрок",              "desc":"Выиграй в казино 5 раз подряд"},
	# Репутация
	{"id":"a20","icon":"⭐","title":"Уважаемый человек",  "desc":"Получи репутацию 80+"},
	{"id":"a21","icon":"🦹","title":"Криминальный талант","desc":"Упади до репутации 0"},
	# Полиция/налоги
	{"id":"a22","icon":"👮","title":"Попался",            "desc":"Попади под полицейскую проверку"},
	{"id":"a23","icon":"📋","title":"Честный налогоплательщик","desc":"Заплати налоги 12 раз"},
	# Образование
	{"id":"a25","icon":"📖","title":"Самоучка",          "desc":"Получи первое образование"},
	{"id":"a26","icon":"🎓","title":"Студент",            "desc":"Окончи ВУЗ (Бакалавр)"},
	{"id":"a27","icon":"🧠","title":"Гений",              "desc":"Получи уровень образования Гений"},
	# Транспорт
	{"id":"a28","icon":"🚲","title":"Велосипедист",       "desc":"Купи велосипед"},
	{"id":"a29","icon":"🚗","title":"Автовладелец",       "desc":"Купи первую машину"},
	{"id":"a30","icon":"🏎","title":"На скорости",        "desc":"Купи суперкар или лимузин"},
	# Кредиты
	{"id":"a31","icon":"💳","title":"В долгах",           "desc":"Возьми первый кредит"},
	{"id":"a32","icon":"✅","title":"Чист!",               "desc":"Полностью выплати кредит"},
	# Здоровье
	{"id":"a33","icon":"💪","title":"Железное здоровье",  "desc":"Восстанови здоровье до 100"},
	# Секретные / Титулы
	{"id":"a24","icon":"🎭","title":"Zero to Oligarch",  "desc":"Достигни титула Олигарх"},
	{"id":"a37","icon":"💼","title":"Магнат",             "desc":"Достигни титула Магнат"},
	{"id":"a38","icon":"🥇","title":"В высшей лиге",      "desc":"Достигни титула Мультимиллионер"},
	{"id":"a34","icon":"🏝","title":"Остров удачи",       "desc":"Попади на Остров Удачи"},
	{"id":"grey_cardinal","icon":"👑","title":"Серый кардинал","desc":"Стань теневым правителем города"},
	{"id":"president","icon":"🏛","title":"Президент","desc":"Победи в президентской гонке"},
]

var unlocked_ids: Array = []
var _casino_streak: int = 0
var _tax_count: int = 0

func _ready() -> void:
	var gm = get_node("/root/GameManager")
	gm.money_changed.connect(_check_money)
	gm.title_changed.connect(_check_title)
	gm.housing_changed.connect(_check_housing)
	gm.health_changed.connect(_check_health)
	gm.day_changed.connect(_check_day)

	var rm = get_node_or_null("/root/ReputationManager")
	if rm: rm.reputation_changed.connect(_check_reputation)

	var bm = get_node_or_null("/root/BusinessManager")
	if bm:
		bm.business_changed.connect(_check_business)

	var em = get_node_or_null("/root/EducationManager")
	if em: em.education_changed.connect(_check_education)

	var tm = get_node_or_null("/root/TransportManager")
	if tm: tm.transport_changed.connect(func(_n, _m): _check_transport())

	var lm = get_node_or_null("/root/LoanManager")
	if lm:
		lm.loan_taken.connect(func(_a): unlock("a31"))
		lm.loan_closed.connect(func(_n): unlock("a32"))

func unlock(id: String) -> void:
	if id in unlocked_ids:
		return
	unlocked_ids.append(id)
	for a in ALL:
		if a.id == id:
			achievement_unlocked.emit(a)
			break

# ── чекеры ───────────────────────────────────────────────────────────────────

func _check_money(amount: float) -> void:
	if amount >= 100:       unlock("a01")
	if amount >= 1000:      unlock("a02")
	if amount >= 50000:     unlock("a03")
	if amount >= 1000000:   unlock("a04")
	if amount >= 1000000000: unlock("a05")

func _check_day(d: int) -> void:
	if d >= 7:   unlock("a06")
	if d >= 30:  unlock("a07")
	if d >= 365: unlock("a08")
	# Налоги каждые 30 дней — засчитываем только если ставка > 0 (не Бомж)
	if d % 30 == 0:
		var gm2 = get_node_or_null("/root/GameManager")
		const TAX_RATES := [0.0, 0.0, 0.04, 0.05, 0.07, 0.08, 0.10, 0.12, 0.14, 0.16, 0.18, 0.20, 0.22, 0.24, 0.26, 0.28, 0.30]
		var rate: float = TAX_RATES[gm2.current_title_index] if gm2 else 0.0
		if rate > 0.0:
			_tax_count += 1
			if _tax_count >= 12: unlock("a23")

func _check_title(title: String) -> void:
	if title == "Мультимиллионер": unlock("a38")
	if title == "Магнат":          unlock("a37")
	if title == "Олигарх":         unlock("a24")

func _check_housing(housing: String) -> void:
	if housing == "Коробка":        unlock("a10")
	if housing == "Палатка":        unlock("a11")
	if housing == "Своя квартира":  unlock("a12")
	if housing == "Коттедж":        unlock("a13")
	if housing == "Вилла":          unlock("a14")
	if housing == "Пентхаус":       unlock("a35")
	if housing == "Личный остров":  unlock("a36")

func _check_health(hp: float) -> void:
	if hp <= 1.0:   unlock("a09")
	if hp >= 100.0: unlock("a33")

func _check_reputation(val: int) -> void:
	if val >= 80: unlock("a20")
	if val <= 0:  unlock("a21")

func _check_business(_ignored = null) -> void:
	var bm = get_node_or_null("/root/BusinessManager")
	if bm == null: return
	if bm.business_count() > 0: unlock("a15")
	# Сотрудники: максимум по любому бизнесу империи
	var max_emp: int = 0
	for b in bm.businesses:
		max_emp = maxi(max_emp, (b.get("employees", []) as Array).size())
	if max_emp >= 10: unlock("a16")
	# Корпорация — если хоть один бизнес в империи стал корпорацией
	for b in bm.businesses:
		if String(b.get("type_id", "")) == "corporation": unlock("a17"); break

func _check_education(level: int) -> void:
	if level >= 1: unlock("a25")
	if level >= 5: unlock("a26")
	if level >= 9: unlock("a27")

func _check_transport() -> void:
	var tm = get_node_or_null("/root/TransportManager")
	if tm == null: return
	var mult: float = tm.get_speed_mult()
	if mult >= 1.7: unlock("a28")  # велосипед (1.7), не самокат (1.4)
	if mult >= 2.2: unlock("a29")  # жигуль (2.2)
	if mult >= 4.0: unlock("a30")  # роскошь авто (4.0), не иномарка (3.0)

# Вызывается из Building.gd при выигрыше/проигрыше казино
func on_casino_result(won: bool) -> void:
	if won:
		unlock("a18")
		_casino_streak += 1
		if _casino_streak >= 5: unlock("a19")
	else:
		_casino_streak = 0

# Вызывается из GameManager при полицейской проверке
func on_police_check() -> void:
	unlock("a22")

func save(cfg: ConfigFile) -> void:
	cfg.set_value("achievements", "unlocked",      unlocked_ids)
	cfg.set_value("achievements", "tax_count",     _tax_count)
	cfg.set_value("achievements", "casino_streak", _casino_streak)

func load(cfg: ConfigFile) -> void:
	unlocked_ids    = cfg.get_value("achievements", "unlocked",      [])
	_tax_count      = cfg.get_value("achievements", "tax_count",     0)
	_casino_streak  = cfg.get_value("achievements", "casino_streak", 0)
