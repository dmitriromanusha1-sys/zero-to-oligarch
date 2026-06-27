extends Node
# Жизнь и династия. Личное измерение поверх экономики: возраст, этапы жизни,
# счастье и настроение. Фаза 1 — фундамент (на нём строятся отношения, семья,
# старение и наследие в следующих фазах).

signal life_changed

var birth_age: int = 18            # возраст на старте игры
var happiness: float = 60.0        # 0..100 — общий уровень счастья

# Этапы жизни по возрасту.
const STAGES: Array = [
	{"min":0,  "name":"Юность",   "icon":"🌱"},
	{"min":30, "name":"Расцвет",  "icon":"🔥"},
	{"min":45, "name":"Зрелость", "icon":"🏛"},
	{"min":60, "name":"Седина",   "icon":"🍂"},
	{"min":75, "name":"Старость", "icon":"⏳"},
]

const HAPPINESS_DRIFT: float = 0.05

# ── Тело, форма и внешность (Фаза 2) ──────────────────────────────────────────
var fitness: float = 50.0          # физическая форма 0..100
var style: float = 50.0            # уход за собой / стиль 0..100
var _last_workout_day: int = -99
var _last_groom_day: int = -99

const FITNESS_DECAY: float = 0.3   # форма уходит без тренировок
const STYLE_DECAY: float = 0.2
const WORKOUT_BASE_COST: int = 1500
const WORKOUT_FITNESS: float = 8.0
const WORKOUT_HEALTH: float = 4.0
const WORKOUT_HAPPY: float = 2.0
const GROOM_BASE_COST: int = 4000
const GROOM_STYLE: float = 10.0
const GROOM_HAPPY: float = 1.5

# ── Друзья и круг общения (Фаза 11) ───────────────────────────────────────────
var friends: Array = []   # {name, level, since_day}
var _last_hangout_day: int = -99
const MAX_FRIENDS: int = 8
const FRIEND_MEET_COST: int = 4000
const HANGOUT_COST: int = 6000
const HANGOUT_LEVEL: float = 5.0
const HANGOUT_HAPPY: float = 2.0
const FRIEND_DECAY: float = 0.3
const FRIEND_NAMES: Array = [
	"Олег", "Дима", "Костя", "Паша", "Юля", "Катя", "Настя", "Боря",
	"Слава", "Гена", "Инна", "Жора", "Лера", "Стас", "Аня", "Витя",
]

# ── Личная репутация и статус (Фаза 12) ───────────────────────────────────────
# Положение в обществе как личности (не путать с деловой/криминальной репутацией).
var social_rep: float = 40.0
var _last_social_day: int = -99
const SOCIAL_DRIFT: float = 0.05
const SOCIAL_OUTING_COST: int = 50000
const SOCIAL_OUTING_REP: float = 6.0

# ── Хобби и увлечения (Фаза 13) ───────────────────────────────────────────────
# Хобби берутся один раз и дают пассивное счастье, а некоторые — рост навыка.
var hobbies: Array = []   # список id освоенных хобби
const HOBBIES: Array = [
	{"id":"reading", "name":"Чтение",     "icon":"📚", "cost":50_000,  "happy":3.0, "stat":"intellect", "gain":0.05, "upkeep":0,    "desc":"Книги расширяют кругозор."},
	{"id":"music",   "name":"Музыка",     "icon":"🎸", "cost":200_000, "happy":4.0, "stat":"charisma",  "gain":0.05, "upkeep":0,    "desc":"Игра на инструменте."},
	{"id":"sport",   "name":"Спорт",      "icon":"🏃", "cost":80_000,  "happy":3.0, "stat":"fitness",   "gain":0.15, "upkeep":0,    "desc":"Любительский спорт поддерживает форму."},
	{"id":"cooking", "name":"Кулинария",  "icon":"🍳", "cost":60_000,  "happy":3.0, "stat":"",          "gain":0.0,  "upkeep":0,    "desc":"Готовить — это медитация."},
	{"id":"art",     "name":"Живопись",   "icon":"🎨", "cost":150_000, "happy":4.0, "stat":"",          "gain":0.0,  "upkeep":0,    "desc":"Творчество успокаивает."},
	{"id":"travel",  "name":"Путешествия","icon":"✈", "cost":500_000, "happy":7.0, "stat":"",          "gain":0.0,  "upkeep":5000, "desc":"Новые страны — новые впечатления."},
]

# ── Образ жизни, роскошь и коллекции (Фаза 14) ────────────────────────────────
# Предметы статуса: поднимают положение в обществе и счастье, входят в капитал.
var luxuries: Array = []   # список id купленных предметов роскоши
const LUXURIES: Array = [
	{"id":"watch",   "name":"Швейцарские часы",     "icon":"⌚", "cost":2_000_000,   "prestige":5.0,  "happy":3.0,  "value":1_500_000,   "min_title":4, "desc":"Часы, которые говорят за вас."},
	{"id":"jewelry", "name":"Ювелирные украшения",  "icon":"💍", "cost":5_000_000,   "prestige":6.0,  "happy":3.0,  "value":3_500_000,   "min_title":4, "desc":"Блеск, заметный издалека."},
	{"id":"wine",    "name":"Винная коллекция",     "icon":"🍷", "cost":10_000_000,  "prestige":7.0,  "happy":4.0,  "value":7_000_000,   "min_title":5, "desc":"Погреб редких вин."},
	{"id":"art",     "name":"Коллекция искусства",  "icon":"🖼", "cost":20_000_000,  "prestige":10.0, "happy":5.0,  "value":16_000_000,  "min_title":5, "desc":"Полотна мастеров."},
	{"id":"cars",    "name":"Гараж суперкаров",     "icon":"🏎", "cost":50_000_000,  "prestige":12.0, "happy":6.0,  "value":35_000_000,  "min_title":6, "desc":"Коллекция редких авто."},
	{"id":"yacht",   "name":"Яхта",                 "icon":"⛵", "cost":200_000_000, "prestige":18.0, "happy":8.0,  "value":140_000_000, "min_title":7, "desc":"Личная яхта — символ свободы."},
	{"id":"jet",     "name":"Частный джет",         "icon":"🛩", "cost":500_000_000, "prestige":25.0, "happy":10.0, "value":350_000_000, "min_title":8, "desc":"Весь мир за несколько часов."},
]

# ── Пороки и зависимости (Фаза 15) ────────────────────────────────────────────
# Соблазны дают всплеск счастья, но растят зависимость (вред здоровью/деньгам и
# подрыв базового счастья). Сила воли сопротивляется, лечение сбивает зависимость.
var vices: Dictionary = {}   # id -> уровень зависимости 0..100
const VICE_RECOVER: float = 0.8     # естественное восстановление в день
const REHAB_COST: int = 200_000
const REHAB_AMOUNT: float = 40.0
const VICES: Array = [
	{"id":"alcohol",  "name":"Алкоголь",       "icon":"🍷", "happy":5.0, "addict":7.0, "cost":3000,  "harm_health":0.020, "harm_money":0.0,    "desc":"Расслабляет, но затягивает."},
	{"id":"smoking",  "name":"Курение",        "icon":"🚬", "happy":3.0, "addict":8.0, "cost":1000,  "harm_health":0.030, "harm_money":0.0,    "desc":"Минутное удовольствие, долгий вред."},
	{"id":"gambling", "name":"Азартные игры",  "icon":"🎰", "happy":6.0, "addict":9.0, "cost":50000, "harm_health":0.0,   "harm_money":0.0030, "desc":"Адреналин и пустые карманы."},
	{"id":"parties",  "name":"Вечеринки",      "icon":"🎉", "happy":6.0, "addict":5.0, "cost":80000, "harm_health":0.010, "harm_money":0.0010, "desc":"Веселье до утра."},
]

