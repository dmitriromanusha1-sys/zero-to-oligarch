extends Node
# Теневая империя — криминальный путь параллельно легальному заработку.
# Фундамент: «розыск» (heat) — внимание полиции, растёт с тёмными делами и спадает
# со временем; криминальный авторитет — статус в иерархии; «грязные» деньги —
# нал с тёмных дел, который надо отмывать (отдельная фаза). Последствия (облавы,
# арест, тюрьма) подключаются дальше.

signal crime_changed
signal heat_changed(value: float)
signal busted              # арест (фаза тюрьмы)
signal raided(info: Dictionary)

var prison_days: int = 0   # оставшийся срок (0 — на свободе)

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
	if qty <= 0 or bm_good(id).is_empty() or is_imprisoned():
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
	if qty <= 0 or bm_have(id) < qty or is_imprisoned():
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

# ── Контроль районов (передел) ────────────────────────────────────────────────
# Берёшь районы под контроль силой банды. «Передел» — стычка с местной ОПГ: шанс
# зависит от силы банды против врага. Контролируемый район даёт крупный теневой
# доход, но богатые районы и охраняются злее. Можно брать только открытые районы.
var controlled_zones: Array = []

func zone_rival_strength(z: int) -> float:
	return 5.0 + float(z) * 4.0

func turf_income(z: int) -> float:
	return 50000.0 * float(z + 1)

func turf_heat(z: int) -> float:
	return 1.0 + float(z) * 0.5

func controls_zone(z: int) -> bool:
	return controlled_zones.has(z)

func turf_war_chance(z: int) -> float:
	var p: float = gang_power()
	return clampf(p / (p + zone_rival_strength(z)) + lieutenant_bonus("war"), 0.05, 0.95)

func can_take_zone(z: int) -> bool:
	if controls_zone(z) or z < 0 or z > 8 or is_imprisoned():
		return false
	var zm := get_node_or_null("/root/ZoneManager")
	if zm and z > zm.max_zone_reached:
		return false
	return gang_power() > 0.0

# Передел района. {ok, success, reason}
func take_zone(z: int) -> Dictionary:
	if not can_take_zone(z):
		return {"ok": false, "reason": "недоступно (нужна банда / открытый район)"}
	var win: bool = randf() < turf_war_chance(z)
	add_heat(turf_heat(z) * 3.0)   # война шумит
	if win:
		controlled_zones.append(z)
		add_criminal_rep(3.0 + float(z) * 0.5)
		emit_signal("crime_changed")
		return {"ok": true, "success": true}
	else:
		gang_loyalty = clampf(gang_loyalty - 15.0, 0.0, 100.0)
		if randf() < 0.5:
			gang_size = maxi(0, gang_size - 1)   # потери в перестрелке
		emit_signal("crime_changed")
		return {"ok": true, "success": false}

func lose_zone(z: int) -> void:
	controlled_zones.erase(z)
	emit_signal("crime_changed")

func turf_income_total() -> float:
	var t: float = 0.0
	for z in controlled_zones:
		t += turf_income(int(z))
	return t

func turf_heat_total() -> float:
	var t: float = 0.0
	for z in controlled_zones:
		t += turf_heat(int(z))
	return t

# ── Братва / ОПГ ──────────────────────────────────────────────────────────────
# Набираешь бойцов: они усиливают дела и расширяют зону влияния, но требуют
# содержания. Не платишь — лояльность падает, дойдёт до нуля — дезертируют.
var gang_size: int = 0
var gang_loyalty: float = 100.0
const GANG_HIRE_COST := 200000.0   # вербовка одного бойца
const GANG_UPKEEP := 5000.0        # содержание бойца в день

# ── Бригадиры (именные лейтенанты) ────────────────────────────────────────────
# Поверх рядовых бойцов — бригадиры с именем, специализацией и личной лояльностью.
# Каждый усиливает свою сферу: дела, рэкет или войну за районы. Число ограничено
# криминальным рангом.
const LT_NAMES := ["Серый", "Тихий", "Шрам", "Кабан", "Хром", "Молчун", "Лысый",
	"Батя", "Жук", "Студент", "Цыган", "Беспалый", "Поп", "Купец"]
