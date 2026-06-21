extends Node

signal money_changed(amount: float)
signal net_worth_changed(amount: float)
signal title_changed(title: String)
signal housing_changed(housing: String)
signal day_changed(day: int)
signal time_changed(hour: int, minute: int)
signal health_changed(hp: float)
signal hunger_changed(val: float)
signal thirst_changed(val: float)
signal energy_changed(val: float)
signal view_zoom_changed(zoom: float)

# Зум камеры/интерфейса: 0.6 (макс. обзор, камера далеко) .. 1.8 (макс. приближение), меняется Ctrl+колесо мыши
var view_zoom: float = 1.0
const VIEW_ZOOM_MIN: float = 0.6
const VIEW_ZOOM_MAX: float = 1.8

func adjust_view_zoom(delta_steps: float) -> void:
	view_zoom = clampf(view_zoom + delta_steps * 0.1, VIEW_ZOOM_MIN, VIEW_ZOOM_MAX)
	emit_signal("view_zoom_changed", view_zoom)

const TITLES = [
	{
		"name": "Бомж",            "min_money": 0,
		"icon": "🗑",
		"desc": "Дно достигнуто. Карманы пусты, будущего не видно. Но именно отсюда начинаются все великие истории.",
	},
	{
		"name": "Бродяга",         "min_money": 1_000,
		"icon": "👣",
		"desc": "Тысяча рублей — это уже что-то. Ты в движении, у тебя есть цель. Главное — не останавливаться.",
	},
	{
		"name": "Нищий",           "min_money": 5_000,
		"icon": "🪙",
		"desc": "Пять тысяч — первый шаг к стабильности. Ещё немного, и ты выберешься из самого дна.",
	},
	{
		"name": "Безработный",     "min_money": 15_000,
		"icon": "📋",
		"desc": "Деньги есть, работы нет. Время найти себя — или создать своё дело с нуля.",
	},
	{
		"name": "Бедный",          "min_money": 40_000,
		"icon": "🧦",
		"desc": "Сводишь концы с концами. До следующего уровня — пропасть, но ты уже умеешь выживать.",
	},
	{
		"name": "Работяга",        "min_money": 100_000,
		"icon": "🔧",
		"desc": "Сто тысяч честно заработано. Ты знаешь цену деньгам. Теперь пора научиться их приумножать.",
	},
	{
		"name": "Простой",         "min_money": 250_000,
		"icon": "👕",
		"desc": "Четверть миллиона. Большинство людей остаётся здесь навсегда. Ты не большинство.",
	},
	{
		"name": "Средний класс",   "min_money": 600_000,
		"icon": "🏠",
		"desc": "Есть жильё, есть доход. Ты стабилен. Но стабильность — это не вершина, это плацдарм.",
	},
	{
		"name": "Специалист",      "min_money": 1_500_000,
		"icon": "💼",
		"desc": "Полтора миллиона. Твои навыки стоят денег. Теперь заставь деньги работать на тебя.",
	},
	{
		"name": "Менеджер",        "min_money": 4_000_000,
		"icon": "📊",
		"desc": "Четыре миллиона — и ты уже руководишь, а не подчиняешься. Впереди — настоящий бизнес.",
	},
	{
		"name": "Богатый",         "min_money": 10_000_000,
		"icon": "💎",
		"desc": "Десять миллионов. Ты богат — и это не метафора. Большинство людей не увидит таких денег никогда.",
	},
	{
		"name": "Предприниматель", "min_money": 25_000_000,
		"icon": "🏭",
		"desc": "Двадцать пять миллионов. Бизнес работает, деньги идут. Ты создаёшь рабочие места и возможности.",
	},
	{
		"name": "Миллионер",       "min_money": 60_000_000,
		"icon": "💰",
		"desc": "Шестьдесят миллионов. Слово «миллионер» теперь — это ты. Входи в высший свет.",
	},
	{
		"name": "Бизнесмен",       "min_money": 200_000_000,
		"icon": "🤝",
		"desc": "Двести миллионов. Твоё имя знают в деловых кругах. Ты играешь по крупному.",
	},
	{
		"name": "Мультимиллионер", "min_money": 600_000_000,
		"icon": "🛥",
		"desc": "Шестьсот миллионов. Яхты, особняки, полёты бизнес-классом — теперь это норма, не мечта.",
	},
	{
		"name": "Магнат",          "min_money": 2_500_000_000,
		"icon": "👔",
		"desc": "Два с половиной миллиарда. Ты не просто богат — ты влиятелен. Рынки реагируют на твои решения.",
	},
	{
		"name": "Олигарх",         "min_money": 10_000_000_000,
		"icon": "👑",
		"desc": "Десять миллиардов. Высшая ступень. Путь от бомжа до олигарха пройден. Ты — легенда.",
	},
]