# ── Ментальное здоровье и выгорание (Фаза 16) ─────────────────────────────────
var stress: float = 20.0   # 0..100; высокий = выгорание
var _last_therapy_day: int = -99
const WORK_STRESS: float = 1.0           # стресс за смену
const STRESS_RECOVER_BASE: float = 1.2
const THERAPY_COST: int = 100_000
const THERAPY_RELIEF: float = 25.0
const BURNOUT_THRESHOLD: float = 90.0

# ── Болезни и медицина (Фаза 18) ──────────────────────────────────────────────
var illnesses: Array = []   # активные id болезней
var medical_tier: int = 0
const ILLNESSES: Array = [
	{"id":"flu",          "name":"Грипп",            "drain":1.5, "happy":3.0, "cure":50_000,    "min_age":0},
	{"id":"injury",       "name":"Травма",           "drain":2.0, "happy":4.0, "cure":150_000,   "min_age":0},
	{"id":"hypertension", "name":"Гипертония",       "drain":1.0, "happy":2.0, "cure":300_000,   "min_age":45},
	{"id":"diabetes",     "name":"Диабет",           "drain":1.2, "happy":3.0, "cure":800_000,   "min_age":50},
	{"id":"heart",        "name":"Болезнь сердца",   "drain":2.5, "happy":5.0, "cure":3_000_000, "min_age":55},
]
const MEDICAL_TIERS: Array = [
	{"name":"Базовая медицина",      "install":0,          "upkeep":0,         "longevity":0,  "illness_mult":1.0},
	{"name":"Семейный врач",         "install":1_000_000,  "upkeep":50_000,    "longevity":2,  "illness_mult":0.7},
	{"name":"Частная клиника",       "install":10_000_000, "upkeep":300_000,   "longevity":5,  "illness_mult":0.5},
	{"name":"Программа долголетия",   "install":100_000_000,"upkeep":2_000_000, "longevity":10, "illness_mult":0.3},
]

# ── Завещание и наследство (Фаза 19) ──────────────────────────────────────────
var heir_index: int = -1       # выбранный наследник среди детей (-1 = авто)
var estate_planning: int = 0   # уровень планирования наследства
var generation: int = 1        # поколение династии (Фаза 20)
const MAX_AGE: int = 110
const ESTATE_PLANS: Array = [
	{"name":"Без завещания",      "install":0,           "tax":0.40},
	{"name":"Завещание",          "install":1_000_000,   "tax":0.30},
	{"name":"Семейный траст",     "install":20_000_000,  "tax":0.15},
	{"name":"Офшорная структура", "install":100_000_000, "tax":0.05},
]

# ── Личные навыки (Фаза 3) ────────────────────────────────────────────────────
const SKILLS: Array = [
	{"id":"intellect", "name":"Интеллект", "icon":"🧠", "action":"Учиться / читать",       "desc":"Выше доход от работы."},
	{"id":"charisma",  "name":"Харизма",   "icon":"😎", "action":"Нетворкинг / тренинг",   "desc":"Помогает в отношениях и обществе."},
	{"id":"willpower", "name":"Сила воли", "icon":"🧘", "action":"Медитация / дисциплина", "desc":"Дисциплина: форма и стиль уходят медленнее."},
]
var skills: Dictionary = {"intellect": 30.0, "charisma": 30.0, "willpower": 30.0}
var _last_dev_day: int = -99
const DEV_BASE_COST: int = 3000

# ── Знакомства и свидания (Фаза 4) ────────────────────────────────────────────
var partner: Dictionary = {}       # текущий партнёр (пусто = одинок) — развивается в фазе 5
var prospect: Dictionary = {}      # с кем сейчас встречаешься {name, interest}
var _last_date_day: int = -99

const MEET_COST: int = 3000
const DATE_COST: int = 5000
const COUPLE_THRESHOLD: float = 70.0   # симпатия, при которой можно сойтись

# ── Отношения с партнёром (Фаза 5) ────────────────────────────────────────────
var _last_pdate_day: int = -99
var _last_gift_day: int = -99
const RELATIONSHIP_DECAY: float = 0.4   # отношения остывают без внимания
const PARTNER_DATE_COST: int = 8000
const PARTNER_DATE_REL: float = 6.0
const GIFT_COST: int = 30000
const GIFT_REL: float = 12.0

# ── Брак и свадьба (Фаза 6) ───────────────────────────────────────────────────
const MARRY_THRESHOLD: float = 65.0     # отношения для предложения
const WEDDING_BASE: int = 500_000
const PRENUP_BASE: int = 200_000
const MARRY_REL_BONUS: float = 10.0
const DIVORCE_FRAC: float = 0.30        # раздел без брачного договора
const DIVORCE_FRAC_PRENUP: float = 0.05

# ── Дети (Фаза 7) ─────────────────────────────────────────────────────────────
var children: Array = []   # {name, born_day, gender}
const MAX_CHILDREN: int = 5
const CHILD_INIT_COST: int = 100_000     # подготовка к рождению
const CHILD_COST_DAY: int = 800          # ежедневное содержание (база)
const CHILD_JOY: float = 4.0
const CHILD_NAMES_M: Array = ["Артём", "Максим", "Лев", "Марк", "Тимур", "Глеб", "Илья", "Роман"]
const CHILD_NAMES_F: Array = ["Алиса", "Вера", "Майя", "София", "Ника", "Ева", "Рита", "Лана"]

# ── Воспитание (Фаза 8) ───────────────────────────────────────────────────────
var _last_family_day: int = -99
var _last_develop_day: int = -99
const FAMILY_TIME_BOND: float = 6.0
const FAMILY_TIME_HAPPY: float = 2.0
const DEVELOP_COST: int = 20000
const DEVELOP_UPBRINGING: float = 8.0
const BOND_DECAY: float = 0.5

# ── Образование детей (Фаза 9) ────────────────────────────────────────────────
# Ступени обучения по возрасту: каждая стоит денег и повышает образование ребёнка.
const EDU_STAGES: Array = [
	{"name":"Частная школа",        "min_age":7,  "cost":500_000,    "edu":25},
	{"name":"Престижный вуз",       "min_age":17, "cost":3_000_000,  "edu":35},
	{"name":"Зарубежная стажировка","min_age":20, "cost":10_000_000, "edu":40},
]

# ── Семейные события (Фаза 10) ────────────────────────────────────────────────
const FAMILY_EVENT_CHANCE: float = 0.04   # шанс семейного события в день
const FAMILY_EVENTS: Array = [
	{"id":"anniversary",  "need":"partner",  "text":"💐 Годовщина отношений — тёплый вечер вдвоём.", "happy":4,  "rel":5},
	{"id":"family_trip",  "need":"partner",  "text":"🏖 Семейная поездка подняла всем настроение.",   "happy":6,  "rel":4,  "bond":4, "money_pct":-0.005},
	{"id":"quarrel",      "need":"partner",  "text":"😠 Бытовая ссора подпортила настроение.",         "happy":-3, "rel":-6},
	{"id":"in_laws",      "need":"partner",  "text":"👵 Визит родни немного вымотал.",                  "happy":-2},
	{"id":"gift_money",   "need":"partner",  "text":"🎁 Родственники подарили деньги.",                 "happy":2,  "money":300000},
	{"id":"kid_award",    "need":"children", "text":"🏅 Ваш ребёнок получил награду — вы горды!",        "happy":5,  "upbringing":4},
	{"id":"kid_milestone","need":"children", "text":"🎉 Ребёнок сделал большие успехи.",                "happy":4,  "bond":3},
	{"id":"kid_sick",     "need":"children", "text":"🤒 Ребёнок заболел — расходы на лечение.",          "happy":-4, "money_pct":-0.01},
	{"id":"school_event", "need":"children", "text":"🎭 Школьный праздник — приятные хлопоты.",          "happy":3,  "bond":2, "money_pct":-0.002},
]
const DATING_NAMES: Array = [
	"Алиса", "Марк", "София", "Артём", "Ника", "Даниил", "Вера", "Кирилл",
	"Лана", "Егор", "Майя", "Тимур", "Ева", "Лёва", "Рита", "Глеб",
]

