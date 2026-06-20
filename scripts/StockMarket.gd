extends Node

signal prices_changed
signal market_event_triggered(ev_name: String, ev_desc: String, is_positive: bool)
signal dividend_paid(stock_id: String, amount: float)

const STOCKS := [
	{"id":"gazp", "name":"ГазПром",     "icon":"⛽", "base":120.0,  "volatility":0.08, "trend": 0.002, "sector":"energy",  "div_yield":0.040},
	{"id":"sber", "name":"СберБанк",    "icon":"🏦", "base":280.0,  "volatility":0.06, "trend": 0.001, "sector":"finance", "div_yield":0.060},
	{"id":"luks", "name":"ЛукОйл",      "icon":"🛢", "base":6500.0, "volatility":0.10, "trend": 0.003, "sector":"energy",  "div_yield":0.050},
	{"id":"yand", "name":"Яндекс",      "icon":"🔍", "base":3200.0, "volatility":0.14, "trend": 0.005, "sector":"tech",    "div_yield":0.000},
	{"id":"kryp", "name":"КриптоРубль", "icon":"₿",  "base":50.0,   "volatility":0.25, "trend": 0.000, "sector":"crypto",  "div_yield":0.000},
]

const MARKET_EVENTS := [
	{"id":"oil_boom",    "name":"🛢 Нефтяной бум",         "desc":"Цены на нефть взлетели!",                      "sector":"energy",  "mult":1.18, "pos":true,  "days":3},
	{"id":"oil_crash",   "name":"🛢 Обвал нефти",           "desc":"Санкции ударили по нефтяному сектору.",         "sector":"energy",  "mult":0.82, "pos":false, "days":2},
	{"id":"bank_crisis", "name":"🏦 Банковский кризис",     "desc":"Вкладчики массово снимают средства.",           "sector":"finance", "mult":0.85, "pos":false, "days":2},
	{"id":"bank_rally",  "name":"🏦 Банковский бум",        "desc":"ЦБ снизил ключевую ставку — акции банков растут.","sector":"finance","mult":1.12, "pos":true,  "days":3},
	{"id":"tech_rally",  "name":"💻 Технологический рост",  "desc":"Иностранные инвесторы вернулись в IT.",         "sector":"tech",   "mult":1.22, "pos":true,  "days":3},
	{"id":"tech_crash",  "name":"💻 IT-крах",               "desc":"Регулятор ограничил технологические компании.", "sector":"tech",   "mult":0.80, "pos":false, "days":2},
	{"id":"crypto_pump", "name":"₿ Крипто-ажиотаж",         "desc":"Инфлюенсеры разогнали рынок криптовалют.",     "sector":"crypto", "mult":1.55, "pos":true,  "days":1},
	{"id":"crypto_dump", "name":"₿ Крипто-обвал",           "desc":"Регулятор запретил операции с криптой.",        "sector":"crypto", "mult":0.50, "pos":false, "days":1},
	{"id":"bull_market", "name":"📈 Бычий рынок",           "desc":"Общий подъём: инвесторы оптимистичны!",        "sector":"all",    "mult":1.08, "pos":true,  "days":4},
	{"id":"bear_market", "name":"📉 Медвежий рынок",        "desc":"Инвесторы в панике распродают активы.",        "sector":"all",    "mult":0.91, "pos":false, "days":3},
	{"id":"ipo_boom",    "name":"🚀 IPO-ажиотаж",           "desc":"Успешный выход новой компании поднял всех.",   "sector":"all",    "mult":1.06, "pos":true,  "days":2},
]

var prices:       Dictionary = {}  # id → float
var owned:        Dictionary = {}  # id → int
var history:      Dictionary = {}  # id → Array[float] (last 30)
var cost_basis:   Dictionary = {}  # id → avg buy price float
var daily_change: Dictionary = {}  # id → float (0.05 = +5%)
var active_event: Dictionary = {}  # current event or {}
var event_days_left: int = 0
var _day_counter: int = 0

func _ready() -> void:
	for s in STOCKS:
		prices[s.id]       = s.base
		owned[s.id]        = 0
		history[s.id]      = [s.base]
		cost_basis[s.id]   = 0.0
		daily_change[s.id] = 0.0
	get_node("/root/GameManager").day_changed.connect(_on_day)

