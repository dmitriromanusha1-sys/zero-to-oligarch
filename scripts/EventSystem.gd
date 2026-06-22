extends Node

signal event_triggered(event: Dictionary)

const EVENTS = [
	# ── Бомж / Нищий ──────────────────────────────────────────────────────────
	{"text": "Нашёл кошелёк на улице! +500 ₽",                    "money":500,       "health":0,   "min_title":0},
	{"text": "Облили из лужи проезжающие. -5 здоровья",            "money":0,         "health":-5,  "min_title":0},
	{"text": "Добрый прохожий угостил едой. +10 здоровья",         "money":0,         "health":10,  "min_title":0},
	{"text": "Полиция попросила освободить место. -100 ₽ штраф",   "money":-100,      "health":-3,  "min_title":0},
	{"text": "Нашёл металлолом. Сдал. +800 ₽",                    "money":800,       "health":-2,  "min_title":0},
	{"text": "Заболел. -15 здоровья",                              "money":-200,      "health":-15, "min_title":0},
	{"text": "Выиграл в карты у соседа. +1 000 ₽",                "money":1000,      "health":0,   "min_title":0},
	{"text": "Украли рюкзак. -500 ₽",                             "money":-500,      "health":-5,  "min_title":0},
	{"text": "Разовая подработка — разгрузил фуру. +1 500 ₽",     "money":1500,      "health":-5,  "min_title":0},
	{"text": "Нашёл купюру под скамейкой. +200 ₽",                "money":200,       "health":0,   "min_title":0},
	{"text": "Дали стакан супа в столовой. +8 здоровья",           "money":0,         "health":8,   "min_title":0},
	{"text": "Продал старые вещи на барахолке. +1 200 ₽",         "money":1200,      "health":0,   "min_title":0},
	{"text": "Переспал на улице в мороз. -10 здоровья",            "money":0,         "health":-10, "min_title":0, "req_housing_max":1},
	{"text": "Нашёл рабочий телефон. Продал. +2 500 ₽",           "money":2500,      "health":0,   "min_title":0},
	{"text": "Дворник пнул — убирайся! -5 здоровья",              "money":0,         "health":-5,  "min_title":0},
	{"text": "Сосед угостил домашней едой. +12 здоровья",          "money":0,         "health":12,  "min_title":0},
	{"text": "Нашёл монетки в старом пальто. +150 ₽",             "money":150,       "health":0,   "min_title":0},
	{"text": "Стал статистом на съёмках. +2 000 ₽",               "money":2000,      "health":0,   "min_title":0},
	{"text": "Нашёл заначку в старом матрасе. +3 500 ₽",         "money":3500,      "health":0,   "min_title":0},
	{"text": "Порезался о разбитую бутылку. -8 здоровья",         "money":0,         "health":-8,  "min_title":0, "req_housing_max":2},

	# ── Бедный / Средний (титулы 2–7, деньги 5к–600к) ───────────────────────
	{"text": "Налоговая проверка! Штраф -5 000 ₽",                             "money":-5000,   "health":-5,  "min_title":4},
	{"text": "Сосед занял и вернул с процентами. +3 000 ₽",                    "money":3000,    "health":0,   "min_title":2},
	{"text": "Повышение на работе! +10 000 ₽",                                 "money":10000,   "health":5,   "min_title":4},
	{"text": "Машина сломалась. Ремонт -8 000 ₽",                              "money":-8000,   "health":-3,  "min_title":4},
	{"text": "Удачная сделка на рынке. +15 000 ₽",                             "money":15000,   "health":0,   "min_title":4},
	{"text": "Мошенники обманули. -20 000 ₽",                                  "money":-20000,  "health":-10, "min_title":4},
	{"text": "Сосед попросил приютить кота. Кот сломал ноутбук. -12 000 ₽",   "money":-12000,  "health":0,   "min_title":4},
	{"text": "Срочный фриланс за ночь. +18 000 ₽",                             "money":18000,   "health":-5,  "min_title":4},
	{"text": "Пожар в подъезде. Ценности спасены, но нервы... -10 здоровья",   "money":0,       "health":-10, "min_title":2},
	{"text": "Выиграл в государственной лотерее. +25 000 ₽",                   "money":25000,   "health":0,   "min_title":2},
	{"text": "Коллега подставил перед начальством. -7 000 ₽ премии",           "money":-7000,   "health":-5,  "min_title":4},
	{"text": "Друг вернул старый долг. +30 000 ₽",                             "money":30000,   "health":5,   "min_title":4},
	{"text": "Ремонт в квартире затянулся. -15 000 ₽",                         "money":-15000,  "health":-3,  "min_title":4, "req_housing":8},
	{"text": "Написал статью в газету. Заплатили. +5 000 ₽",                   "money":5000,    "health":0,   "min_title":3},
	{"text": "Перепутал ценники в магазине. Неловко. -2 000 ₽",                "money":-2000,   "health":0,   "min_title":2},
	{"text": "Нашёл ошибку в счёте ЖКХ. Вернули переплату. +4 500 ₽",         "money":4500,    "health":0,   "min_title":2},
	{"text": "Сорвал спину на переезде. Лечение -6 000 ₽, -8 здоровья",        "money":-6000,   "health":-8,  "min_title":3},
	{"text": "Подработка репетитором. Ученик сдал ЕГЭ. +8 000 ₽",             "money":8000,    "health":0,   "min_title":3},
	{"text": "Выиграл спор с коллегой. Поставил ящик пива — зато +репутация",  "money":-3000,   "health":0,   "min_title":3, "rep":3},
	{"text": "Кошка соседки прожевала кабель ноутбука. Сосед компенсировал. +5 000 ₽", "money":5000, "health":5, "min_title":4},
	{"text": "Получил квартальную премию. +20 000 ₽",                          "money":20000,   "health":5,   "min_title":5},
	{"text": "Штраф ГАИ за превышение. -3 500 ₽",                              "money":-3500,   "health":0,   "min_title":4},
	{"text": "Подписал выгодный контракт на консалтинг. +35 000 ₽",            "money":35000,   "health":0,   "min_title":6},
	{"text": "Конкурент переманил твоего лучшего сотрудника. -10 здоровья",     "money":0,       "health":-10, "min_title":6},

	# ── Специалист / Менеджер (титулы 8–10, деньги 1.5М–25М) ────────────────
	{"text": "Чиновник потребовал откат. -100 000 ₽",                          "money":-100000,  "health":-5,  "min_title":8},
	{"text": "Выгодная инвестиция окупилась! +200 000 ₽",                      "money":200000,   "health":5,   "min_title":8},
	{"text": "Выступил на экономическом форуме. +репутация, +200 000 ₽",       "money":200000,   "health":0,   "min_title":8, "rep":8},
	{"text": "Журналист написал лестную статью. +репутация и +150 000 ₽",      "money":150000,   "health":0,   "min_title":9, "rep":5},
	{"text": "Конкурент слил компромат. -репутация",                            "money":-50000,   "health":-5,  "min_title":8, "rep":-10},
	{"text": "Банковский депозит принёс сверхдоход. +300 000 ₽",               "money":300000,   "health":0,   "min_title":9, "rep":3},
	{"text": "Налоговая нашла ошибку в декларации. Доначислили -250 000 ₽",    "money":-250000,  "health":-5,  "min_title":8},

	# ── Богатый / Предприниматель (титулы 10–12, деньги 10М–200М) ────────────
	{"text": "Рейдерский захват! Потерял актив. -500 000 ₽",                   "money":-500000,  "health":-10, "min_title":10, "req_biz":true},
	{"text": "Партнёр украл деньги. -300 000 ₽",                               "money":-300000,  "health":-15, "min_title":10, "req_biz":true},
	{"text": "Выиграл тендер у государства. +1 000 000 ₽",                     "money":1000000,  "health":5,   "min_title":10},
	{"text": "Яхта требует ремонта. -400 000 ₽",                               "money":-400000,  "health":0,   "min_title":11},
	{"text": "Арбитражный суд вынес решение в твою пользу. +500 000 ₽",        "money":500000,   "health":5,   "min_title":10, "req_biz":true},
	{"text": "Конкурент обанкротился — его клиенты у тебя. +400 000 ₽",        "money":400000,   "health":5,   "min_title":10, "req_biz":true},
	{"text": "Вложил деньги в стартап. Он взлетел! +1 200 000 ₽",             "money":1200000,  "health":5,   "min_title":10},
	{"text": "Пожар в офисе. Страховка покрыла не всё. -600 000 ₽",            "money":-600000,  "health":-8,  "min_title":10, "req_biz":true},
	{"text": "Хедхантеры переманили ключевого сотрудника. -180 000 ₽",         "money":-180000,  "health":-3,  "min_title":10, "req_biz":true},

	# ── Миллионер / Бизнесмен (титулы 12–14, деньги 60М–600М) ───────────────
	{"text": "Санкции заморозили счёт. -2 000 000 ₽",                          "money":-2000000, "health":-10, "min_title":12},
	{"text": "Нефтяной контракт. +5 000 000 ₽",                                "money":5000000,  "health":0,   "min_title":12},
	{"text": "IPO акций вашей компании. +3 000 000 ₽",                         "money":3000000,  "health":0,   "min_title":12},
	{"text": "Налоговый рай закрыли. -800 000 ₽",                              "money":-800000,  "health":-5,  "min_title":12},
	{"text": "Международный контракт подписан. +2 500 000 ₽",                  "money":2500000,  "health":0,   "min_title":12},

	# ── Мультимиллионер / Магнат (титулы 14+, деньги 600М+) ─────────────────
	{"text": "Forbes включил в рейтинг богатейших! +репутация, +500 000 ₽",    "money":500000,   "health":5,   "min_title":14, "rep":20},
	{"text": "Крупная сделка с иностранным концерном. +8 000 000 ₽",           "money":8000000,  "health":0,   "min_title":14},
	{"text": "ФНС нашла скрытые активы. Штраф -5 000 000 ₽",                   "money":-5000000, "health":-8,  "min_title":14},
	{"text": "Конкурент устроил информационную атаку. -репутация",              "money":-1000000, "health":-10, "min_title":14, "rep":-15},
	{"text": "Личный самолёт требует ремонта двигателей. -3 000 000 ₽",        "money":-3000000, "health":0,   "min_title":14},
	{"text": "Купили контрольный пакет крупной корпорации. +15 000 000 ₽",     "money":15000000, "health":5,   "min_title":14},
	{"text": "Государство национализировало завод. -10 000 000 ₽",              "money":-10000000,"health":-15, "min_title":14},
	{"text": "Личный яхт-флот принёс доход от аренды. +2 000 000 ₽",           "money":2000000,  "health":0,   "min_title":14},
	{"text": "Пресса написала о твоей благотворительности. +репутация",         "money":-500000,  "health":5,   "min_title":14, "rep":25},
	{"text": "Хакеры атаковали цифровые активы. -4 000 000 ₽",                 "money":-4000000, "health":-5,  "min_title":14},
	{"text": "Получил государственный орден. +репутация, +1 000 000 ₽",         "money":1000000,  "health":10,  "min_title":14, "rep":30},
	{"text": "Сделка по слиянию компаний сорвалась. -2 000 000 ₽",             "money":-2000000, "health":-5,  "min_title":14},
]