var gm: Node

func _ready() -> void:
	gm = get_node("/root/GameManager")

# ── Возраст и этапы жизни ──────────────────────────────────────────────────────
func age() -> int:
	return birth_age + int(gm.day / 365.0)

func days_into_year() -> int:
	return gm.day % 365

func days_to_birthday() -> int:
	return 365 - days_into_year()

func life_stage() -> Dictionary:
	var s: Dictionary = STAGES[0]
	for st in STAGES:
		if age() >= int(st.min): s = st
	return s

# ── Старение (Фаза 17) ────────────────────────────────────────────────────────
# Чем старше — тем быстрее уходит форма и тяжелее организму.
func aging_factor() -> float:
	var a: int = age()
	if a <= 40: return 1.0
	return 1.0 + (a - 40) * 0.03   # +3% к деградации формы за год после 40

func is_elderly() -> bool:
	return age() >= 60

# Ожидаемая продолжительность жизни: база ± форма/здоровье/пороки (+ медицина в ф.18).
func life_expectancy() -> float:
	var base: float = 78.0
	base += (fitness - 50.0) * 0.10
	base += (gm.health - 50.0) * 0.10
	base -= avg_addiction() * 0.15
	base += longevity_bonus()
	return clampf(base, 55.0, 110.0)

# Бонус долголетия от медицины (см. фазу 18).
func longevity_bonus() -> float:
	return float(MEDICAL_TIERS[medical_tier].get("longevity", 0))

func years_left() -> int:
	return maxi(0, int(round(life_expectancy())) - age())

# ── Счастье / настроение ──────────────────────────────────────────────────────
func add_happiness(amount: float) -> void:
	happiness = clampf(happiness + amount, 0.0, 100.0)
	emit_signal("life_changed")

# Целевой уровень счастья, к которому дрейфует настроение.
func happiness_baseline() -> float:
	var b: float = 40.0
	b += gm.current_title_index * 3.0          # статус/достаток радует
	b += (gm.health - 50.0) * 0.2              # здоровье ±
	b += (fitness - 50.0) * 0.10               # спорт радует
	b += (appearance() - 50.0) * 0.06          # хорошо выглядеть приятно
	b += (skill("charisma") - 50.0) * 0.05     # социальная уверенность
	if not partner.is_empty():
		var f: float = 25.0 if is_married() else 18.0
		b += relationship() / 100.0 * f        # крепкие отношения/брак делают счастливее
	# Радость от детей зависит от близости (связи): близкая семья — счастливее
	var joy: float = 0.0
	for ch in children:
		joy += float(ch.get("bond", 50.0)) / 100.0 * CHILD_JOY
	b += minf(joy, 18.0)
	b += minf(friend_count() * 1.0 + close_friends() * 2.0, 14.0)  # круг общения
	b += (social_rep - 40.0) * 0.08                                # уважение в обществе
	b += minf(hobby_happiness(), 16.0)                             # любимые занятия
	b += minf(luxury_happiness(), 12.0)                            # роскошь и комфорт
	b -= avg_addiction() * 0.12                                    # зависимости подтачивают
	b -= stress * 0.12                                             # стресс/выгорание
	b -= illness_happy_penalty()                                  # болезни угнетают
	return clampf(b, 5.0, 100.0)

# ── Ментальное здоровье и выгорание ───────────────────────────────────────────
func add_stress(amount: float) -> void:
	stress = clampf(stress + amount, 0.0, 100.0)

func on_worked() -> void:
	add_stress(WORK_STRESS)

func mental_label() -> String:
	if stress >= BURNOUT_THRESHOLD: return "На грани выгорания"
	if stress >= 65.0: return "Сильный стресс"
	if stress >= 40.0: return "Напряжён"
	if stress >= 20.0: return "В тонусе"
	return "Спокоен"

func mental_color() -> Color:
	if stress >= 65.0: return Color(0.95, 0.5, 0.45)
	if stress >= 40.0: return Color(0.9, 0.8, 0.45)
	return Color(0.55, 0.85, 0.65)

func therapy_cost() -> int:
	return gm.shop_price(THERAPY_COST)

func can_therapy() -> bool:
	return gm.day > _last_therapy_day and gm.money >= float(therapy_cost())

# Сеанс терапии: заметно снижает стресс.
func therapy() -> bool:
	if not can_therapy(): return false
	if not gm.spend_money(therapy_cost()): return false
	stress = maxf(0.0, stress - THERAPY_RELIEF)
	add_happiness(2.0)
	_last_therapy_day = gm.day
	emit_signal("life_changed")
	gm.save_game()
	return true

# Ежедневно: восстановление (хобби и сила воли помогают), пороки добавляют стресс,
# при пике — риск выгорания.
func _stress_tick() -> void:
	stress = clampf(stress + avg_addiction() * 0.02, 0.0, 100.0)
	var recover: float = STRESS_RECOVER_BASE * (1.0 + hobbies.size() * 0.20 + skill("willpower") / 200.0)
	stress = clampf(stress - recover, 0.0, 100.0)
	if stress >= BURNOUT_THRESHOLD and randf() < 0.10:
		stress = maxf(0.0, stress - 40.0)
		add_happiness(-15.0)
		gm.health = maxf(0.0, gm.health - 10.0)
		var es := get_node_or_null("/root/EventSystem")
		if es:
			es.event_triggered.emit({
				"text": "🧠 Выгорание! Вы сорвались от перегрузки — нужен отдых.",
				"money": 0, "health": -10})

# ── Болезни и медицина ────────────────────────────────────────────────────────
func _illness(id: String) -> Dictionary:
	for d in ILLNESSES:
		if d.id == id: return d
	return {}

func has_illness(id: String) -> bool:
	return id in illnesses

func illness_happy_penalty() -> float:
	var t: float = 0.0
	for id in illnesses:
		t += float(_illness(id).get("happy", 0.0))
	return t

func medical_illness_mult() -> float:
	return float(MEDICAL_TIERS[medical_tier].get("illness_mult", 1.0))

# Риск заболеть в день: возраст, форма, пороки, стресс; медицина снижает.
func illness_risk() -> float:
	var r: float = 0.004
	r += maxf(0.0, age() - 40) * 0.0004
	r += maxf(0.0, 50.0 - fitness) * 0.0001
	r += avg_addiction() * 0.0002
	r += stress * 0.0001
	r *= medical_illness_mult()
	return clampf(r, 0.0, 0.25)

func cure_cost(id: String) -> int:
	return gm.shop_price(int(_illness(id).get("cure", 0)))

func can_cure(id: String) -> bool:
	return has_illness(id) and gm.money >= float(cure_cost(id))

func cure(id: String) -> bool:
	if not can_cure(id): return false
	if not gm.spend_money(cure_cost(id)): return false
	illnesses.erase(id)
	add_happiness(2.0)
	emit_signal("life_changed")
	gm.save_game()
	return true

func medical_next_cost() -> int:
	if medical_tier + 1 >= MEDICAL_TIERS.size(): return 0
	return int(MEDICAL_TIERS[medical_tier + 1].install)

func can_upgrade_medical() -> bool:
	return medical_tier + 1 < MEDICAL_TIERS.size() and gm.money >= float(medical_next_cost())

func upgrade_medical() -> bool:
	if not can_upgrade_medical(): return false
	if not gm.spend_money(medical_next_cost()): return false
	medical_tier += 1
	emit_signal("life_changed")
	gm.save_game()
	return true