const LT_SPECS := ["schemes", "racket", "war"]
const LT_SPEC_NAME := {"schemes": "дела", "racket": "рэкет", "war": "война"}
const LT_HIRE_COST := 1_000_000.0
var lieutenants: Array = []   # [{name, spec, loyalty}]

func max_lieutenants() -> int:
	return rank()   # авторитет: 0 (Никто) .. 4 (Вор в законе)

func recruit_lieutenant(spec: String) -> bool:
	if not LT_SPECS.has(spec) or lieutenants.size() >= max_lieutenants():
		return false
	var gm := get_node_or_null("/root/GameManager")
	if gm == null or not gm.spend_money(LT_HIRE_COST):
		return false
	lieutenants.append({"name": LT_NAMES[randi() % LT_NAMES.size()], "spec": spec, "loyalty": 100.0})
	emit_signal("crime_changed")
	return true

func dismiss_lieutenant(idx: int) -> void:
	if idx >= 0 and idx < lieutenants.size():
		lieutenants.remove_at(idx)
		emit_signal("crime_changed")

# Суммарный бонус бригадиров заданной специализации (взвешен лояльностью).
func lieutenant_bonus(spec: String) -> float:
	var per: float = 0.10 if spec == "racket" else (0.08 if spec == "war" else 0.05)
	var b: float = 0.0
	for lt in lieutenants:
		if String(lt.get("spec", "")) == spec:
			b += per * (float(lt.get("loyalty", 0.0)) / 100.0)
	return b

func max_gang() -> int:
	return int(criminal_rep / 10.0)   # авторитет определяет размер банды

func gang_power() -> float:
	return float(gang_size) * (gang_loyalty / 100.0)

func gang_scheme_bonus() -> float:
	return clampf(gang_power() * 0.01, 0.0, 0.20)   # до +0.20 к шансу дел

func gang_upkeep_daily() -> float:
	return float(gang_size) * GANG_UPKEEP

func recruit_gang(n: int) -> bool:
	if n <= 0 or gang_size + n > max_gang() or is_imprisoned():
		return false
	var gm := get_node_or_null("/root/GameManager")
	if gm == null or not gm.spend_money(GANG_HIRE_COST * n):
		return false
	gang_size += n
	emit_signal("crime_changed")
	return true

func disband_gang(n: int) -> void:
	gang_size = maxi(0, gang_size - n)
	emit_signal("crime_changed")

# Содержание банды (вызывается раз в день): платишь — лояльны, нет — недовольство.
const LT_UPKEEP := 20000.0   # содержание бригадира в день

func _process_gang_day() -> void:
	if gang_size <= 0 and lieutenants.is_empty():
		return
	var gm := get_node_or_null("/root/GameManager")
	var upkeep: float = gang_upkeep_daily() + float(lieutenants.size()) * LT_UPKEEP
	var paid: bool = gm != null and gm.spend_money(upkeep)
	if paid:
		if gang_size > 0:
			gang_loyalty = clampf(gang_loyalty + 1.0 + rank_loyalty_bonus(), 0.0, 100.0)
		for lt in lieutenants:
			lt["loyalty"] = clampf(float(lt.loyalty) + 1.0 + rank_loyalty_bonus(), 0.0, 100.0)
	else:
		if gang_size > 0:
			gang_loyalty = clampf(gang_loyalty - 12.0, 0.0, 100.0)
			if gang_loyalty <= 0.0:
				gang_size = maxi(0, gang_size - 1)   # дезертирство рядового
				gang_loyalty = 30.0
		# Недовольные бригадиры теряют лояльность, при нуле уходят
		var keep: Array = []
		for lt in lieutenants:
			lt["loyalty"] = clampf(float(lt.loyalty) - 10.0, 0.0, 100.0)
			if float(lt.loyalty) > 0.0:
				keep.append(lt)
		lieutenants = keep
	emit_signal("crime_changed")

