extends CanvasLayer

var _im: Node
var _gm: Node
var _em: Node
var _title_lbl: Label
var _tab_row: HBoxContainer
var _list: VBoxContainer
var _panel: Panel

var _available_items: Array = []
var _current_tab: String = "food"
var _work_reward: float = 0.0
var _work_edu_req: int = 0
var _work_callback: Callable = Callable()

const TAB_META := {
	"food":  {"label": "🍽 Еда",      "color": Color(0.55, 0.35, 0.15)},
	"drink": {"label": "💧 Напитки",  "color": Color(0.15, 0.35, 0.55)},
	"heal":  {"label": "❤ Лечение",  "color": Color(0.20, 0.50, 0.30)},
	"meal":  {"label": "🍴 Обед",     "color": Color(0.50, 0.25, 0.45)},
	"work":  {"label": "💼 Работать", "color": Color(0.20, 0.25, 0.50)},
}

func _ready() -> void:
	layer = 11
	visible = false
	_im = get_node("/root/InventoryManager")
	_gm = get_node("/root/GameManager")
	_em = get_node_or_null("/root/EducationManager")
	_build_ui()

func _build_ui() -> void:
	var dimmer := ColorRect.new()
	dimmer.set_anchors_preset(Control.PRESET_FULL_RECT)
	dimmer.color = Color(0, 0, 0, 0.78)
	dimmer.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(dimmer)

	_panel = Panel.new()
	_panel.set_anchors_preset(Control.PRESET_CENTER)
	_panel.position = Vector2(-260, -270)
	_panel.size = Vector2(520, 540)
	var ps := StyleBoxFlat.new()
	ps.bg_color = Color(0.05, 0.05, 0.09, 0.97)
	ps.border_color = UITheme.GOLD_DIM
	for side in [SIDE_LEFT, SIDE_RIGHT, SIDE_TOP, SIDE_BOTTOM]:
		ps.set_border_width(side, 2)
		ps.set_corner_radius(side, 10)
	_panel.add_theme_stylebox_override("panel", ps)
	add_child(_panel)

	var vbox := VBoxContainer.new()
	vbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	vbox.add_theme_constant_override("separation", 6)
	_panel.add_child(vbox)

	# Заголовок
	var header := HBoxContainer.new()
	vbox.add_child(header)
	_title_lbl = Label.new()
	_title_lbl.text = "🛒 Магазин"
	_title_lbl.add_theme_font_size_override("font_size", 20)
	_title_lbl.add_theme_color_override("font_color", Color(1.0, 0.88, 0.25))
	_title_lbl.add_theme_constant_override("outline_size", 3)
	_title_lbl.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.70))
	_title_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(_title_lbl)
	var close := Button.new()
	close.text = "✕"
	close.custom_minimum_size = Vector2(34, 34)
	close.add_theme_font_size_override("font_size", 14)
	var cs := StyleBoxFlat.new()
	cs.bg_color = Color(0.22, 0.07, 0.07, 0.90)
	cs.border_color = Color(0.55, 0.18, 0.18, 0.80)
	for s in [SIDE_LEFT, SIDE_RIGHT, SIDE_TOP, SIDE_BOTTOM]:
		cs.set_border_width(s, 1)
		cs.set_corner_radius(s, 6)
	close.add_theme_stylebox_override("normal", cs)
	close.pressed.connect(func(): visible = false)
	header.add_child(close)

	vbox.add_child(HSeparator.new())

	# Вкладки
	_tab_row = HBoxContainer.new()
	_tab_row.add_theme_constant_override("separation", 4)
	vbox.add_child(_tab_row)

	vbox.add_child(HSeparator.new())

	# Список товаров
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(scroll)

	_list = VBoxContainer.new()
	_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_list.add_theme_constant_override("separation", 4)
	scroll.add_child(_list)