const HOUSINGS = [
	{
		"name": "Улица", "icon": "🌧",
		"desc": "Спишь под открытым небом. Холодно, опасно и голодно.",
		"price": 0, "monthly": 0,
		"health_regen": -1.0, "hunger_drain": 1.3, "thirst_drain": 1.3,
		"income_mult": 1.0, "expense_mult": 1.0, "rep_per_day": -1.0,
		"crime_risk": 0.4, "happiness": -10.0, "skill_xp_mult": 0.8, "tier": 0,
	},
	{
		"name": "Коробка", "icon": "📦",
		"desc": "Картонная коробка под мостом. Хотя бы крыша над головой.",
		"price": 100, "monthly": 0,
		"health_regen": -0.5, "hunger_drain": 1.15, "thirst_drain": 1.15,
		"income_mult": 1.0, "expense_mult": 1.0, "rep_per_day": -0.5,
		"crime_risk": 0.3, "happiness": -5.0, "skill_xp_mult": 0.85, "tier": 0,
	},
	{
		"name": "Палатка", "icon": "⛺",
		"desc": "Туристическая палатка на окраине. Минимальный комфорт.",
		"price": 2000, "monthly": 0,
		"health_regen": 0.0, "hunger_drain": 1.0, "thirst_drain": 1.0,
		"income_mult": 1.0, "expense_mult": 1.0, "rep_per_day": 0.0,
		"crime_risk": 0.2, "happiness": 0.0, "skill_xp_mult": 0.9, "tier": 1,
	},
	{
		"name": "Подвал", "icon": "🕳",
		"desc": "Сырой подвал жилого дома. Темно, но есть стены и крыша.",
		"price": 5000, "monthly": 0,
		"health_regen": -0.5, "hunger_drain": 0.95, "thirst_drain": 0.95,
		"income_mult": 1.0, "expense_mult": 1.0, "rep_per_day": -0.2,
		"crime_risk": 0.15, "happiness": -3.0, "skill_xp_mult": 0.92, "tier": 1,
	},
	{
		"name": "Чердак", "icon": "🏚",
		"desc": "Чердак старой пятиэтажки. Летом жарко, зимой холодно.",
		"price": 10000, "monthly": 0,
		"health_regen": 0.2, "hunger_drain": 0.92, "thirst_drain": 0.92,
		"income_mult": 1.0, "expense_mult": 1.0, "rep_per_day": 0.0,
		"crime_risk": 0.1, "happiness": -1.0, "skill_xp_mult": 0.95, "tier": 1,
	},
	{
		"name": "Общага", "icon": "🛏",
		"desc": "Место в общежитии. Шумно, но есть горячая вода.",
		"price": 0, "monthly": 5000,
		"health_regen": 0.5, "hunger_drain": 0.9, "thirst_drain": 0.9,
		"income_mult": 1.0, "expense_mult": 1.0, "rep_per_day": 0.2,
		"crime_risk": 0.08, "happiness": 2.0, "skill_xp_mult": 1.0, "tier": 2,
	},
	{
		"name": "Комната", "icon": "🚪",
		"desc": "Съёмная комната в квартире. Есть свой угол.",
		"price": 0, "monthly": 12000,
		"health_regen": 1.0, "hunger_drain": 0.88, "thirst_drain": 0.88,
		"income_mult": 1.02, "expense_mult": 1.0, "rep_per_day": 0.5,
		"crime_risk": 0.05, "happiness": 5.0, "skill_xp_mult": 1.03, "tier": 2,
	},
	{
		"name": "Однушка", "icon": "🏠",
		"desc": "Однокомнатная квартира в аренду. Своё пространство.",
		"price": 0, "monthly": 20000,
		"health_regen": 1.5, "hunger_drain": 0.85, "thirst_drain": 0.85,
		"income_mult": 1.05, "expense_mult": 1.0, "rep_per_day": 1.0,
		"crime_risk": 0.03, "happiness": 8.0, "skill_xp_mult": 1.05, "tier": 3,
	},
	{
		"name": "Своя квартира", "icon": "🏢",
		"desc": "Собственная квартира. Никакой аренды, твои правила.",
		"price": 3000000, "monthly": 0,
		"health_regen": 2.0, "hunger_drain": 0.82, "thirst_drain": 0.82,
		"income_mult": 1.10, "expense_mult": 0.95, "rep_per_day": 2.0,
		"crime_risk": 0.02, "happiness": 12.0, "skill_xp_mult": 1.08, "tier": 4,
	},
	{
		"name": "Дом", "icon": "🏘",
		"desc": "Частный дом с участком. Спокойствие и стабильность.",
		"price": 15000000, "monthly": 0,
		"health_regen": 3.0, "hunger_drain": 0.78, "thirst_drain": 0.78,
		"income_mult": 1.15, "expense_mult": 0.92, "rep_per_day": 3.0,
		"crime_risk": 0.01, "happiness": 18.0, "skill_xp_mult": 1.12, "tier": 5,
	},
	{
		"name": "Коттедж", "icon": "🌲",
		"desc": "Уютный коттедж за городом. Воздух, тишина, пространство.",
		"price": 80000000, "monthly": 0,
		"health_regen": 4.0, "hunger_drain": 0.74, "thirst_drain": 0.74,
		"income_mult": 1.20, "expense_mult": 0.88, "rep_per_day": 5.0,
		"crime_risk": 0.005, "happiness": 25.0, "skill_xp_mult": 1.18, "tier": 6,
	},
	{
		"name": "Вилла", "icon": "🏰",
		"desc": "Роскошная вилла с бассейном и охраной.",
		"price": 500000000, "monthly": 0,
		"health_regen": 5.0, "hunger_drain": 0.68, "thirst_drain": 0.68,
		"income_mult": 1.30, "expense_mult": 0.85, "rep_per_day": 8.0,
		"crime_risk": 0.002, "happiness": 35.0, "skill_xp_mult": 1.25, "tier": 8,
	},
	{
		"name": "Пентхаус", "icon": "🌆",
		"desc": "Пентхаус на вершине небоскрёба. Весь город у твоих ног.",
		"price": 1500000000, "monthly": 0,
		"health_regen": 6.0, "hunger_drain": 0.60, "thirst_drain": 0.60,
		"income_mult": 1.45, "expense_mult": 0.80, "rep_per_day": 12.0,
		"crime_risk": 0.001, "happiness": 50.0, "skill_xp_mult": 1.35, "tier": 9,
	},
	{
		"name": "Личный остров", "icon": "🏝",
		"desc": "Собственный остров в тёплых морях. Недосягаемость для проблем.",
		"price": 10000000000, "monthly": 0,
		"health_regen": 8.0, "hunger_drain": 0.50, "thirst_drain": 0.50,
		"income_mult": 1.60, "expense_mult": 0.70, "rep_per_day": 20.0,
		"crime_risk": 0.0, "happiness": 100.0, "skill_xp_mult": 1.50, "tier": 10,
	},
]