func medical_monthly() -> float:
	return float(gm.shop_price(int(MEDICAL_TIERS[medical_tier].get("upkeep", 0))))

func _illness_tick() -> void:
	# Урон от активных болезней
	for id in illnesses:
		gm.health = maxf(0.0, gm.health - float(_illness(id).get("drain", 0.0)))
	# Новая болезнь
	if illnesses.size() < 3 and randf() < illness_risk():
		var pool: Array = []
		for d in ILLNESSES:
			if age() >= int(d.min_age) and not has_illness(String(d.id)):
				pool.append(d)
		if not pool.is_empty():
			var d: Dictionary = pool[randi() % pool.size()]
			illnesses.append(String(d.id))
			var es := get_node_or_null("/root/EventSystem")
			if es:
				es.event_triggered.emit({
					"text": "🤒 У вас обнаружили: %s. Нужно лечение." % d.get("name", "болезнь"),
					"money": 0, "health": 0})

# ── Завещание и наследство ────────────────────────────────────────────────────
# Качество наследника: воспитание + образование + связь (плюс капля навыков семьи).
func heir_quality(index: int) -> float:
	if index < 0 or index >= children.size(): return 0.0
	var q: float = child_upbringing(index) * 0.35 + child_education(index) * 0.45 + child_bond(index) * 0.20
	return clampf(q, 0.0, 100.0)

func best_heir_index() -> int:
	var best: int = -1
	var bq: float = -1.0
	for i in range(children.size()):
		var q: float = heir_quality(i)
		if q > bq:
			bq = q; best = i
	return best

# Действующий наследник: выбранный вручную либо лучший по качеству.
func effective_heir_index() -> int:
	if heir_index >= 0 and heir_index < children.size(): return heir_index
	return best_heir_index()

func has_heir() -> bool:
	return effective_heir_index() >= 0

func set_heir(index: int) -> bool:
	if index < 0 or index >= children.size(): return false
	heir_index = index
	emit_signal("life_changed")
	gm.save_game()
	return true

func inheritance_tax_rate() -> float:
	return float(ESTATE_PLANS[estate_planning].get("tax", 0.40))

func estate_value() -> float:
	return gm.get_net_worth()

func heir_inheritance() -> float:
	return estate_value() * (1.0 - inheritance_tax_rate())

func estate_next_cost() -> int:
	if estate_planning + 1 >= ESTATE_PLANS.size(): return 0
	return int(ESTATE_PLANS[estate_planning + 1].install)

func can_upgrade_estate() -> bool:
	return estate_planning + 1 < ESTATE_PLANS.size() and gm.money >= float(estate_next_cost())

func upgrade_estate() -> bool:
	if not can_upgrade_estate(): return false
	if not gm.spend_money(estate_next_cost()): return false
	estate_planning += 1
	emit_signal("life_changed")
	gm.save_game()
	return true

# ── Смертность и смена поколения (Фаза 20) ────────────────────────────────────
# Риск смерти растёт у предела жизни; при пике возраста — гарантированно.
func mortality_risk() -> float:
	if age() >= MAX_AGE: return 1.0
	var over: float = float(age()) - life_expectancy()
	var r: float = 0.0
	if over > -6.0:
		r = clampf((over + 6.0) * 0.012, 0.0, 0.6)
	if gm.health <= 8.0 and age() > 50:
		r += 0.05
	return clampf(r, 0.0, 1.0)

# Наследник перенимает эстафету: молодой, со стартовыми качествами от воспитания.
func _become_heir(quality: float, heir_name: String) -> void:
	var young: int = 20
	birth_age = young - int(gm.day / 365.0)   # чтобы age() == young
	happiness = 60.0
	stress = 20.0
	fitness = 55.0
	style = 55.0
	social_rep = clampf(30.0 + quality * 0.20, 0.0, 100.0)
	skills = {
		"intellect": maxf(20.0, quality * 0.6),
		"charisma":  maxf(20.0, quality * 0.5),
		"willpower": maxf(20.0, quality * 0.5),
	}
	# Личная жизнь наследника — с чистого листа (империя и активы остаются)
	partner = {}; prospect = {}; children = []; friends = []
	vices = {}; illnesses = []; hobbies = []
	heir_index = -1
	_last_workout_day = -99; _last_groom_day = -99; _last_dev_day = -99
	_last_date_day = -99; _last_pdate_day = -99; _last_gift_day = -99
	_last_hangout_day = -99; _last_social_day = -99
	_last_family_day = -99; _last_develop_day = -99; _last_therapy_day = -99

func die() -> void:
	var heir_i: int = effective_heir_index()
	var heir_name: String = String(children[heir_i].get("name", "?")) if heir_i >= 0 else "дальний родственник"
	var hq: float = heir_quality(heir_i) if heir_i >= 0 else 20.0
	# Налог на наследство списывается с наличных (структуры снижают его)
	gm.money = gm.money * (1.0 - inheritance_tax_rate())
	gm.emit_signal("money_changed", gm.money)
	generation += 1
	_become_heir(hq, heir_name)
	var es := get_node_or_null("/root/EventSystem")
	if es:
		es.event_triggered.emit({
			"text": "☠ Глава династии ушёл из жизни. Эстафету принимает %s — поколение %d. Империя продолжается." % [heir_name, generation],
			"money": 0, "health": 0})
	gm.health = 100.0
	gm.emit_signal("health_changed", gm.health)
	emit_signal("life_changed")
	gm.save_game()

# ── Пороки и зависимости ──────────────────────────────────────────────────────
func _vice(id: String) -> Dictionary:
	for v in VICES:
		if v.id == id: return v
	return {}

func vice_addiction(id: String) -> float:
	return float(vices.get(id, 0.0))

func avg_addiction() -> float:
	var t: float = 0.0
	for v in VICES:
		t += vice_addiction(v.id)
	return t / float(VICES.size())

func vice_cost(id: String) -> int:
	return gm.shop_price(int(_vice(id).get("cost", 0)))

func can_indulge(id: String) -> bool:
	return not _vice(id).is_empty() and gm.money >= float(vice_cost(id))

# Поддаться пороку: всплеск счастья, но рост зависимости (сила воли тормозит).
func indulge(id: String) -> bool:
	var v := _vice(id)
	if v.is_empty(): return false
	if not gm.spend_money(vice_cost(id)): return false
	add_happiness(float(v.happy))
	var resist: float = 1.0 - skill("willpower") * 0.004   # до −40% роста зависимости
	vices[id] = clampf(vice_addiction(id) + float(v.addict) * resist, 0.0, 100.0)
	emit_signal("life_changed")
	gm.save_game()
	return true

func rehab_cost() -> int:
	return gm.shop_price(REHAB_COST)

func can_rehab(id: String) -> bool:
	return vice_addiction(id) > 0.0 and gm.money >= float(rehab_cost())

# Лечение: резко сбивает зависимость.
func rehab(id: String) -> bool:
	if not can_rehab(id): return false
	if not gm.spend_money(rehab_cost()): return false
	vices[id] = maxf(0.0, vice_addiction(id) - REHAB_AMOUNT)
	emit_signal("life_changed")
	gm.save_game()
	return true

# Ежедневно: вред от зависимостей и естественное восстановление (с силой воли).
func _vice_tick() -> void:
	var recover: float = VICE_RECOVER * (1.0 + skill("willpower") / 100.0)
	for v in VICES:
		var id: String = String(v.id)
		var a: float = vice_addiction(id)
		if a <= 0.0: continue
		var hh: float = float(v.get("harm_health", 0.0))
		if hh > 0.0:
			gm.health = maxf(0.0, gm.health - a * hh)
		var hm: float = float(v.get("harm_money", 0.0))
		if hm > 0.0:
			gm.add_money(-(gm.money * a / 100.0 * hm))
		vices[id] = maxf(0.0, a - recover)

