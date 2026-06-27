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

# ── Лобби законов (Фаза 2) ────────────────────────────────────────────────────
# Тратишь влияние, чтобы временно продавить закон под себя. Закон действует
# `days` дней, потом уходит на «остывание» `cooldown`. Лоббизм бьёт по репутации.
const LAWS: Array = [
	{"id":"tax_break",     "name":"Налоговые каникулы",   "icon":"🧾", "inf":120, "money":5_000_000,  "days":30, "cooldown":60, "rep":-3, "desc":"−60% налога на прибыль бизнеса."},
	{"id":"subsidy",       "name":"Субсидия бизнесу",     "icon":"🏭", "inf":150, "money":10_000_000, "days":30, "cooldown":60, "rep":-2, "desc":"+25% к ежедневному доходу бизнеса."},
	{"id":"rate_freeze",   "name":"Заморозка ставки ЦБ",  "icon":"🏦", "inf":180, "money":0,          "days":40, "cooldown":80, "rep":-2, "desc":"Ставка по ипотеке не выше 8%."},
	{"id":"price_control", "name":"Госрегулирование цен", "icon":"🛒", "inf":140, "money":3_000_000,  "days":30, "cooldown":60, "rep":-3, "desc":"−15% стоимости жизни в городе."},
]

const RATE_FREEZE_CAP: float = 0.08

var active_laws: Dictionary = {}    # id -> осталось дней действия
var law_cooldowns: Dictionary = {}  # id -> осталось дней до повторного принятия

# ── Медиа-империя (Фаза 3) ────────────────────────────────────────────────────
# СМИ дают пассивное влияние и «охват» — силу PR/компромата. Покупаются один раз.
const MEDIA: Array = [
	{"id":"newspaper", "name":"Газета",           "icon":"📰", "cost":8_000_000,   "inf_day":3,  "reach":1, "min_title":5, "desc":"Городская газета — первый рупор."},
	{"id":"radio",     "name":"Радиохолдинг",     "icon":"📻", "cost":30_000_000,  "inf_day":7,  "reach":2, "min_title":6, "desc":"Эфир на весь город."},
	{"id":"tv",        "name":"Телеканал",        "icon":"📺", "cost":120_000_000, "inf_day":18, "reach":4, "min_title":6, "desc":"ТВ формирует повестку дня."},
	{"id":"portal",    "name":"Новостной портал", "icon":"🌐", "cost":400_000_000, "inf_day":45, "reach":7, "min_title":7, "desc":"Онлайн-СМИ №1 в стране."},
]

var media_owned: Dictionary = {}    # id -> true
var campaign_cd: Dictionary = {}    # id ("pr"/"smear") -> осталось дней до повтора

const PR_INF_COST: float = 60.0
const PR_COOLDOWN: int = 14
const PR_REP_BASE: int = 2          # +репутация = base + охват

const SMEAR_INF_COST: float = 100.0
const SMEAR_MONEY_COST: int = 5_000_000
const SMEAR_COOLDOWN: int = 21
const SMEAR_POWER_PER_REACH: float = 0.02   # перетянутая доля рынка = охват × это
const SMEAR_HEAT_PER_REACH: float = 0.05    # снижение антимонопольного жара

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

# ── Лобби законов ─────────────────────────────────────────────────────────────
func _law(id: String) -> Dictionary:
	for l in LAWS:
		if l.id == id: return l
	return {}

func law_active(id: String) -> bool:
	return int(active_laws.get(id, 0)) > 0

func law_days_left(id: String) -> int:
	return int(active_laws.get(id, 0))

func law_cooldown_left(id: String) -> int:
	return int(law_cooldowns.get(id, 0))

func can_pass_law(id: String) -> bool:
	if not politics_unlocked(): return false
	var l := _law(id)
	if l.is_empty(): return false
	if law_active(id) or law_cooldown_left(id) > 0: return false
	return influence >= float(l.inf) and gm.money >= float(l.money)

func pass_law(id: String) -> bool:
	if not can_pass_law(id): return false
	var l := _law(id)
	if not gm.spend_money(l.money): return false
	add_influence(-float(l.inf))
	active_laws[id] = int(l.days)
	var rm := get_node_or_null("/root/ReputationManager")
	if rm and rm.has_method("add"):
		rm.add(int(l.get("rep", 0)))
	emit_signal("connections_changed")
	gm.save_game()
	return true

func _tick_laws() -> void:
	var es := get_node_or_null("/root/EventSystem")
	for id in active_laws.keys():
		var left: int = int(active_laws[id]) - 1
		if left <= 0:
			active_laws.erase(id)
			var l := _law(id)
			law_cooldowns[id] = int(l.get("cooldown", 0))
			if es:
				es.event_triggered.emit({
					"text": "📜 Закон «%s» утратил силу." % l.get("name", "?"),
					"money": 0, "health": 0})
		else:
			active_laws[id] = left
	for id in law_cooldowns.keys():
		var cl: int = int(law_cooldowns[id]) - 1
		if cl <= 0: law_cooldowns.erase(id)
		else: law_cooldowns[id] = cl

# Эффекты активных законов (читаются другими системами)
func law_tax_mult() -> float:
	return 0.40 if law_active("tax_break") else 1.0

func law_business_mult() -> float:
	return 1.25 if law_active("subsidy") else 1.0

func law_rate_cap() -> float:
	return RATE_FREEZE_CAP if law_active("rate_freeze") else 1.0   # 1.0 = без ограничения

