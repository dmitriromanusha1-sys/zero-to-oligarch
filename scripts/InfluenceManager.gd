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

# ── Контроль районов и выборы (Фаза 4) ────────────────────────────────────────
# Выдвигаешься в районе: платишь деньги+влияние, шанс победы зависит от
# репутации, охвата СМИ и связей. Контроль района даёт пассив и бонус к доходу.
var districts: Dictionary = {}      # index -> true (под контролем игрока)
var election_cd: Dictionary = {}    # index -> дней до повторного выдвижения

const ELECTION_INF_BASE: float = 50.0
const ELECTION_INF_PER: float = 20.0
const ELECTION_MONEY_BASE: int = 10_000_000
const ELECTION_COOLDOWN: int = 30
const DISTRICT_INF_DAY: float = 2.0          # пассивное влияние за район/день
const DISTRICT_INCOME_STEP: float = 0.02     # +2% к доходу бизнеса за район
const DISTRICT_INCOME_MAX: float = 0.20
const DISTRICT_LOSE_BASE: float = 0.08       # месячный риск потерять район

# ── Высшая власть и риски (Фаза 5) ────────────────────────────────────────────
# Власть притягивает подозрение в коррупции. Накапливается от лоббизма, компромата
# и удержания районов; раз в месяц — риск антикоррупционного расследования.
# СМИ маскируют, «замятие» сбивает жар. Вершина — титул «Серый кардинал».
var corruption_heat: float = 0.0
var grey_cardinal: bool = false              # достигнут ли эндгейм-титул

const HEAT_MAX: float = 1.5
const LAW_HEAT: float = 0.12
const SMEAR_HEAT: float = 0.15
const ELECTION_HEAT: float = 0.10
const COVERUP_INF: float = 120.0
const COVERUP_MONEY: int = 20_000_000
const COVERUP_COOLDOWN: int = 20
const COVERUP_REDUCE: float = 0.55           # «замятие» срезает жар на 55%

const GC_DISTRICTS: int = 6                  # условия титула «Серый кардинал»

# ── Спецслужбы и компромат-досье (Фаза 6) ─────────────────────────────────────
# Карманная «контора» ведёт слежку и копит ДОСЬЕ — компромат, который пускаешь
# в ход: шантаж и саботаж конкурентов или иммунитет от расследований.
var intel_level: int = 0                     # уровень спецслужбы 0..3
var dossiers: int = 0                        # готовые досье на руках
var surveillance: float = 0.0               # накопленный прогресс слежки (≥1 → +досье)
var intel_immunity_days: int = 0             # дней иммунитета от расследований

const INTEL_MAX_LEVEL: int = 3
const INTEL_MIN_TITLE: int = 6
const INTEL_COST_MONEY: Array = [30_000_000, 100_000_000, 300_000_000]  # за уровень 1..3
const INTEL_COST_INF: Array = [80, 200, 450]
const SURVEIL_PER_DAY: Array = [0.0, 0.04, 0.08, 0.14]   # прогресс/день по уровню
const DOSSIER_MAX: int = 5

const SURVEIL_INF: float = 40.0              # «заказать слежку» (ускоренно)
const SURVEIL_MONEY: int = 5_000_000
const SURVEIL_COOLDOWN: int = 10
const INTEL_OP_HEAT: float = 0.06            # нелегальные операции поднимают подозрение

const IMMUNITY_DOSSIERS: int = 2
const IMMUNITY_DAYS: int = 60
const SABOTAGE_POWER: float = 0.18           # саботаж сильнее обычного компромата

# ── Своя партия (Фаза 7) ──────────────────────────────────────────────────────
# Партия — легальная опора власти: члены растут со временем, идеология даёт бафф,
# партийная машина повышает шанс на выборах и даёт пассивное влияние.
var party_founded: bool = false
var party_members: float = 0.0
var party_ideology: String = ""              # "" пока не выбрана