# ── Хобби ─────────────────────────────────────────────────────────────────────
func _hobby(id: String) -> Dictionary:
	for h in HOBBIES:
		if h.id == id: return h
	return {}

func has_hobby(id: String) -> bool:
	return id in hobbies

func can_take_hobby(id: String) -> bool:
	var h := _hobby(id)
	return not h.is_empty() and not has_hobby(id) and gm.money >= float(gm.shop_price(int(h.cost)))

func take_hobby(id: String) -> bool:
	var h := _hobby(id)
	if h.is_empty() or has_hobby(id): return false
	if not gm.spend_money(gm.shop_price(int(h.cost))): return false
	hobbies.append(id)
	add_happiness(3.0)
	emit_signal("life_changed")
	gm.save_game()
	return true

func hobby_happiness() -> float:
	var t: float = 0.0
	for id in hobbies:
		t += float(_hobby(id).get("happy", 0.0))
	return t

func hobby_upkeep() -> float:
	var t: float = 0.0
	for id in hobbies:
		t += float(gm.shop_price(int(_hobby(id).get("upkeep", 0))))
	return t

func _hobby_tick() -> void:
	for id in hobbies:
		var h := _hobby(id)
		var st: String = String(h.get("stat", ""))
		var gain: float = float(h.get("gain", 0.0))
		if gain <= 0.0: continue
		if skills.has(st):
			skills[st] = clampf(float(skills[st]) + gain, 0.0, 100.0)
		elif st == "fitness":
			fitness = clampf(fitness + gain, 0.0, 100.0)
	var up: float = hobby_upkeep()
	if up > 0.0:
		gm.add_money(-up)

# ── Роскошь и коллекции ───────────────────────────────────────────────────────
func _luxury(id: String) -> Dictionary:
	for l in LUXURIES:
		if l.id == id: return l
	return {}

func owns_luxury(id: String) -> bool:
	return id in luxuries

func can_buy_luxury(id: String) -> bool:
	var l := _luxury(id)
	if l.is_empty() or owns_luxury(id): return false
	return gm.current_title_index >= int(l.min_title) and gm.money >= float(l.cost)

func buy_luxury(id: String) -> bool:
	var l := _luxury(id)
	if l.is_empty() or owns_luxury(id): return false
	if gm.current_title_index < int(l.min_title): return false
	if not gm.spend_money(int(l.cost)): return false
	luxuries.append(id)
	add_happiness(4.0)
	emit_signal("life_changed")
	gm.save_game()
	return true

func luxury_prestige() -> float:
	var t: float = 0.0
	for id in luxuries:
		t += float(_luxury(id).get("prestige", 0.0))
	return t

func luxury_happiness() -> float:
	var t: float = 0.0
	for id in luxuries:
		t += float(_luxury(id).get("happy", 0.0))
	return t

# Стоимость коллекций — входит в чистый капитал (net worth).
func collectibles_value() -> float:
	var t: float = 0.0
	for id in luxuries:
		t += float(_luxury(id).get("value", 0.0))
	return t

# ── Личная репутация и статус ─────────────────────────────────────────────────
func social_baseline() -> float:
	var b: float = 20.0
	b += appearance() * 0.15
	b += skill("charisma") * 0.15
	b += close_friends() * 4.0
	b += gm.current_title_index * 2.5
	if is_married(): b += 5.0
	b += minf(child_count() * 2.0, 8.0)
	b += luxury_prestige()                  # предметы статуса
	return clampf(b, 0.0, 100.0)

func social_status_label() -> String:
	if social_rep >= 85.0: return "Звезда общества"
	if social_rep >= 65.0: return "Уважаемая персона"
	if social_rep >= 45.0: return "Известный человек"
	if social_rep >= 25.0: return "В узких кругах"
	return "Незаметный"

func social_outing_cost() -> int:
	return gm.shop_price(SOCIAL_OUTING_COST)

func can_social_outing() -> bool:
	return gm.day > _last_social_day and gm.money >= float(social_outing_cost())

# Светский выход: поднимает положение в обществе и настроение.
func social_outing() -> bool:
	if not can_social_outing(): return false
	if not gm.spend_money(social_outing_cost()): return false
	social_rep = clampf(social_rep + SOCIAL_OUTING_REP, 0.0, 100.0)
	add_happiness(2.5)
	_last_social_day = gm.day
	emit_signal("life_changed")
	gm.save_game()
	return true

func _social_rep_tick() -> void:
	social_rep = clampf(social_rep + (social_baseline() - social_rep) * SOCIAL_DRIFT, 0.0, 100.0)

# ── Друзья и круг общения ─────────────────────────────────────────────────────
func friend_count() -> int:
	return friends.size()

func close_friends() -> int:
	var n: int = 0
	for f in friends:
		if float(f.get("level", 0.0)) >= 60.0: n += 1
	return n

func avg_friend_level() -> float:
	if friends.is_empty(): return 0.0
	var t: float = 0.0
	for f in friends: t += float(f.get("level", 0.0))
	return t / float(friends.size())

func friend_meet_cost() -> int:
	return gm.shop_price(FRIEND_MEET_COST)

func can_make_friend() -> bool:
	return friend_count() < MAX_FRIENDS and gm.money >= float(friend_meet_cost())

func make_friend() -> bool:
	if not can_make_friend(): return false
	if not gm.spend_money(friend_meet_cost()): return false
	var nm: String = FRIEND_NAMES[randi() % FRIEND_NAMES.size()]
	var start: float = clampf(25.0 + skill("charisma") * 0.25 + randf_range(0.0, 15.0), 10.0, 70.0)
	friends.append({"name": nm, "level": start, "since_day": gm.day})
	add_happiness(2.0)
	emit_signal("life_changed")
	gm.save_game()
	return true

func hangout_cost() -> int:
	return gm.shop_price(HANGOUT_COST)

func can_hangout() -> bool:
	return friend_count() > 0 and gm.day > _last_hangout_day and gm.money >= float(hangout_cost())

# Встреча с друзьями: укрепляет все дружбы (харизма помогает) и радует.
func hangout() -> bool:
	if not can_hangout(): return false
	if not gm.spend_money(hangout_cost()): return false
	var gain: float = HANGOUT_LEVEL + skill("charisma") * 0.03
	for f in friends:
		f["level"] = clampf(float(f.get("level", 0.0)) + gain, 0.0, 100.0)
	add_happiness(HANGOUT_HAPPY)
	_last_hangout_day = gm.day
	emit_signal("life_changed")
	gm.save_game()
	return true

# Дружбы слабеют без общения; совсем заброшенные сходят на нет.
func _social_tick() -> void:
	var drifted: Array = []
	for i in range(friends.size()):
		friends[i]["level"] = float(friends[i].get("level", 0.0)) - FRIEND_DECAY
		if friends[i]["level"] <= 0.0:
			drifted.append(i)
	drifted.reverse()
	for i in drifted:
		friends.remove_at(i)

# ── Дети ──────────────────────────────────────────────────────────────────────
func child_count() -> int:
	return children.size()

func child_age(index: int) -> int:
	if index < 0 or index >= children.size(): return 0
	return int((gm.day - int(children[index].get("born_day", gm.day))) / 365.0)

func child_init_cost() -> int:
	return gm.shop_price(CHILD_INIT_COST)

func children_upkeep() -> float:
	return child_count() * float(gm.shop_price(CHILD_COST_DAY))

func can_have_child() -> bool:
	return not partner.is_empty() and child_count() < MAX_CHILDREN and gm.money >= float(child_init_cost())