func _on_day(_d: int) -> void:
	_day_counter += 1
	_tick_event()
	_update_prices()
	if _day_counter % 7 == 0:
		_pay_dividends()

func _tick_event() -> void:
	if event_days_left > 0:
		event_days_left -= 1
		if event_days_left == 0:
			active_event = {}
	elif randf() < 0.18:
		var ev: Dictionary = MARKET_EVENTS[randi() % MARKET_EVENTS.size()]
		active_event = ev.duplicate()
		event_days_left = ev.days
		market_event_triggered.emit(ev.name, ev.desc, ev.pos)

func _update_prices() -> void:
	for s in STOCKS:
		var old: float = prices[s.id]

		# Базовое случайное движение + тренд
		var change: float = randf_range(-s.volatility, s.volatility) + s.trend

		# Секторная корреляция: нефтяные акции движутся вместе
		if s.sector == "energy":
			var gazp_chg: float = daily_change.get("gazp", 0.0)
			if s.id != "gazp" and absf(gazp_chg) > 0.01:
				change += gazp_chg * 0.45  # частичная корреляция

		# Активное событие влияет на соответствующий сектор
		if not active_event.is_empty():
			var matches: bool = active_event.sector == s.sector or active_event.sector == "all"
			if matches:
				var effect: float = (active_event.mult - 1.0) * randf_range(0.55, 1.0)
				change += effect

		var new_price: float = maxf(old * (1.0 + change), 1.0)
		new_price = snappedf(new_price, 0.01)
		daily_change[s.id] = (new_price - old) / old
		prices[s.id] = new_price
		history[s.id].append(new_price)
		if history[s.id].size() > 30:
			history[s.id].pop_front()

	prices_changed.emit()

func _pay_dividends() -> void:
	var gm := get_node("/root/GameManager")
	for s in STOCKS:
		if s.div_yield <= 0.0 or owned[s.id] <= 0:
			continue
		# Недельный дивиденд = годовая доходность / 52
		var amount: float = prices[s.id] * owned[s.id] * (s.div_yield / 52.0)
		amount = snappedf(amount, 0.01)
		if amount >= 0.01:
			gm.add_money(amount)
			dividend_paid.emit(s.id, amount)

func buy(stock_id: String, shares: int) -> bool:
	var gm := get_node("/root/GameManager")
	var cost: float = prices[stock_id] * shares
	if not gm.spend_money(cost):
		return false
	var prev: int = owned[stock_id]
	owned[stock_id] += shares
	# Обновляем среднюю цену покупки
	if prev == 0:
		cost_basis[stock_id] = prices[stock_id]
	else:
		cost_basis[stock_id] = (cost_basis[stock_id] * prev + cost) / owned[stock_id]
	return true

func sell(stock_id: String, shares: int) -> bool:
	if owned[stock_id] < shares:
		return false
	owned[stock_id] -= shares
	if owned[stock_id] == 0:
		cost_basis[stock_id] = 0.0
	get_node("/root/GameManager").add_money(prices[stock_id] * shares)
	return true

func sell_all(stock_id: String) -> bool:
	if owned[stock_id] <= 0:
		return false
	return sell(stock_id, owned[stock_id])

func get_portfolio_value() -> float:
	var total := 0.0
	for id in owned:
		total += owned[id] * prices[id]
	return total

func get_total_invested() -> float:
	var total := 0.0
	for id in owned:
		total += cost_basis[id] * owned[id]
	return total

func get_stock(stock_id: String) -> Dictionary:
	for s in STOCKS:
		if s.id == stock_id:
			return s
	return {}

func save(cfg: ConfigFile) -> void:
	cfg.set_value("stocks", "owned",       owned)
	cfg.set_value("stocks", "prices",      prices)
	cfg.set_value("stocks", "history",     history)
	cfg.set_value("stocks", "cost_basis",  cost_basis)
	cfg.set_value("stocks", "day_counter", _day_counter)

func load(cfg: ConfigFile) -> void:
	owned        = cfg.get_value("stocks", "owned",       owned)
	prices       = cfg.get_value("stocks", "prices",      prices)
	history      = cfg.get_value("stocks", "history",     history)
	cost_basis   = cfg.get_value("stocks", "cost_basis",  cost_basis)
	_day_counter = cfg.get_value("stocks", "day_counter", 0)
	for s in STOCKS:
		if not daily_change.has(s.id):
			daily_change[s.id] = 0.0