# ── Коррупция и иммунитет ─────────────────────────────────────────────────────
# Взятки ментам сбивают розыск (дороже при высоком heat, дешевле со связями в
# полиции из ветки «Влияние»). «Крыша сверху» — оплаченный иммунитет на срок:
# розыск спадает быстрее.
var protection_days: int = 0
const BRIBE_COST_PER_HEAT := 25000.0
const PROTECTION_DAYS := 30

func police_connection() -> int:
	var inf := get_node_or_null("/root/InfluenceManager")
	return inf.connection_level("police") if inf and inf.has_method("connection_level") else 0

func bribe_cost_per_heat() -> float:
	var disc: float = maxf(0.40, 1.0 - 0.15 * float(police_connection()))   # связи — до −60%
	return BRIBE_COST_PER_HEAT * (1.0 + heat / 50.0) * disc

# Дать взятку: тратит чистые деньги, сбивает розыск. {ok, cooled, spent}
func bribe_police(amount: float) -> Dictionary:
	if amount <= 0.0 or heat <= 0.0:
		return {"ok": false, "reason": "нечего сбивать"}
	var gm := get_node_or_null("/root/GameManager")
	if gm == null:
		return {"ok": false, "reason": "нет денег"}
	var cph: float = bribe_cost_per_heat()
	var cooled: float = minf(heat, minf(amount, gm.money) / cph)
	var cost: float = cooled * cph
	if cooled <= 0.0 or not gm.spend_money(cost):
		return {"ok": false, "reason": "нет денег"}
	cool_heat(cooled)
	emit_signal("crime_changed")
	return {"ok": true, "cooled": cooled, "spent": cost}

func protection_cost() -> int:
	return int(2_000_000.0 * maxf(0.50, 1.0 - 0.10 * float(police_connection())))

func has_protection() -> bool:
	return protection_days > 0

# Купить «крышу сверху»: +30 дней иммунитета (розыск спадает быстрее).
func buy_protection() -> bool:
	var gm := get_node_or_null("/root/GameManager")
	if gm == null or not gm.spend_money(protection_cost()):
		return false
	protection_days += PROTECTION_DAYS
	emit_signal("crime_changed")
	return true

# ── Рэкет / «крыша» ───────────────────────────────────────────────────────────
# Берёшь точки под крышу: каждая даёт ежедневный грязный доход, но постоянно
# держит розыск повышенным. Число точек ограничено авторитетом; «наезд» может
# сорваться (шумит и поднимает розыск).
const RACKET_TARGETS := [
	{"id":"kiosk",   "name":"Ларёк",          "icon":"🏪", "min_rep":5,  "income":12000.0,  "heat":1.0},
	{"id":"market",  "name":"Рынок",          "icon":"🛒", "min_rep":15, "income":35000.0,  "heat":1.5},
	{"id":"cafe",    "name":"Кафе",           "icon":"☕", "min_rep":25, "income":70000.0,  "heat":2.0},
	{"id":"service", "name":"Автосервис",     "icon":"🔧", "min_rep":35, "income":130000.0, "heat":2.5},
	{"id":"club",    "name":"Ночной клуб",    "icon":"🎰", "min_rep":50, "income":300000.0, "heat":3.5},
	{"id":"mall",    "name":"Торговый центр",  "icon":"🏬", "min_rep":70, "income":700000.0, "heat":5.0},
]
var rackets: Array = []   # id точек под крышей

func racket_target(id: String) -> Dictionary:
	for t in RACKET_TARGETS:
		if t.id == id:
			return t
	return {}

func is_racket_held(id: String) -> bool:
	return rackets.has(id)

func max_rackets() -> int:
	# авторитет + сила банды расширяют «зону влияния»
	return 1 + int(criminal_rep / 18.0) + int(gang_power() / 4.0)

func racket_claim_chance(id: String) -> float:
	return clampf(0.50 + criminal_rep / 200.0, 0.30, 0.90)