func have_child() -> bool:
	if not can_have_child(): return false
	if not gm.spend_money(child_init_cost()): return false
	var girl: bool = randf() < 0.5
	var pool: Array = CHILD_NAMES_F if girl else CHILD_NAMES_M
	var nm: String = pool[randi() % pool.size()]
	children.append({"name": nm, "born_day": gm.day, "gender": ("f" if girl else "m"), "bond": 60.0, "upbringing": 0.0})
	add_happiness(8.0)
	var es := get_node_or_null("/root/EventSystem")
	if es:
		es.event_triggered.emit({
			"text": "👶 У вас родился%s %s!" % [("ась дочь" if girl else "ся сын"), nm],
			"money": 0, "health": 0})
	emit_signal("life_changed")
	gm.save_game()
	return true

# ── Воспитание ────────────────────────────────────────────────────────────────
func child_bond(index: int) -> float:
	if index < 0 or index >= children.size(): return 0.0
	return float(children[index].get("bond", 50.0))

func child_upbringing(index: int) -> float:
	if index < 0 or index >= children.size(): return 0.0
	return float(children[index].get("upbringing", 0.0))

func avg_child_bond() -> float:
	if children.is_empty(): return 0.0
	var t: float = 0.0
	for ch in children: t += float(ch.get("bond", 50.0))
	return t / float(children.size())

func avg_child_upbringing() -> float:
	if children.is_empty(): return 0.0
	var t: float = 0.0
	for ch in children: t += float(ch.get("upbringing", 0.0))
	return t / float(children.size())

func can_family_time() -> bool:
	return child_count() > 0 and gm.day > _last_family_day

# Время с семьёй: бесплатно, укрепляет связь и поднимает настроение.
func family_time() -> bool:
	if not can_family_time(): return false
	for ch in children:
		ch["bond"] = clampf(float(ch.get("bond", 50.0)) + FAMILY_TIME_BOND, 0.0, 100.0)
	add_happiness(FAMILY_TIME_HAPPY)
	_last_family_day = gm.day
	emit_signal("life_changed")
	gm.save_game()
	return true

func develop_cost() -> int:
	return gm.shop_price(DEVELOP_COST) * child_count()

func can_develop_children() -> bool:
	return child_count() > 0 and gm.day > _last_develop_day and gm.money >= float(develop_cost())

# Развивающие занятия: растят воспитание (пригодится наследнику).
func develop_children() -> bool:
	if not can_develop_children(): return false
	if not gm.spend_money(develop_cost()): return false
	for ch in children:
		ch["upbringing"] = clampf(float(ch.get("upbringing", 0.0)) + DEVELOP_UPBRINGING, 0.0, 100.0)
	_last_develop_day = gm.day
	emit_signal("life_changed")
	gm.save_game()
	return true

# Связь с детьми слабеет без внимания.
func _parenting_tick() -> void:
	for ch in children:
		ch["bond"] = clampf(float(ch.get("bond", 50.0)) - BOND_DECAY, 0.0, 100.0)

# ── Семейные события ──────────────────────────────────────────────────────────
func _apply_family_event(ev: Dictionary) -> void:
	if ev.has("happy"): add_happiness(float(ev.happy))
	if ev.has("rel") and not partner.is_empty(): add_relationship(float(ev.rel))
	if ev.has("bond"):
		for ch in children:
			ch["bond"] = clampf(float(ch.get("bond", 50.0)) + float(ev.bond), 0.0, 100.0)
	if ev.has("upbringing"):
		for ch in children:
			ch["upbringing"] = clampf(float(ch.get("upbringing", 0.0)) + float(ev.upbringing), 0.0, 100.0)
	var money_delta: float = float(ev.get("money", 0))
	if ev.has("money_pct"):
		money_delta += gm.money * float(ev.money_pct)
	money_delta = round(money_delta)
	if money_delta != 0.0:
		gm.add_money(money_delta)
	var txt: String = String(ev.text)
	if money_delta != 0.0:
		txt += " (%s)" % gm.format_money(money_delta)
	var es := get_node_or_null("/root/EventSystem")
	if es:
		es.event_triggered.emit({"text": txt, "money": 0, "health": 0})
	emit_signal("life_changed")

func _family_events_tick() -> void:
	if partner.is_empty() and children.is_empty(): return
	if randf() >= FAMILY_EVENT_CHANCE: return
	var pool: Array = []
	for ev in FAMILY_EVENTS:
		var need: String = String(ev.get("need", ""))
		if need == "partner" and partner.is_empty(): continue
		if need == "children" and children.is_empty(): continue
		pool.append(ev)
	if pool.is_empty(): return
	_apply_family_event(pool[randi() % pool.size()])

# ── Образование детей ─────────────────────────────────────────────────────────
func child_edu_stage(index: int) -> int:
	if index < 0 or index >= children.size(): return 0
	return int(children[index].get("edu_stage", 0))

func child_education(index: int) -> float:
	var total: float = 0.0
	var done: int = child_edu_stage(index)
	for s in range(mini(done, EDU_STAGES.size())):
		total += float(EDU_STAGES[s].edu)
	return total

func next_edu_stage(index: int) -> Dictionary:
	var st: int = child_edu_stage(index)
	if st < EDU_STAGES.size(): return EDU_STAGES[st]
	return {}

func edu_stage_cost(index: int) -> int:
	var ns := next_edu_stage(index)
	if ns.is_empty(): return 0
	return gm.shop_price(int(ns.cost))

func can_enroll_child(index: int) -> bool:
	var ns := next_edu_stage(index)
	if ns.is_empty(): return false
	return child_age(index) >= int(ns.min_age) and gm.money >= float(edu_stage_cost(index))

func enroll_child(index: int) -> bool:
	if not can_enroll_child(index): return false
	var ns := next_edu_stage(index)
	if not gm.spend_money(edu_stage_cost(index)): return false
	children[index]["edu_stage"] = child_edu_stage(index) + 1
	add_happiness(3.0)
	var es := get_node_or_null("/root/EventSystem")
	if es:
		es.event_triggered.emit({
			"text": "🎓 %s — ваш ребёнок поступил: «%s»." % [children[index].get("name", "?"), ns.get("name", "")],
			"money": 0, "health": 0})
	emit_signal("life_changed")
	gm.save_game()
	return true

# ── Личные навыки ─────────────────────────────────────────────────────────────
func skill(id: String) -> float:
	return float(skills.get(id, 0.0))

func dev_cost() -> int:
	return gm.shop_price(DEV_BASE_COST)

func can_train() -> bool:
	return gm.day > _last_dev_day and gm.money >= float(dev_cost())

func train_skill(id: String) -> bool:
	if not can_train() or not skills.has(id): return false
	if not gm.spend_money(dev_cost()): return false
	var cur: float = skill(id)
	var gain: float = (100.0 - cur) * 0.08 + 1.0   # медленнее у потолка
	skills[id] = clampf(cur + gain, 0.0, 100.0)
	add_happiness(0.5)
	_last_dev_day = gm.day
	emit_signal("life_changed")
	gm.save_game()
	return true

# Дисциплина (сила воли) замедляет деградацию формы и стиля.
func discipline_mult() -> float:
	return 1.0 - skill("willpower") / 100.0 * 0.5

# ── Знакомства и свидания ─────────────────────────────────────────────────────
func is_single() -> bool:
	return partner.is_empty()

func has_prospect() -> bool:
	return not prospect.is_empty()

# Привлекательность как партнёра: внешность + харизма + статус.
func dating_appeal() -> float:
	var status: float = minf(20.0, gm.current_title_index * 2.0)
	return clampf(appearance() * 0.35 + skill("charisma") * 0.35 + status + minf(social_rep * 0.15, 15.0), 0.0, 100.0)

func can_meet() -> bool:
	return is_single() and not has_prospect() and gm.money >= float(gm.shop_price(MEET_COST))

