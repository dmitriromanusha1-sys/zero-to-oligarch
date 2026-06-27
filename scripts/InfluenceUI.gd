extends CanvasLayer
# Окно «Политический клуб»: влияние, пожертвования и связи с чиновниками.
# Открывается из Политического клуба (район олигархов).

var gm
var im
var _panel: PanelContainer
var _vb: VBoxContainer

func _ready() -> void:
	layer = 21
	visible = false
	add_to_group("influence_ui")
	gm = get_node_or_null("/root/GameManager")
	im = get_node_or_null("/root/InfluenceManager")
	_build_shell()
	if im and im.has_signal("connections_changed"):
		im.connections_changed.connect(func(): if visible: _rebuild())
	if im and im.has_signal("influence_changed"):
		im.influence_changed.connect(func(_v): if visible: _rebuild())

func _build_shell() -> void:
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.55)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.gui_input.connect(func(e):
		if e is InputEventMouseButton and e.pressed: close())
	add_child(dim)

	_panel = PanelContainer.new()
	_panel.set_anchors_preset(Control.PRESET_CENTER)
	_panel.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_panel.grow_vertical = Control.GROW_DIRECTION_BOTH
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.10, 0.07, 0.13, 0.98)
	sb.border_color = Color(0.62, 0.45, 0.85, 0.9)
	sb.set_border_width_all(2)
	sb.set_corner_radius_all(14)
	sb.set_content_margin_all(18)
	_panel.add_theme_stylebox_override("panel", sb)
	add_child(_panel)

	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(540, 580)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_panel.add_child(scroll)

	_vb = VBoxContainer.new()
	_vb.add_theme_constant_override("separation", 6)
	_vb.custom_minimum_size = Vector2(520, 0)
	scroll.add_child(_vb)

func open() -> void:
	if gm == null: gm = get_node_or_null("/root/GameManager")
	if im == null: im = get_node_or_null("/root/InfluenceManager")
	_rebuild()
	visible = true
	_panel.modulate.a = 0.0
	_panel.scale = Vector2(0.95, 0.95)
	var tw := create_tween()
	tw.set_parallel(true)
	tw.tween_property(_panel, "modulate:a", 1.0, 0.15)
	tw.tween_property(_panel, "scale", Vector2.ONE, 0.15).set_ease(Tween.EASE_OUT)

func close() -> void:
	visible = false