func open(shop_name: String, items: Array, work_reward: float = 0.0, work_edu_req: int = 0, work_callback: Callable = Callable()) -> void:
	_title_lbl.text = shop_name
	_available_items = items
	_work_reward = work_reward
	_work_edu_req = work_edu_req
	_work_callback = work_callback
	_rebuild_tabs()
	visible = true
	_panel.modulate.a = 0.0
	_panel.scale = Vector2(0.92, 0.92)
	var tw := create_tween()
	tw.set_parallel(true)
	tw.tween_property(_panel, "modulate:a", 1.0, 0.22)
	tw.tween_property(_panel, "scale", Vector2(1.0, 1.0), 0.22).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	_refresh()

func _rebuild_tabs() -> void:
	for c in _tab_row.get_children():
		c.queue_free()

	# Определяем какие типы есть в этом магазине
	var present_types: Array = []
	for iid in _available_items:
		if not _im.ITEMS.has(iid):
			continue
		var t: String = _im.ITEMS[iid].type
		if t not in present_types:
			present_types.append(t)

	# Порядок вкладок
	var all_tabs: Array = []
	var order := ["food", "drink", "heal", "meal"]
	for t in order:
		if t in present_types:
			all_tabs.append(t)
			_add_tab_btn(t)

	if _work_reward > 0:
		all_tabs.append("work")
		_add_tab_btn("work")

	# Сбрасываем на первую вкладку только если текущая недоступна в этом магазине
	if _current_tab not in all_tabs and all_tabs.size() > 0:
		_current_tab = all_tabs[0]

func _add_tab_btn(type: String) -> void:
	var meta: Dictionary = TAB_META[type]
	var btn := Button.new()
	btn.text = meta.label
	btn.custom_minimum_size = Vector2(0, 30)
	btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	btn.add_theme_font_size_override("font_size", 12)
	var active: bool = (type == _current_tab)
	var col: Color = meta.color
	var s := StyleBoxFlat.new()
	s.bg_color = col if active else col.darkened(0.45)
	s.border_color = col.lightened(0.2) if active else Color(col.r, col.g, col.b, 0.4)
	for side in [SIDE_LEFT, SIDE_RIGHT, SIDE_TOP, SIDE_BOTTOM]:
		s.set_border_width(side, 1 if not active else 2)
		s.set_corner_radius(side, 5)
	btn.add_theme_stylebox_override("normal", s)
	var sh := s.duplicate() as StyleBoxFlat
	sh.bg_color = col.lightened(0.1)
	btn.add_theme_stylebox_override("hover", sh)
	btn.pressed.connect(func():
		_current_tab = type
		_rebuild_tabs()
		_refresh()
	)
	_tab_row.add_child(btn)

func _refresh() -> void:
	for c in _list.get_children():
		c.queue_free()

	if _current_tab == "work":
		_refresh_work_tab()
		return

	var money_lbl := Label.new()
	money_lbl.text = "💰 Наличные: " + _gm.format_money(_gm.money)
	money_lbl.add_theme_font_size_override("font_size", 13)
	money_lbl.add_theme_color_override("font_color", Color(1.0, 0.85, 0.3))
	_list.add_child(money_lbl)

	# Бафф обеда если активен
	if _gm.meal_buff_days > 0:
		var buff_lbl := Label.new()
		buff_lbl.text = "🍴 Бонус обеда: -%.0f%% расход еды/воды (%d дн.)" % [_gm.meal_drain_bonus * 100, _gm.meal_buff_days]
		buff_lbl.add_theme_font_size_override("font_size", 11)
		buff_lbl.add_theme_color_override("font_color", Color(0.6, 1.0, 0.7))
		_list.add_child(buff_lbl)

	# Контекст цен: активный ценовой шок (дефицит/распродажа), чтобы цены были понятны
	var _cb = get_node_or_null("/root/CentralBankManager")
	if _cb and _cb.has_method("has_shock") and _cb.has_shock():
		var up: bool = _cb.price_shock > 1.0
		var shock_lbl := Label.new()
		shock_lbl.text = "🛒 %s: цены %s на %d%% (ещё %d дн.)" % [_cb.shock_name,
			("выше" if up else "ниже"), int(round(absf(_cb.price_shock - 1.0) * 100.0)), _cb.shock_days_left]
		shock_lbl.add_theme_font_size_override("font_size", 11)
		shock_lbl.add_theme_color_override("font_color", Color(1.0, 0.55, 0.4) if up else Color(0.55, 1.0, 0.6))
		_list.add_child(shock_lbl)

	_list.add_child(HSeparator.new())

	var shown := 0
	for item_id in _available_items:
		if not _im.ITEMS.has(item_id):
			continue
		var item: Dictionary = _im.ITEMS[item_id]
		if item.type != _current_tab:
			continue
		shown += 1
		_add_item_row(item_id, item)

	if shown == 0:
		var empty := Label.new()
		empty.text = "Нет товаров в этой категории"
		empty.add_theme_font_size_override("font_size", 12)
		empty.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5))
		empty.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		_list.add_child(empty)