func meet_someone() -> bool:
	if not can_meet(): return false
	if not gm.spend_money(gm.shop_price(MEET_COST)): return false
	var nm: String = DATING_NAMES[randi() % DATING_NAMES.size()]
	var start: float = clampf(dating_appeal() * 0.4 + randf_range(0.0, 20.0), 5.0, 60.0)
	prospect = {"name": nm, "interest": start}
	emit_signal("life_changed")
	gm.save_game()
	return true

func can_date() -> bool:
	return has_prospect() and gm.day > _last_date_day and gm.money >= float(gm.shop_price(DATE_COST))

# Свидание: симпатия растёт (зависит от харизмы/внешности), но бывает и осечка.
func go_on_date() -> String:
	if not can_date(): return ""
	if not gm.spend_money(gm.shop_price(DATE_COST)): return ""
	_last_date_day = gm.day
	var gain: float = 8.0 + (dating_appeal() - 50.0) * 0.12 + randf_range(-4.0, 7.0)
	prospect["interest"] = clampf(float(prospect.get("interest", 0.0)) + gain, 0.0, 100.0)
	add_happiness(1.5)
	emit_signal("life_changed")
	gm.save_game()
	return "%+d симпатии" % int(round(gain))

func can_become_couple() -> bool:
	return has_prospect() and float(prospect.get("interest", 0.0)) >= COUPLE_THRESHOLD

func become_couple() -> bool:
	if not can_become_couple(): return false
	partner = {"name": String(prospect.get("name", "?")), "relationship": 50.0, "since_day": gm.day}
	prospect = {}
	add_happiness(8.0)
	var es := get_node_or_null("/root/EventSystem")
	if es:
		es.event_triggered.emit({
			"text": "❤ Теперь вы в отношениях с %s!" % partner.get("name", "?"),
			"money": 0, "health": 0})
	emit_signal("life_changed")
	gm.save_game()
	return true

func stop_seeing() -> void:
	prospect = {}
	emit_signal("life_changed")
	gm.save_game()

# ── Отношения с партнёром ─────────────────────────────────────────────────────
func relationship() -> float:
	return float(partner.get("relationship", 0.0))

func add_relationship(amount: float) -> void:
	if partner.is_empty(): return
	partner["relationship"] = clampf(relationship() + amount, 0.0, 100.0)

func relationship_label() -> String:
	var r: float = relationship()
	if r >= 85.0: return "Крепкие как никогда"
	if r >= 65.0: return "Гармония"
	if r >= 45.0: return "Стабильно"
	if r >= 25.0: return "Прохладно"
	return "На грани разрыва"

func can_partner_date() -> bool:
	return not partner.is_empty() and gm.day > _last_pdate_day and gm.money >= float(gm.shop_price(PARTNER_DATE_COST))

func partner_date() -> bool:
	if not can_partner_date(): return false
	if not gm.spend_money(gm.shop_price(PARTNER_DATE_COST)): return false
	add_relationship(PARTNER_DATE_REL)
	add_happiness(2.0)
	_last_pdate_day = gm.day
	emit_signal("life_changed")
	gm.save_game()
	return true

func can_gift() -> bool:
	return not partner.is_empty() and gm.day > _last_gift_day and gm.money >= float(gm.shop_price(GIFT_COST))

func give_gift() -> bool:
	if not can_gift(): return false
	if not gm.spend_money(gm.shop_price(GIFT_COST)): return false
	add_relationship(GIFT_REL)
	add_happiness(1.5)
	_last_gift_day = gm.day
	emit_signal("life_changed")
	gm.save_game()
	return true

func breakup() -> void:
	if partner.is_empty(): return
	var nm: String = String(partner.get("name", "?"))
	partner = {}
	add_happiness(-12.0)
	var es := get_node_or_null("/root/EventSystem")
	if es:
		es.event_triggered.emit({"text": "💔 Вы расстались с %s." % nm, "money": 0, "health": 0})
	emit_signal("life_changed")
	gm.save_game()

# ── Брак ──────────────────────────────────────────────────────────────────────
func is_married() -> bool:
	return not partner.is_empty() and bool(partner.get("married", false))

func has_prenup() -> bool:
	return bool(partner.get("prenup", false))

func wedding_cost() -> int:
	return int(gm.shop_price(WEDDING_BASE) * (1.0 + gm.current_title_index * 0.25))

func prenup_cost() -> int:
	return gm.shop_price(PRENUP_BASE)

func can_marry() -> bool:
	return not partner.is_empty() and not is_married() and relationship() >= MARRY_THRESHOLD

func marry(with_prenup: bool) -> bool:
	if not can_marry(): return false
	var cost: int = wedding_cost() + (prenup_cost() if with_prenup else 0)
	if gm.money < float(cost): return false
	if not gm.spend_money(cost): return false
	partner["married"] = true
	partner["prenup"] = with_prenup
	partner["wedding_day"] = gm.day
	add_relationship(MARRY_REL_BONUS)
	add_happiness(15.0)
	var es := get_node_or_null("/root/EventSystem")
	if es:
		es.event_triggered.emit({
			"text": "💍 Свадьба! Вы теперь в браке с %s.%s" % [partner.get("name", "?"),
				(" Брачный договор подписан." if with_prenup else "")],
			"money": 0, "health": 0})
	emit_signal("life_changed")
	gm.save_game()
	return true

func divorce_cost() -> float:
	var frac: float = DIVORCE_FRAC_PRENUP if has_prenup() else DIVORCE_FRAC
	return maxf(0.0, gm.money * frac)

func can_divorce() -> bool:
	return is_married()

func divorce() -> void:
	if not is_married(): return
	var nm: String = String(partner.get("name", "?"))
	var cost: float = divorce_cost()
	if cost > 0.0:
		gm.add_money(-cost)
	partner = {}
	add_happiness(-15.0)
	var es := get_node_or_null("/root/EventSystem")
	if es:
		es.event_triggered.emit({
			"text": "💔 Развод с %s. Раздел имущества: −%s." % [nm, gm.format_money(cost)],
			"money": 0, "health": 0})
	emit_signal("life_changed")
	gm.save_game()

# Отношения остывают без внимания; иногда — ссоры; на нуле — разрыв.
func _relationship_tick() -> void:
	if partner.is_empty(): return
	add_relationship(-RELATIONSHIP_DECAY)
	if gm.day % 30 == 0:
		var conflict: float = 0.12 * (1.0 - relationship() / 100.0)
		if randf() < conflict:
			add_relationship(-randf_range(4.0, 10.0))
			var es := get_node_or_null("/root/EventSystem")
			if es:
				es.event_triggered.emit({"text": "😠 Ссора с %s подпортила отношения." % partner.get("name", "?"), "money": 0, "health": 0})
	if relationship() <= 0.0:
		if is_married(): divorce()
		else: breakup()

# ── Тело, форма и внешность ───────────────────────────────────────────────────
# Внешность складывается из формы, стиля и возраста (молодость — плюс).
func appearance() -> float:
	var age_factor: float = clampf((35 - age()) * 0.3, -12.0, 5.0)
	return clampf(fitness * 0.45 + style * 0.45 + age_factor, 0.0, 100.0)

func workout_cost() -> int:
	return gm.shop_price(WORKOUT_BASE_COST)

func can_workout() -> bool:
	return gm.day > _last_workout_day and gm.money >= float(workout_cost())

func workout() -> bool:
	if not can_workout(): return false
	if not gm.spend_money(workout_cost()): return false
	fitness = clampf(fitness + WORKOUT_FITNESS, 0.0, 100.0)
	# Тренировка прибавляет здоровье до предела, но никогда не снижает текущее
	var cap: float = float(gm.get("max_stat")) if gm.get("max_stat") != null else 100.0
	gm.health = maxf(gm.health, minf(gm.health + WORKOUT_HEALTH, cap))
	gm.emit_signal("health_changed", gm.health)
	add_happiness(WORKOUT_HAPPY)
	_last_workout_day = gm.day
	emit_signal("life_changed")
	gm.save_game()
	return true