var money: float = 0.0
var health: float = 100.0
var hunger: float = 100.0
var thirst: float = 100.0
var energy: float = 100.0
var current_title_index: int = 0
var current_housing_index: int = 0
var day: int = 1
var current_hour: int = 8
var current_minute: int = 0
var money_history: Array = []   # [{day, money}] — каждые 5 дней
var meal_buff_days: int = 0       # оставшихся дней бонуса после обеда
var meal_drain_bonus: float = 0.0 # снижение расхода еды/воды (0.0–0.50, чем дороже обед — тем больше % и дольше срок)

const SAVE_PATH_LEGACY = "user://savegame.cfg"   # старое единое сохранение (миграция)
const SECS_PER_GAME_MIN: float = 0.5   # 1 сек реального времени = 2 игровых минуты

# Слот сохранения 1..3, выбирается в главном меню
var current_slot: int = 1

func slot_path(slot: int) -> String:
	return "user://savegame_slot%d.cfg" % slot

func slot_exists(slot: int) -> bool:
	return FileAccess.file_exists(slot_path(slot))

# Краткая инфа о слоте для отображения в меню без переключения текущего состояния игры
func slot_info(slot: int) -> Dictionary:
	var cfg := ConfigFile.new()
	if cfg.load(slot_path(slot)) != OK:
		return {}
	var t_idx: int = cfg.get_value("player", "title_index", 0)
	return {
		"day": cfg.get_value("player", "day", 1),
		"money": cfg.get_value("player", "money", 0.0),
		"title_index": t_idx,
		"title": TITLES[clampi(t_idx, 0, TITLES.size() - 1)].name,
	}

