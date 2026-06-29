extends CanvasLayer
# Экран «Теневые дела» — пульт криминальной империи: розыск, авторитет, грязные
# деньги, отмыв, дела, чёрный рынок, рэкет, банда, районы, коррупция, тюрьма.

var gm: Node
var cm: Node
var zm: Node
var _panel: PanelContainer
var _vb: VBoxContainer
var _status: String = ""

func _ready() -> void:
	layer = 22
	visible = false
	add_to_group("crime_ui")
	_resolve()
	_build_shell()
	if cm:
		if cm.has_signal("crime_changed"):
			cm.crime_changed.connect(func(): if visible: _rebuild())
		if cm.has_signal("raided"):
			cm.raided.connect(_on_raided)

func _resolve() -> void:
	gm = get_node_or_null("/root/GameManager")
	cm = get_node_or_null("/root/CrimeManager")
	zm = get_node_or_null("/root/ZoneManager")

func _build_shell() -> void:
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.6)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.gui_input.connect(func(e):
		if e is InputEventMouseButton and e.pressed: close())
	add_child(dim)

	_panel = PanelContainer.new()
	_panel.set_anchors_preset(Control.PRESET_CENTER)
	_panel.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_panel.grow_vertical = Control.GROW_DIRECTION_BOTH
	_panel.add_theme_stylebox_override("panel", UITheme.panel_box())
	add_child(_panel)

	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(560, 600)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_panel.add_child(scroll)

	_vb = VBoxContainer.new()
	_vb.add_theme_constant_override("separation", 6)
	_vb.custom_minimum_size = Vector2(540, 0)
	scroll.add_child(_vb)

func open() -> void:
	_resolve()
	_rebuild()
	visible = true
	var fit: float = UITheme.fit_scale(_panel)
	_panel.pivot_offset = _panel.size * 0.5
	_panel.modulate.a = 0.0
	_panel.scale = Vector2(fit, fit) * 0.95
	var tw := create_tween()
	tw.set_parallel(true)
	tw.tween_property(_panel, "modulate:a", 1.0, 0.15)
	tw.tween_property(_panel, "scale", Vector2(fit, fit), 0.15).set_ease(Tween.EASE_OUT)

func close() -> void:
	visible = false

func _on_raided(info: Dictionary) -> void:
	var t := "🚨 Облава! Изъято денег: %s" % gm.format_money(info.get("cash", 0))
	if info.get("arrested", false):
		t = "🚓 Тебя взяли! Срок назначен."
	_status = t
	if visible: _rebuild()

