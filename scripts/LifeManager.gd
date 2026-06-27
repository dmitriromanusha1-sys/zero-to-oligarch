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
	return clampf(b, 5.0, 100.0)

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

# Счастье влияет на продуктивность работы (мотивация): 0.85..1.15.
func productivity_mult() -> float:
	return 0.85 + (happiness / 100.0) * 0.30

# ── Ежедневный ход жизни ──────────────────────────────────────────────────────
func process_day() -> void:
	happiness = clampf(happiness + (happiness_baseline() - happiness) * HAPPINESS_DRIFT, 0.0, 100.0)
	fitness = clampf(fitness - FITNESS_DECAY, 0.0, 100.0)
	style = clampf(style - STYLE_DECAY, 0.0, 100.0)
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

func save(cfg: ConfigFile) -> void:
	cfg.set_value("life", "birth_age", birth_age)
	cfg.set_value("life", "happiness", happiness)
	cfg.set_value("life", "fitness", fitness)
	cfg.set_value("life", "style", style)
	cfg.set_value("life", "last_workout_day", _last_workout_day)
	cfg.set_value("life", "last_groom_day", _last_groom_day)

func load_data(cfg: ConfigFile) -> void:
	birth_age = cfg.get_value("life", "birth_age", 18)
	happiness = cfg.get_value("life", "happiness", 60.0)
	fitness = cfg.get_value("life", "fitness", 50.0)
	style = cfg.get_value("life", "style", 50.0)
	_last_workout_day = cfg.get_value("life", "last_workout_day", -99)
	_last_groom_day = cfg.get_value("life", "last_groom_day", -99)