func _rebuild() -> void:
	for c in _vb.get_children():
		c.queue_free()
	if im == null or gm == null:
		return
	_title("🏛 Политический клуб")
	_lbl(_vb, "Влияние: %d   ·   Ранг: %s" % [int(im.influence), im.power_rank()],
		Color(0.95, 0.85, 0.45) if im.grey_cardinal else Color(0.82, 0.72, 1.0), 16)

	if not im.politics_unlocked():
		_note("Большая политика открывается с титула «%s». Сначала станьте заметной фигурой." % gm.TITLES[im.CONN_MIN_TITLE].name)
		_sep()

	# Пожертвования: деньги → влияние
	_header("💰 Конвертировать капитал во влияние")
	for d in im.DONATIONS:
		_vb.add_child(_donation_card(d))
	_sep()

	# Связи с чиновниками
	_header("🤝 Связи с чиновниками")
	for o in im.OFFICIALS:
		_vb.add_child(_official_card(o))
	_sep()

	# Лобби законов
	_header("📜 Лобби законов")
	for l in im.LAWS:
		_vb.add_child(_law_card(l))
	_sep()

	# Медиа-империя
	_header("📡 Медиа-империя")
	_lbl(_vb, "Охват: %d · влияние от СМИ: +%d/день" % [im.media_reach(), int(im.media_influence_day())],
		Color(0.74, 0.70, 0.88), 12)
	for m in im.MEDIA:
		_vb.add_child(_media_card(m))
	# Кампании
	if im.media_reach() > 0:
		_vb.add_child(_campaign_card("pr"))
		_vb.add_child(_campaign_card("smear"))
	else:
		_note("Купите хотя бы одно СМИ, чтобы запускать PR и компромат.")
	_sep()

	# Контроль районов
	_header("🗳 Контроль районов")
	_lbl(_vb, "Под контролем: %d из %d  ·  +%d%% к доходу бизнеса" % [
		im.controlled_count(), im.district_count(),
		int(round((im.district_income_mult() - 1.0) * 100.0))],
		Color(0.74, 0.70, 0.88), 12)
	for i in range(im.district_count()):
		_vb.add_child(_district_card(i))
	_sep()

	# Своя партия
	_header("🎌 Своя партия")
	if not im.party_founded:
		_vb.add_child(_party_found_card())
	else:
		_lbl(_vb, "Членов: %d  ·  сила %d%%  ·  +%d%% к выборам  ·  +%d влияния/день" % [
			int(im.party_members), int(round(im.party_strength() * 100.0)),
			int(round(im.party_election_bonus() * 100.0)), int(im.party_influence_day())],
			Color(0.74, 0.70, 0.88), 12)
		_vb.add_child(_party_recruit_card())
		_lbl(_vb, "Идеология:", Color(0.66, 0.62, 0.76), 11)
		for ig in im.IDEOLOGIES:
			_vb.add_child(_ideology_card(ig))
	_sep()

	# Высшая власть и риски
	_header("⚖️ Высшая власть и риски")
	var heat_pct: int = int(round(im.scrutiny() / im.HEAT_MAX * 100.0))
	var inv_pct: int = int(round(im.investigation_chance() * 100.0))
	var hcol: Color = Color(0.95, 0.45, 0.4) if heat_pct >= 60 else (Color(0.95, 0.78, 0.4) if heat_pct >= 30 else Color(0.55, 0.85, 0.6))
	_lbl(_vb, "Подозрение: %d%%  ·  риск расследования: %d%%/мес" % [heat_pct, inv_pct], hcol, 12)
	if im.is_grey_cardinal():
		_lbl(_vb, "👑 Вы — Серый кардинал. Город под вашей теневой властью.", Color(0.95, 0.85, 0.45), 12)
	else:
		_lbl(_vb, "Серый кардинал: %d/%d районов · связи %d/%d · нужен Новостной портал" % [
			im.controlled_count(), im.GC_DISTRICTS, im.total_connection_levels(), im.max_connection_total()],
			Color(0.66, 0.62, 0.76), 11)
	_vb.add_child(_coverup_card())
	if im.has_immunity():
		_lbl(_vb, "🛡 Иммунитет от расследований: ещё %d дн." % im.intel_immunity_days, Color(0.55, 0.85, 0.6), 11)
	_sep()

	# Спецслужбы и досье
	_header("🕵 Спецслужбы и досье")
	_vb.add_child(_intel_service_card())
	if im.intel_active():
		_lbl(_vb, "Досье: %d/%d  ·  слежка: %d%%" % [im.dossiers, im.DOSSIER_MAX,
			int(round(im.surveillance_progress() * 100.0))], Color(0.74, 0.70, 0.88), 12)
		_vb.add_child(_intel_action_card("surveil"))
		_vb.add_child(_intel_action_card("blackmail"))
		_vb.add_child(_intel_action_card("sabotage"))
		_vb.add_child(_intel_action_card("immunity"))
	_sep()

	# Президентская гонка (капстоун)
	_header("🏛 Президентская гонка")
	if im.is_president:
		_lbl(_vb, "🏛 Вы — Президент страны. Высшая власть достигнута.", Color(0.95, 0.85, 0.45), 14)
		_lbl(_vb, "Бонусы: +%d%% к доходу бизнеса, +%d влияния/день, иммунитет к расследованиям." % [
			int(im.PRES_INCOME_BONUS * 100.0), int(im.PRES_INFLUENCE_DAY)], Color(0.74, 0.80, 0.70), 11)
	else:
		var sup: int = int(round(im.national_support() * 100.0))
		var req: int = int(im.PRES_MIN_SUPPORT * 100.0)
		var scol: Color = Color(0.55, 0.85, 0.6) if sup >= req else Color(0.95, 0.78, 0.4)
		_lbl(_vb, "Национальный рейтинг: %d%%  (нужно %d%%)" % [sup, req], scol, 13)
		_lbl(_vb, "Рейтинг растят районы, партия, СМИ, репутация и связи.", Color(0.66, 0.62, 0.76), 11)
		_vb.add_child(_president_card())

	var spacer := Control.new()
	spacer.custom_minimum_size = Vector2(0, 8)
	_vb.add_child(spacer)
	var close_btn := Button.new()
	close_btn.text = "Закрыть"
	close_btn.add_theme_font_size_override("font_size", 16)
	_style(close_btn, Color(0.16, 0.12, 0.20), Color(0.5, 0.4, 0.65))
	close_btn.pressed.connect(close)
	_vb.add_child(close_btn)

func _donation_card(d: Dictionary) -> PanelContainer:
	var card := PanelContainer.new()
	var cs := StyleBoxFlat.new()
	cs.bg_color = Color(0.10, 0.08, 0.14, 0.9)
	cs.border_color = Color(0.45, 0.38, 0.6, 0.7)
	cs.set_border_width_all(1); cs.set_corner_radius_all(8); cs.set_content_margin_all(10)
	card.add_theme_stylebox_override("panel", cs)
	var row := HBoxContainer.new(); row.add_theme_constant_override("separation", 10); card.add_child(row)
	var col := VBoxContainer.new(); col.size_flags_horizontal = Control.SIZE_EXPAND_FILL; row.add_child(col)
	_lbl(col, d.get("name", "?"), Color(0.88, 0.85, 0.95), 14)
	_lbl(col, "%s → +%d влияния · +%d репутации" % [gm.format_money(d.cost), int(d.inf), int(d.get("rep", 0))], Color(0.70, 0.66, 0.82), 11)
	var did: String = d.id
	var btn := Button.new(); btn.text = "Пожертвовать"
	btn.add_theme_font_size_override("font_size", 12)
	if im.can_donate(did):
		_style(btn, Color(0.16, 0.13, 0.24), Color(0.5, 0.42, 0.72))
		btn.pressed.connect(func(): im.donate(did))
	else:
		_style(btn, Color(0.09, 0.09, 0.13), Color(0.26, 0.26, 0.36, 0.55)); btn.disabled = true
	btn.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(btn)
	return card

