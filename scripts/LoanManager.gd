extends Node

signal loan_taken(amount: float)
signal loan_closed(loan_name: String)
signal loan_defaulted(payment: float)
signal loans_changed

# Категории кредитов
const LOAN_TYPES: Array = [
	{
		"id": "micro",
		"name": "💳 Микрозайм",
		"min": 1000.0, "max": 50000.0,
		"rate": 0.15,         # % в месяц
		"min_months": 1, "max_months": 3,
		"income_req": 0.0,    # минимальный доход/день
		"rep_req": 0,
		"need_business": false,
		"color": Color(0.70, 0.55, 0.20),
	},
	{
		"id": "consumer",
		"name": "🏦 Потреб. кредит",
		"min": 50000.0, "max": 500000.0,
		"rate": 0.08,
		"min_months": 3, "max_months": 24,
		"income_req": 667.0,  # ~20 тыс/мес
		"rep_req": 0,
		"need_business": false,
		"color": Color(0.35, 0.60, 0.90),
	},
	{
		"id": "auto",
		"name": "🚗 Автокредит",
		"min": 500000.0, "max": 5000000.0,
		"rate": 0.06,
		"min_months": 12, "max_months": 60,
		"income_req": 3333.0, # ~100 тыс/мес
		"rep_req": 0,
		"need_business": false,
		"color": Color(0.40, 0.80, 0.50),
	},
	{
		"id": "mortgage",
		"name": "🏠 Ипотека",
		"min": 1000000.0, "max": 50000000.0,
		"rate": 0.04,
		"min_months": 60, "max_months": 360,
		"income_req": 10000.0,
		"rep_req": 0,
		"need_business": false,
		"housing_tier_req": 2,  # минимум Общага
		"color": Color(0.55, 0.45, 0.85),
	},
	{
		"id": "business",
		"name": "💼 Бизнес-кредит",
		"min": 1000000.0, "max": 500000000.0,
		"rate": 0.05,
		"min_months": 12, "max_months": 120,
		"income_req": 33333.0,
		"rep_req": 0,
		"need_business": true,
		"color": Color(0.90, 0.65, 0.20),
	},
	{
		"id": "vip",
		"name": "👑 VIP-кредит",
		"min": 100000000.0, "max": 10000000000.0,
		"rate": 0.03,
		"min_months": 12, "max_months": 240,
		"income_req": 3333333.0,
		"rep_req": 50,
		"need_business": true,
		"color": Color(1.0, 0.85, 0.10),
	},
]

# Активные кредиты
# {id, name, principal, monthly, remaining, next_due_day, overdue_days, taken_day}
var active_loans: Array = []

# Кредитная история — закрытые кредиты
# {name, principal, closed_day, success}
var loan_history: Array = []

# Рейтинг: "A", "B", "C", "D"
var credit_rating: String = "B"

# Бан на новые кредиты (до какого дня)
var ban_until_day: int = 0

# Кулдаун по категории после отказа: {loan_type_id -> день_до_которого_нельзя}
var rejection_cooldowns: Dictionary = {}

# ── Расчёт одобрения ────────────────────────────────────────────────────────

func approval_chance(type_idx: int, amount: float, months: int) -> float:
	var gm: Node = get_node("/root/GameManager")
	var lt: Dictionary = LOAN_TYPES[type_idx]

	# Базовый шанс по рейтингу
	var base: float = {"A": 0.95, "B": 0.75, "C": 0.50, "D": 0.20}.get(credit_rating, 0.75)

	# Доход/день
	var daily_income: float = gm.get_monthly_income() / 30.0
	var monthly_payment: float = _calc_monthly(amount, lt.rate, months)
	var income_factor: float = clampf(daily_income * 30.0 / maxf(monthly_payment, 1.0), 0.0, 2.0)
	income_factor = clampf(income_factor * 0.5, 0.0, 1.0)

	# Текущий долг снижает шанс
	var debt_ratio: float = get_total_debt() / maxf(gm.money + 1.0, 1.0)
	var debt_factor: float = clampf(1.0 - debt_ratio * 0.5, 0.1, 1.0)

	# Репутация
	var rm: Node = get_node_or_null("/root/ReputationManager")
	var rep_bonus: float = 0.0
	if rm: rep_bonus = clampf(float(rm.reputation) / 200.0, 0.0, 0.15)

	# Жильё
	var housing_tier: int = gm.HOUSINGS[gm.current_housing_index].get("tier", 0) as int
	var housing_bonus: float = clampf(float(housing_tier) / 20.0, 0.0, 0.10)

	# Накопления: если у игрока есть сбережения относительно суммы кредита
	var cash_ratio: float = clampf(gm.money / maxf(amount, 1.0), 0.0, 1.5) / 1.5 * 0.20

	var chance: float = base * (0.4 + income_factor * 0.6) * debt_factor + rep_bonus + housing_bonus + cash_ratio
	return clampf(chance, 0.02, 0.98)