func delete_slot(slot: int) -> void:
	var path := slot_path(slot)
	if FileAccess.file_exists(path):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(path))

var _time_acc: float = 0.0

func _ready() -> void:
	_migrate_legacy_save()
	load_game()
	var sm := get_node_or_null("/root/SettingsManager")
	if sm: Engine.time_scale = sm.default_speed
	var autosave_timer := Timer.new()
	autosave_timer.wait_time = 300.0   # каждые 5 минут
	autosave_timer.autostart = true
	autosave_timer.timeout.connect(save_game)
	add_child(autosave_timer)

func _process(delta: float) -> void:
	_time_acc += delta
	if _time_acc < SECS_PER_GAME_MIN:
		return
	_time_acc -= SECS_PER_GAME_MIN
	current_minute += 1
	if current_minute >= 60:
		current_minute = 0
		current_hour += 1
		if current_hour >= 24:
			current_hour = 0
			next_day()
			return
	emit_signal("time_changed", current_hour, current_minute)

# --- Деньги ---

func add_money(amount: float) -> void:
	money += amount
	emit_signal("money_changed", money)
	_check_title()
	emit_signal("net_worth_changed", get_net_worth())

func spend_money(amount: float) -> bool:
	if money < amount:
		return false
	money -= amount
	emit_signal("money_changed", money)
	_check_title()
	emit_signal("net_worth_changed", get_net_worth())
	return true

func recheck_net_worth() -> void:
	_check_title()
	emit_signal("net_worth_changed", get_net_worth())

# --- Жильё ---

func buy_housing(index: int) -> bool:
	var h = HOUSINGS[index]
	if h.price > 0:
		if not spend_money(h.price):
			return false
	current_housing_index = index
	emit_signal("housing_changed", h.name)
	save_game()
	return true

# --- Следующий день ---

# ── Сон ───────────────────────────────────────────────────────────────────────
# Энергию даёт только сон. Качество сна зависит от жилья (энергия/час и лечение/
# час), еда/вода тратятся медленно, на небезопасном жилье можно лишиться денег.
const SLEEP_HUNGER_PER_H := 4.0
const SLEEP_THIRST_PER_H := 5.0

func get_sleep_energy_per_hour() -> float:
	var tier: int = HOUSINGS[current_housing_index].get("tier", 0) as int
	return lerpf(4.0, 16.0, clampf(tier / 10.0, 0.0, 1.0))

func get_sleep_health_per_hour() -> float:
	var tier: int = HOUSINGS[current_housing_index].get("tier", 0) as int
	return lerpf(-0.8, 2.5, clampf(tier / 10.0, 0.0, 1.0))

# Возвращает сводку: {energy_gain, robbed, robbed_amount}
func sleep_hours(hours: int) -> Dictionary:
	var h: Dictionary = HOUSINGS[current_housing_index]
	var before_e: float = energy
	energy = clamp(energy + get_sleep_energy_per_hour() * hours, 0.0, 100.0)
	var energy_gain: float = energy - before_e
	emit_signal("energy_changed", energy)

	var meal_m: float = 1.0 - meal_drain_bonus
	hunger = clamp(hunger - SLEEP_HUNGER_PER_H * hours * meal_m, 0.0, 100.0)
	thirst = clamp(thirst - SLEEP_THIRST_PER_H * hours * meal_m, 0.0, 100.0)
	emit_signal("hunger_changed", hunger)
	emit_signal("thirst_changed", thirst)

	health = clamp(health + get_sleep_health_per_hour() * hours, 0.0, 100.0)
	emit_signal("health_changed", health)

	# Кража во сне — только если нет крыши над головой (бомж, tier 0).
	# В любом помещении (палатка и выше) деньги в безопасности.
	var robbed: bool = false
	var robbed_amount: float = 0.0
	var tier_now: int = h.get("tier", 0) as int
	var crime: float = h.get("crime_risk", 0.0) as float
	if tier_now == 0 and crime > 0.0 and money > 0.0:
		var chance: float = clampf(crime * (hours / 8.0), 0.0, 0.9)
		if randf() < chance:
			robbed = true
			robbed_amount = money * randf_range(0.05, 0.15)
			money = maxf(0.0, money - robbed_amount)
			emit_signal("money_changed", money)
			_check_title()
			var es = get_node_or_null("/root/EventSystem")
			if es:
				es.event_triggered.emit({
					"text": "🦹 Тебя обокрали во сне! Потеряно %s" % format_money(robbed_amount),
					"money": -robbed_amount, "health": 0
				})

	# Сон тратит игровое время
	advance_time(hours)
	save_game()
	return {"energy_gain": energy_gain, "robbed": robbed, "robbed_amount": robbed_amount}