func _official_card(o: Dictionary) -> PanelContainer:
	var oid: String = o.id
	var lvl: int = im.connection_level(oid)
	var card := PanelContainer.new()
	var cs := StyleBoxFlat.new()
	cs.bg_color = Color(0.09, 0.07, 0.13, 0.92)
	cs.border_color = Color(0.55, 0.42, 0.78, 0.8) if lvl > 0 else Color(0.32, 0.28, 0.42, 0.6)
	cs.set_border_width_all(1); cs.set_corner_radius_all(8); cs.set_content_margin_all(10)
	card.add_theme_stylebox_override("panel", cs)
	var row := HBoxContainer.new(); row.add_theme_constant_override("separation", 10); card.add_child(row)
	var icon := Label.new(); icon.text = o.get("icon", "🤝")
	icon.add_theme_font_size_override("font_size", 24); icon.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	row.add_child(icon)
	var col := VBoxContainer.new(); col.size_flags_horizontal = Control.SIZE_EXPAND_FILL; row.add_child(col)
	var dots: String = ""
	for s in range(im.MAX_CONNECTION_LEVEL):
		dots += "●" if s < lvl else "○"
	_lbl(col, "%s  %s" % [o.get("name", "?"), dots], Color(0.88, 0.82, 1.0), 14)
	_lbl(col, o.get("desc", ""), Color(0.68, 0.64, 0.80), 11)

	var btn := Button.new()
	btn.add_theme_font_size_override("font_size", 11)
	btn.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	if lvl >= im.MAX_CONNECTION_LEVEL:
		btn.text = "✅ Максимум"
		_style(btn, Color(0.10, 0.16, 0.10), Color(0.35, 0.55, 0.35)); btn.disabled = true
	elif not im.politics_unlocked():
		btn.text = "🔒 Титул %d" % im.CONN_MIN_TITLE
		_style(btn, Color(0.09, 0.09, 0.13), Color(0.26, 0.26, 0.36, 0.55)); btn.disabled = true
	else:
		btn.text = "Укрепить (%d вл. + %s)" % [im.conn_inf_cost(oid), gm.format_money(im.conn_money_cost(oid))]
		if im.can_raise_connection(oid):
			_style(btn, Color(0.16, 0.13, 0.24), Color(0.5, 0.42, 0.72))
			btn.pressed.connect(func(): im.raise_connection(oid))
		else:
			_style(btn, Color(0.09, 0.09, 0.13), Color(0.26, 0.26, 0.36, 0.55)); btn.disabled = true
	row.add_child(btn)
	return card

func _law_card(l: Dictionary) -> PanelContainer:
	var lid: String = l.id
	var active: bool = im.law_active(lid)
	var cooldown: int = im.law_cooldown_left(lid)
	var card := PanelContainer.new()
	var cs := StyleBoxFlat.new()
	cs.bg_color = Color(0.09, 0.07, 0.13, 0.92)
	cs.border_color = Color(0.55, 0.45, 0.30, 0.85) if active else Color(0.32, 0.28, 0.42, 0.6)
	cs.set_border_width_all(1); cs.set_corner_radius_all(8); cs.set_content_margin_all(10)
	card.add_theme_stylebox_override("panel", cs)
	var row := HBoxContainer.new(); row.add_theme_constant_override("separation", 10); card.add_child(row)
	var icon := Label.new(); icon.text = l.get("icon", "📜")
	icon.add_theme_font_size_override("font_size", 24); icon.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	row.add_child(icon)
	var col := VBoxContainer.new(); col.size_flags_horizontal = Control.SIZE_EXPAND_FILL; row.add_child(col)
	var status: String = ""
	if active: status = "  🟢 действует %d дн." % im.law_days_left(lid)
	elif cooldown > 0: status = "  ⏳ остывание %d дн." % cooldown
	_lbl(col, l.get("name", "?") + status, Color(0.90, 0.84, 1.0), 14)
	_lbl(col, "%s  ·  %d вл.%s · −%d реп." % [l.get("desc", ""), int(l.inf),
		(" + " + gm.format_money(l.money)) if int(l.money) > 0 else "", -int(l.get("rep", 0))],
		Color(0.68, 0.64, 0.80), 11)
	var btn := Button.new()
	btn.add_theme_font_size_override("font_size", 12)
	btn.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	if active:
		btn.text = "Активен"
		_style(btn, Color(0.12, 0.16, 0.10), Color(0.4, 0.55, 0.3)); btn.disabled = true
	elif cooldown > 0:
		btn.text = "Остывание"
		_style(btn, Color(0.09, 0.09, 0.13), Color(0.26, 0.26, 0.36, 0.55)); btn.disabled = true
	elif not im.politics_unlocked():
		btn.text = "🔒 Титул %d" % im.CONN_MIN_TITLE
		_style(btn, Color(0.09, 0.09, 0.13), Color(0.26, 0.26, 0.36, 0.55)); btn.disabled = true
	else:
		btn.text = "Провести"
		if im.can_pass_law(lid):
			_style(btn, Color(0.16, 0.13, 0.24), Color(0.5, 0.42, 0.72))
			btn.pressed.connect(func(): im.pass_law(lid))
		else:
			_style(btn, Color(0.09, 0.09, 0.13), Color(0.26, 0.26, 0.36, 0.55)); btn.disabled = true
	row.add_child(btn)
	return card