# «Наезд» на точку. {ok, success, reason}
func claim_racket(id: String) -> Dictionary:
	if is_imprisoned():
		return {"ok": false, "reason": "ты в тюрьме"}
	var t := racket_target(id)
	if t.is_empty() or is_racket_held(id):
		return {"ok": false, "reason": "недоступно"}
	if criminal_rep < float(t.min_rep):
		return {"ok": false, "reason": "мало авторитета"}
	if rackets.size() >= max_rackets():
		return {"ok": false, "reason": "зона влияния заполнена"}
	var win: bool = randf() < racket_claim_chance(id)
	if win:
		rackets.append(id)
		add_criminal_rep(2.0)
		add_heat(float(t.heat) * 2.0)   # наезд шумит
		emit_signal("crime_changed")
		return {"ok": true, "success": true}
	else:
		add_heat(float(t.heat) * 4.0)   # сорванный наезд — много шума
		emit_signal("crime_changed")
		return {"ok": true, "success": false}

func drop_racket(id: String) -> void:
	rackets.erase(id)
	emit_signal("crime_changed")

func racket_income_total() -> float:
	var total: float = 0.0
	for id in rackets:
		total += float(racket_target(id).get("income", 0.0))
	return total

func racket_heat_total() -> float:
	var total: float = 0.0
	for id in rackets:
		total += float(racket_target(id).get("heat", 0.0))
	return total

# ── Отмыв денег ───────────────────────────────────────────────────────────────
# Грязный нал нельзя тратить открыто: прогоняешь через бизнесы-«прачечные» с
# комиссией. Чем больше своих бизнесов — тем выше дневной лимит и ниже комиссия.
var laundered_today: float = 0.0
const LAUNDER_BASE_CAP := 50000.0     # сколько можно отмыть без прикрытия в день
const LAUNDER_PER_FRONT := 250000.0   # +лимит за каждый бизнес-прачечную

func front_count() -> int:
	var bm := get_node_or_null("/root/BusinessManager")
	return bm.business_count() if bm and bm.has_method("business_count") else 0

func laundering_capacity() -> float:
	return LAUNDER_BASE_CAP + float(front_count()) * LAUNDER_PER_FRONT

func laundering_fee() -> float:
	# больше прачечных — дешевле отмыв (0.30 → 0.10)
	return clampf(0.30 - float(front_count()) * 0.04, 0.10, 0.35)

func launder_left_today() -> float:
	return maxf(0.0, laundering_capacity() - laundered_today)

# Отмыть сумму грязных денег → чистые (минус комиссия). {ok, laundered, received, fee}
func launder(amount: float) -> Dictionary:
	var amt: float = clampf(amount, 0.0, minf(dirty_money, launder_left_today()))
	if amt <= 0.0:
		return {"ok": false, "reason": "нет грязных денег или исчерпан дневной лимит"}
	var fee: float = laundering_fee()
	var clean: float = amt * (1.0 - fee)
	dirty_money -= amt
	laundered_today += amt
	var gm := get_node_or_null("/root/GameManager")
	if gm: gm.add_money(clean)
	add_heat(amt / 1_000_000.0 * 2.0)   # финансовый след
	emit_signal("crime_changed")
	return {"ok": true, "laundered": amt, "received": clean, "fee": fee}

# ── Тёмные дела (схемы) ───────────────────────────────────────────────────────
# Операции с риском: успех даёт грязный нал и авторитет, провал шумит (лишний
# розыск). Каждое дело тратит энергию и требует определённого авторитета. Шанс
# успеха растёт с авторитетом.
const SCHEMES := [
	{"id":"pickpocket","name":"Карманная кража",       "icon":"👛", "min_rep":0,  "payout":8000,    "heat":4.0,  "chance":0.80, "energy":8.0},
	{"id":"scam",      "name":"Развод на деньги",       "icon":"🎭", "min_rep":5,  "payout":25000,   "heat":6.0,  "chance":0.70, "energy":10.0},
	{"id":"robbery",   "name":"Уличный грабёж",         "icon":"🦹", "min_rep":15, "payout":60000,   "heat":10.0, "chance":0.62, "energy":14.0},
	{"id":"carjack",   "name":"Угон авто",              "icon":"🚗", "min_rep":25, "payout":150000,  "heat":14.0, "chance":0.55, "energy":16.0},
	{"id":"burglary",  "name":"Квартирная кража",       "icon":"🏚", "min_rep":35, "payout":350000,  "heat":18.0, "chance":0.50, "energy":18.0},
	{"id":"heist",     "name":"Налёт на инкассатора",   "icon":"💰", "min_rep":55, "payout":1500000, "heat":30.0, "chance":0.40, "energy":25.0},
]