var gm: Node

func _ready() -> void:
	gm = get_node("/root/GameManager")

func roll_event() -> Dictionary:
	var available: Array = EVENTS.filter(func(ev): return _is_available(ev))
	if available.is_empty():
		return {}
	var picked: Dictionary = available[randi() % available.size()]

	if picked.money != 0:
		if picked.money > 0:
			gm.add_money(picked.money)
		else:
			# Не больше 20% текущих наличных за одно событие — чтобы крупные номиналы
			# из таблицы не выбивали игрока в ноль одним роллом
			var loss: float = minf(abs(picked.money), gm.money * 0.2)
			if loss > 0:
				gm.spend_money(loss)

	if picked.health != 0:
		gm.health = clamp(gm.health + picked.health, 0, gm.stat_max())
		gm.emit_signal("health_changed", gm.health)

	if picked.get("rep", 0) != 0:
		var rm: Node = get_node_or_null("/root/ReputationManager")
		if rm: rm.add(picked.rep)

	emit_signal("event_triggered", picked)
	var am: Node = get_node_or_null("/root/AudioManager")
	if am:
		if picked.money < 0 or picked.health < 0:
			am.play_negative()
		elif picked.money > 0:
			am.play_coin()
	return picked

func _is_available(ev: Dictionary) -> bool:
	if ev.get("min_title", 0) > gm.current_title_index:
		return false
	# req_housing — минимальный индекс жилья (игрок должен жить не хуже)
	if ev.get("req_housing", -1) >= 0 and gm.current_housing_index < ev.req_housing:
		return false
	# req_housing_max — максимальный индекс жилья (плохие события только для бедных)
	if ev.get("req_housing_max", -1) >= 0 and gm.current_housing_index > ev.req_housing_max:
		return false
	# req_biz — событие требует наличия бизнеса
	if ev.get("req_biz", false):
		var bm: Node = get_node_or_null("/root/BusinessManager")
		if bm == null or bm.owned_business_id == "":
			return false
	return true