func _media_card(m: Dictionary) -> PanelContainer:
	var mid: String = m.id
	var owned: bool = im.owns_media(mid)
	var locked: bool = gm.current_title_index < int(m.min_title)
	var card := PanelContainer.new()
	var cs := StyleBoxFlat.new()
	cs.bg_color = Color(0.09, 0.07, 0.13, 0.92)
	cs.border_color = Color(0.55, 0.42, 0.78, 0.85) if owned else Color(0.32, 0.28, 0.42, 0.6)
	cs.set_border_width_all(1); cs.set_corner_radius_all(8); cs.set_content_margin_all(10)
	card.add_theme_stylebox_override("panel", cs)
	var row := HBoxContainer.new(); row.add_theme_constant_override("separation", 10); card.add_child(row)
	var icon := Label.new(); icon.text = m.get("icon", "📡")
	icon.add_theme_font_size_override("font_size", 24); icon.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	row.add_child(icon)
	var col := VBoxContainer.new(); col.size_flags_horizontal = Control.SIZE_EXPAND_FILL; row.add_child(col)
	_lbl(col, m.get("name", "?") + ("  ✅" if owned else ""), Color(0.90, 0.84, 1.0), 14)
	_lbl(col, "%s  ·  охват +%d · +%d влияния/день" % [m.get("desc", ""), int(m.reach), int(m.inf_day)],
		Color(0.68, 0.64, 0.80), 11)
	var btn := Button.new()
	btn.add_theme_font_size_override("font_size", 12)
	btn.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	if owned:
		btn.text = "В собственности"
		_style(btn, Color(0.12, 0.16, 0.10), Color(0.4, 0.55, 0.3)); btn.disabled = true
	elif locked:
		btn.text = "🔒 Титул %d" % int(m.min_title)
		_style(btn, Color(0.09, 0.09, 0.13), Color(0.26, 0.26, 0.36, 0.55)); btn.disabled = true
	else:
		btn.text = "Купить (%s)" % gm.format_money(m.cost)
		if im.can_buy_media(mid):
			_style(btn, Color(0.16, 0.13, 0.24), Color(0.5, 0.42, 0.72))
			btn.pressed.connect(func(): im.buy_media(mid))
		else:
			_style(btn, Color(0.09, 0.09, 0.13), Color(0.26, 0.26, 0.36, 0.55)); btn.disabled = true
	row.add_child(btn)
	return card

func _campaign_card(kind: String) -> PanelContainer:
	var is_pr: bool = kind == "pr"
	var cd: int = im.campaign_cd_left(kind)
	var card := PanelContainer.new()
	var cs := StyleBoxFlat.new()
	cs.bg_color = Color(0.11, 0.08, 0.10, 0.92) if not is_pr else Color(0.08, 0.10, 0.13, 0.92)
	cs.border_color = Color(0.62, 0.40, 0.45, 0.7) if not is_pr else Color(0.40, 0.55, 0.70, 0.7)
	cs.set_border_width_all(1); cs.set_corner_radius_all(8); cs.set_content_margin_all(10)
	card.add_theme_stylebox_override("panel", cs)
	var row := HBoxContainer.new(); row.add_theme_constant_override("separation", 10); card.add_child(row)
	var icon := Label.new(); icon.text = "📣" if is_pr else "🗞"
	icon.add_theme_font_size_override("font_size", 22); icon.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	row.add_child(icon)
	var col := VBoxContainer.new(); col.size_flags_horizontal = Control.SIZE_EXPAND_FILL; row.add_child(col)
	if is_pr:
		_lbl(col, "PR-кампания", Color(0.86, 0.90, 1.0), 14)
		_lbl(col, "+%d репутации · %d влияния" % [im.PR_REP_BASE + im.media_reach(), int(im.PR_INF_COST)], Color(0.68, 0.72, 0.85), 11)
	else:
		_lbl(col, "Компромат на конкурента", Color(1.0, 0.84, 0.86), 14)
		_lbl(col, "Перетянуть долю рынка + сбить антимонополию · %d влияния + %s" % [int(im.SMEAR_INF_COST), gm.format_money(im.SMEAR_MONEY_COST)], Color(0.85, 0.68, 0.70), 11)
	var btn := Button.new()
	btn.add_theme_font_size_override("font_size", 12)
	btn.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	if cd > 0:
		btn.text = "⏳ %d дн." % cd
		_style(btn, Color(0.09, 0.09, 0.13), Color(0.26, 0.26, 0.36, 0.55)); btn.disabled = true
	else:
		btn.text = "Запустить"
		var ok: bool = im.can_run_pr() if is_pr else im.can_run_smear()
		if ok:
			_style(btn, Color(0.16, 0.13, 0.24), Color(0.5, 0.42, 0.72))
			if is_pr: btn.pressed.connect(func(): im.run_pr())
			else: btn.pressed.connect(func(): im.run_smear())
		else:
			_style(btn, Color(0.09, 0.09, 0.13), Color(0.26, 0.26, 0.36, 0.55)); btn.disabled = true
	row.add_child(btn)
	return card