func scheme(id: String) -> Dictionary:
	for s in SCHEMES:
		if s.id == id:
			return s
	return {}

func scheme_chance(id: String) -> float:
	var s := scheme(id)
	if s.is_empty():
		return 0.0
	# Авторитет (до +0.33), банда (до +0.20) и бригадир по делам повышают шанс
	return clampf(float(s.chance) + criminal_rep / 300.0 + gang_scheme_bonus() + lieutenant_bonus("schemes"), 0.05, 0.95)

func can_attempt(id: String) -> bool:
	var s := scheme(id)
	if s.is_empty() or criminal_rep < float(s.min_rep):
		return false
	var gm := get_node_or_null("/root/GameManager")
	return gm != null and gm.energy >= float(s.energy)

# Провернуть дело. Возвращает {ok, success, amount, reason}.
func attempt_scheme(id: String) -> Dictionary:
	if is_imprisoned():
		return {"ok": false, "reason": "ты в тюрьме"}
	var s := scheme(id)
	if s.is_empty():
		return {"ok": false, "reason": "нет такого дела"}
	if criminal_rep < float(s.min_rep):
		return {"ok": false, "reason": "мало авторитета"}
	var gm := get_node_or_null("/root/GameManager")
	if gm == null or gm.energy < float(s.energy):
		return {"ok": false, "reason": "нет сил"}
	gm.energy = clampf(gm.energy - float(s.energy), 0.0, gm.stat_max())
	gm.emit_signal("energy_changed", gm.energy)
	var win: bool = randf() < scheme_chance(id)
	# Провал шумит сильнее — внимание полиции
	add_heat(float(s.heat) * (1.0 if win else 1.6))
	if win:
		add_dirty_money(float(s.payout))
		add_criminal_rep(clampf(float(s.min_rep) * 0.1 + 2.0, 2.0, 8.0))
		return {"ok": true, "success": true, "amount": int(s.payout)}
	else:
		add_criminal_rep(0.5)   # опыт даже при провале
		return {"ok": true, "success": false, "amount": 0}

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

# Перки ранга: авторитет на улице конвертируется в реальную силу.
const RANK_PERKS := [
	"—",
	"доступ к тёмным делам и крыше",
	"+теневой доход, набор банды",
	"крупная банда, уважение улиц",
	"вор в законе: макс. доход, верная банда, розыск тает",
]

func rank_perk_text() -> String:
	return RANK_PERKS[clampi(rank(), 0, RANK_PERKS.size() - 1)]

func rank_income_mult() -> float:
	return 1.0 + float(rank()) * 0.08   # до ×1.32 теневому доходу

func rank_heat_resist() -> float:
	return float(rank()) * 0.5          # уважение/связи ускоряют спад розыска

func rank_loyalty_bonus() -> float:
	return float(rank()) * 1.5          # авторитет держит банду верной

# Подпись уровня розыска для UI: чем выше — тем опаснее
func heat_label() -> Dictionary:
	if heat >= 80.0:   return {"name": "Облава близко", "color": Color(0.95, 0.30, 0.30)}
	elif heat >= 50.0: return {"name": "В разработке",  "color": Color(0.95, 0.55, 0.30)}
	elif heat >= 20.0: return {"name": "Под наблюдением","color": Color(0.90, 0.80, 0.40)}
	else:              return {"name": "Спокойно",       "color": Color(0.55, 0.80, 0.55)}