# ── Сборка ────────────────────────────────────────────────────────────────────
func _rebuild() -> void:
	for c in _vb.get_children():
		c.queue_free()
	if cm == null:
		return

	_title("🕶 Теневые дела")
	if _status != "":
		_lbl(_vb, _status, Color(0.95, 0.7, 0.5), 12)

	# Шапка: розыск, авторитет, грязные деньги
	var hl: Dictionary = cm.heat_label()
	_lbl(_vb, "🚨 Розыск: %d/100 — %s" % [int(cm.heat), hl.name], hl.color, 13)
	_lbl(_vb, "👑 Авторитет: %s (%d) · %s" % [cm.rank_name(), int(cm.criminal_rep), cm.rank_perk_text()], Color(0.85, 0.78, 0.55), 12)
	_lbl(_vb, "💵 Грязные деньги: %s" % gm.format_money(cm.dirty_money), Color(0.7, 0.85, 0.6), 12)
	if cm.has_protection():
		_lbl(_vb, "🛡 Крыша сверху: %d дн." % cm.protection_days, Color(0.6, 0.8, 0.9), 11)
	if cm.has_informant():
		_lbl(_vb, "🕵 Информатор: %d дн." % cm.informant_days, Color(0.6, 0.8, 0.9), 11)

	# Тюрьма — если сидим, только залог
	if cm.is_imprisoned():
		_sep()
		_lbl(_vb, "🚓 Ты в тюрьме. Осталось: %d дн." % cm.prison_days, Color(0.9, 0.5, 0.45), 14)
		_action_btn("💸 Выйти под залог (%s)" % gm.format_money(cm.bail_cost()), "danger", func(): cm.post_bail())
		_close_btn()
		return

	# Заказ — разовый жирный контракт
	if cm.has_contract():
		var c: Dictionary = cm.contract(cm.current_contract)
		_sep(); _header("🕶 Поступил заказ!")
		_lbl(_vb, "%s %s — куш %s · шанс %d%% · энергия %d" % [c.icon, c.name, gm.format_money(c.payout), int(cm.contract_chance(cm.current_contract) * 100), int(c.energy)], Color(0.95, 0.85, 0.6), 13)
		_action_btn("✅ Взяться за заказ", "primary", _on_contract)
		_action_btn("Отказаться", "ghost", func(): cm.decline_contract())

	# Отмыв
	_sep(); _header("💼 Отмыв денег")
	_lbl(_vb, "Лимит сегодня: %s · комиссия %d%%" % [gm.format_money(cm.launder_left_today()), int(cm.laundering_fee() * 100)], Color(0.65, 0.67, 0.75), 11)
	if cm.dirty_money > 0.0:
		_action_btn("Отмыть всё доступное", "primary", func(): cm.launder(cm.dirty_money))

	# Тёмные дела
	_sep(); _header("🎭 Тёмные дела")
	for s in cm.SCHEMES:
		_scheme_row(s)

	# Чёрный рынок
	_sep(); _header("📦 Чёрный рынок")
	for g in cm.BM_GOODS:
		_bm_row(g)

	# Рэкет
	_sep(); _header("🏪 Рэкет / крыша (%d/%d)" % [cm.rackets.size(), cm.max_rackets()])
	for t in cm.RACKET_TARGETS:
		_racket_row(t)

	# Банда
	_sep(); _header("👥 Братва (%d/%d, лояльность %d%%)" % [cm.gang_size, cm.max_gang(), int(cm.gang_loyalty)])
	if cm.max_gang() > 0:
		_action_btn("Завербовать бойца (%s)" % gm.format_money(cm.GANG_HIRE_COST), "ghost", func(): cm.recruit_gang(1))
	# Бригадиры
	_lbl(_vb, "Бригадиры: %d/%d — усиливают дела, рэкет или войну" % [cm.lieutenants.size(), cm.max_lieutenants()], Color(0.78, 0.72, 0.55), 11)
	for lt in cm.lieutenants:
		_lbl(_vb, "  • %s — %s (лояльность %d%%)" % [lt.name, cm.LT_SPEC_NAME[lt.spec], int(lt.loyalty)], Color(0.7, 0.75, 0.82), 10)
	if cm.lieutenants.size() < cm.max_lieutenants():
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 6)
		for spec in cm.LT_SPECS:
			var b := _mk_btn("Бригадир: " + cm.LT_SPEC_NAME[spec], "ghost")
			b.pressed.connect(_on_recruit_lt.bind(String(spec)))
			row.add_child(b)
		_vb.add_child(row)

	# Общак
	_sep(); _header("💰 Общак (%s)" % gm.format_money(cm.obshchak))
	_lbl(_vb, "Касса банды страхует содержание и держит лояльность.", Color(0.65, 0.67, 0.75), 10)
	if cm.dirty_money > 0.0:
		_action_btn("Внести грязные в общак", "ghost", func(): cm.deposit_obshchak(cm.dirty_money))
	if cm.obshchak > 0.0:
		_action_btn("Забрать из общака", "ghost", func(): cm.withdraw_obshchak(cm.obshchak))

	# Районы
	_sep(); _header("🗺 Контроль районов")
	if cm.rackets.size() + cm.controlled_zones.size() > 0:
		var thr: int = int(round(cm.rival_attack_chance() * 100))
		_lbl(_vb, "⚔ Риск наезда конкурентов: %d%%/день — держи банду сильной" % thr, Color(0.9, 0.62, 0.45), 11)
	for z in range(9):
		_turf_row(z)

	# Коррупция
	_sep(); _header("👮 Коррупция")
	if cm.heat > 0.0:
		_action_btn("Дать взятку (сбить ~10 розыска)", "ghost", func(): cm.bribe_police(cm.bribe_cost_per_heat() * 10.0))
	_action_btn("Купить крышу сверху (%s)" % gm.format_money(cm.protection_cost()), "ghost", func(): cm.buy_protection())
	_action_btn("Нанять информатора (%s)" % gm.format_money(cm.informant_cost()), "ghost", func(): cm.hire_informant())

	_close_btn()

# ── Строки ────────────────────────────────────────────────────────────────────
func _scheme_row(s: Dictionary) -> void:
	var card := _card()
	_lbl(card, "%s %s — куш %s" % [s.icon, s.name, gm.format_money(s.payout)], Color(0.9, 0.88, 0.78), 13)
	var avail: bool = cm.can_attempt(s.id)
	_lbl(card, "Нужен авторитет %d · шанс %d%% · энергия %d" % [s.min_rep, int(cm.scheme_chance(s.id) * 100), int(s.energy)], Color(0.62, 0.64, 0.72), 10)
	if avail:
		_action_btn_to(card, "Провернуть", "primary", _on_scheme.bind(String(s.id)))

func _on_scheme(id: String) -> void:
	var r: Dictionary = cm.attempt_scheme(id)
	_status = ("✅ Дело выгорело!" if r.get("success", false) else "❌ Сорвалось, шухер!") if r.ok else "Нельзя сейчас"
	_rebuild()