func _district_card(i: int) -> PanelContainer:
	var controlled: bool = im.controls(i)
	var cd: int = im.election_cd_left(i)
	var card := PanelContainer.new()
	var cs := StyleBoxFlat.new()
	cs.bg_color = Color(0.07, 0.10, 0.08, 0.92) if controlled else Color(0.09, 0.07, 0.13, 0.92)
	cs.border_color = Color(0.40, 0.65, 0.42, 0.85) if controlled else Color(0.32, 0.28, 0.42, 0.6)
	cs.set_border_width_all(1); cs.set_corner_radius_all(8); cs.set_content_margin_all(10)
	card.add_theme_stylebox_override("panel", cs)
	var row := HBoxContainer.new(); row.add_theme_constant_override("separation", 10); card.add_child(row)
	var col := VBoxContainer.new(); col.size_flags_horizontal = Control.SIZE_EXPAND_FILL; row.add_child(col)
	var status: String = "  ✅ под контролем" if controlled else ""
	_lbl(col, im.district_name(i) + status, Color(0.86, 0.92, 0.86) if controlled else Color(0.88, 0.84, 0.98), 14)
	if not controlled:
		_lbl(col, "Шанс победы: %d%%  ·  %d вл. + %s" % [
			int(round(im.election_win_chance(i) * 100.0)), im.election_inf_cost(i),
			gm.format_money(im.election_money_cost(i))], Color(0.68, 0.64, 0.80), 11)
	else:
		_lbl(col, "Даёт +%d влияния/день и долю бонуса к доходу." % int(im.DISTRICT_INF_DAY), Color(0.64, 0.80, 0.66), 11)
	var btn := Button.new()
	btn.add_theme_font_size_override("font_size", 12)
	btn.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	if controlled:
		btn.text = "Ваш"
		_style(btn, Color(0.12, 0.16, 0.10), Color(0.4, 0.55, 0.3)); btn.disabled = true
	elif cd > 0:
		btn.text = "⏳ %d дн." % cd
		_style(btn, Color(0.09, 0.09, 0.13), Color(0.26, 0.26, 0.36, 0.55)); btn.disabled = true
	elif not im.politics_unlocked():
		btn.text = "🔒 Титул %d" % im.CONN_MIN_TITLE
		_style(btn, Color(0.09, 0.09, 0.13), Color(0.26, 0.26, 0.36, 0.55)); btn.disabled = true
	else:
		btn.text = "Выдвинуться"
		if im.can_run_election(i):
			_style(btn, Color(0.16, 0.13, 0.24), Color(0.5, 0.42, 0.72))
			btn.pressed.connect(func(): im.run_election(i))
		else:
			_style(btn, Color(0.09, 0.09, 0.13), Color(0.26, 0.26, 0.36, 0.55)); btn.disabled = true
	row.add_child(btn)
	return card

func _coverup_card() -> PanelContainer:
	var cd: int = im.campaign_cd_left("coverup")
	var card := PanelContainer.new()
	var cs := StyleBoxFlat.new()
	cs.bg_color = Color(0.11, 0.08, 0.10, 0.92)
	cs.border_color = Color(0.60, 0.45, 0.40, 0.7)
	cs.set_border_width_all(1); cs.set_corner_radius_all(8); cs.set_content_margin_all(10)
	card.add_theme_stylebox_override("panel", cs)
	var row := HBoxContainer.new(); row.add_theme_constant_override("separation", 10); card.add_child(row)
	var icon := Label.new(); icon.text = "🧯"
	icon.add_theme_font_size_override("font_size", 22); icon.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	row.add_child(icon)
	var col := VBoxContainer.new(); col.size_flags_horizontal = Control.SIZE_EXPAND_FILL; row.add_child(col)
	_lbl(col, "Замять скандал", Color(1.0, 0.86, 0.82), 14)
	_lbl(col, "−%d%% подозрения · %d влияния + %s" % [int(im.COVERUP_REDUCE * 100.0),
		int(im.COVERUP_INF), gm.format_money(im.COVERUP_MONEY)], Color(0.85, 0.70, 0.68), 11)
	var btn := Button.new()
	btn.add_theme_font_size_override("font_size", 12)
	btn.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	if cd > 0:
		btn.text = "⏳ %d дн." % cd
		_style(btn, Color(0.09, 0.09, 0.13), Color(0.26, 0.26, 0.36, 0.55)); btn.disabled = true
	else:
		btn.text = "Замять"
		if im.can_coverup():
			_style(btn, Color(0.16, 0.13, 0.24), Color(0.5, 0.42, 0.72))
			btn.pressed.connect(func(): im.coverup())
		else:
			_style(btn, Color(0.09, 0.09, 0.13), Color(0.26, 0.26, 0.36, 0.55)); btn.disabled = true
	row.add_child(btn)
	return card