# ── Полиция: розыск, облавы ───────────────────────────────────────────────────
# При высоком розыске полиция приходит с обыском: изъятие контрабанды и части
# грязных денег, прикрытие точки/района, а при экстремальном heat — арест.
# Связь с полицией («Влияние»), «крыша сверху» и сильная банда снижают риск.
func raid_risk() -> float:
	if heat < 40.0:
		return 0.0
	var base: float = clampf((heat - 40.0) / 60.0 * 0.5, 0.0, 0.5)
	if has_protection():
		base *= 0.4
	base *= maxf(0.5, 1.0 - gang_power() * 0.01)   # банда отбивается
	var inf := get_node_or_null("/root/InfluenceManager")
	var pol: float = inf.police_raid_mult() if inf and inf.has_method("police_raid_mult") else 1.0
	return clampf(base * pol, 0.0, 0.9)

func _do_raid() -> Dictionary:
	var pre_heat: float = heat
	var info: Dictionary = {"contraband": not bm_inventory.is_empty()}
	bm_inventory = {}                       # контрабанду изъяли
	var seized: float = dirty_money * 0.4   # часть грязных денег изъята
	dirty_money -= seized
	info["cash"] = seized
	if not rackets.is_empty():
		info["lost"] = rackets.pop_back()   # прикрыли точку
	elif not controlled_zones.is_empty():
		info["lost_zone"] = controlled_zones.pop_back()
	heat = clampf(heat * 0.5, 0.0, 100.0)   # после рейда внимание частично спадает
	# Публичная облава бьёт по легальной репутации и нервам
	var rm := get_node_or_null("/root/ReputationManager")
	if rm and rm.has_method("add"):
		rm.add(-5)
	var life := get_node_or_null("/root/LifeManager")
	if life and life.has_method("add_stress"):
		life.add_stress(8.0)
	# Арест при экстремальном розыске → срок
	if pre_heat >= 80.0 and randf() < 0.5:
		info["arrested"] = true
		go_to_prison()
		if life and life.has_method("add_stress"):
			life.add_stress(20.0)   # арест — сильнейший стресс
	# Уведомление игроку (облава могла случиться при закрытом экране)
	var es := get_node_or_null("/root/EventSystem")
	if es and es.has_signal("event_triggered"):
		var txt: String = "🚓 Тебя взяли с поличным! Назначен срок." if info.get("arrested", false) \
			else "🚨 Облава! Изъято %s грязными." % _fmt(seized)
		es.event_triggered.emit({"text": txt, "money": 0, "health": 0})
	emit_signal("heat_changed", heat)
	emit_signal("raided", info)
	emit_signal("crime_changed")
	return info

func _fmt(v: float) -> String:
	var gm := get_node_or_null("/root/GameManager")
	return gm.format_money(v) if gm and gm.has_method("format_money") else str(int(v))

func _process_police_day() -> void:
	if randf() < raid_risk():
		_do_raid()

# ── Тюрьма ────────────────────────────────────────────────────────────────────
# Арест → срок: дни идут, активный криминал заблокирован. Профессия «Юрист» и
# связи смягчают срок; можно выйти под залог. Отсидка снимает розыск.
func is_imprisoned() -> bool:
	return prison_days > 0

func lawyer_mitigation() -> float:
	var m: float = 0.0
	var pm := get_node_or_null("/root/ProfessionManager")
	if pm and pm.profession == "lawyer":
		m += 0.40                     # сам юрист защищается
	var inf := get_node_or_null("/root/InfluenceManager")
	if inf and inf.has_method("connection_level"):
		m += 0.08 * float(inf.connection_level("mayor"))   # связи в верхах
	return clampf(m, 0.0, 0.70)

func sentence_length() -> int:
	var base: float = 10.0 + criminal_rep / 5.0   # авторитетных судят строже
	return maxi(1, int(base * (1.0 - lawyer_mitigation())))

func go_to_prison() -> void:
	prison_days = sentence_length()
	heat = clampf(heat * 0.3, 0.0, 100.0)   # отсидка снимает розыск
	emit_signal("busted")
	emit_signal("crime_changed")

func bail_cost() -> int:
	return prison_days * 500000   # залог за каждый оставшийся день