func _on_contract() -> void:
	var r: Dictionary = cm.attempt_contract()
	_status = ("💰 Заказ выполнен!" if r.get("success", false) else "❌ Заказ провален!") if r.ok else "Нельзя сейчас"
	_rebuild()

func _on_recruit_lt(spec: String) -> void:
	cm.recruit_lieutenant(spec)
	_rebuild()

func _bm_row(g: Dictionary) -> void:
	var card := _card()
	var id: String = g.id
	_lbl(card, "%s %s · цена %s · на руках %d" % [g.icon, g.name, gm.format_money(cm.bm_price(id)), cm.bm_have(id)], Color(0.9, 0.88, 0.78), 12)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	var buy := _mk_btn("Купить", "primary"); buy.pressed.connect(func(): cm.bm_buy(id, 1)); row.add_child(buy)
	if cm.bm_have(id) > 0:
		var sell := _mk_btn("Продать", "ghost"); sell.pressed.connect(func(): cm.bm_sell(id, 1)); row.add_child(sell)
	card.add_child(row)

func _racket_row(t: Dictionary) -> void:
	var card := _card()
	var id: String = t.id
	var held: bool = cm.is_racket_held(id)
	_lbl(card, "%s %s — дань %s/день" % [t.icon, t.name, gm.format_money(t.income)], Color(0.9, 0.88, 0.78), 12)
	if held:
		_lbl(card, "✅ под твоей крышей", UITheme.GREEN, 10)
	elif cm.criminal_rep >= float(t.min_rep) and cm.rackets.size() < cm.max_rackets():
		_action_btn_to(card, "Наехать (шанс %d%%)" % int(cm.racket_claim_chance(id) * 100), "ghost", _on_claim.bind(id))
	else:
		_lbl(card, "🔒 нужен авторитет %d" % t.min_rep, Color(0.7, 0.6, 0.45), 10)

func _on_claim(id: String) -> void:
	var r: Dictionary = cm.claim_racket(id)
	_status = ("🏪 Точка под крышей!" if r.get("success", false) else "❌ Наезд сорвался") if r.ok else ""
	_rebuild()

func _turf_row(z: int) -> void:
	var zname: String = "Зона %d" % z
	if zm and "ZONE_META" in zm and z < zm.ZONE_META.size():
		zname = String(zm.ZONE_META[z].get("name", zname))
	if cm.controls_zone(z):
		_lbl(_vb, "✅ %s — под контролем (%s/день)" % [zname, gm.format_money(cm.turf_income(z))], UITheme.GREEN, 11)
	elif cm.can_take_zone(z):
		_action_btn("⚔ Передел: %s (шанс %d%%)" % [zname, int(cm.turf_war_chance(z) * 100)], "ghost", _on_turf.bind(z))

func _on_turf(z: int) -> void:
	var r: Dictionary = cm.take_zone(z)
	_status = ("🗺 Район взят!" if r.get("success", false) else "❌ Передел проигран") if r.ok else ""
	_rebuild()

# ── Хелперы ───────────────────────────────────────────────────────────────────
func _card() -> VBoxContainer:
	var c := PanelContainer.new()
	c.add_theme_stylebox_override("panel", UITheme.card_box(true))
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 2)
	c.add_child(box)
	_vb.add_child(c)
	return box

func _mk_btn(text: String, variant: String) -> Button:
	var b := Button.new()
	b.text = text
	b.add_theme_font_size_override("font_size", 12)
	UITheme.style_button(b, variant)
	return b

func _action_btn(text: String, variant: String, cb: Callable) -> void:
	_action_btn_to(_vb, text, variant, cb)

func _action_btn_to(parent: Node, text: String, variant: String, cb: Callable) -> void:
	var b := _mk_btn(text, variant)
	b.pressed.connect(cb)
	parent.add_child(b)

func _close_btn() -> void:
	var b := _mk_btn("Закрыть", "ghost")
	b.pressed.connect(close)
	_vb.add_child(b)

func _title(t: String) -> void:
	var l := Label.new()
	l.text = t
	l.add_theme_font_size_override("font_size", 20)
	l.add_theme_color_override("font_color", UITheme.GOLD)
	_vb.add_child(l)

func _header(t: String) -> void:
	var l := Label.new()
	l.text = t
	l.add_theme_font_size_override("font_size", 15)
	l.add_theme_color_override("font_color", Color(0.86, 0.88, 0.96))
	_vb.add_child(l)

func _lbl(parent: Node, t: String, col: Color, size: int) -> void:
	var l := Label.new()
	l.text = t
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", col)
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	parent.add_child(l)

func _sep() -> void:
	_vb.add_child(UITheme.gold_rule())