const PARTY_MIN_TITLE: int = 6
const PARTY_FOUND_MONEY: int = 50_000_000
const PARTY_FOUND_INF: float = 150.0
const PARTY_RECRUIT_MONEY: int = 5_000_000
const PARTY_RECRUIT_MEMBERS: float = 2000.0
const PARTY_RECRUIT_COOLDOWN: int = 7
const PARTY_MEMBERS_PER_DAY: float = 50.0
const PARTY_STRENGTH_CAP: float = 100_000.0  # членов для максимальной силы
const PARTY_SWITCH_INF: float = 100.0        # смена идеологии стоит влияния

const IDEOLOGIES: Array = [
	{"id":"siloviki",    "name":"Силовики",    "icon":"🪖", "desc":"−40% риска антикоррупционного скандала."},
	{"id":"liberals",    "name":"Либералы",    "icon":"📈", "desc":"−15% налога на прибыль бизнеса."},
	{"id":"populists",   "name":"Популисты",   "icon":"📣", "desc":"−30% стоимости выборов."},
	{"id":"technocrats", "name":"Технократы",  "icon":"⚙", "desc":"+25% пассивного влияния."},
]

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
	corruption_heat = minf(HEAT_MAX, corruption_heat + LAW_HEAT)
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
	corruption_heat = minf(HEAT_MAX, corruption_heat + SMEAR_HEAT)
	campaign_cd["smear"] = SMEAR_COOLDOWN
	emit_signal("connections_changed")
	gm.save_game()
	return target

func _tick_campaigns() -> void:
	for id in campaign_cd.keys():
		var left: int = int(campaign_cd[id]) - 1
		if left <= 0: campaign_cd.erase(id)
		else: campaign_cd[id] = left

# ── Контроль районов и выборы ─────────────────────────────────────────────────
func _zm() -> Node:
	return get_node_or_null("/root/ZoneManager")

func district_count() -> int:
	var zm := _zm()
	return zm.ZONE_META.size() if zm else 9

func district_name(i: int) -> String:
	var zm := _zm()
	if zm and i >= 0 and i < zm.ZONE_META.size():
		return zm.ZONE_META[i].icon + " " + zm.ZONE_META[i].name
	return "Район %d" % (i + 1)

func controls(i: int) -> bool:
	return bool(districts.get(i, false))

func controlled_count() -> int:
	var n: int = 0
	for k in districts:
		if bool(districts[k]): n += 1
	return n

func power_level() -> int:
	return controlled_count()

func election_inf_cost(i: int) -> int:
	return int((ELECTION_INF_BASE + i * ELECTION_INF_PER) * ideology_election_cost_mult())

func election_money_cost(i: int) -> int:
	return int(ELECTION_MONEY_BASE * (i + 1) * ideology_election_cost_mult())

func election_cd_left(i: int) -> int:
	return int(election_cd.get(i, 0))

func district_difficulty(i: int) -> float:
	return clampf(0.10 + i * 0.05, 0.10, 0.55)

# Шанс победы на выборах: репутация + охват СМИ + связи − сложность района.
func election_win_chance(i: int) -> float:
	var rm := get_node_or_null("/root/ReputationManager")
	var rep: float = (float(rm.reputation) / 100.0) if rm else 0.3
	var power: float = 0.15 + media_reach() * 0.03 + rep * 0.25 \
		+ connection_level("mayor") * 0.05 + controlled_count() * 0.03 + party_election_bonus()
	return clampf(power - district_difficulty(i), 0.05, 0.95)

func can_run_election(i: int) -> bool:
	if not politics_unlocked() or controls(i): return false
	if election_cd_left(i) > 0: return false
	return influence >= float(election_inf_cost(i)) and gm.money >= float(election_money_cost(i))

# Выдвижение: тратит ресурсы, бросает кубик. Победа → контроль района.
func run_election(i: int) -> bool:
	if not can_run_election(i): return false
	if not gm.spend_money(election_money_cost(i)): return false
	add_influence(-float(election_inf_cost(i)))
	var es := get_node_or_null("/root/EventSystem")
	var won: bool = randf() < election_win_chance(i)
	if won:
		districts[i] = true
		corruption_heat = minf(HEAT_MAX, corruption_heat + ELECTION_HEAT)
		if es:
			es.event_triggered.emit({
				"text": "🗳 Победа на выборах! Район «%s» под вашим контролем." % district_name(i),
				"money": 0, "health": 0})
	else:
		election_cd[i] = ELECTION_COOLDOWN
		if es:
			es.event_triggered.emit({
				"text": "🗳 Выборы в районе «%s» проиграны. Кампания впустую." % district_name(i),
				"money": 0, "health": 0})
	emit_signal("connections_changed")
	gm.save_game()
	return won