# Прокрутка времени на N часов (рабочая смена). Если смена выходит за полночь —
# просто наступает следующий день (с его обработкой), иначе сдвигаем часы.
func advance_time(hours: int) -> void:
	if hours <= 0:
		return
	if current_hour + hours >= 24:
		next_day()
	else:
		current_hour += hours
		current_minute = 0
		_time_acc = 0.0
		emit_signal("time_changed", current_hour, current_minute)

func next_day() -> void:
	day += 1
	current_hour = 8
	current_minute = 0
	_time_acc = 0.0
	emit_signal("day_changed", day)
	emit_signal("time_changed", current_hour, current_minute)

	var h = HOUSINGS[current_housing_index]

	# Ежемесячные события: аренда + ЦБ
	if day % 30 == 0:
		var cb: Node = get_node_or_null("/root/CentralBankManager")
		if cb:
			cb.process_month()
		# Аренда с учётом накопленной инфляции
		if h.monthly > 0:
			var price_mult: float = cb.price_index if cb else 1.0
			var rent: int = int(h.monthly * (_diff().penalty as float) * price_mult)
			if not spend_money(rent):
				current_housing_index = 0
				emit_signal("housing_changed", HOUSINGS[0].name)

	# Здоровье от жилья теперь начисляется ПОЧАСОВО во время сна (см. sleep_hours),
	# а не раз в день — поэтому здесь больше ничего не делаем.

	# Репутация от жилья
	var rep_day: float = h.get("rep_per_day", 0.0) as float
	if rep_day != 0.0:
		var rm = get_node_or_null("/root/ReputationManager")
		if rm: rm.add(int(rep_day))

	# Сытость и жажда убывают каждый день (с множителем жилья)
	var d: Dictionary = _diff()
	var drain_m: float = d.drain as float
	var health_m: float = d.health as float
	var h_hunger: float = h.get("hunger_drain", 1.0) as float
	var h_thirst: float = h.get("thirst_drain", 1.0) as float
	var meal_m: float = 1.0 - meal_drain_bonus
	hunger = clamp(hunger - 15.0 * drain_m * h_hunger * meal_m, 0.0, 100.0)
	thirst = clamp(thirst - 20.0 * drain_m * h_thirst * meal_m, 0.0, 100.0)
	if meal_buff_days > 0:
		meal_buff_days -= 1
		if meal_buff_days <= 0:
			meal_drain_bonus = 0.0
	emit_signal("hunger_changed", hunger)
	emit_signal("thirst_changed", thirst)
	# Штраф здоровью если голоден или обезвожен (смягчён, чтобы не убивать
	# новичка за пару дней нищеты — это предупреждение, а не приговор)
	if hunger <= 0.0:
		health = clamp(health - 3.0 * health_m, 0.0, 100.0)
		emit_signal("health_changed", health)
	if thirst <= 0.0:
		health = clamp(health - 4.0 * health_m, 0.0, 100.0)
		emit_signal("health_changed", health)

	# Энергия за смену дня НЕ восстанавливается — только сном (см. sleep_hours)

	# Пассивный доход от бизнеса
	var bm = get_node_or_null("/root/BusinessManager")
	if bm:
		bm.process_day()

	# Платежи по кредитам
	var lm = get_node_or_null("/root/LoanManager")
	if lm:
		lm.process_day(day)

	# Налоги раз в 30 дней
	if day % 30 == 0:
		_collect_tax()

	# Проверка полиции раз в 7 дней
	if day % 7 == 0:
		_police_check()

	# Запись истории каждые 5 дней (net worth для точного отображения прогресса)
	if day % 5 == 0:
		money_history.append({"day": day, "money": get_net_worth()})
		if money_history.size() > 200:
			money_history.pop_front()

	# Газета каждые 7 дней
	if day % 7 == 0:
		var np = get_tree().get_first_node_in_group("newspaper")
		if np: np.show_newspaper(day)

	# Случайное событие (25% шанс каждый день)
	if randf() < 0.25:
		var es = get_node_or_null("/root/EventSystem")
		if es:
			es.roll_event()

	save_game()

