extends CanvasLayer

# Еженедельная газета: новости + подсказки по акциям

const HEADLINES: Array = [
	# Экономика
	"Рубль укрепился на фоне роста нефти до $90 за баррель",
	"Правительство обещает снизить налоги. Когда-нибудь.",
	"ЦБ поднял ключевую ставку на 0.5%. Аналитики в шоке",
	"ЦБ снизил ставку впервые за год. Рынки ликуют",
	"ЦБ оставил ставку без изменений. Рынок разочарован",
	"Инфляция «под контролем», заявили чиновники",
	"Инфляция ускорилась — эксперты требуют ужесточения политики",
	"Аренда выросла — виновата инфляция, говорят эксперты",
	"Коммунальные тарифы выросли. Сюрприз!",
	"Банки повысили ставки по вкладам вслед за ЦБ",
	"Ипотека подорожала: ставки бьют рекорды",
	"Минфин доложил о профиците бюджета. Куда пойдут деньги — неизвестно",
	"Рост ВВП составил 1.3%. Эксперты спорят: это хорошо или плохо",
	"Государство выделило миллиарды на «цифровую трансформацию»",
	"Рынок труда: вакансий много, зарплаты маленькие",
	"Пенсионный возраст снова обсуждают",
	"Нефтяники попросили субсидий. Получили.",
	"Импорт электроники вырос на 40% — эксперты озадачены",
	# Бизнес
	"Олигарх купил яхту длиной 200 метров. Зачем?",
	"Банк выдал кредит без справки о доходах. Клиент не вернул.",
	"Новый торговый центр открылся на месте сквера",
	"Очередь за iPhone растянулась на квартал",
	"Крупный ритейлер объявил о рекордной прибыли. Акции выросли на 8%",
	"Стартап оценили в миллиард — продукта ещё нет",
	"Иностранный инвестор покинул рынок. «Слишком много неопределённости»",
	"Местный завод перешёл на четырёхдневную рабочую неделю",
	"Сеть кофеен закрыла 30 точек после проверки Роспотребнадзора",
	"Криптобиржа заморозила вывод средств. Пользователи паникуют",
	"IT-компания набирает 500 сотрудников. Зарплаты выше рынка",
	# Общество
	"Дядя Вася с улицы Ленина выиграл в лотерею и немедленно пропил выигрыш",
	"Местный предприниматель открыл шаурмячную в 3-й раз после двух банкротств",
	"Участковый Иванов задержал нарушителя. Нарушитель оказался его братом",
	"Цены на картошку выросли. «Сложная геополитика», — объяснили эксперты",
	"Мэрия объявила о строительстве нового парка. На месте старого парка",
	"Жители микрорайона протестуют против застройки. Застройщик не в курсе",
	"В городе открылся 47-й банк. Горожане запутались",
	"Школьник изобрёл приложение и продал его за ₽5 млн",
	"Пенсионерка выиграла суд у управляющей компании. В третий раз",
]

const STOCK_TIPS: Array = [
	"Аналитики прогнозируют рост %s в ближайшее время",
	"Инсайдеры активно скупают акции %s",
	"Источники сообщают о трудностях у %s",
	"%s может объявить дивиденды на следующей неделе",
	"Слияние компаний: %s под угрозой поглощения?",
	"Государство планирует субсидировать %s",
	"Крупный фонд избавляется от акций %s — что это значит?",
	"Прибыль %s превысила прогнозы на 15%%",
	"Менеджмент %s массово скупает собственные акции",
	"%s объявила о buyback на ₽500 млн",
]

var _panel: Control
var _hidden_until_day: int = -1   # день, до которого газета скрыта

func _ready() -> void:
	layer = 20
	visible = false
	add_to_group("newspaper")

func show_newspaper(day: int) -> void:
	if day <= _hidden_until_day:
		return
	visible = true
	for c in get_children():
		c.queue_free()
	_panel = null
	_build(day)
	# Анимация появления
	_panel.modulate.a = 0.0
	_panel.position.y += 30
	var tw := create_tween()
	tw.set_parallel(true)
	tw.tween_property(_panel, "modulate:a", 1.0, 0.30)
	tw.tween_property(_panel, "position:y", _panel.position.y - 30, 0.30).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)