func _tick_elections() -> void:
	for i in election_cd.keys():
		var left: int = int(election_cd[i]) - 1
		if left <= 0: election_cd.erase(i)
		else: election_cd[i] = left

# Месячно: соперники могут отбить район при слабом удержании (мало СМИ).
func _maybe_lose_districts() -> void:
	var flip: float = maxf(0.0, DISTRICT_LOSE_BASE - media_reach() * 0.01)
	if flip <= 0.0: return
	var es := get_node_or_null("/root/EventSystem")
	for i in districts.keys():
		if bool(districts[i]) and randf() < flip:
			districts[i] = false
			if es:
				es.event_triggered.emit({
					"text": "🗳 Район «%s» перешёл под контроль соперников." % district_name(int(i)),
					"money": 0, "health": 0})

# Бонус к доходу бизнеса от контролируемых районов.
func district_income_mult() -> float:
	return 1.0 + minf(DISTRICT_INCOME_MAX, controlled_count() * DISTRICT_INCOME_STEP)

# Совокупный политический множитель дохода (лобби-субсидия × контроль районов).
func political_income_mult() -> float:
	return law_business_mult() * district_income_mult()

# ── Высшая власть и риски ─────────────────────────────────────────────────────
func scrutiny() -> float:
	return clampf(corruption_heat, 0.0, HEAT_MAX)

func media_shield() -> float:
	return media_reach() * 0.02   # охват СМИ маскирует подозрение

func investigation_chance() -> float:
	if has_immunity(): return 0.0
	return clampf((scrutiny() - media_shield()) * ideology_risk_mult(), 0.0, 0.90)

# Замять скандал: СМИ-машина хоронит историю, жар падает.
func can_coverup() -> bool:
	if campaign_cd_left("coverup") > 0: return false
	if corruption_heat <= 0.05: return false
	return influence >= COVERUP_INF and gm.money >= float(COVERUP_MONEY)

func coverup() -> bool:
	if not can_coverup(): return false
	if not gm.spend_money(COVERUP_MONEY): return false
	add_influence(-COVERUP_INF)
	corruption_heat = maxf(0.0, corruption_heat * (1.0 - COVERUP_REDUCE))
	campaign_cd["coverup"] = COVERUP_COOLDOWN
	emit_signal("connections_changed")
	gm.save_game()
	return true

# Месячно: накопление жара, риск расследования, затухание.
func _corruption_tick() -> void:
	corruption_heat = minf(HEAT_MAX, corruption_heat + controlled_count() * 0.02 + active_laws.size() * 0.03)
	if randf() < investigation_chance():
		_trigger_scandal()
	corruption_heat = maxf(0.0, corruption_heat * 0.88 - media_reach() * 0.005)

func _trigger_scandal() -> void:
	var sev: float = scrutiny()
	var es := get_node_or_null("/root/EventSystem")
	var fine: float = gm.money * minf(0.25, 0.10 * sev)
	if fine > 0.0:
		gm.add_money(-fine)
	add_influence(-influence * 0.30)
	var rm := get_node_or_null("/root/ReputationManager")
	if rm and rm.has_method("add"):
		rm.add(-int(round(8.0 * sev)))
	var lost_district: String = ""
	if controlled_count() > 0 and randf() < 0.4 * sev:
		for i in districts.keys():
			if bool(districts[i]):
				lost_district = district_name(int(i))
				districts[i] = false
				break
	corruption_heat *= 0.5
	if es:
		var txt: String = "⚖️ Антикоррупционный скандал! Штраф %s, влияние и репутация подорваны." % gm.format_money(fine)
		if lost_district != "":
			txt += " Потерян район «%s»." % lost_district
		es.event_triggered.emit({"text": txt, "money": -fine, "health": 0})
	emit_signal("connections_changed")

# ── Спецслужбы и компромат-досье ──────────────────────────────────────────────
func intel_active() -> bool:
	return intel_level > 0