func get_effective_rate(base_rate: float) -> float:
	var cb: Node = get_node_or_null("/root/CentralBankManager")
	if cb:
		return cb.get_effective_loan_rate(base_rate)
	return base_rate

func _calc_monthly(amount: float, rate: float, months: int) -> float:
	if months <= 0:
		return amount
	var eff_rate: float = get_effective_rate(rate)
	return amount * eff_rate + amount / float(months)

func calc_total(amount: float, rate: float, months: int) -> float:
	return _calc_monthly(amount, rate, months) * float(months)

func calc_overpay(amount: float, rate: float, months: int) -> float:
	return calc_total(amount, rate, months) - amount

# ── Взять кредит ─────────────────────────────────────────────────────────────

func try_take_loan(type_idx: int, amount: float, months: int) -> bool:
	var gm: Node = get_node("/root/GameManager")

	if gm.day < ban_until_day:
		return false

	var lt: Dictionary = LOAN_TYPES[type_idx]

	# Проверяем кулдаун по категории
	if rejection_cooldowns.get(lt.id, 0) > gm.day:
		return false

	var chance: float = approval_chance(type_idx, amount, months)
	if randf() > chance:
		# Отказ — ставим кулдаун 90 дней для этой категории
		rejection_cooldowns[lt.id] = gm.day + 90
		return false  # отказано

	var monthly: float = _calc_monthly(amount, lt.rate, months)
	var total: float = monthly * float(months)

	active_loans.append({
		"id":           lt.id,
		"name":         lt.name,
		"principal":    amount,
		"monthly":      monthly,
		"remaining":    total,
		"next_due_day": gm.day + 30,
		"overdue_days": 0,
		"taken_day":    gm.day,
	})
	gm.add_money(amount)
	emit_signal("loan_taken", amount)
	emit_signal("loans_changed")
	return true

# ── Досрочное погашение ───────────────────────────────────────────────────────

func repay_partial(loan_idx: int, amount: float) -> bool:
	var gm: Node = get_node("/root/GameManager")
	if loan_idx < 0 or loan_idx >= active_loans.size():
		return false
	var loan: Dictionary = active_loans[loan_idx]
	var pay: float = minf(amount, loan.remaining)
	if not gm.spend_money(pay):
		return false
	loan.remaining -= pay
	if loan.remaining <= 1.0:
		_close_loan(loan_idx, true)
	else:
		emit_signal("loans_changed")
	return true

func repay_full(loan_idx: int) -> bool:
	var gm: Node = get_node("/root/GameManager")
	if loan_idx < 0 or loan_idx >= active_loans.size():
		return false
	var loan: Dictionary = active_loans[loan_idx]
	# Досрочное погашение — скидка 5%
	var pay: float = loan.remaining * 0.95
	if not gm.spend_money(pay):
		return false
	_close_loan(loan_idx, true)
	return true

func _close_loan(idx: int, success: bool) -> void:
	var gm: Node = get_node("/root/GameManager")
	var loan: Dictionary = active_loans[idx]
	loan_history.append({
		"name":       loan.name,
		"principal":  loan.get("principal", loan.remaining),
		"closed_day": gm.day,
		"success":    success,
	})
	emit_signal("loan_closed", loan.name)
	active_loans.remove_at(idx)
	_update_rating()
	emit_signal("loans_changed")

func _update_rating() -> void:
	if loan_history.is_empty():
		return
	var good: int = 0
	var bad: int = 0
	for h in loan_history:
		if h.success: good += 1
		else: bad += 1
	var ratio: float = float(good) / float(good + bad)
	if ratio >= 0.95 and good >= 3:
		credit_rating = "A"
	elif ratio >= 0.75:
		credit_rating = "B"
	elif ratio >= 0.50:
		credit_rating = "C"
	else:
		credit_rating = "D"

# ── Ежедневная обработка ─────────────────────────────────────────────────────

