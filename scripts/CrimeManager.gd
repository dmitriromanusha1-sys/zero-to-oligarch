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

# ── Чёрный рынок ──────────────────────────────────────────────────────────────
# Контрабанда с плавающими ценами: покупаешь чистыми деньгами, продаёшь — и навар
# падает «грязным» налом (нужен отмыв). Каждая сделка поднимает розыск.
const BM_GOODS := [
	{"id":"booze",  "name":"Палёный алкоголь",      "icon":"🍾", "base":2000,   "heat":2.0},
	{"id":"smokes", "name":"Контрабандные сигареты", "icon":"🚬", "base":6000,   "heat":2.5},
	{"id":"fake",   "name":"Контрафакт",             "icon":"👜", "base":18000,  "heat":4.0},
	{"id":"parts",  "name":"Краденые запчасти",      "icon":"🔩", "base":45000,  "heat":6.0},
	{"id":"gold",   "name":"Левое золото",           "icon":"🪙", "base":160000, "heat":9.0},
	{"id":"arms",   "name":"Стволы",                 "icon":"🔫", "base":550000, "heat":18.0},
]
var bm_prices: Dictionary = {}      # id → текущий множитель цены (random walk вокруг 1.0)
var bm_inventory: Dictionary = {}   # id → количество на руках

func _ready() -> void:
	_init_bm_prices()

func _init_bm_prices() -> void:
	for g in BM_GOODS:
		if not bm_prices.has(g.id):
			bm_prices[g.id] = randf_range(0.8, 1.2)

func bm_good(id: String) -> Dictionary:
	for g in BM_GOODS:
		if g.id == id:
			return g
	return {}

func bm_price(id: String) -> int:
	var g := bm_good(id)
	if g.is_empty():
		return 0
	return int(float(g.base) * float(bm_prices.get(id, 1.0)))

func bm_have(id: String) -> int:
	return int(bm_inventory.get(id, 0))

# Купить контрабанду (чистыми деньгами). Возвращает true при успехе.
func bm_buy(id: String, qty: int) -> bool:
	if qty <= 0 or bm_good(id).is_empty():
		return false
	var gm := get_node_or_null("/root/GameManager")
	var cost: int = bm_price(id) * qty
	if gm == null or not gm.spend_money(cost):
		return false
	bm_inventory[id] = bm_have(id) + qty
	add_heat(float(bm_good(id).get("heat", 1.0)))
	emit_signal("crime_changed")
	return true

# Продать контрабанду — навар падает «грязным» налом.
func bm_sell(id: String, qty: int) -> bool:
	if qty <= 0 or bm_have(id) < qty:
		return false
	var revenue: int = bm_price(id) * qty
	bm_inventory[id] = bm_have(id) - qty
	if bm_inventory[id] <= 0:
		bm_inventory.erase(id)
	add_dirty_money(revenue)
	add_heat(float(bm_good(id).get("heat", 1.0)))
	add_criminal_rep(0.4 * qty)   # имя на улице растёт
	emit_signal("crime_changed")
	return true

# Суточное колебание цен — random walk с возвратом к 1.0, чтобы был навар.
func bm_fluctuate() -> void:
	for g in BM_GOODS:
		var p: float = float(bm_prices.get(g.id, 1.0))
		p += randf_range(-0.18, 0.18)
		p = lerpf(p, 1.0, 0.10)            # мягкий возврат к среднему
		bm_prices[g.id] = clampf(p, 0.5, 2.0)
	emit_signal("crime_changed")

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
	bm_fluctuate()   # цены чёрного рынка колеблются

func save(cfg: ConfigFile) -> void:
	cfg.set_value("crime", "heat", heat)
	cfg.set_value("crime", "criminal_rep", criminal_rep)
	cfg.set_value("crime", "dirty_money", dirty_money)
	cfg.set_value("crime", "bm_prices", bm_prices)
	cfg.set_value("crime", "bm_inventory", bm_inventory)

func load_data(cfg: ConfigFile) -> void:
	heat = cfg.get_value("crime", "heat", 0.0)
	criminal_rep = cfg.get_value("crime", "criminal_rep", 0.0)
	dirty_money = cfg.get_value("crime", "dirty_money", 0.0)
	bm_prices = cfg.get_value("crime", "bm_prices", {})
	bm_inventory = cfg.get_value("crime", "bm_inventory", {})
	_init_bm_prices()

func reset() -> void:
	heat = 0.0
	criminal_rep = 0.0
	dirty_money = 0.0
	bm_inventory = {}
	bm_prices = {}
	_init_bm_prices()