func intel_next_money() -> int:
	if intel_level >= INTEL_MAX_LEVEL: return 0
	return int(INTEL_COST_MONEY[intel_level])

func intel_next_inf() -> int:
	if intel_level >= INTEL_MAX_LEVEL: return 0
	return int(INTEL_COST_INF[intel_level])

func can_upgrade_intel() -> bool:
	if not politics_unlocked() or gm.current_title_index < INTEL_MIN_TITLE: return false
	if intel_level >= INTEL_MAX_LEVEL: return false
	return influence >= float(intel_next_inf()) and gm.money >= float(intel_next_money())

func upgrade_intel() -> bool:
	if not can_upgrade_intel(): return false
	if not gm.spend_money(intel_next_money()): return false
	add_influence(-float(intel_next_inf()))
	intel_level += 1
	emit_signal("connections_changed")
	gm.save_game()
	return true

func surveillance_progress() -> float:
	return surveillance

func can_order_surveillance() -> bool:
	if not intel_active() or campaign_cd_left("surveil") > 0: return false
	if dossiers >= DOSSIER_MAX: return false
	return influence >= SURVEIL_INF and gm.money >= float(SURVEIL_MONEY)

func order_surveillance() -> bool:
	if not can_order_surveillance(): return false
	if not gm.spend_money(SURVEIL_MONEY): return false
	add_influence(-SURVEIL_INF)
	dossiers = mini(DOSSIER_MAX, dossiers + 1)
	corruption_heat = minf(HEAT_MAX, corruption_heat + INTEL_OP_HEAT)
	campaign_cd["surveil"] = SURVEIL_COOLDOWN
	emit_signal("connections_changed")
	gm.save_game()
	return true

# Шантаж: конкурент откупается деньгами и отдаёт часть доли (тратит 1 досье).
func can_blackmail() -> bool:
	if dossiers < 1: return false
	var bm := get_node_or_null("/root/BusinessManager")
	return bm != null and bm.has_method("intel_blackmail") and not bm.active_sectors().is_empty()

func blackmail() -> Dictionary:
	if not can_blackmail(): return {}
	var bm := get_node_or_null("/root/BusinessManager")
	var res: Dictionary = bm.intel_blackmail()
	if res.is_empty(): return {}
	dossiers -= 1
	corruption_heat = minf(HEAT_MAX, corruption_heat + INTEL_OP_HEAT)
	emit_signal("connections_changed")
	gm.save_game()
	return res

# Саботаж: жёстко обваливает долю крупнейшего конкурента (тратит 1 досье).
func can_sabotage() -> bool:
	if dossiers < 1: return false
	var bm := get_node_or_null("/root/BusinessManager")
	return bm != null and bm.has_method("media_smear_competitor") and not bm.active_sectors().is_empty()

func sabotage() -> String:
	if not can_sabotage(): return ""
	var bm := get_node_or_null("/root/BusinessManager")
	var target: String = bm.media_smear_competitor(SABOTAGE_POWER)
	if target == "": return ""
	dossiers -= 1
	corruption_heat = minf(HEAT_MAX, corruption_heat + INTEL_OP_HEAT)
	emit_signal("connections_changed")
	gm.save_game()
	return target

# Иммунитет: досье на следователя гасит подозрение и защищает от расследований.
func can_buy_immunity() -> bool:
	return dossiers >= IMMUNITY_DOSSIERS

func buy_immunity() -> bool:
	if not can_buy_immunity(): return false
	dossiers -= IMMUNITY_DOSSIERS
	corruption_heat = 0.0
	intel_immunity_days = IMMUNITY_DAYS
	emit_signal("connections_changed")
	gm.save_game()
	return true

func has_immunity() -> bool:
	return intel_immunity_days > 0

# Ежедневный прогресс слежки → новые досье.
func _intel_tick() -> void:
	if intel_active() and dossiers < DOSSIER_MAX:
		surveillance += float(SURVEIL_PER_DAY[intel_level])
		while surveillance >= 1.0 and dossiers < DOSSIER_MAX:
			surveillance -= 1.0
			dossiers += 1
	if intel_immunity_days > 0:
		intel_immunity_days -= 1