# Налоги: % от накопленных денег зависит от титула
func _diff() -> Dictionary:
	var sm := get_node_or_null("/root/SettingsManager")
	return sm.get_diff() if sm else {"penalty": 1.0, "tax": 1.0, "drain": 1.0, "health": 1.0}

func _collect_tax() -> void:
	if money <= 0:
		return
	const TAX_RATES := [0.0, 0.0, 0.04, 0.05, 0.07, 0.08, 0.10, 0.12, 0.14, 0.16, 0.18, 0.20, 0.22, 0.24, 0.26, 0.28, 0.30]
	var rate: float = TAX_RATES[current_title_index]
	if rate <= 0.0:
		return
	var tax: float = minf(money * rate * (_diff().tax as float), money)
	money -= tax
	emit_signal("money_changed", money)
	_check_title()
	var rm = get_node_or_null("/root/ReputationManager")
	if rm: rm.add(2)
	var _sm2 := get_node_or_null("/root/SettingsManager")
	var es = get_node_or_null("/root/EventSystem")
	if es and (not _sm2 or _sm2.notify_taxes):
		es.event_triggered.emit({
			"text": "📋 Налоговая взяла %.0f%% — уплачено %s" % [rate * 100, format_money(tax)],
			"money": -tax,
			"health": 0
		})

# Полиция: при низкой репутации забирает часть денег
func _police_check() -> void:
	var rm = get_node_or_null("/root/ReputationManager")
	if rm == null or not rm.is_suspicious():
		return
	if money <= 0:
		return
	# Шанс облавы зависит от того насколько плоха репутация
	var chance: float = 0.15 + (40 - rm.reputation) * 0.01
	if randf() > chance:
		return
	var fine: float = money * 0.1 * (_diff().penalty as float)
	money -= fine
	emit_signal("money_changed", money)
	_check_title()
	rm.add(-5)
	var achm = get_node_or_null("/root/AchievementManager")
	if achm: achm.on_police_check()
	var _sm3 := get_node_or_null("/root/SettingsManager")
	var es = get_node_or_null("/root/EventSystem")
	if es and (not _sm3 or _sm3.notify_police):
		es.event_triggered.emit({
			"text": "👮 Участковый проверил документы и забрал %s «на нужды района»" % format_money(fine),
			"money": -fine,
			"health": 0
		})

# --- Титул ---

func get_net_worth() -> float:
	var nw: float = money

	# Жильё (собственное, не аренда) — 80% от цены покупки
	var h: Dictionary = HOUSINGS[current_housing_index]
	if h.price > 0:
		nw += h.price * 0.8

	var bm: Node = get_node_or_null("/root/BusinessManager")
	if bm:
		# Бизнес — 70% от стоимости открытия
		if bm.owned_business_id != "":
			for bt in bm.BUSINESS_TYPES:
				if bt.id == bm.owned_business_id:
					nw += bt.cost * 0.7
					break
		# Банковский депозит — 100%
		nw += bm.bank_deposit

	# Акции — текущая рыночная стоимость
	var sm: Node = get_node_or_null("/root/StockMarket")
	if sm:
		for sid in sm.owned:
			var shares: int = sm.owned[sid]
			if shares > 0:
				nw += shares * sm.prices.get(sid, 0.0)

	# Инвентарь — 50% от цены предмета
	var im: Node = get_node_or_null("/root/InventoryManager")
	if im:
		for item_id in im.inventory:
			var count: int = im.inventory[item_id]
			if count > 0 and item_id in im.ITEMS:
				nw += count * im.ITEMS[item_id].price * 0.5

	# Транспорт — 60% от цены (кроме пешком)
	var tm: Node = get_node_or_null("/root/TransportManager")
	if tm:
		for vid in tm.owned_vehicles:
			if vid == "walk":
				continue
			for vt in tm.VEHICLES:
				if vt.id == vid:
					nw += vt.price * 0.6
					break

	# Вычитаем долги по кредитам
	var lm: Node = get_node_or_null("/root/LoanManager")
	if lm:
		nw -= lm.get_total_debt()

	return maxf(nw, 0.0)

func _check_title() -> void:
	var nw: float = get_net_worth()
	var new_index = 0
	for i in range(TITLES.size()):
		if nw >= TITLES[i].min_money:
			new_index = i
	if new_index != current_title_index:
		current_title_index = new_index
		emit_signal("title_changed", TITLES[current_title_index].name)