func post_bail() -> bool:
	if prison_days <= 0:
		return false
	var gm := get_node_or_null("/root/GameManager")
	if gm == null or not gm.spend_money(bail_cost()):
		return false
	prison_days = 0
	emit_signal("crime_changed")
	return true

func _process_prison_day() -> void:
	if prison_days > 0:
		prison_days -= 1
		if prison_days == 0:
			emit_signal("crime_changed")

# Суточная обработка: розыск медленно спадает (связи/взятки усилят спад позже).
func process_day() -> void:
	_process_prison_day() # идёт срок
	_process_gang_day()   # содержание банды и лояльность
	# Доход с точек под крышей и контролируемых районов (грязным, × ранг) + розыск
	var inc_mult: float = rank_income_mult()
	if not rackets.is_empty():
		add_dirty_money(racket_income_total() * inc_mult * (1.0 + lieutenant_bonus("racket")))
		add_heat(racket_heat_total())
	if not controlled_zones.is_empty():
		add_dirty_money(turf_income_total() * inc_mult)
		add_heat(turf_heat_total())
	# Спад розыска: база + сопротивление ранга; «крыша сверху» ускоряет ещё
	var decay: float = HEAT_DECAY + rank_heat_resist()
	if protection_days > 0:
		protection_days -= 1
		decay += HEAT_DECAY * 2.0
	if heat > 0.0:
		heat = clampf(heat - decay, 0.0, 100.0)
		emit_signal("heat_changed", heat)
	bm_fluctuate()        # цены чёрного рынка колеблются
	laundered_today = 0.0 # дневной лимит отмыва обновляется
	if not is_imprisoned():
		_process_police_day()   # риск облавы (не трогают того, кто уже сидит)

func save(cfg: ConfigFile) -> void:
	cfg.set_value("crime", "heat", heat)
	cfg.set_value("crime", "criminal_rep", criminal_rep)
	cfg.set_value("crime", "dirty_money", dirty_money)
	cfg.set_value("crime", "bm_prices", bm_prices)
	cfg.set_value("crime", "bm_inventory", bm_inventory)
	cfg.set_value("crime", "laundered_today", laundered_today)
	cfg.set_value("crime", "rackets", rackets)
	cfg.set_value("crime", "protection_days", protection_days)
	cfg.set_value("crime", "gang_size", gang_size)
	cfg.set_value("crime", "gang_loyalty", gang_loyalty)
	cfg.set_value("crime", "lieutenants", lieutenants)
	cfg.set_value("crime", "controlled_zones", controlled_zones)
	cfg.set_value("crime", "prison_days", prison_days)

func load_data(cfg: ConfigFile) -> void:
	heat = cfg.get_value("crime", "heat", 0.0)
	criminal_rep = cfg.get_value("crime", "criminal_rep", 0.0)
	dirty_money = cfg.get_value("crime", "dirty_money", 0.0)
	bm_prices = cfg.get_value("crime", "bm_prices", {})
	bm_inventory = cfg.get_value("crime", "bm_inventory", {})
	laundered_today = cfg.get_value("crime", "laundered_today", 0.0)
	rackets = cfg.get_value("crime", "rackets", [])
	protection_days = cfg.get_value("crime", "protection_days", 0)
	gang_size = cfg.get_value("crime", "gang_size", 0)
	gang_loyalty = cfg.get_value("crime", "gang_loyalty", 100.0)
	lieutenants = cfg.get_value("crime", "lieutenants", [])
	controlled_zones = cfg.get_value("crime", "controlled_zones", [])
	prison_days = cfg.get_value("crime", "prison_days", 0)
	_init_bm_prices()

func reset() -> void:
	heat = 0.0
	criminal_rep = 0.0
	dirty_money = 0.0
	bm_inventory = {}
	bm_prices = {}
	laundered_today = 0.0
	rackets = []
	protection_days = 0
	gang_size = 0
	gang_loyalty = 100.0
	lieutenants = []
	controlled_zones = []
	prison_days = 0
	_init_bm_prices()
