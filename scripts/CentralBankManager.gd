extends Node

# Управляет ключевой ставкой ЦБ и инфляцией.
# Все ставки хранятся в % ГОДОВЫХ (0.08 = 8%/год).
# Потребители (BusinessManager, LoanManager) получают МЕСЯЧНЫЕ ставки через геттеры.

signal rate_changed(new_rate: float, old_rate: float)
signal inflation_changed(new_rate: float)

const KEY_RATE_MIN: float = 0.06   # 6%/год  — минимальная ключевая ставка
const KEY_RATE_MAX: float = 0.30   # 30%/год — максимальная ключевая ставка

const INFL_MIN: float = 0.02      # 2%/год  — минимальная инфляция
const INFL_MAX: float = 0.35      # 35%/год — максимальная инфляция

# Вклад = ключевая × 0.85 (банки всегда ниже ключевой)
const DEPOSIT_FACTOR: float = 0.85
# Спред кредита над ключевой ставкой (годовых)
const LOAN_SPREAD: float = 0.04

var key_rate: float = 0.16      # стартовая ключевая ставка: 16%/год (как в РФ 2024)
var inflation: float = 0.08     # стартовая инфляция: 8%/год
var price_index: float = 1.0    # накопленный индекс цен (1.0 = базовый уровень)
var wage_index: float = 1.0     # накопленный индекс зарплат (доход от работы)

# Экономический цикл: normal | boom | recession
var phase: String = "normal"
var phase_months_left: int = 0

# Насколько быстро растут зарплаты относительно инфляции в каждой фазе.
# В норме зарплаты чуть отстают от цен (мягкое давление), в рецессию почти
# замораживаются (цены растут — доход стоит), в бум обгоняют инфляцию.
const PHASE_WAGE_GROWTH := {"normal": 1.00, "boom": 1.35, "recession": 0.25}
# Дополнительная тяга инфляции в фазе (бум/спад разгоняют цены).
const PHASE_INFL_DRIFT  := {"normal": 0.0, "boom": 0.008, "recession": 0.012}

var _rng: RandomNumberGenerator = RandomNumberGenerator.new()

func _ready() -> void:
	_rng.randomize()

# ── Геттеры ──────────────────────────────────────────────────────────────────

# Месячная ставка вклада — для BusinessManager.process_day()
func get_deposit_rate() -> float:
	return (key_rate * DEPOSIT_FACTOR) / 12.0

# Месячная эффективная ставка кредита — для LoanManager._calc_monthly()
func get_effective_loan_rate(base_monthly: float) -> float:
	var min_monthly: float = (key_rate + LOAN_SPREAD) / 12.0
	return maxf(base_monthly, min_monthly)

# Годовая инфляция (0.08 = 8%)
func get_annual_inflation() -> float:
	return inflation

# Годовая ключевая ставка (0.16 = 16%)
func get_annual_key_rate() -> float:
	return key_rate

func format_annual(annual: float) -> String:
	return "%.1f%% /год  (≈%.2f%% /мес)" % [annual * 100.0, annual / 12.0 * 100.0]

func format_inflation() -> String:
	return "%.1f%% /год" % [inflation * 100.0]

func format_key_rate() -> String:
	return "%.1f%% /год" % [key_rate * 100.0]

# ── Геттеры экономики для игрока ──────────────────────────────────────────────

# Множитель потребительских цен (еда, лекарства, услуги, образование, транспорт)
func price_mult() -> float:
	return price_index

# Множитель дохода от работы (зарплаты)
func wage_mult() -> float:
	return wage_index

func is_recession() -> bool:
	return phase == "recession"

func is_boom() -> bool:
	return phase == "boom"

# Короткая метка фазы для UI
func phase_label() -> String:
	match phase:
		"boom":      return "📈 Экономический бум"
		"recession": return "📉 Рецессия"
		_:           return "⚖ Стабильность"

# ── Ежемесячная обработка ────────────────────────────────────────────────────

