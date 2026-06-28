extends Node

signal reputation_changed(value: int)

# Репутация: 0..100. Начальное значение зависит от старта игры.
var reputation: int = 30

const LEVELS := [
	{"min": 0,  "name": "Криминальный",  "color": Color(0.8, 0.2, 0.2)},
	{"min": 20, "name": "Подозрительный","color": Color(0.8, 0.5, 0.2)},
	{"min": 40, "name": "Обычный",       "color": Color(0.8, 0.8, 0.8)},
	{"min": 60, "name": "Уважаемый",     "color": Color(0.4, 0.8, 0.4)},
	{"min": 80, "name": "Известный",     "color": Color(0.3, 0.7, 1.0)},
]

func add(amount: int) -> void:
	# 💇 сфера услуг — быстрее растёт репутация (только прирост, не штрафы)
	if amount > 0:
		var prof := get_node_or_null("/root/ProfessionManager")
		if prof and prof.has_method("reputation_gain_mult"):
			amount = int(round(amount * prof.reputation_gain_mult()))
	reputation = clampi(reputation + amount, 0, 100)
	reputation_changed.emit(reputation)

func get_level_name() -> String:
	var result := LEVELS[0].name
	for l in LEVELS:
		if reputation >= l.min:
			result = l.name
	return result

func get_level_color() -> Color:
	var result: Color = LEVELS[0].color
	for l in LEVELS:
		if reputation >= l.min:
			result = l.color
	return result

func is_suspicious() -> bool:
	return reputation < 40

func save(cfg: ConfigFile) -> void:
	cfg.set_value("reputation", "value", reputation)

func load(cfg: ConfigFile) -> void:
	reputation = cfg.get_value("reputation", "value", 30)
