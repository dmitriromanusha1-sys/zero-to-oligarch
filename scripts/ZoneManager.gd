extends Node

signal zone_changed(zone_index: int)

var current_zone: int = 0
# Максимальная зона, которую игрок когда-либо достиг (прогресс/память).
# В отличие от current_zone (физическое положение игрока на карте прямо
# сейчас), это значение никогда не уменьшается — если игрок прошёлся назад
# в более раннюю зону и вышел из игры, разблокировка дальних зон не теряется.
var max_zone_reached: int = 0
var _travel_teleport: bool = false  # World читает это при zone_changed

const ZONE_W: float = 2500.0
const ZONE_H: float = 2500.0

# Раскладка зон в сетке 3×3 змейкой:
#   (0,0)=0  (1,0)=1  (2,0)=2
#   (2,1)=3  (1,1)=4  (0,1)=5
#   (0,2)=6  (1,2)=7  (2,2)=8
const ZONE_GRID: Array = [
	Vector2i(0,0), Vector2i(1,0), Vector2i(2,0),
	Vector2i(2,1), Vector2i(1,1), Vector2i(0,1),
	Vector2i(0,2), Vector2i(1,2), Vector2i(2,2),
]

const ZONE_CONDITIONS: Array = [
	{"title_req":  2, "edu_req": 1, "desc": "Нищий (5 000 ₽) + Начальная школа"},
	{"title_req":  4, "edu_req": 3, "desc": "Бедный (40 000 ₽) + ПТУ"},
	{"title_req":  6, "edu_req": 4, "desc": "Простой (250 000 ₽) + Колледж"},
	{"title_req":  8, "edu_req": 5, "desc": "Специалист (1 500 000 ₽) + Бакалавр"},
	{"title_req": 10, "edu_req": 6, "desc": "Богатый (10 000 000 ₽) + Магистр"},
	{"title_req": 12, "edu_req": 7, "desc": "Миллионер (60 000 000 ₽) + Аспирант"},
	{"title_req": 14, "edu_req": 8, "desc": "Мультимиллионер (600 000 000 ₽) + Доктор наук"},
	{"title_req": 15, "edu_req": 9, "desc": "Магнат (2 500 000 000 ₽) + Гений"},
	{},  # Зона 8 — финальная
]

const ZONE_META: Array = [
	{"name": "Трущобы",                   "icon": "🏚", "bg": Color(0.11, 0.11, 0.13)},
	{"name": "Рабочий квартал",           "icon": "🏗", "bg": Color(0.10, 0.12, 0.10)},
	{"name": "Спальный район",            "icon": "🏘", "bg": Color(0.09, 0.11, 0.14)},
	{"name": "Средний класс",             "icon": "🏙", "bg": Color(0.10, 0.13, 0.12)},
	{"name": "Бизнес-квартал",            "icon": "🏢", "bg": Color(0.08, 0.10, 0.14)},
	{"name": "Элитный район",             "icon": "💎", "bg": Color(0.12, 0.10, 0.06)},
	{"name": "Район олигархов",           "icon": "👑", "bg": Color(0.08, 0.07, 0.04)},
	{"name": "Правительственный квартал", "icon": "🏛", "bg": Color(0.06, 0.07, 0.10)},
	{"name": "Высший свет",              "icon": "⭐", "bg": Color(0.04, 0.05, 0.08)},
]

# Центр зоны в мировых координатах
func get_zone_center(z: int) -> Vector2:
	var g: Vector2i = ZONE_GRID[z]
	return Vector2((g.x - 1) * ZONE_W, (g.y - 1) * ZONE_H)

func get_zone_name() -> String:
	return ZONE_META[current_zone].icon + " " + ZONE_META[current_zone].name

func get_zone_bg() -> Color:
	return ZONE_META[current_zone].bg

# Физическое присутствие игрока в зоне (вызывается из World при ходьбе по
# карте). Двигает "память" прогресса вперёд, но никогда не откатывает её назад.
func register_visit(z: int) -> void:
	current_zone = z
	if z > max_zone_reached:
		max_zone_reached = z

func is_final_zone() -> bool:
	return max_zone_reached >= ZONE_META.size() - 1