func process_month() -> void:
	var es: Node = get_node_or_null("/root/EventSystem")

	# 1. Обновляем накопленный индекс цен (годовую инфляцию делим на 12)
	price_index *= (1.0 + inflation / 12.0)

	# 1b. Индекс зарплат растёт медленнее/быстрее цен в зависимости от фазы
	var wage_growth: float = (inflation / 12.0) * (PHASE_WAGE_GROWTH.get(phase, 0.90) as float)
	wage_index *= (1.0 + wage_growth)

	# 1c. Смена фаз экономического цикла
	_update_phase(es)

	# 2. Случайное изменение инфляции с возвратом к целевым 7%/год
	#    Шок: ±1.2% годовых за месяц, плюс тяга к 7%, плюс разгон в фазе цикла
	var infl_shock: float = _rng.randf_range(-0.012, 0.015)
	infl_shock += (0.07 - inflation) * 0.12
	infl_shock += PHASE_INFL_DRIFT.get(phase, 0.0) as float
	var old_infl: float = inflation
	inflation = clampf(inflation + infl_shock, INFL_MIN, INFL_MAX)
	inflation = roundf(inflation * 200.0) / 200.0    # шаг 0.5%

	if absf(inflation - old_infl) >= 0.005:
		emit_signal("inflation_changed", inflation)
		if absf(inflation - old_infl) >= 0.02 and es:
			var trend: String = "растёт" if inflation > old_infl else "снижается"
			es.event_triggered.emit({
				"text": "📊 Инфляция %s: %.1f%%/год" % [trend, inflation * 100.0],
				"money": 0, "health": 0
			})

	# 3. ЦБ реагирует на инфляцию (годовые пороги)
	var rate_delta: float = 0.0
	if inflation > 0.20:
		# Высокая инфляция — агрессивное повышение
		rate_delta = _rng.randf_range(0.01, 0.04)
	elif inflation > 0.12:
		# Умеренно высокая — мягкое повышение
		rate_delta = _rng.randf_range(-0.005, 0.02)
	elif inflation < 0.04:
		# Дефляционный риск — снижение ставки
		rate_delta = _rng.randf_range(-0.03, -0.005)
	else:
		# Целевой диапазон 4–12% — небольшие колебания
		rate_delta = _rng.randf_range(-0.01, 0.01)

	var old_rate: float = key_rate
	key_rate = clampf(key_rate + rate_delta, KEY_RATE_MIN, KEY_RATE_MAX)
	key_rate = roundf(key_rate * 200.0) / 200.0     # шаг 0.5%

	if absf(key_rate - old_rate) >= 0.005:
		emit_signal("rate_changed", key_rate, old_rate)
		if es:
			var dir: String = "⬆ повышена" if key_rate > old_rate else "⬇ снижена"
			es.event_triggered.emit({
				"text": "🏦 ЦБ: ключевая ставка %s до %.1f%%/год" % [dir, key_rate * 100.0],
				"money": 0, "health": 0
			})

# Переходы экономического цикла: из нормы можно сорваться в бум или рецессию
# (2–4 мес), после чего экономика возвращается к стабильности.
func _update_phase(es: Node) -> void:
	if phase != "normal":
		phase_months_left -= 1
		if phase_months_left <= 0:
			phase = "normal"
			if es:
				es.event_triggered.emit({
					"text": "⚖ Экономика стабилизировалась — цены и зарплаты выровнялись.",
					"money": 0, "health": 0
				})
		return
	var roll: float = _rng.randf()
	if roll < 0.07:
		phase = "recession"
		phase_months_left = _rng.randi_range(2, 4)
		if es:
			es.event_triggered.emit({
				"text": "📉 Экономический спад! Цены растут, а зарплаты почти не двигаются. Тяжёлые времена настали.",
				"money": 0, "health": 0
			})
	elif roll < 0.13:
		phase = "boom"
		phase_months_left = _rng.randi_range(2, 4)
		if es:
			es.event_triggered.emit({
				"text": "📈 Экономический бум! Зарплаты и бизнес идут в гору — лови момент.",
				"money": 0, "health": 0
			})

# ── Сохранение ───────────────────────────────────────────────────────────────

func save(cfg: ConfigFile) -> void:
	cfg.set_value("cb", "key_rate",    key_rate)
	cfg.set_value("cb", "inflation",   inflation)
	cfg.set_value("cb", "price_index", price_index)
	cfg.set_value("cb", "wage_index",  wage_index)
	cfg.set_value("cb", "phase",       phase)
	cfg.set_value("cb", "phase_left",  phase_months_left)

func load_data(cfg: ConfigFile) -> void:
	var saved_rate: float = cfg.get_value("cb", "key_rate", -1.0)
	# Миграция: если сохранение содержит старые месячные ставки (> 0.5 = 50%/мес невозможно)
	# значит это годовые — используем как есть; если < 0.5 может быть старое месячное значение
	if saved_rate > 0.0 and saved_rate < 0.5:
		# Если старое значение выглядит как месячная ставка (0.05 = 5%/мес)
		# конвертируем в годовую. Граница: < 0.12 скорее всего месячная (> 12% месяц — крайне редко)
		if saved_rate < 0.12:
			key_rate = clampf(saved_rate * 12.0, KEY_RATE_MIN, KEY_RATE_MAX)
		else:
			key_rate = saved_rate
	else:
		key_rate = 0.16

	var saved_infl: float = cfg.get_value("cb", "inflation", -1.0)
	if saved_infl > 0.0 and saved_infl < 0.12:
		# Старое месячное значение — конвертируем
		inflation = clampf(saved_infl * 12.0, INFL_MIN, INFL_MAX)
	elif saved_infl >= 0.12:
		inflation = saved_infl
	else:
		inflation = 0.08

	price_index = cfg.get_value("cb", "price_index", 1.0)
	wage_index  = cfg.get_value("cb", "wage_index", 1.0)
	phase       = cfg.get_value("cb", "phase", "normal")
	phase_months_left = cfg.get_value("cb", "phase_left", 0)

func reset() -> void:
	key_rate    = 0.16
	inflation   = 0.08
	price_index = 1.0
	wage_index  = 1.0
	phase       = "normal"
	phase_months_left = 0