# ── Своя партия ───────────────────────────────────────────────────────────────
func can_found_party() -> bool:
	if party_founded or not politics_unlocked(): return false
	if gm.current_title_index < PARTY_MIN_TITLE: return false
	return influence >= PARTY_FOUND_INF and gm.money >= float(PARTY_FOUND_MONEY)

func found_party() -> bool:
	if not can_found_party(): return false
	if not gm.spend_money(PARTY_FOUND_MONEY): return false
	add_influence(-PARTY_FOUND_INF)
	party_founded = true
	party_members = PARTY_RECRUIT_MEMBERS
	emit_signal("connections_changed")
	gm.save_game()
	return true

func party_strength() -> float:
	return clampf(party_members / PARTY_STRENGTH_CAP, 0.0, 1.0)

func party_election_bonus() -> float:
	return party_strength() * 0.25 if party_founded else 0.0

func party_influence_day() -> float:
	return (party_members / 1000.0) * 0.5 if party_founded else 0.0

func can_recruit() -> bool:
	if not party_founded or campaign_cd_left("recruit") > 0: return false
	return gm.money >= float(PARTY_RECRUIT_MONEY)

func recruit() -> bool:
	if not can_recruit(): return false
	if not gm.spend_money(PARTY_RECRUIT_MONEY): return false
	party_members += PARTY_RECRUIT_MEMBERS
	campaign_cd["recruit"] = PARTY_RECRUIT_COOLDOWN
	emit_signal("connections_changed")
	gm.save_game()
	return true

func _ideology(id: String) -> Dictionary:
	for ig in IDEOLOGIES:
		if ig.id == id: return ig
	return {}

func ideology_switch_cost() -> float:
	return 0.0 if party_ideology == "" else PARTY_SWITCH_INF

func can_set_ideology(id: String) -> bool:
	if not party_founded or id == party_ideology: return false
	if _ideology(id).is_empty(): return false
	return influence >= ideology_switch_cost()

func set_ideology(id: String) -> bool:
	if not can_set_ideology(id): return false
	add_influence(-ideology_switch_cost())
	party_ideology = id
	emit_signal("connections_changed")
	gm.save_game()
	return true

# Баффы идеологии (читаются другими системами)
func ideology_risk_mult() -> float:
	return 0.6 if party_ideology == "siloviki" else 1.0

func ideology_tax_bonus() -> float:
	return 0.15 if party_ideology == "liberals" else 0.0

func ideology_election_cost_mult() -> float:
	return 0.70 if party_ideology == "populists" else 1.0

func ideology_influence_mult() -> float:
	return 1.25 if party_ideology == "technocrats" else 1.0

# Совокупный налоговый множитель: лобби-каникулы × скидки (связь + либералы).
func total_tax_mult() -> float:
	var disc: float = clampf(tax_discount() + ideology_tax_bonus(), 0.0, 0.6)
	return law_tax_mult() * (1.0 - disc)

func _party_tick() -> void:
	if not party_founded: return
	var rm := get_node_or_null("/root/ReputationManager")
	var rep_f: float = (0.5 + float(rm.reputation) / 100.0) if rm else 1.0
	var growth: float = (PARTY_MEMBERS_PER_DAY + media_reach() * 20.0 + controlled_count() * 30.0) * rep_f
	party_members += growth

# ── Ранг власти / эндгейм ─────────────────────────────────────────────────────
func power_score() -> int:
	return controlled_count() * 10 + total_connection_levels() * 4 + media_reach() * 2 \
		+ active_laws.size() * 2 + intel_level * 5 + int(party_strength() * 20.0)

func power_rank() -> String:
	var s: int = power_score()
	if grey_cardinal: return "Серый кардинал"
	if s >= 90: return "Теневой магнат"
	if s >= 45: return "Влиятельная фигура"
	if s >= 15: return "Игрок средней руки"
	return "Начинающий"

func max_connection_total() -> int:
	return MAX_CONNECTION_LEVEL * OFFICIALS.size()

func is_grey_cardinal() -> bool:
	return controlled_count() >= GC_DISTRICTS \
		and total_connection_levels() >= max_connection_total() \
		and owns_media("portal")

