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
	return clampf(b, 5.0, 100.0)

# ── Личная репутация и статус ─────────────────────────────────────────────────
func social_baseline() -> float:
	var b: float = 20.0
	b += appearance() * 0.15
	b += skill("charisma") * 0.15
	b += close_friends() * 4.0
	b += gm.current_title_index * 2.5
	if is_married(): b += 5.0
	b += minf(child_count() * 2.0, 8.0)
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
	return mood * smarts

# ── Ежедневный ход жизни ──────────────────────────────────────────────────────
func process_day() -> void:
	happiness = clampf(happiness + (happiness_baseline() - happiness) * HAPPINESS_DRIFT, 0.0, 100.0)
	var disc: float = discipline_mult()
	fitness = clampf(fitness - FITNESS_DECAY * disc, 0.0, 100.0)
	style = clampf(style - STYLE_DECAY * disc, 0.0, 100.0)
	_relationship_tick()
	_parenting_tick()
	_family_events_tick()
	_social_tick()
	_social_rep_tick()
	var upkeep: float = children_upkeep()
	if upkeep > 0.0:
		gm.add_money(-upkeep)
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
