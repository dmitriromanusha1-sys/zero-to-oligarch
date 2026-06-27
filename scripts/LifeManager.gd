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
	return clampf(b, 5.0, 100.0)

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
	return clampf(appearance() * 0.40 + skill("charisma") * 0.40 + status, 0.0, 100.0)

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
