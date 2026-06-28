extends Node
# Теневая империя — криминальный путь параллельно легальному заработку.
# Фундамент: «розыск» (heat) — внимание полиции, растёт с тёмными делами и спадает
# со временем; криминальный авторитет — статус в иерархии; «грязные» деньги —
# нал с тёмных дел, который надо отмывать (отдельная фаза). Последствия (облавы,
# арест, тюрьма) подключаются дальше.

signal crime_changed
signal heat_changed(value: float)
signal busted              # арест (фаза тюрьмы)

var heat: float = 0.0          # розыск 0..100
var criminal_rep: float = 0.0  # криминальный авторитет 0..100
var dirty_money: float = 0.0   # грязные деньги (нужен отмыв)

const HEAT_DECAY := 2.0        # ежедневный спад розыска (без новых дел)

# Иерархия: порог авторитета → ранг
const RANKS := ["Никто", "Шестёрка", "Бригадир", "Авторитет", "Вор в законе"]
const RANK_REP := [0, 15, 40, 65, 90]

func add_heat(amount: float) -> void:
	heat = clampf(heat + amount, 0.0, 100.0)
	emit_signal("heat_changed", heat)
	emit_signal("crime_changed")

func cool_heat(amount: float) -> void:
	add_heat(-amount)

func add_criminal_rep(amount: float) -> void:
	criminal_rep = clampf(criminal_rep + amount, 0.0, 100.0)
	emit_signal("crime_changed")

func add_dirty_money(amount: float) -> void:
	dirty_money = maxf(0.0, dirty_money + amount)
	emit_signal("crime_changed")

func is_criminal() -> bool:
	return criminal_rep > 0.0 or heat > 0.0 or dirty_money > 0.0

func rank() -> int:
	var r: int = 0
	for i in RANK_REP.size():
		if criminal_rep >= RANK_REP[i]:
			r = i
	return r

func rank_name() -> String:
	return RANKS[rank()]

# Подпись уровня розыска для UI: чем выше — тем опаснее
func heat_label() -> Dictionary:
	if heat >= 80.0:   return {"name": "Облава близко", "color": Color(0.95, 0.30, 0.30)}
	elif heat >= 50.0: return {"name": "В разработке",  "color": Color(0.95, 0.55, 0.30)}
	elif heat >= 20.0: return {"name": "Под наблюдением","color": Color(0.90, 0.80, 0.40)}
	else:              return {"name": "Спокойно",       "color": Color(0.55, 0.80, 0.55)}

# Суточная обработка: розыск медленно спадает (связи/взятки усилят спад позже).
func process_day() -> void:
	if heat > 0.0:
		heat = clampf(heat - HEAT_DECAY, 0.0, 100.0)
		emit_signal("heat_changed", heat)

func save(cfg: ConfigFile) -> void:
	cfg.set_value("crime", "heat", heat)
	cfg.set_value("crime", "criminal_rep", criminal_rep)
	cfg.set_value("crime", "dirty_money", dirty_money)

func load_data(cfg: ConfigFile) -> void:
	heat = cfg.get_value("crime", "heat", 0.0)
	criminal_rep = cfg.get_value("crime", "criminal_rep", 0.0)
	dirty_money = cfg.get_value("crime", "dirty_money", 0.0)

func reset() -> void:
	heat = 0.0
	criminal_rep = 0.0
	dirty_money = 0.0