func is_zone_complete() -> bool:
	if is_final_zone():
		return false
	var cond: Dictionary = ZONE_CONDITIONS[max_zone_reached]
	if cond.is_empty():
		return false
	var gm: Node = get_node("/root/GameManager")
	var em: Node = get_node_or_null("/root/EducationManager")
	var title_ok: bool = gm.current_title_index >= cond.title_req
	var edu_ok: bool = true
	if em: edu_ok = em.level >= cond.edu_req
	return title_ok and edu_ok

func get_condition_text() -> String:
	if is_final_zone():
		return "Вы достигли вершины! Переезжайте на Остров."
	return ZONE_CONDITIONS[max_zone_reached].get("desc", "")

func get_progress_text() -> String:
	if is_final_zone():
		return "🏝 Нажмите «На Остров» чтобы завершить игру!"
	var cond: Dictionary = ZONE_CONDITIONS[max_zone_reached]
	if cond.is_empty():
		return ""
	var gm: Node = get_node("/root/GameManager")
	var em: Node = get_node_or_null("/root/EducationManager")
	var t_idx: int = gm.current_title_index
	var t_req: int = cond.title_req
	var e_lv: int  = em.level if em else 0
	var e_req: int = cond.edu_req
	var t_name: String = gm.TITLES[t_req].name
	var e_name: String = em.LEVELS[e_req].name if em else "?"
	var t_icon: String = "✅" if t_idx >= t_req else "❌"
	var e_icon: String = "✅" if e_lv >= e_req else "❌"
	return "%s Титул: %s\n%s Образование: %s" % [t_icon, t_name, e_icon, e_name]

# Требования для разблокировки зоны zone_idx (нужно выполнить в зоне zone_idx-1)
func get_unlock_info(zone_idx: int) -> Dictionary:
	if zone_idx <= 0 or zone_idx >= ZONE_CONDITIONS.size():
		return {}
	var cond: Dictionary = ZONE_CONDITIONS[zone_idx - 1]
	if cond.is_empty():
		return {}
	var gm: Node = get_node("/root/GameManager")
	var em: Node = get_node_or_null("/root/EducationManager")
	var t_idx: int = gm.current_title_index
	var e_lv: int  = em.level if em else 0
	return {
		"desc":       cond.get("desc", ""),
		"title_req":  cond.title_req,
		"title_name": gm.TITLES[cond.title_req].name,
		"title_ok":   t_idx >= cond.title_req,
		"edu_req":    cond.edu_req,
		"edu_name":   em.LEVELS[cond.edu_req].name if em else "?",
		"edu_ok":     e_lv >= cond.edu_req,
		"zones_away": zone_idx - max_zone_reached,
	}

func advance_zone() -> void:
	travel_to(max_zone_reached + 1)

# target_zone <= max_zone_reached — возврат в уже открытую зону, разрешён всегда.
# target_zone == max_zone_reached + 1 — продвижение вперёд, требует is_zone_complete().
func travel_to(target_zone: int) -> void:
	if target_zone == current_zone:
		return
	if target_zone > max_zone_reached:
		if target_zone != max_zone_reached + 1:
			push_warning("travel_to: нельзя перепрыгнуть через зоны")
			return
		if not is_zone_complete():
			push_warning("travel_to: условия не выполнены")
			return
	print(">>> travel_to: переходим в зону ", target_zone)
	register_visit(target_zone)
	var gm: Node = get_node("/root/GameManager")
	gm.save_game()
	_travel_teleport = true
	emit_signal("zone_changed", current_zone)
	_travel_teleport = false

func trigger_island_ending() -> void:
	var gm: Node = get_node("/root/GameManager")
	gm.save_game()
	SceneTransition.go("res://scenes/IslandEnding.tscn")

func save(cfg: ConfigFile) -> void:
	cfg.set_value("zone", "current", current_zone)
	cfg.set_value("zone", "max_reached", max_zone_reached)

func load_data(cfg: ConfigFile) -> void:
	current_zone = cfg.get_value("zone", "current", 0)
	max_zone_reached = cfg.get_value("zone", "max_reached", current_zone)