func _intel_service_card() -> PanelContainer:
	var lvl: int = im.intel_level
	var card := PanelContainer.new()
	var cs := StyleBoxFlat.new()
	cs.bg_color = Color(0.08, 0.08, 0.11, 0.92)
	cs.border_color = Color(0.50, 0.50, 0.58, 0.8) if lvl > 0 else Color(0.30, 0.30, 0.38, 0.6)
	cs.set_border_width_all(1); cs.set_corner_radius_all(8); cs.set_content_margin_all(10)
	card.add_theme_stylebox_override("panel", cs)
	var row := HBoxContainer.new(); row.add_theme_constant_override("separation", 10); card.add_child(row)
	var icon := Label.new(); icon.text = "🕵"
	icon.add_theme_font_size_override("font_size", 24); icon.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	row.add_child(icon)
	var col := VBoxContainer.new(); col.size_flags_horizontal = Control.SIZE_EXPAND_FILL; row.add_child(col)
	var dots: String = ""
	for s in range(im.INTEL_MAX_LEVEL):
		dots += "●" if s < lvl else "○"
	_lbl(col, "Спецслужба  %s" % dots, Color(0.88, 0.88, 0.94), 14)
	_lbl(col, "Ведёт слежку и копит досье. Выше уровень — быстрее.", Color(0.66, 0.66, 0.76), 11)
	var btn := Button.new()
	btn.add_theme_font_size_override("font_size", 12)
	btn.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	if lvl >= im.INTEL_MAX_LEVEL:
		btn.text = "✅ Максимум"
		_style(btn, Color(0.12, 0.16, 0.10), Color(0.4, 0.55, 0.3)); btn.disabled = true
	elif gm.current_title_index < im.INTEL_MIN_TITLE:
		btn.text = "🔒 Титул %d" % im.INTEL_MIN_TITLE
		_style(btn, Color(0.09, 0.09, 0.13), Color(0.26, 0.26, 0.36, 0.55)); btn.disabled = true
	else:
		btn.text = "%s (%d вл. + %s)" % ["Создать" if lvl == 0 else "Усилить", im.intel_next_inf(), gm.format_money(im.intel_next_money())]
		if im.can_upgrade_intel():
			_style(btn, Color(0.16, 0.13, 0.24), Color(0.5, 0.42, 0.72))
			btn.pressed.connect(func(): im.upgrade_intel())
		else:
			_style(btn, Color(0.09, 0.09, 0.13), Color(0.26, 0.26, 0.36, 0.55)); btn.disabled = true
	row.add_child(btn)
	return card

func _intel_action_card(kind: String) -> PanelContainer:
	var titles := {"surveil":"Заказать слежку", "blackmail":"Шантаж конкурента",
		"sabotage":"Саботаж конкурента", "immunity":"Досье на следователя"}
	var descs := {
		"surveil":"+1 досье · %d вл. + %s" % [int(im.SURVEIL_INF), gm.format_money(im.SURVEIL_MONEY)],
		"blackmail":"Конкурент откупается и отдаёт долю · 1 досье",
		"sabotage":"Жёстко обваливает долю конкурента · 1 досье",
		"immunity":"−подозрение до 0 и %d дн. иммунитета · %d досье" % [im.IMMUNITY_DAYS, im.IMMUNITY_DOSSIERS]}
	var icons := {"surveil":"🔍", "blackmail":"💼", "sabotage":"💣", "immunity":"🛡"}
	var card := PanelContainer.new()
	var cs := StyleBoxFlat.new()
	cs.bg_color = Color(0.09, 0.07, 0.11, 0.92)
	cs.border_color = Color(0.45, 0.40, 0.52, 0.7)
	cs.set_border_width_all(1); cs.set_corner_radius_all(8); cs.set_content_margin_all(10)
	card.add_theme_stylebox_override("panel", cs)
	var row := HBoxContainer.new(); row.add_theme_constant_override("separation", 10); card.add_child(row)
	var icon := Label.new(); icon.text = icons[kind]
	icon.add_theme_font_size_override("font_size", 22); icon.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	row.add_child(icon)
	var col := VBoxContainer.new(); col.size_flags_horizontal = Control.SIZE_EXPAND_FILL; row.add_child(col)
	_lbl(col, titles[kind], Color(0.88, 0.84, 0.96), 14)
	_lbl(col, descs[kind], Color(0.68, 0.64, 0.78), 11)
	var btn := Button.new()
	btn.add_theme_font_size_override("font_size", 12)
	btn.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var ok: bool = false
	var label: String = "Запустить"
	if kind == "surveil":
		var cd: int = im.campaign_cd_left("surveil")
		if cd > 0: label = "⏳ %d дн." % cd
		ok = im.can_order_surveillance()
	elif kind == "blackmail":
		ok = im.can_blackmail()
	elif kind == "sabotage":
		ok = im.can_sabotage()
	elif kind == "immunity":
		ok = im.can_buy_immunity()
	btn.text = label
	if ok:
		_style(btn, Color(0.16, 0.13, 0.24), Color(0.5, 0.42, 0.72))
		match kind:
			"surveil": btn.pressed.connect(func(): im.order_surveillance())
			"blackmail": btn.pressed.connect(func(): im.blackmail())
			"sabotage": btn.pressed.connect(func(): im.sabotage())
			"immunity": btn.pressed.connect(func(): im.buy_immunity())
	else:
		_style(btn, Color(0.09, 0.09, 0.13), Color(0.26, 0.26, 0.36, 0.55)); btn.disabled = true
	row.add_child(btn)
	return card