func _build(day: int) -> void:
	var dimmer := ColorRect.new()
	dimmer.name = "Dimmer"
	dimmer.set_anchors_preset(Control.PRESET_FULL_RECT)
	dimmer.color = Color(0, 0, 0, 0.65)
	dimmer.mouse_filter = Control.MOUSE_FILTER_STOP
	dimmer.gui_input.connect(func(event: InputEvent):
		if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			_close()
	)
	add_child(dimmer)

	_panel = Panel.new()
	_panel.set_anchors_preset(Control.PRESET_CENTER)
	_panel.position = Vector2(-290, -270)
	_panel.size = Vector2(580, 540)
	add_child(_panel)

	var bg := ColorRect.new()
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.color = Color(0.95, 0.90, 0.75)
	_panel.add_child(bg)

	var scroll := ScrollContainer.new()
	scroll.set_anchors_preset(Control.PRESET_FULL_RECT)
	scroll.add_theme_constant_override("separation", 0)
	_panel.add_child(scroll)

	var vbox := VBoxContainer.new()
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.add_theme_constant_override("separation", 8)
	vbox.set_anchors_preset(Control.PRESET_TOP_WIDE)
	scroll.add_child(vbox)

	# Заголовок газеты
	var paper_name := Label.new()
	paper_name.text = "📰 РОССИЙСКИЙ ВЕСТНИК"
	paper_name.add_theme_font_size_override("font_size", 22)
	paper_name.add_theme_color_override("font_color", Color(0.1, 0.1, 0.1))
	paper_name.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(paper_name)

	var date_lbl := Label.new()
	date_lbl.text = "День %d  |  Выпуск #%d" % [day, int(day / 7.0)]
	date_lbl.add_theme_font_size_override("font_size", 11)
	date_lbl.add_theme_color_override("font_color", Color(0.3, 0.3, 0.3))
	date_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(date_lbl)

	vbox.add_child(_sep_dark())

	# Случайные заголовки
	var rng := RandomNumberGenerator.new()
	rng.seed = day * 12345

	var h_count: int = mini(4, HEADLINES.size())
	var used: Array = []
	for _i in h_count:
		var idx: int = rng.randi() % HEADLINES.size()
		while idx in used:
			idx = (idx + 1) % HEADLINES.size()
		used.append(idx)
		var h_lbl := Label.new()
		h_lbl.text = "• " + HEADLINES[idx]
		h_lbl.add_theme_font_size_override("font_size", 13)
		h_lbl.add_theme_color_override("font_color", Color(0.1, 0.1, 0.1))
		h_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD
		vbox.add_child(h_lbl)

	vbox.add_child(_sep_dark())

	# Финансовая колонка с подсказками по акциям
	var fin_lbl := Label.new()
	fin_lbl.text = "📈 ФИНАНСЫ"
	fin_lbl.add_theme_font_size_override("font_size", 15)
	fin_lbl.add_theme_color_override("font_color", Color(0.1, 0.3, 0.1))
	vbox.add_child(fin_lbl)

	var sm: Node = get_node_or_null("/root/StockMarket")
	if sm:
		var stock_count: int = mini(2, sm.STOCKS.size())
		var stock_used: Array = []
		for _i in stock_count:
			var sidx: int = rng.randi() % sm.STOCKS.size()
			while sidx in stock_used:
				sidx = (sidx + 1) % sm.STOCKS.size()
			stock_used.append(sidx)
			var stock: Dictionary = sm.STOCKS[sidx]
			var tip_idx: int = rng.randi() % STOCK_TIPS.size()
			var tip_text: String = STOCK_TIPS[tip_idx] % (stock.icon + " " + stock.name)
			var s_lbl := Label.new()
			s_lbl.text = "• " + tip_text
			s_lbl.add_theme_font_size_override("font_size", 12)
			s_lbl.add_theme_color_override("font_color", Color(0.1, 0.25, 0.1))
			s_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD
			vbox.add_child(s_lbl)

	# Блок ЦБ и инфляции
	var cb: Node = get_node_or_null("/root/CentralBankManager")
	if cb:
		vbox.add_child(_sep_light())
		var cb_lbl := Label.new()
		cb_lbl.text = "🏦 ЦБ: ключевая ставка — %.1f%%/год  (≈%.2f%%/мес)" % [cb.key_rate * 100.0, cb.key_rate / 12.0 * 100.0]
		cb_lbl.add_theme_font_size_override("font_size", 12)
		cb_lbl.add_theme_color_override("font_color", Color(0.1, 0.2, 0.5))
		cb_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD
		vbox.add_child(cb_lbl)
		var infl_lbl := Label.new()
		var infl_color := Color(0.6, 0.15, 0.1) if cb.inflation > 0.10 else Color(0.1, 0.4, 0.2)
		infl_lbl.text = "📊 Инфляция: %.1f%%/год  |  Индекс цен: %.3f" % [cb.inflation * 100.0, cb.price_index]
		infl_lbl.add_theme_font_size_override("font_size", 12)
		infl_lbl.add_theme_color_override("font_color", infl_color)
		infl_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD
		vbox.add_child(infl_lbl)
		# Фаза экономического цикла и индекс зарплат
		if cb.has_method("phase_label"):
			var phase_lbl := Label.new()
			var ph_color := Color(0.1, 0.4, 0.2)
			if cb.is_recession(): ph_color = Color(0.6, 0.15, 0.1)
			elif cb.is_boom(): ph_color = Color(0.1, 0.45, 0.25)
			phase_lbl.text = "%s  |  Индекс зарплат: %.3f" % [cb.phase_label(), cb.wage_index]
			phase_lbl.add_theme_font_size_override("font_size", 12)
			phase_lbl.add_theme_color_override("font_color", ph_color)
			phase_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD
			vbox.add_child(phase_lbl)
		var bm_cb: Node = get_node_or_null("/root/BusinessManager")
		if bm_cb and bm_cb.bank_deposit > 0:
			var dep_rate: float = bm_cb.get_tiered_rate()
			var dep_info := Label.new()
			dep_info.text = "💳 Ставка по вашему вкладу: %.2f%%/мес  (≈%.0f%% год)" % [dep_rate * 100.0, dep_rate * 12.0 * 100.0]
			dep_info.add_theme_font_size_override("font_size", 12)
			dep_info.add_theme_color_override("font_color", Color(0.15, 0.45, 0.15))
			vbox.add_child(dep_info)
		# Стоимость жизни: цена базовой корзины с учётом инфляции
		var gm_econ: Node = get_node_or_null("/root/GameManager")
		if gm_econ and gm_econ.has_method("shop_price"):
			var zm_econ: Node = get_node_or_null("/root/ZoneManager")
			var zone_str: String = ""
			if zm_econ and zm_econ.has_method("cost_of_living_mult"):
				zone_str = "  ·  район ×%.2f" % zm_econ.cost_of_living_mult()
			var col_lbl := Label.new()
			col_lbl.text = "🛒 Стоимость жизни: хлеб %s, вода %s (база 50/30)%s" % [
				gm_econ.format_money(gm_econ.shop_price(50)), gm_econ.format_money(gm_econ.shop_price(30)), zone_str]
			col_lbl.add_theme_font_size_override("font_size", 12)
			col_lbl.add_theme_color_override("font_color", Color(0.45, 0.25, 0.10))
			col_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD
			vbox.add_child(col_lbl)
			# Суммарно уплачено налогов (НДФЛ + налог на прибыль)
			var wage_tax: float = gm_econ.get("total_wage_tax") if gm_econ.get("total_wage_tax") != null else 0.0
			var biz_tax: float = 0.0
			if bm_cb and bm_cb.get("total_tax_paid") != null:
				biz_tax = bm_cb.total_tax_paid
			if wage_tax + biz_tax > 0.0:
				var tax_lbl := Label.new()
				tax_lbl.text = "🧾 Уплачено налогов всего: %s" % gm_econ.format_money(wage_tax + biz_tax)
				tax_lbl.add_theme_font_size_override("font_size", 12)
				tax_lbl.add_theme_color_override("font_color", Color(0.5, 0.2, 0.15))
				vbox.add_child(tax_lbl)

	# Личная финансовая сводка
	var gm: Node = get_node_or_null("/root/GameManager")
	var bm: Node = get_node_or_null("/root/BusinessManager")
	var lm: Node = get_node_or_null("/root/LoanManager")
	if gm:
		vbox.add_child(_sep_dark())
		var pers_lbl := Label.new()
		pers_lbl.text = "💼 ВАШ КАПИТАЛ"
		pers_lbl.add_theme_font_size_override("font_size", 13)
		pers_lbl.add_theme_color_override("font_color", Color(0.2, 0.2, 0.6))
		vbox.add_child(pers_lbl)
		var cap_lbl := Label.new()
		cap_lbl.text = "• Состояние: " + gm.format_money(gm.money)
		cap_lbl.add_theme_font_size_override("font_size", 12)
		cap_lbl.add_theme_color_override("font_color", Color(0.1, 0.1, 0.4))
		vbox.add_child(cap_lbl)
		if bm and bm.owned_business_id != "":
			var income: float = bm.get_daily_income() * 30.0
			var inc_lbl := Label.new()
			inc_lbl.text = "• Доход бизнеса/мес: " + gm.format_money(income)
			inc_lbl.add_theme_font_size_override("font_size", 12)
			inc_lbl.add_theme_color_override("font_color", Color(0.1, 0.1, 0.4))
			vbox.add_child(inc_lbl)
		if bm and bm.bank_deposit > 0:
			var dep_lbl := Label.new()
			dep_lbl.text = "• Вклад в банке: " + gm.format_money(bm.bank_deposit)
			dep_lbl.add_theme_font_size_override("font_size", 12)
			dep_lbl.add_theme_color_override("font_color", Color(0.1, 0.1, 0.4))
			vbox.add_child(dep_lbl)
		if lm:
			var debt: float = lm.get_total_debt()
			if debt > 0:
				var debt_lbl := Label.new()
				debt_lbl.text = "• Общий долг по кредитам: " + gm.format_money(debt)
				debt_lbl.add_theme_font_size_override("font_size", 12)
				debt_lbl.add_theme_color_override("font_color", Color(0.7, 0.25, 0.25))
				vbox.add_child(debt_lbl)
		var smn: Node = get_node_or_null("/root/StockMarket")
		if smn:
			var pv: float = smn.get_portfolio_value()
			if pv > 0:
				var pv_lbl := Label.new()
				pv_lbl.text = "• Портфель акций: " + gm.format_money(pv)
				pv_lbl.add_theme_font_size_override("font_size", 12)
				pv_lbl.add_theme_color_override("font_color", Color(0.1, 0.1, 0.4))
				vbox.add_child(pv_lbl)

	vbox.add_child(_sep_dark())

	# Кнопки управления
	var hint_lbl := Label.new()
	hint_lbl.text = "Нажмите на затемнение или кнопку, чтобы закрыть"
	hint_lbl.add_theme_font_size_override("font_size", 10)
	hint_lbl.add_theme_color_override("font_color", Color(0.4, 0.35, 0.25))
	hint_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(hint_lbl)

	var btn_row := HBoxContainer.new()
	btn_row.alignment = BoxContainer.ALIGNMENT_CENTER
	btn_row.add_theme_constant_override("separation", 12)
	vbox.add_child(btn_row)

	# Кнопка "Закрыть"
	var btn_close := Button.new()
	btn_close.text = "✕  Закрыть"
	btn_close.custom_minimum_size = Vector2(160, 38)
	btn_close.add_theme_font_size_override("font_size", 14)
	btn_close.add_theme_color_override("font_color", Color.WHITE)
	_style_btn(btn_close, Color(0.55, 0.12, 0.10), Color(0.72, 0.18, 0.15))
	btn_close.pressed.connect(_close)
	btn_row.add_child(btn_close)

	# Кнопка "Не показывать до следующего выпуска"
	var btn_hide := Button.new()
	btn_hide.text = "🙈  До следующего выпуска"
	btn_hide.custom_minimum_size = Vector2(220, 38)
	btn_hide.add_theme_font_size_override("font_size", 13)
	btn_hide.add_theme_color_override("font_color", Color(0.85, 0.75, 0.50))
	_style_btn(btn_hide, Color(0.18, 0.14, 0.06), Color(0.38, 0.28, 0.10))
	btn_hide.pressed.connect(func():
		if gm:
			_hidden_until_day = gm.day + 6   # скрыть на 6 дней (один выпуск = 7 дней)
		_close()
	)
	btn_row.add_child(btn_hide)