func _refresh_work_tab() -> void:
	var can_work: bool = true
	var edu_level: int = _em.level if _em else 0

	# Ставка/смена (та же механика, что и у обычной работы)
	var salary_lbl := Label.new()
	salary_lbl.text = "💼 Ставка: " + _gm.format_money((_work_reward / 8.0) * _gm.wage_factor()) + " / час   🕒 смена 4–12 ч"
	salary_lbl.add_theme_font_size_override("font_size", 15)
	salary_lbl.add_theme_color_override("font_color", Color(0.6, 0.9, 1.0))
	salary_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_list.add_child(salary_lbl)

	_list.add_child(HSeparator.new())

	# Требование образования
	if _work_edu_req > 0 and _em:
		var req_name: String = _em.LEVELS[_work_edu_req].name
		var req_icon: String = _em.LEVELS[_work_edu_req].icon
		var cur_name: String = _em.LEVELS[edu_level].name
		can_work = _em.can_work_at(_work_edu_req)

		var req_lbl := Label.new()
		req_lbl.text = "🎓 Требуется: %s %s" % [req_icon, req_name]
		req_lbl.add_theme_font_size_override("font_size", 13)
		req_lbl.add_theme_color_override("font_color", Color(1.0, 0.85, 0.3))
		req_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		_list.add_child(req_lbl)

		var cur_lbl := Label.new()
		cur_lbl.text = "Ваш уровень: %s %s" % [_em.LEVELS[edu_level].icon, cur_name]
		cur_lbl.add_theme_font_size_override("font_size", 12)
		cur_lbl.add_theme_color_override("font_color", Color(0.55, 1.0, 0.55) if can_work else Color(1.0, 0.45, 0.45))
		cur_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		_list.add_child(cur_lbl)

		if not can_work:
			var hint_lbl := Label.new()
			hint_lbl.text = "❌ Недостаточный уровень образования"
			hint_lbl.add_theme_font_size_override("font_size", 12)
			hint_lbl.add_theme_color_override("font_color", Color(1.0, 0.4, 0.4))
			hint_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			hint_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD
			_list.add_child(hint_lbl)

		_list.add_child(HSeparator.new())

	# Кнопка работать
	var btn := Button.new()
	btn.text = "💼  Выбрать смену"
	btn.custom_minimum_size = Vector2(200, 44)
	btn.add_theme_font_size_override("font_size", 15)
	if can_work:
		btn.add_theme_color_override("font_color", Color(0.65, 1.0, 0.75))
		var bs := StyleBoxFlat.new()
		bs.bg_color = Color(0.10, 0.20, 0.40)
		bs.border_color = Color(0.30, 0.55, 0.90, 0.85)
		bs.set_border_width_all(2)
		bs.set_corner_radius_all(8)
		btn.add_theme_stylebox_override("normal", bs)
		var bsh := bs.duplicate() as StyleBoxFlat
		bsh.bg_color = Color(0.15, 0.28, 0.52)
		btn.add_theme_stylebox_override("hover", bsh)
		btn.pressed.connect(func():
			visible = false
			if _work_callback.is_valid():
				_work_callback.call()
		)
	else:
		btn.disabled = true
		btn.modulate = Color(0.40, 0.40, 0.40)

	var center := CenterContainer.new()
	center.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	center.add_child(btn)
	_list.add_child(center)