func process_day(current_day: int) -> void:
	if active_loans.is_empty():
		return
	var gm: Node = get_node("/root/GameManager")
	var es: Node = get_node_or_null("/root/EventSystem")
	var to_remove: Array = []

	for i in active_loans.size():
		var loan: Dictionary = active_loans[i]
		if current_day < loan.next_due_day:
			continue

		var payment: float = minf(loan.monthly, loan.remaining)
		if gm.spend_money(payment):
			loan.remaining -= payment
			loan.overdue_days = 0
			loan.next_due_day += 30
			if loan.remaining <= 1.0:
				to_remove.append(i)
				if es:
					es.event_triggered.emit({
						"text": "✅ Кредит «%s» полностью выплачен!" % loan.name,
						"money": 0, "health": 0
					})
			else:
				if es:
					es.event_triggered.emit({
						"text": "🏦 Платёж по кредиту «%s»: -%s" % [loan.name, gm.format_money(payment)],
						"money": -payment, "health": 0
					})
		else:
			# Просрочка
			loan.overdue_days += 30
			loan.next_due_day += 30

			if loan.overdue_days <= 7:
				# Предупреждение
				if es:
					es.event_triggered.emit({
						"text": "⚠ Просрочка по «%s»! Нет денег на платёж." % loan.name,
						"money": 0, "health": 0
					})
			elif loan.overdue_days <= 30:
				# Штраф +20% к долгу, −репутация
				loan.remaining *= 1.20
				var rm: Node = get_node_or_null("/root/ReputationManager")
				if rm: rm.add(-5)
				emit_signal("loan_defaulted", payment)
				if es:
					es.event_triggered.emit({
						"text": "❗ Просрочка «%s»! Долг вырос на 20%%, репутация −5" % loan.name,
						"money": 0, "health": 0
					})
			else:
				# Коллекторы: штраф деньгами, бан
				var fine: float = loan.remaining * 0.15
				gm.money = maxf(0.0, gm.money - fine)
				gm.emit_signal("money_changed", gm.money)
				var rm: Node = get_node_or_null("/root/ReputationManager")
				if rm: rm.add(-15)
				# Бан на 30 дней если просрочка > 60 дней
				if loan.overdue_days > 60:
					ban_until_day = current_day + 30
					loan_history.append({
						"name": loan.name, "principal": loan.principal,
						"closed_day": current_day, "success": false
					})
					to_remove.append(i)
					_update_rating()
				if es:
					es.event_triggered.emit({
						"text": "🚨 Коллекторы по «%s»! Списано %s, репутация −15" % [loan.name, gm.format_money(fine)],
						"money": -fine, "health": 0
					})

	to_remove.sort()
	to_remove.reverse()
	for i in to_remove:
		if i < active_loans.size():
			active_loans.remove_at(i)
	if not to_remove.is_empty():
		emit_signal("loans_changed")

# ── Геттеры ──────────────────────────────────────────────────────────────────

func get_total_debt() -> float:
	var total: float = 0.0
	for l in active_loans:
		total += l.remaining
	return total

func get_monthly_total() -> float:
	var total: float = 0.0
	for l in active_loans:
		total += l.monthly
	return total

func is_banned(current_day: int) -> bool:
	return current_day < ban_until_day

func rating_color() -> Color:
	return {"A": Color(0.3, 1.0, 0.4), "B": Color(0.5, 0.8, 1.0),
			"C": Color(1.0, 0.85, 0.2), "D": Color(1.0, 0.3, 0.3)}.get(credit_rating, Color.WHITE)

# ── Сохранение ───────────────────────────────────────────────────────────────

func save(cfg: ConfigFile) -> void:
	cfg.set_value("loans", "active",               active_loans)
	cfg.set_value("loans", "history",              loan_history)
	cfg.set_value("loans", "rating",               credit_rating)
	cfg.set_value("loans", "ban_until_day",        ban_until_day)
	cfg.set_value("loans", "rejection_cooldowns",  rejection_cooldowns)

func load_data(cfg: ConfigFile) -> void:
	active_loans         = cfg.get_value("loans", "active",               [])
	loan_history         = cfg.get_value("loans", "history",              [])
	credit_rating        = cfg.get_value("loans", "rating",               "B")
	ban_until_day        = cfg.get_value("loans", "ban_until_day",        0)
	rejection_cooldowns  = cfg.get_value("loans", "rejection_cooldowns",  {})
