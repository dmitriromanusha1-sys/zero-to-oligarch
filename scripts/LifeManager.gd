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
	return clampf(b, 5.0, 100.0)

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
	var prev_age: int = age()
	happiness = clampf(happiness + (happiness_baseline() - happiness) * HAPPINESS_DRIFT, 0.0, 100.0)
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

func save(cfg: ConfigFile) -> void:
	cfg.set_value("life", "birth_age", birth_age)
	cfg.set_value("life", "happiness", happiness)

func load_data(cfg: ConfigFile) -> void:
	birth_age = cfg.get_value("life", "birth_age", 18)
	happiness = cfg.get_value("life", "happiness", 60.0)