func _add_item_row(item_id: String, item: Dictionary) -> void:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	_list.add_child(row)

	var icon_lbl := Label.new()
	icon_lbl.text = item.icon
	icon_lbl.add_theme_font_size_override("font_size", 20)
	icon_lbl.custom_minimum_size = Vector2(28, 28)
	row.add_child(icon_lbl)

	var info := VBoxContainer.new()
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(info)

	var name_lbl := Label.new()
	name_lbl.text = item.name
	name_lbl.add_theme_font_size_override("font_size", 13)
	info.add_child(name_lbl)

	var eff_parts: Array = []
	if item.type == "meal":
		eff_parts.append("🍽 +100  💧 +100")
		var bonus: float = item.get("drain_bonus", 0.0)
		if bonus > 0.0:
			eff_parts.append("⏱ -%.0f%% расход / %d дн." % [bonus * 100, item.get("buff_days", 0)])
	else:
		if item.get("hunger", 0) > 0: eff_parts.append("🍽 +%d" % item.hunger)
		if item.get("thirst", 0) > 0: eff_parts.append("💧 +%d" % item.thirst)
		if item.get("health", 0) > 0: eff_parts.append("❤ +%d" % item.health)

	var eff_lbl := Label.new()
	eff_lbl.text = "  ".join(eff_parts)
	eff_lbl.add_theme_font_size_override("font_size", 11)
	eff_lbl.add_theme_color_override("font_color", Color(0.6, 0.8, 0.6))
	info.add_child(eff_lbl)

	var price: int = _gm.shop_price(item.price)
	var price_lbl := Label.new()
	price_lbl.text = _gm.format_money(price)
	price_lbl.add_theme_font_size_override("font_size", 13)
	price_lbl.add_theme_color_override("font_color", Color(1.0, 0.85, 0.3))
	price_lbl.custom_minimum_size = Vector2(80, 0)
	row.add_child(price_lbl)

	var btn := Button.new()
	btn.text = "Заказать" if item.type == "meal" else "Купить"
	btn.custom_minimum_size = Vector2(88, 28)
	btn.add_theme_font_size_override("font_size", 11)
	var can_afford: bool = _gm.money >= price
	if can_afford:
		btn.add_theme_color_override("font_color", Color(0.60, 1.0, 0.70))
		var bs := StyleBoxFlat.new()
		bs.bg_color = Color(0.07, 0.18, 0.10) if item.type != "meal" else Color(0.18, 0.07, 0.18)
		bs.border_color = Color(0.22, 0.58, 0.30, 0.85) if item.type != "meal" else Color(0.55, 0.20, 0.55, 0.85)
		for s in [SIDE_LEFT, SIDE_RIGHT, SIDE_TOP, SIDE_BOTTOM]:
			bs.set_border_width(s, 1)
			bs.set_corner_radius(s, 5)
		btn.add_theme_stylebox_override("normal", bs)
		var bsh := bs.duplicate() as StyleBoxFlat
		bsh.bg_color = bs.bg_color.lightened(0.10)
		btn.add_theme_stylebox_override("hover", bsh)
	else:
		btn.disabled = true
		btn.modulate = Color(0.45, 0.45, 0.45)
	var iid: String = item_id
	btn.pressed.connect(func(): _buy(iid))
	row.add_child(btn)

func _buy(item_id: String) -> void:
	var item: Dictionary = _im.ITEMS[item_id]
	if not _gm.spend_money(_gm.shop_price(item.price)):
		return
	var am: Node = get_node_or_null("/root/AudioManager")
	if item.type == "meal":
		_im.apply_meal_effect(item, _gm)
		if am: am.play_buy()
	else:
		_im.add_item(item_id)
		if am: am.play_buy()
	_refresh()