func get_title() -> String:
	return TITLES[current_title_index].name

func get_housing() -> String:
	return HOUSINGS[current_housing_index].name

# Бонус жилья к расходу энергии на работе: 0.0 (нет жилья) .. 0.40 (-40% на лучшем жильё)
func get_housing_energy_drain_bonus() -> float:
	var tier: int = HOUSINGS[current_housing_index].get("tier", 0) as int
	return lerpf(0.0, 0.40, clampf(tier / 10.0, 0.0, 1.0))

func get_monthly_income() -> float:
	var bm: Node = get_node_or_null("/root/BusinessManager")
	var biz_daily: float = bm.get_daily_income() if bm else 0.0
	return biz_daily * 30.0

func format_money(amount: float) -> String:
	var sign_str := "-" if amount < 0.0 else ""
	var a := absf(amount)
	var val_str: String
	if a >= 1_000_000_000:
		val_str = "%.1f млрд ₽" % (a / 1_000_000_000)
	elif a >= 1_000_000:
		val_str = "%.1f млн ₽" % (a / 1_000_000)
	elif a >= 1_000:
		val_str = "%.1f тыс ₽" % (a / 1_000)
	else:
		val_str = "%d ₽" % int(a)
	return sign_str + val_str

# --- Сохранение ---

func save_game() -> void:
	var cfg = ConfigFile.new()
	cfg.set_value("player", "money", money)
	cfg.set_value("player", "health", health)
	cfg.set_value("player", "hunger", hunger)
	cfg.set_value("player", "thirst", thirst)
	cfg.set_value("player", "energy", energy)
	cfg.set_value("player", "title_index", current_title_index)
	cfg.set_value("player", "housing_index", current_housing_index)
	cfg.set_value("player", "day", day)
	cfg.set_value("player", "money_history", money_history)
	cfg.set_value("player", "hour", current_hour)
	cfg.set_value("player", "minute", current_minute)
	cfg.set_value("player", "meal_buff_days", meal_buff_days)
	cfg.set_value("player", "meal_drain_bonus", meal_drain_bonus)
	var bm = get_node_or_null("/root/BusinessManager")
	if bm: bm.save(cfg)
	var qm = get_node_or_null("/root/QuestManager")
	if qm: qm.save(cfg)
	var rm = get_node_or_null("/root/ReputationManager")
	if rm: rm.save(cfg)
	var achm = get_node_or_null("/root/AchievementManager")
	if achm: achm.save(cfg)
	var sm = get_node_or_null("/root/StockMarket")
	if sm: sm.save(cfg)
	var im = get_node_or_null("/root/InventoryManager")
	if im: im.save(cfg)
	var lm = get_node_or_null("/root/LoanManager")
	if lm: lm.save(cfg)
	var cb = get_node_or_null("/root/CentralBankManager")
	if cb: cb.save(cfg)
	var em = get_node_or_null("/root/EducationManager")
	if em: em.save(cfg)
	var zm = get_node_or_null("/root/ZoneManager")
	if zm: zm.save(cfg)
	var tm = get_node_or_null("/root/TransportManager")
	if tm: tm.save(cfg)
	var am = get_node_or_null("/root/AudioManager")
	if am: am.save(cfg)
	cfg.save(slot_path(current_slot))
	var hud := get_tree().get_first_node_in_group("hud") if get_tree() else null
	var _sm := get_node_or_null("/root/SettingsManager")
	if hud and hud.has_method("show_autosave_toast") and (not _sm or _sm.notify_autosave):
		hud.show_autosave_toast()

func _migrate_legacy_save() -> void:
	# До введения слотов было одно сохранение — переносим его в слот 1,
	# чтобы у игроков с прогрессом он не "пропал" после обновления
	if FileAccess.file_exists(SAVE_PATH_LEGACY) and not slot_exists(1):
		var src := FileAccess.open(SAVE_PATH_LEGACY, FileAccess.READ)
		if src:
			var data := src.get_as_text()
			src.close()
			var dst := FileAccess.open(slot_path(1), FileAccess.WRITE)
			if dst:
				dst.store_string(data)
				dst.close()