func _sep_dark() -> Control:
	var s := ColorRect.new()
	s.custom_minimum_size = Vector2(0, 2)
	s.color = Color(0.2, 0.1, 0.0)
	return s

func _sep_light() -> Control:
	var s := ColorRect.new()
	s.custom_minimum_size = Vector2(0, 1)
	s.color = Color(0.2, 0.1, 0.0, 0.4)
	return s

func _style_btn(btn: Button, col_normal: Color, col_hover: Color) -> void:
	var sn := StyleBoxFlat.new()
	sn.bg_color = col_normal
	sn.border_color = col_hover
	for s in [SIDE_LEFT, SIDE_RIGHT, SIDE_TOP, SIDE_BOTTOM]:
		sn.set_border_width(s, 2)
		sn.set_corner_radius(s, 6)
	btn.add_theme_stylebox_override("normal", sn)
	var sh := sn.duplicate() as StyleBoxFlat
	sh.bg_color = col_hover
	btn.add_theme_stylebox_override("hover", sh)

func _close() -> void:
	if _panel == null or not is_instance_valid(_panel):
		return
	var tw := create_tween()
	tw.tween_property(_panel, "modulate:a", 0.0, 0.20)
	await tw.finished
	visible = false
	for c in get_children():
		c.queue_free()
	_panel = null
