extends Node
# Должности (вакансии) на предприятиях. Один работодатель — несколько позиций под
# разные квалификации, как в реальной жизни: столовая = посудомойщик + повар +
# администратор. Игрок занимает позицию, под которую подходит по профессии и
# образованию и где есть свободное место.
#
# Позиция: {prof, title, min_edu, salary, slots, taken}
#   prof    — требуемая профессия ("" = любая, гейт только по образованию)
#   min_edu — минимальный уровень образования (индекс LEVELS)
#   salary  — базовый МЕСЯЧНЫЙ оклад (индексируется зарплатами при выдаче)
#   slots   — всего мест;  taken — занято NPC (часть мест уже не свободна)
#
# Это стартовый набор работодателей — полную карту по всем 9 зонам распишем дальше.
const EMPLOYERS := {
	"canteen": {
		"name": "Столовая «Уют»", "icon": "🍲", "zone": 0,
		"positions": [
			{"prof":"",        "title":"Посудомойщик",  "min_edu":0, "salary":30000,  "slots":3, "taken":1},
			{"prof":"cook",    "title":"Повар",          "min_edu":4, "salary":60000,  "slots":2, "taken":1},
			{"prof":"manager", "title":"Администратор",  "min_edu":5, "salary":95000,  "slots":1, "taken":0},
		],
	},
	"autoservice": {
		"name": "Автосервис «Гараж»", "icon": "🔧", "zone": 1,
		"positions": [
			{"prof":"",          "title":"Подсобник",    "min_edu":0, "salary":36000,  "slots":2, "taken":1},
			{"prof":"mechanic",  "title":"Автомеханик",  "min_edu":4, "salary":85000,  "slots":2, "taken":0},
			{"prof":"accountant","title":"Бухгалтер",    "min_edu":6, "salary":130000, "slots":1, "taken":0},
		],
	},
	"office": {
		"name": "Бизнес-центр «Меридиан»", "icon": "🏢", "zone": 4,
		"positions": [
			{"prof":"manager",   "title":"Менеджер по продажам", "min_edu":5, "salary":160000, "slots":3, "taken":1},
			{"prof":"accountant","title":"Бухгалтер",            "min_edu":6, "salary":210000, "slots":2, "taken":0},
			{"prof":"programmer","title":"Программист",          "min_edu":6, "salary":320000, "slots":2, "taken":0},
			{"prof":"lawyer",    "title":"Юрист",                "min_edu":7, "salary":520000, "slots":1, "taken":0},
		],
	},
}

func employer(id: String) -> Dictionary:
	return EMPLOYERS.get(id, {})

func employer_ids() -> Array:
	return EMPLOYERS.keys()

func positions(id: String) -> Array:
	return employer(id).get("positions", [])

func free_slots(pos: Dictionary) -> int:
	return maxi(0, int(pos.get("slots", 0)) - int(pos.get("taken", 0)))

func is_open(pos: Dictionary) -> bool:
	return free_slots(pos) > 0

# Подходит ли игрок: образование не ниже требуемого и (если нужна профессия) —
# именно эта профессия.
func qualifies(pos: Dictionary) -> bool:
	var em := get_node_or_null("/root/EducationManager")
	var lvl: int = em.level if em else 0
	if lvl < int(pos.get("min_edu", 0)):
		return false
	var need: String = String(pos.get("prof", ""))
	if need != "":
		var pm := get_node_or_null("/root/ProfessionManager")
		if pm == null or pm.profession != need:
			return false
	return true

# Месячный оклад с учётом индексации зарплат и профильной надбавки профессии.
func monthly_salary(pos: Dictionary) -> int:
	var gm := get_node_or_null("/root/GameManager")
	var wf: float = gm.wage_factor() if gm and gm.has_method("wage_factor") else 1.0
	var prof_mult: float = 1.0
	var pm := get_node_or_null("/root/ProfessionManager")
	if pm and pm.has_method("work_pay_mult"):
		prof_mult = pm.work_pay_mult(String(pos.get("prof", "")))
	return int(float(pos.get("salary", 0)) * wf * prof_mult)

# Позиции работодателя, которые игрок может занять прямо сейчас (подходит + есть место).
func available_for_player(id: String) -> Array:
	var out: Array = []
	for pos in positions(id):
		if qualifies(pos) and is_open(pos):
			out.append(pos)
	return out

# Все работодатели заданной зоны.
func employers_in_zone(zone: int) -> Array:
	var out: Array = []
	for eid in EMPLOYERS:
		if int(EMPLOYERS[eid].get("zone", -1)) == zone:
			out.append(eid)
	return out