func _party_found_card() -> PanelContainer:
	var card := PanelContainer.new()
	var cs := StyleBoxFlat.new()
	cs.bg_color = Color(0.09, 0.07, 0.13, 0.92)
	cs.border_color = Color(0.45, 0.40, 0.60, 0.7)
	cs.set_border_width_all(1); cs.set_corner_radius_all(8); cs.set_content_margin_all(10)
	card.add_theme_stylebox_override("panel", cs)
	var row := HBoxContainer.new(); row.add_theme_constant_override("separation", 10); card.add_child(row)
	var icon := Label.new(); icon.text = "🎌"
	icon.add_theme_font_size_override("font_size", 24); icon.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	row.add_child(icon)
	var col := VBoxContainer.new(); col.size_flags_horizontal = Control.SIZE_EXPAND_FILL; row.add_child(col)
	_lbl(col, "Основать партию", Color(0.88, 0.84, 0.96), 14)
	_lbl(col, "Легальная опора власти: члены, идеология, бонус к выборам.", Color(0.66, 0.62, 0.76), 11)
	var btn := Button.new()
	btn.add_theme_font_size_override("font_size", 12)
	btn.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	if gm.current_title_index < im.PARTY_MIN_TITLE:
		btn.text = "🔒 Титул %d" % im.PARTY_MIN_TITLE
		_style(btn, Color(0.09, 0.09, 0.13), Color(0.26, 0.26, 0.36, 0.55)); btn.disabled = true
	else:
		btn.text = "Основать (%d вл. + %s)" % [int(im.PARTY_FOUND_INF), gm.format_money(im.PARTY_FOUND_MONEY)]
		if im.can_found_party():
			_style(btn, Color(0.16, 0.13, 0.24), Color(0.5, 0.42, 0.72))
			btn.pressed.connect(func(): im.found_party())
		else:
			_style(btn, Color(0.09, 0.09, 0.13), Color(0.26, 0.26, 0.36, 0.55)); btn.disabled = true
	row.add_child(btn)
	return card

func _party_recruit_card() -> PanelContainer:
	var cd: int = im.campaign_cd_left("recruit")
	var card := PanelContainer.new()
	var cs := StyleBoxFlat.new()
	cs.bg_color = Color(0.09, 0.07, 0.11, 0.92)
	cs.border_color = Color(0.45, 0.40, 0.52, 0.7)
	cs.set_border_width_all(1); cs.set_corner_radius_all(8); cs.set_content_margin_all(10)
	card.add_theme_stylebox_override("panel", cs)
	var row := HBoxContainer.new(); row.add_theme_constant_override("separation", 10); card.add_child(row)
	var icon := Label.new(); icon.text = "📋"
	icon.add_theme_font_size_override("font_size", 22); icon.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	row.add_child(icon)
	var col := VBoxContainer.new(); col.size_flags_horizontal = Control.SIZE_EXPAND_FILL; row.add_child(col)
	_lbl(col, "Кампания по набору", Color(0.88, 0.84, 0.96), 14)
	_lbl(col, "+%d членов · %s" % [int(im.PARTY_RECRUIT_MEMBERS), gm.format_money(im.PARTY_RECRUIT_MONEY)], Color(0.66, 0.62, 0.76), 11)
	var btn := Button.new()
	btn.add_theme_font_size_override("font_size", 12)
	btn.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	if cd > 0:
		btn.text = "⏳ %d дн." % cd
		_style(btn, Color(0.09, 0.09, 0.13), Color(0.26, 0.26, 0.36, 0.55)); btn.disabled = true
	else:
		btn.text = "Набор"
		if im.can_recruit():
			_style(btn, Color(0.16, 0.13, 0.24), Color(0.5, 0.42, 0.72))
			btn.pressed.connect(func(): im.recruit())
		else:
			_style(btn, Color(0.09, 0.09, 0.13), Color(0.26, 0.26, 0.36, 0.55)); btn.disabled = true
	row.add_child(btn)
	return card

