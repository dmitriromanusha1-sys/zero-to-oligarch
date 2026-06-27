extends Node
# Власть и влияние. «Влияние» — политический капитал, который ты копишь деньгами
# (пожертвования) и тратишь на связи с чиновниками. Фаза 1: ресурс, пожертвования,
# связи и их пассивные бонусы. Дальше — лобби законов, СМИ, выборы.

signal influence_changed(value: float)
signal connections_changed

var influence: float = 0.0

# ── Связи с чиновниками: id → уровень 0..MAX. Уровень усиливает бонус. ──────────
const MAX_CONNECTION_LEVEL: int = 3
const CONN_MIN_TITLE: int = 5   # доступ к политике — с титула «крупный» и выше

const OFFICIALS: Array = [
	{"id":"police", "name":"Начальник полиции",   "icon":"👮", "desc":"Реже облавы участкового и меньше штрафы."},
	{"id":"tax",    "name":"Налоговый инспектор",  "icon":"🧾", "desc":"Снижает налоги на доход (до −15%)."},
	{"id":"mayor",  "name":"Мэр города",           "icon":"🏛", "desc":"Дешевле жизнь в городе и пассивное влияние."},
	{"id":"banker", "name":"Председатель банка",   "icon":"🏦", "desc":"Лучше ставка по вкладу (до +1.5%/мес)."},
]

var connections: Dictionary = {}   # id -> level

# Пожертвования: деньги → влияние (+ немного репутации, благотворитель в почёте).
const DONATIONS: Array = [
	{"id":"charity", "name":"Благотворительный взнос", "cost":500_000,     "inf":5,   "rep":1},
	{"id":"event",   "name":"Спонсорство мероприятия", "cost":5_000_000,   "inf":35,  "rep":2},
	{"id":"fund",    "name":"Партийный фонд",           "cost":50_000_000,  "inf":250, "rep":3},
]

# Поднятие уровня связи: влияние + деньги, растёт с уровнем (индексы 0→ур.1 и т.д.).
const CONN_INF_COST: Array = [40, 120, 300]
const CONN_MONEY_COST: Array = [2_000_000, 10_000_000, 40_000_000]

var gm: Node

func _ready() -> void:
	gm = get_node("/root/GameManager")

# ── Ресурс влияния ────────────────────────────────────────────────────────────
func add_influence(amount: float) -> void:
	influence = maxf(0.0, influence + amount)
	emit_signal("influence_changed", influence)

# ── Связи ─────────────────────────────────────────────────────────────────────
func _official(id: String) -> Dictionary:
	for o in OFFICIALS:
		if o.id == id: return o
	return {}

func connection_level(id: String) -> int:
	return int(connections.get(id, 0))

func total_connection_levels() -> int:
	var t: int = 0
	for k in connections:
		t += int(connections[k])
	return t

func politics_unlocked() -> bool:
	return gm.current_title_index >= CONN_MIN_TITLE

func conn_inf_cost(id: String) -> int:
	var lvl: int = connection_level(id)
	if lvl >= MAX_CONNECTION_LEVEL: return 0
	return int(CONN_INF_COST[lvl])

func conn_money_cost(id: String) -> int:
	var lvl: int = connection_level(id)
	if lvl >= MAX_CONNECTION_LEVEL: return 0
	return int(CONN_MONEY_COST[lvl])

func can_raise_connection(id: String) -> bool:
	if not politics_unlocked(): return false
	var lvl: int = connection_level(id)
	if lvl >= MAX_CONNECTION_LEVEL: return false
	return influence >= float(conn_inf_cost(id)) and gm.money >= float(conn_money_cost(id))

func raise_connection(id: String) -> bool:
	if not can_raise_connection(id): return false
	if not gm.spend_money(conn_money_cost(id)): return false
	add_influence(-float(conn_inf_cost(id)))
	connections[id] = connection_level(id) + 1
	emit_signal("connections_changed")
	gm.save_game()
	return true

# ── Пожертвования ─────────────────────────────────────────────────────────────
func _donation(id: String) -> Dictionary:
	for d in DONATIONS:
		if d.id == id: return d
	return {}

func can_donate(id: String) -> bool:
	var d := _donation(id)
	return not d.is_empty() and gm.money >= float(d.cost)

func donate(id: String) -> bool:
	var d := _donation(id)
	if d.is_empty(): return false
	if not gm.spend_money(d.cost): return false
	add_influence(float(d.inf))
	var rm := get_node_or_null("/root/ReputationManager")
	if rm and rm.has_method("add"):
		rm.add(int(d.get("rep", 0)))
	emit_signal("connections_changed")
	gm.save_game()
	return true

# ── Пассивные бонусы (читаются другими системами) ─────────────────────────────
func police_raid_mult() -> float:
	return maxf(0.0, 1.0 - 0.25 * connection_level("police"))   # до −75% шанса

func police_fine_mult() -> float:
	return maxf(0.0, 1.0 - 0.20 * connection_level("police"))   # до −60% штрафа

func tax_discount() -> float:
	return 0.05 * connection_level("tax")                       # до −15% налога

func expense_mult() -> float:
	return maxf(0.0, 1.0 - 0.04 * connection_level("mayor"))    # до −12% стоимости жизни

func deposit_bonus() -> float:
	return 0.005 * connection_level("banker")                  # до +1.5%/мес

# Ежедневно: пассивное влияние от политической машины (мэр + сеть связей).
func process_day() -> void:
	if not politics_unlocked(): return
	var passive: float = total_connection_levels() * 0.2 + connection_level("mayor") * 0.5
	if passive > 0.0:
		add_influence(passive)

func reset() -> void:
	influence = 0.0
	connections = {}

func save(cfg: ConfigFile) -> void:
	cfg.set_value("influence", "value", influence)
	cfg.set_value("influence", "connections", connections)

func load_data(cfg: ConfigFile) -> void:
	influence = cfg.get_value("influence", "value", 0.0)
	connections = cfg.get_value("influence", "connections", {})