func _check_grey_cardinal() -> void:
	if grey_cardinal or not is_grey_cardinal():
		return
	grey_cardinal = true
	var es := get_node_or_null("/root/EventSystem")
	if es:
		es.event_triggered.emit({
			"text": "👑 Вы стали Серым кардиналом — теневым правителем города. Власть в ваших руках.",
			"money": 0, "health": 0})
	var achm := get_node_or_null("/root/AchievementManager")
	if achm and achm.has_method("unlock"):
		achm.unlock("grey_cardinal")

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

# Ежедневно: тикают законы/кампании/выборы; пассивное влияние (СМИ + машина + районы).
func process_day() -> void:
	_tick_laws()
	_tick_campaigns()
	_tick_elections()
	_intel_tick()
	_party_tick()
	if gm.day % 30 == 0:
		_maybe_lose_districts()
		_corruption_tick()
	var passive: float = media_influence_day()        # СМИ работают всегда
	passive += controlled_count() * DISTRICT_INF_DAY  # контроль районов
	passive += party_influence_day()                  # партийная машина
	if politics_unlocked():
		passive += total_connection_levels() * 0.2 + connection_level("mayor") * 0.5
	passive *= ideology_influence_mult()              # бафф технократов
	if passive > 0.0:
		add_influence(passive)
	_check_grey_cardinal()

func reset() -> void:
	influence = 0.0
	connections = {}
	active_laws = {}
	law_cooldowns = {}
	media_owned = {}
	campaign_cd = {}
	districts = {}
	election_cd = {}
	corruption_heat = 0.0
	grey_cardinal = false
	intel_level = 0
	dossiers = 0
	surveillance = 0.0
	intel_immunity_days = 0
	party_founded = false
	party_members = 0.0
	party_ideology = ""

func save(cfg: ConfigFile) -> void:
	cfg.set_value("influence", "value", influence)
	cfg.set_value("influence", "connections", connections)
	cfg.set_value("influence", "active_laws", active_laws)
	cfg.set_value("influence", "law_cooldowns", law_cooldowns)
	cfg.set_value("influence", "media_owned", media_owned)
	cfg.set_value("influence", "campaign_cd", campaign_cd)
	cfg.set_value("influence", "districts", districts)
	cfg.set_value("influence", "election_cd", election_cd)
	cfg.set_value("influence", "corruption_heat", corruption_heat)
	cfg.set_value("influence", "grey_cardinal", grey_cardinal)
	cfg.set_value("influence", "intel_level", intel_level)
	cfg.set_value("influence", "dossiers", dossiers)
	cfg.set_value("influence", "surveillance", surveillance)
	cfg.set_value("influence", "intel_immunity_days", intel_immunity_days)
	cfg.set_value("influence", "party_founded", party_founded)
	cfg.set_value("influence", "party_members", party_members)
	cfg.set_value("influence", "party_ideology", party_ideology)

func load_data(cfg: ConfigFile) -> void:
	influence = cfg.get_value("influence", "value", 0.0)
	connections = cfg.get_value("influence", "connections", {})
	active_laws = cfg.get_value("influence", "active_laws", {})
	law_cooldowns = cfg.get_value("influence", "law_cooldowns", {})
	media_owned = cfg.get_value("influence", "media_owned", {})
	campaign_cd = cfg.get_value("influence", "campaign_cd", {})
	districts = cfg.get_value("influence", "districts", {})
	election_cd = cfg.get_value("influence", "election_cd", {})
	corruption_heat = cfg.get_value("influence", "corruption_heat", 0.0)
	grey_cardinal = cfg.get_value("influence", "grey_cardinal", false)
	intel_level = cfg.get_value("influence", "intel_level", 0)
	dossiers = cfg.get_value("influence", "dossiers", 0)
	surveillance = cfg.get_value("influence", "surveillance", 0.0)
	intel_immunity_days = cfg.get_value("influence", "intel_immunity_days", 0)
	party_founded = cfg.get_value("influence", "party_founded", false)
	party_members = cfg.get_value("influence", "party_members", 0.0)
	party_ideology = cfg.get_value("influence", "party_ideology", "")