func _ideology_card(ig: Dictionary) -> PanelContainer:
	var iid: String = ig.id
	var chosen: bool = im.party_ideology == iid
	var card := PanelContainer.new()
	var cs := StyleBoxFlat.new()
	cs.bg_color = Color(0.07, 0.10, 0.08, 0.92) if chosen else Color(0.09, 0.07, 0.11, 0.92)
	cs.border_color = Color(0.40, 0.65, 0.42, 0.85) if chosen else Color(0.34, 0.30, 0.42, 0.6)
	cs.set_border_width_all(1); cs.set_corner_radius_all(8); cs.set_content_margin_all(10)
	card.add_theme_stylebox_override("panel", cs)
	var row := HBoxContainer.new(); row.add_theme_constant_override("separation", 10); card.add_child(row)
	var icon := Label.new(); icon.text = ig.get("icon", "🎌")
	icon.add_theme_font_size_override("font_size", 22); icon.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	row.add_child(icon)
	var col := VBoxContainer.new(); col.size_flags_horizontal = Control.SIZE_EXPAND_FILL; row.add_child(col)
	_lbl(col, ig.get("name", "?") + ("  ✅" if chosen else ""), Color(0.88, 0.84, 0.96), 14)
	_lbl(col, ig.get("desc", ""), Color(0.66, 0.62, 0.76), 11)
	var btn := Button.new()
	btn.add_theme_font_size_override("font_size", 12)
	btn.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	if chosen:
		btn.text = "Выбрана"
		_style(btn, Color(0.12, 0.16, 0.10), Color(0.4, 0.55, 0.3)); btn.disabled = true
	else:
		var cost: int = int(im.ideology_switch_cost())
		btn.text = "Выбрать" if cost == 0 else "Сменить (%d вл.)" % cost
		if im.can_set_ideology(iid):
			_style(btn, Color(0.16, 0.13, 0.24), Color(0.5, 0.42, 0.72))
			btn.pressed.connect(func(): im.set_ideology(iid))
		else:
			_style(btn, Color(0.09, 0.09, 0.13), Color(0.26, 0.26, 0.36, 0.55)); btn.disabled = true
	row.add_child(btn)
	return card

func _president_card() -> PanelContainer:
	var cd: int = im.election_attempt_cd
	var card := PanelContainer.new()
	var cs := StyleBoxFlat.new()
	cs.bg_color = Color(0.10, 0.09, 0.06, 0.94)
	cs.border_color = Color(0.70, 0.58, 0.30, 0.85)
	cs.set_border_width_all(1); cs.set_corner_radius_all(8); cs.set_content_margin_all(10)
	card.add_theme_stylebox_override("panel", cs)
	var row := HBoxContainer.new(); row.add_theme_constant_override("separation", 10); card.add_child(row)
	var icon := Label.new(); icon.text = "🏛"
	icon.add_theme_font_size_override("font_size", 24); icon.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	row.add_child(icon)
	var col := VBoxContainer.new(); col.size_flags_horizontal = Control.SIZE_EXPAND_FILL; row.add_child(col)
	_lbl(col, "Баллотироваться в Президенты", Color(0.96, 0.90, 0.70), 14)
	_lbl(col, "Шанс = рейтинг · %d вл. + %s" % [int(im.PRES_ENTRY_INF), gm.format_money(im.PRES_ENTRY_MONEY)], Color(0.80, 0.74, 0.60), 11)
	var btn := Button.new()
	btn.add_theme_font_size_override("font_size", 12)
	btn.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	if cd > 0:
		btn.text = "⏳ %d дн." % cd
		_style(btn, Color(0.09, 0.09, 0.13), Color(0.26, 0.26, 0.36, 0.55)); btn.disabled = true
	elif not im.politics_unlocked():
		btn.text = "🔒 Титул %d" % im.CONN_MIN_TITLE
		_style(btn, Color(0.09, 0.09, 0.13), Color(0.26, 0.26, 0.36, 0.55)); btn.disabled = true
	else:
		btn.text = "Идти на выборы"
		if im.can_run_president():
			_style(btn, Color(0.22, 0.17, 0.10), Color(0.7, 0.55, 0.3))
			btn.pressed.connect(func(): im.run_for_president())
		else:
			_style(btn, Color(0.09, 0.09, 0.13), Color(0.26, 0.26, 0.36, 0.55)); btn.disabled = true
	row.add_child(btn)
	return card

# ── helpers ───────────────────────────────────────────────────────────────────
func _title(t: String) -> void:
	var l := Label.new(); l.text = t
	l.add_theme_font_size_override("font_size", 24)
	l.add_theme_color_override("font_color", Color(1, 1, 1))
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_vb.add_child(l)

func _header(t: String) -> void:
	var s := Control.new(); s.custom_minimum_size = Vector2(0, 4); _vb.add_child(s)
	var l := Label.new(); l.text = t
	l.add_theme_font_size_override("font_size", 15)
	l.add_theme_color_override("font_color", Color(0.72, 0.58, 0.95))
	_vb.add_child(l)

func _lbl(parent: Node, t: String, c: Color, sz: int) -> Label:
	var l := Label.new(); l.text = t
	l.add_theme_font_size_override("font_size", sz)
	l.add_theme_color_override("font_color", c)
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	parent.add_child(l)
	return l

func _note(t: String) -> void:
	_lbl(_vb, t, Color(0.72, 0.66, 0.80), 13)

func _sep() -> void:
	var line := ColorRect.new()
	line.color = Color(0.4, 0.32, 0.5, 0.5)
	line.custom_minimum_size = Vector2(0, 1)
	_vb.add_child(line)

func _style(b: Button, bg: Color, border: Color) -> void:
	var sb := StyleBoxFlat.new()
	sb.bg_color = bg; sb.border_color = border
	sb.set_border_width_all(1); sb.set_corner_radius_all(8); sb.set_content_margin_all(8)
	b.add_theme_stylebox_override("normal", sb)
	var hov := sb.duplicate(); hov.bg_color = bg.lightened(0.10)
	b.add_theme_stylebox_override("hover", hov)
	b.add_theme_color_override("font_color", Color(0.92, 0.9, 0.96))