func load_game() -> void:
	var cfg = ConfigFile.new()
	if cfg.load(slot_path(current_slot)) != OK:
		return
	money = cfg.get_value("player", "money", 0.0)
	health = cfg.get_value("player", "health", 100.0)
	hunger = cfg.get_value("player", "hunger", 100.0)
	thirst = cfg.get_value("player", "thirst", 100.0)
	energy = cfg.get_value("player", "energy", 100.0)
	current_title_index = cfg.get_value("player", "title_index", 0)
	current_housing_index = cfg.get_value("player", "housing_index", 0)
	day = cfg.get_value("player", "day", 1)
	money_history = cfg.get_value("player", "money_history", [])
	current_hour = cfg.get_value("player", "hour", 8)
	current_minute = cfg.get_value("player", "minute", 0)
	meal_buff_days  = cfg.get_value("player", "meal_buff_days", 0)
	meal_drain_bonus = cfg.get_value("player", "meal_drain_bonus", 0.0)
	var bm = get_node_or_null("/root/BusinessManager")
	if bm: bm.load(cfg)
	var qm = get_node_or_null("/root/QuestManager")
	if qm: qm.load(cfg)
	var rm = get_node_or_null("/root/ReputationManager")
	if rm: rm.load(cfg)
	var achm = get_node_or_null("/root/AchievementManager")
	if achm: achm.load(cfg)
	var sm = get_node_or_null("/root/StockMarket")
	if sm: sm.load(cfg)
	var im = get_node_or_null("/root/InventoryManager")
	if im: im.load_data(cfg)
	var lm = get_node_or_null("/root/LoanManager")
	if lm: lm.load_data(cfg)
	var cb = get_node_or_null("/root/CentralBankManager")
	if cb: cb.load_data(cfg)
	var em = get_node_or_null("/root/EducationManager")
	if em: em.load_data(cfg)
	var zm = get_node_or_null("/root/ZoneManager")
	if zm: zm.load_data(cfg)
	var tm = get_node_or_null("/root/TransportManager")
	if tm: tm.load_data(cfg)
	var am = get_node_or_null("/root/AudioManager")
	if am: am.load_data(cfg)

func reset_game() -> void:
	money = 0.0; health = 100.0; hunger = 100.0; thirst = 100.0; energy = 100.0
	current_title_index = 0; current_housing_index = 0
	day = 1; current_hour = 8; current_minute = 0
	money_history.clear()
	meal_buff_days = 0; meal_drain_bonus = 0.0
	var bm = get_node_or_null("/root/BusinessManager")
	if bm:
		bm.owned_business_id = ""; bm.employees.clear(); bm.bank_deposit = 0.0
		bm.business_level = 0; bm.active_loan = 0.0; bm.total_earned = 0.0
		bm.business_days = 0; bm.security_level = 0; bm.last_event = {}
	var lm = get_node_or_null("/root/LoanManager")
	if lm:
		lm.active_loans.clear(); lm.loan_history.clear()
		lm.credit_rating = "B"; lm.ban_until_day = 0; lm.rejection_cooldowns.clear()
	var am_r = get_node_or_null("/root/AudioManager")
	if am_r: am_r.current_station = "standard"; am_r.radio_level = 0
	var dm = get_node_or_null("/root/DistrictManager")
	if dm: dm.unlocked.clear()
	var cb_r = get_node_or_null("/root/CentralBankManager")
	if cb_r: cb_r.reset()
	var rm = get_node_or_null("/root/ReputationManager")
	if rm: rm.reputation = 30
	var em = get_node_or_null("/root/EducationManager")
	if em: em.level = 0
	var zm = get_node_or_null("/root/ZoneManager")
	if zm: zm.current_zone = 0; zm.max_zone_reached = 0
	var qm = get_node_or_null("/root/QuestManager")
	if qm: qm.completed_ids.clear(); qm.active_quests.clear(); qm.diary.clear(); qm.casino_wins = 0; qm._unlock_available()
	var achm = get_node_or_null("/root/AchievementManager")
	if achm: achm.unlocked_ids.clear(); achm._casino_streak = 0; achm._tax_count = 0
	var sm = get_node_or_null("/root/StockMarket")
	if sm:
		for s in sm.STOCKS:
			sm.owned[s.id] = 0; sm.prices[s.id] = s.base; sm.history[s.id] = [s.base]
			sm.cost_basis[s.id] = 0.0; sm.daily_change[s.id] = 0.0
		sm.active_event = {}; sm.event_days_left = 0; sm._day_counter = 0
	var tm = get_node_or_null("/root/TransportManager")
	if tm: tm.current_vehicle_id = "walk"; tm.owned_vehicles = ["walk"]
	var im = get_node_or_null("/root/InventoryManager")
	if im: im.inventory.clear()
	save_game()