# ── Медиа-империя ─────────────────────────────────────────────────────────────
func _media(id: String) -> Dictionary:
	for m in MEDIA:
		if m.id == id: return m
	return {}

func owns_media(id: String) -> bool:
	return bool(media_owned.get(id, false))

func media_reach() -> int:
	var r: int = 0
	for m in MEDIA:
		if owns_media(m.id): r += int(m.reach)
	return r

func media_influence_day() -> float:
	var v: float = 0.0
	for m in MEDIA:
		if owns_media(m.id): v += float(m.inf_day)
	return v

func can_buy_media(id: String) -> bool:
	var m := _media(id)
	if m.is_empty() or owns_media(id): return false
	return gm.current_title_index >= int(m.min_title) and gm.money >= float(m.cost)

func buy_media(id: String) -> bool:
	var m := _media(id)
	if m.is_empty() or owns_media(id): return false
	if gm.current_title_index < int(m.min_title): return false
	if not gm.spend_money(m.cost): return false
	media_owned[id] = true
	emit_signal("connections_changed")
	gm.save_game()
	return true

func campaign_cd_left(id: String) -> int:
	return int(campaign_cd.get(id, 0))

# PR-кампания: поднимает репутацию, сила зависит от охвата СМИ.
func can_run_pr() -> bool:
	return media_reach() > 0 and campaign_cd_left("pr") == 0 and influence >= PR_INF_COST

func run_pr() -> int:
	if not can_run_pr(): return 0
	add_influence(-PR_INF_COST)
	var gain: int = PR_REP_BASE + media_reach()
	var rm := get_node_or_null("/root/ReputationManager")
	if rm and rm.has_method("add"): rm.add(gain)
	campaign_cd["pr"] = PR_COOLDOWN
	emit_signal("connections_changed")
	gm.save_game()
	return gain

# Компромат: бьёт по крупнейшему конкуренту и сбивает антимонопольный жар.
func can_run_smear() -> bool:
	if media_reach() <= 0 or campaign_cd_left("smear") > 0: return false
	if influence < SMEAR_INF_COST or gm.money < float(SMEAR_MONEY_COST): return false
	var bm := get_node_or_null("/root/BusinessManager")
	return bm != null and bm.has_method("media_smear_competitor")

func run_smear() -> String:
	if not can_run_smear(): return ""
	var bm := get_node_or_null("/root/BusinessManager")
	var target: String = bm.media_smear_competitor(media_reach() * SMEAR_POWER_PER_REACH)
	if target == "": return ""
	if not gm.spend_money(SMEAR_MONEY_COST): return ""
	add_influence(-SMEAR_INF_COST)
	if bm.has_method("media_reduce_heat"):
		bm.media_reduce_heat(media_reach() * SMEAR_HEAT_PER_REACH)
	campaign_cd["smear"] = SMEAR_COOLDOWN
	emit_signal("connections_changed")
	gm.save_game()
	return target

func _tick_campaigns() -> void:
	for id in campaign_cd.keys():
		var left: int = int(campaign_cd[id]) - 1
		if left <= 0: campaign_cd.erase(id)
		else: campaign_cd[id] = left

# ── Пассивные бонусы (читаются другими системами) ─────────────────────────────
func police_raid_mult() -> float:
	return maxf(0.0, 1.0 - 0.25 * connection_level("police"))   # до −75% шанса

func police_fine_mult() -> float:
	return maxf(0.0, 1.0 - 0.20 * connection_level("police"))   # до −60% штрафа

func tax_discount() -> float:
	return 0.05 * connection_level("tax")                       # до −15% налога

func expense_mult() -> float:
	var m: float = 1.0 - 0.04 * connection_level("mayor")        # до −12% (связь с мэром)
	if law_active("price_control"): m *= 0.85                    # −15% (госрегулирование цен)
	return maxf(0.0, m)

func deposit_bonus() -> float:
	return 0.005 * connection_level("banker")                  # до +1.5%/мес

# Ежедневно: тикают законы и кампании; пассивное влияние (СМИ + полит. машина).
func process_day() -> void:
	_tick_laws()
	_tick_campaigns()
	var passive: float = media_influence_day()        # СМИ работают всегда
	if politics_unlocked():
		passive += total_connection_levels() * 0.2 + connection_level("mayor") * 0.5
	if passive > 0.0:
		add_influence(passive)

func reset() -> void:
	influence = 0.0
	connections = {}
	active_laws = {}
	law_cooldowns = {}
	media_owned = {}
	campaign_cd = {}

func save(cfg: ConfigFile) -> void:
	cfg.set_value("influence", "value", influence)
	cfg.set_value("influence", "connections", connections)
	cfg.set_value("influence", "active_laws", active_laws)
	cfg.set_value("influence", "law_cooldowns", law_cooldowns)
	cfg.set_value("influence", "media_owned", media_owned)
	cfg.set_value("influence", "campaign_cd", campaign_cd)

func load_data(cfg: ConfigFile) -> void:
	influence = cfg.get_value("influence", "value", 0.0)
	connections = cfg.get_value("influence", "connections", {})
	active_laws = cfg.get_value("influence", "active_laws", {})
	law_cooldowns = cfg.get_value("influence", "law_cooldowns", {})
	media_owned = cfg.get_value("influence", "media_owned", {})
	campaign_cd = cfg.get_value("influence", "campaign_cd", {})