func groom_cost() -> int:
	return gm.shop_price(GROOM_BASE_COST)

func can_groom() -> bool:
	return gm.day > _last_groom_day and gm.money >= float(groom_cost())

func groom() -> bool:
	if not can_groom(): return false
	if not gm.spend_money(groom_cost()): return false
	style = clampf(style + GROOM_STYLE, 0.0, 100.0)
	add_happiness(GROOM_HAPPY)
	_last_groom_day = gm.day
	emit_signal("life_changed")
	gm.save_game()
	return true

func mood_label() -> String:
	if happiness >= 80.0: return "Счастлив"
	if happiness >= 60.0: return "Доволен"
	if happiness >= 40.0: return "Нормально"
	if happiness >= 20.0: return "Подавлен"
	return "В депрессии"

func mood_color() -> Color:
	if happiness >= 60.0: return Color(0.55, 0.9, 0.6)
	if happiness >= 40.0: return Color(0.9, 0.85, 0.5)
	return Color(0.95, 0.55, 0.5)

# Продуктивность работы: счастье (мотивация) × интеллект (компетентность).
func productivity_mult() -> float:
	var mood: float = 0.85 + (happiness / 100.0) * 0.30      # 0.85..1.15
	var smarts: float = 0.90 + (skill("intellect") / 100.0) * 0.20  # 0.90..1.10
	var calm: float = 1.0 - stress / 100.0 * 0.25            # выгорание режет продуктивность
	return mood * smarts * calm

# ── Ежедневный ход жизни ──────────────────────────────────────────────────────
func process_day() -> void:
	happiness = clampf(happiness + (happiness_baseline() - happiness) * HAPPINESS_DRIFT, 0.0, 100.0)
	var disc: float = discipline_mult()
	fitness = clampf(fitness - FITNESS_DECAY * disc * aging_factor(), 0.0, 100.0)
	style = clampf(style - STYLE_DECAY * disc, 0.0, 100.0)
	# Возрастная нагрузка на организм
	if is_elderly():
		gm.health = maxf(0.0, gm.health - (age() - 60) * 0.04)
	_relationship_tick()
	_parenting_tick()
	_family_events_tick()
	_social_tick()
	_social_rep_tick()
	_hobby_tick()
	_vice_tick()
	_stress_tick()
	_illness_tick()
	var upkeep: float = children_upkeep()
	if upkeep > 0.0:
		gm.add_money(-upkeep)
	if gm.day % 30 == 0:
		var med: float = medical_monthly()
		if med > 0.0:
			gm.add_money(-med)
	# Смертность: при срабатывании — смена поколения
	if randf() < mortality_risk():
		die()
	# День рождения
	if gm.day > 1 and days_into_year() == 0:
		var es := get_node_or_null("/root/EventSystem")
		if es:
			es.event_triggered.emit({
				"text": "🎂 С днём рождения! Вам исполнилось %d." % age(),
				"money": 0, "health": 0})
		emit_signal("life_changed")

func reset() -> void:
	birth_age = 18
	happiness = 60.0
	fitness = 50.0
	style = 50.0
	_last_workout_day = -99
	_last_groom_day = -99
	skills = {"intellect": 30.0, "charisma": 30.0, "willpower": 30.0}
	_last_dev_day = -99
	partner = {}
	prospect = {}
	_last_date_day = -99
	_last_pdate_day = -99
	_last_gift_day = -99
	children = []
	_last_family_day = -99
	_last_develop_day = -99
	friends = []
	_last_hangout_day = -99
	social_rep = 40.0
	_last_social_day = -99
	hobbies = []
	luxuries = []
	vices = {}
	stress = 20.0
	_last_therapy_day = -99
	illnesses = []
	medical_tier = 0
	heir_index = -1
	estate_planning = 0
	generation = 1

func save(cfg: ConfigFile) -> void:
	cfg.set_value("life", "birth_age", birth_age)
	cfg.set_value("life", "happiness", happiness)
	cfg.set_value("life", "fitness", fitness)
	cfg.set_value("life", "style", style)
	cfg.set_value("life", "last_workout_day", _last_workout_day)
	cfg.set_value("life", "last_groom_day", _last_groom_day)
	cfg.set_value("life", "skills", skills)
	cfg.set_value("life", "last_dev_day", _last_dev_day)
	cfg.set_value("life", "partner", partner)
	cfg.set_value("life", "prospect", prospect)
	cfg.set_value("life", "last_date_day", _last_date_day)
	cfg.set_value("life", "last_pdate_day", _last_pdate_day)
	cfg.set_value("life", "last_gift_day", _last_gift_day)
	cfg.set_value("life", "children", children)
	cfg.set_value("life", "last_family_day", _last_family_day)
	cfg.set_value("life", "last_develop_day", _last_develop_day)
	cfg.set_value("life", "friends", friends)
	cfg.set_value("life", "last_hangout_day", _last_hangout_day)
	cfg.set_value("life", "social_rep", social_rep)
	cfg.set_value("life", "last_social_day", _last_social_day)
	cfg.set_value("life", "hobbies", hobbies)
	cfg.set_value("life", "luxuries", luxuries)
	cfg.set_value("life", "vices", vices)
	cfg.set_value("life", "stress", stress)
	cfg.set_value("life", "last_therapy_day", _last_therapy_day)
	cfg.set_value("life", "illnesses", illnesses)
	cfg.set_value("life", "medical_tier", medical_tier)
	cfg.set_value("life", "heir_index", heir_index)
	cfg.set_value("life", "estate_planning", estate_planning)
	cfg.set_value("life", "generation", generation)

func load_data(cfg: ConfigFile) -> void:
	birth_age = cfg.get_value("life", "birth_age", 18)
	happiness = cfg.get_value("life", "happiness", 60.0)
	fitness = cfg.get_value("life", "fitness", 50.0)
	style = cfg.get_value("life", "style", 50.0)
	_last_workout_day = cfg.get_value("life", "last_workout_day", -99)
	_last_groom_day = cfg.get_value("life", "last_groom_day", -99)
	skills = cfg.get_value("life", "skills", {"intellect": 30.0, "charisma": 30.0, "willpower": 30.0})
	_last_dev_day = cfg.get_value("life", "last_dev_day", -99)
	partner = cfg.get_value("life", "partner", {})
	prospect = cfg.get_value("life", "prospect", {})
	_last_date_day = cfg.get_value("life", "last_date_day", -99)
	_last_pdate_day = cfg.get_value("life", "last_pdate_day", -99)
	_last_gift_day = cfg.get_value("life", "last_gift_day", -99)
	children = cfg.get_value("life", "children", [])
	_last_family_day = cfg.get_value("life", "last_family_day", -99)
	_last_develop_day = cfg.get_value("life", "last_develop_day", -99)
	friends = cfg.get_value("life", "friends", [])
	_last_hangout_day = cfg.get_value("life", "last_hangout_day", -99)
	social_rep = cfg.get_value("life", "social_rep", 40.0)
	_last_social_day = cfg.get_value("life", "last_social_day", -99)
	hobbies = cfg.get_value("life", "hobbies", [])
	luxuries = cfg.get_value("life", "luxuries", [])
	vices = cfg.get_value("life", "vices", {})
	stress = cfg.get_value("life", "stress", 20.0)
	_last_therapy_day = cfg.get_value("life", "last_therapy_day", -99)
	illnesses = cfg.get_value("life", "illnesses", [])
	medical_tier = cfg.get_value("life", "medical_tier", 0)
	heir_index = cfg.get_value("life", "heir_index", -1)
	estate_planning = cfg.get_value("life", "estate_planning", 0)
	generation = cfg.get_value("life", "generation", 1)
