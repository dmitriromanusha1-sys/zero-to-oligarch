extends CanvasLayer

const FloatingText = preload("res://scripts/FloatingText.gd")

@onready var money_label: Label    = $TopBar/Row/MoneyCol/MoneyLabel
@onready var income_label: Label   = $TopBar/Row/MoneyCol/IncomeLabel
@onready var title_label: Label    = $TopBar/Row/StatusCol/StatusRow1/TitleLabel
@onready var housing_label: Label  = $TopBar/Row/StatusCol/StatusRow1/HousingLabel
@onready var health_bar: ProgressBar = $TopBar/Row/BarsCol/HealthBar
@onready var hunger_bar: ProgressBar = $TopBar/Row/BarsCol/HungerBar
@onready var thirst_bar: ProgressBar = $TopBar/Row/BarsCol/ThirstBar
@onready var energy_bar: ProgressBar = $TopBar/Row/BarsCol/EnergyBar
@onready var day_label: Label      = $TopBar/Row/StatusCol/StatusRow2/DayLabel
@onready var time_label: Label     = $TopBar/Row/StatusCol/StatusRow2/TimeLabel
@onready var title_popup: Label    = $TitlePopup
@onready var housing_btn: Button    = $Dock/DockRow/HousingBtn
@onready var business_btn: Button   = $Dock/DockRow/BusinessBtn
@onready var quest_btn: Button      = $Dock/DockRow/QuestBtn
@onready var sleep_btn: Button        = $Dock/DockRow/SleepBtn
@onready var ach_btn: Button           = $Dock/DockRow/AchBtn
@onready var stats_btn: Button        = $Dock/DockRow/StatsBtn
@onready var stock_btn: Button        = $Dock/DockRow/StockBtn
@onready var inv_btn: Button          = $Dock/DockRow/InvBtn
@onready var loan_btn: Button         = $Dock/DockRow/LoanBtn
@onready var menu_btn: Button         = $Dock/DockRow/MenuBtn
@onready var transport_label: Label   = $TopBar/Row/StatusCol/StatusRow2/TransportLabel
@onready var reputation_label: Label  = $TopBar/Row/StatusCol/StatusRow3/ReputationLabel
@onready var education_label: Label   = $TopBar/Row/StatusCol/StatusRow3/EducationLabel
@onready var ach_ui: CanvasLayer      = $AchievementUI
@onready var stats_ui: CanvasLayer    = $StatsUI
@onready var stock_ui: CanvasLayer   = $StockUI
@onready var inv_ui: CanvasLayer     = $InventoryUI
@onready var pause_menu: CanvasLayer = $PauseMenu
@onready var loan_ui: CanvasLayer    = $LoanUI
@onready var housing_shop: Control  = $HousingShop
@onready var business_shop: Control = $BusinessShop
@onready var quest_ui: Control      = $QuestUI

var gm: Node
var bm: Node
var qm: Node
var rm: Node

var _invest_btn: Button = null
var _invest_popup: PanelContainer = null
var _zone_panel: Panel = null
var _damage_vignette: ColorRect = null
var _game_over_shown: bool = false
var _titles_handbook: CanvasLayer = null
var _titles_btn: Button = null
var _settings_ui: CanvasLayer = null
var _settings_btn: Button = null
var _journal: CanvasLayer = null
var _journal_btn: Button = null
var _economy_btn: Button = null
var _life_btn: Button = null
var _system_btn: Button = null
var _system_popup: PanelContainer = null

# Компактная верхняя панель (Фаза 1 «капремонта»)
var _info_btn: Button = null
var _info_popover: PanelContainer = null

# Категории нижнего дока (Фаза 2 «капремонта»)
var _household_btn: Button = null
var _dock_menu: PanelContainer = null
var _dock_menu_owner: Control = null

var _minimap_root: Control = null
var _minimap_player_dot: ColorRect = null
var _minimap_zone_cells: Array = []

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	add_to_group("hud")
	gm = get_node("/root/GameManager")
	bm = get_node("/root/BusinessManager")
	qm = get_node("/root/QuestManager")
	rm = get_node("/root/ReputationManager")
	rm.reputation_changed.connect(_on_reputation_changed)
	var em: Node = get_node_or_null("/root/EducationManager")
	if em: em.education_changed.connect(func(_l): _refresh_education())

	gm.money_changed.connect(_on_money_changed)
	gm.title_changed.connect(_on_title_changed)
	gm.housing_changed.connect(_on_housing_changed)
	gm.health_changed.connect(_on_health_changed)
	gm.day_changed.connect(_on_day_changed)
	gm.time_changed.connect(_on_time_changed)
	gm.hunger_changed.connect(_on_hunger_changed)
	gm.thirst_changed.connect(_on_thirst_changed)
	gm.energy_changed.connect(_on_energy_changed)
	gm.view_zoom_changed.connect(_on_view_zoom_changed)
	_on_view_zoom_changed(gm.view_zoom)
	bm.business_changed.connect(_refresh_income)
	bm.bank_changed.connect(func(_v): _refresh_income())
	qm.quest_completed.connect(_on_quest_completed)
	qm.quest_added.connect(func(_q): _refresh_quest_tracker())

	_setup_quest_tracker()
	_style_hud()
	_setup_fade_overlay()
	$TopBar.modulate.a = 0.0
	$Dock.modulate.a = 0.0
	var _hud_tw := create_tween()
	_hud_tw.set_parallel(true)
	_hud_tw.tween_property($TopBar, "modulate:a", 1.0, 0.60).set_ease(Tween.EASE_OUT)
	_hud_tw.tween_property($Dock, "modulate:a", 1.0, 0.60).set_ease(Tween.EASE_OUT)

	var zm := get_node_or_null("/root/ZoneManager")
	if zm:
		zm.zone_changed.connect(_on_zone_entered)

	_setup_zone_banner()
	_setup_hp_pulse()
	_add_vignette()
	_setup_damage_vignette()
	_setup_minimap()
	_setup_titles_handbook()
	_setup_settings_ui()

	# Запустить музыку для стартовой зоны
	var zm_init := get_node_or_null("/root/ZoneManager")
	var am_init := get_node_or_null("/root/AudioManager")
	if zm_init and am_init:
		var meta_init: Dictionary = zm_init.ZONE_META[zm_init.current_zone]
		am_init.notify_district(meta_init.name)

	# Тултипы
	housing_btn.tooltip_text   = "Купить или снять жильё.\nЖильё влияет на здоровье каждый день."
	quest_btn.tooltip_text     = "Активные цели и личный дневник.\nВыполняй цели для получения наград."
	sleep_btn.tooltip_text     = "Сон. Выбери сколько часов спать.\nТолько сон восстанавливает энергию — качество зависит от жилья."
	ach_btn.tooltip_text       = "Список достижений.\nЗарабатывай их, играя!"
	stats_btn.tooltip_text     = "Статистика и график роста капитала."
	inv_btn.tooltip_text       = "Инвентарь: еда, напитки, аптечки.\nИспользуй предметы для восстановления."
	menu_btn.tooltip_text      = "Сохранить и выйти в главное меню."
	health_bar.tooltip_text    = "❤ Здоровье. При 0 — конец игры.\nЖильё, еда и отдых восстанавливают."
	hunger_bar.tooltip_text    = "Сытость. Убывает каждый день.\nПри 0 — теряешь здоровье. Ешь!"
	thirst_bar.tooltip_text    = "Жажда. Убывает каждый день.\nПри 0 — теряешь здоровье. Пей!"
	energy_bar.tooltip_text    = "Энергия. Тратится на работе.\nПри 0 — нельзя работать. Поспи, чтобы восстановить!"

	var am = get_node_or_null("/root/AudioManager")
	housing_btn.pressed.connect(func():
		if am: am.play_click()
		housing_shop.open())
	quest_btn.pressed.connect(func():
		if am: am.play_click()
		quest_ui.open())
	sleep_btn.pressed.connect(func():
		if am: am.play_click()
		var su = get_tree().get_first_node_in_group("sleep_ui")
		if su: su.open())
	ach_btn.pressed.connect(func():
		if am: am.play_click()
		ach_ui.open())
	stats_btn.pressed.connect(func():
		if am: am.play_click()
		stats_ui.open())
	inv_btn.pressed.connect(func():
		if am: am.play_click()
		inv_ui.open())
	menu_btn.pressed.connect(_go_to_menu)

	_setup_invest_btn(am)
	_setup_journal_and_system(am)
	_setup_autosave_label()
	_setup_season_label()

	var es = get_node_or_null("/root/EventSystem")
	if es:
		es.event_triggered.connect(_on_event)

	var gm_warn = get_node_or_null("/root/GameManager")
	if gm_warn and gm_warn.has_signal("survival_warning"):
		gm_warn.survival_warning.connect(_on_survival_warning)

	_refresh()

	# Разгрузка верхней панели: иконки на полосках + поповер «Подробности».
	# Вызываем в конце — к этому моменту все динамические чипы (сезон, цикл,
	# бафф еды, истощение) уже созданы и попадут в поповер вместе со своими рядами.
	_setup_labeled_bars()
	_setup_compact_topbar()

const _MODAL_GROUPS := ["shift_ui", "sleep_ui", "food_shop", "business_shop",
	"education_shop", "transport_shop", "radio_shop", "casino_ui", "stock_ui",
	"travel_agency_ui", "loan_ui", "exam_ui", "quest_ui", "settings_ui",
	"bus_stop_ui", "minigame", "newspaper", "economy_ui", "realestate_ui", "influence_ui", "life_ui"]

func _is_blocking_ui_open() -> bool:
	if _game_over_shown or pause_menu.visible:
		return true
	for g in _MODAL_GROUPS:
		for n in get_tree().get_nodes_in_group(g):
			if "visible" in n and n.visible:
				return true
	return false

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		if _game_over_shown:
			return
		if pause_menu.visible:
			pause_menu._resume()
		else:
			pause_menu.open()
		get_viewport().set_input_as_handled()
		return
	# Горячая клавиша T — пропуск суток (до утра следующего дня)
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_T:
		if not _is_blocking_ui_open():
			gm.skip_day()
			_show_popup("⏭ Пропущены сутки · День %d" % gm.day)
			get_viewport().set_input_as_handled()
	# F3 — отладочный оверлей производительности (FPS / кадр / узлы / сироты)
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_F3:
		_toggle_perf_overlay()
		get_viewport().set_input_as_handled()

var _perf_lbl: Label = null
var _perf_acc: float = 0.0

func _toggle_perf_overlay() -> void:
	if _perf_lbl == null:
		_perf_lbl = Label.new()
		_perf_lbl.add_theme_font_size_override("font_size", 13)
		_perf_lbl.add_theme_color_override("font_color", Color(0.6, 1.0, 0.7))
		_perf_lbl.add_theme_constant_override("outline_size", 3)
		_perf_lbl.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.85))
		_perf_lbl.position = Vector2(12, 172)
		_perf_lbl.z_index = 20
		add_child(_perf_lbl)
	_perf_lbl.visible = not _perf_lbl.visible

func _update_perf_overlay(delta: float) -> void:
	if _perf_lbl == null or not _perf_lbl.visible:
		return
	_perf_acc += delta
	if _perf_acc < 0.25:
		return
	_perf_acc = 0.0
	var fps: float = Engine.get_frames_per_second()
	var orphans: int = int(Performance.get_monitor(Performance.OBJECT_ORPHAN_NODE_COUNT))
	_perf_lbl.text = "FPS %d · кадр %.1f мс · узлов %d · сирот %d" % [
		int(fps), 1000.0 / maxf(fps, 1.0), get_tree().get_node_count(), orphans]

var _last_hp: float = 100.0
var _fade_rect: ColorRect = null
var _autosave_lbl: Label = null

func _setup_fade_overlay() -> void:
	_fade_rect = ColorRect.new()
	_fade_rect.color = Color(0, 0, 0, 0)
	_fade_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	_fade_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_fade_rect.z_index = 10
	add_child(_fade_rect)

var _zone_banner: Label = null

func _setup_zone_banner() -> void:
	_zone_panel = Panel.new()
	_zone_panel.set_anchors_preset(Control.PRESET_CENTER_TOP)
	_zone_panel.position = Vector2(-260, 88)
	_zone_panel.size = Vector2(520, 56)
	var zps := StyleBoxFlat.new()
	zps.bg_color = Color(0.04, 0.03, 0.07, 0.86)
	zps.border_color = Color(0.80, 0.65, 0.22, 0.65)
	zps.set_border_width_all(1)
	zps.set_corner_radius_all(10)
	zps.content_margin_left = 12; zps.content_margin_right = 12
	_zone_panel.add_theme_stylebox_override("panel", zps)
	_zone_panel.modulate.a = 0.0
	_zone_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_zone_panel)

	_zone_banner = Label.new()
	_zone_banner.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_zone_banner.set_anchors_preset(Control.PRESET_CENTER_TOP)
	_zone_banner.position = Vector2(-256, 92)
	_zone_banner.size = Vector2(512, 50)
	_zone_banner.add_theme_font_size_override("font_size", 26)
	_zone_banner.add_theme_color_override("font_color", Color(1.0, 0.92, 0.38))
	_zone_banner.add_theme_constant_override("outline_size", 4)
	_zone_banner.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.90))
	_zone_banner.modulate.a = 0.0
	add_child(_zone_banner)

func _add_vignette() -> void:
	var vw: float = 1280.0; var vh: float = 720.0
	var edges := [
		[0.0, 0.0, 70.0, vh,  0.22],
		[vw - 70.0, 0.0, 70.0, vh, 0.22],
		[0.0, 0.0, vw, 55.0, 0.18],
		[0.0, vh - 55.0, vw, 55.0, 0.18],
	]
	for e in edges:
		var vr := ColorRect.new()
		vr.position = Vector2(e[0], e[1])
		vr.size = Vector2(e[2], e[3])
		vr.color = Color(0.0, 0.0, 0.0, e[4])
		vr.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(vr)

func _setup_hp_pulse() -> void:
	pass  # пульсация реализована в _process

func _setup_minimap() -> void:
	const MM: float = 138.0
	const CELL: float = 42.0
	const GAP: float = 2.0
	var zm := get_node_or_null("/root/ZoneManager")
	if zm == null:
		return

	_minimap_root = Control.new()
	_minimap_root.position = Vector2(1280.0 - MM - 8.0, 720.0 - MM - 8.0)
	_minimap_root.size = Vector2(MM, MM)
	_minimap_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_minimap_root)

	var bg := ColorRect.new()
	bg.size = Vector2(MM, MM)
	bg.color = Color(0.04, 0.04, 0.08, 0.86)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_minimap_root.add_child(bg)

	# Тонкая рамка
	for edge in [[0,0,MM,2],[0,MM-2,MM,2],[0,0,2,MM],[MM-2,0,2,MM]]:
		var brd := ColorRect.new()
		brd.position = Vector2(edge[0], edge[1]); brd.size = Vector2(edge[2], edge[3])
		brd.color = Color(0.35, 0.35, 0.55, 0.70); brd.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_minimap_root.add_child(brd)

	# Ячейки зон 3×3
	for z in 9:
		var g: Vector2i = ZoneManager.ZONE_GRID[z]
		var meta: Dictionary = ZoneManager.ZONE_META[z]
		var cell := ColorRect.new()
		cell.size = Vector2(CELL, CELL)
		cell.position = Vector2(GAP + g.x * (CELL + GAP), GAP + g.y * (CELL + GAP))
		cell.color = meta.bg.lightened(0.25)
		cell.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_minimap_root.add_child(cell)
		_minimap_zone_cells.append(cell)

		var icon_lbl := Label.new()
		icon_lbl.text = meta.icon
		icon_lbl.position = cell.position + Vector2(2, 2)
		icon_lbl.add_theme_font_size_override("font_size", 11)
		icon_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_minimap_root.add_child(icon_lbl)

	# Точка игрока
	_minimap_player_dot = ColorRect.new()
	_minimap_player_dot.size = Vector2(5, 5)
	_minimap_player_dot.color = Color(1.0, 1.0, 1.0, 1.0)
	_minimap_root.add_child(_minimap_player_dot)

	_update_minimap_zone(zm.current_zone)
	zm.zone_changed.connect(func(z): _update_minimap_zone(z))

func _update_minimap_zone(zone_idx: int) -> void:
	var zm2 := get_node_or_null("/root/ZoneManager")
	var current: int = zm2.current_zone if zm2 else zone_idx
	for i in _minimap_zone_cells.size():
		var cell: ColorRect = _minimap_zone_cells[i]
		var meta: Dictionary = ZoneManager.ZONE_META[i]
		if i == current:
			cell.color = meta.bg.lightened(0.60)   # текущая — яркая
		elif i < current:
			cell.color = meta.bg.lightened(0.28)   # посещённая — нормальная
		else:
			cell.color = Color(0.04, 0.04, 0.07)   # заблокированная — тёмная

func _setup_damage_vignette() -> void:
	_damage_vignette = ColorRect.new()
	_damage_vignette.color = Color(0.72, 0.04, 0.04, 0.0)
	_damage_vignette.set_anchors_preset(Control.PRESET_FULL_RECT)
	_damage_vignette.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_damage_vignette.z_index = 8
	add_child(_damage_vignette)

func _process(delta: float) -> void:
	_update_perf_overlay(delta)
	if gm == null:
		return
	# Мини-карта: позиция игрока
	if _minimap_player_dot and _minimap_root:
		var player_node = get_tree().get_first_node_in_group("player")
		if player_node:
			const MAP_SIZE: float = 7500.0
			var nx: float = (player_node.global_position.x + 3750.0) / MAP_SIZE
			var ny: float = (player_node.global_position.y + 3750.0) / MAP_SIZE
			_minimap_player_dot.position = Vector2(
				clampf(nx * 138.0 - 2.5, 2.0, 133.0),
				clampf(ny * 138.0 - 2.5, 2.0, 133.0)
			)
	var pulse: float = (sin(Time.get_ticks_msec() * 0.005) + 1.0) * 0.5
	if gm.health <= 30.0:
		var t: float = clampf(1.0 - gm.health / 30.0, 0.0, 1.0)
		health_bar.modulate = Color(1.0, 0.2 + pulse * 0.8, 0.2 + pulse * 0.8)
		if _damage_vignette:
			_damage_vignette.color.a = t * (0.18 + pulse * 0.14)
	else:
		health_bar.modulate = Color(1.0, 1.0, 1.0)
		if _damage_vignette:
			_damage_vignette.color.a = maxf(_damage_vignette.color.a - delta * 2.0, 0.0)
	if gm.hunger <= 20.0:
		hunger_bar.modulate = Color(1.0, 0.25 + pulse * 0.75, 0.25 + pulse * 0.75)
	else:
		hunger_bar.modulate = Color(1.0, 1.0, 1.0)
	if gm.thirst <= 20.0:
		thirst_bar.modulate = Color(1.0, 0.25 + pulse * 0.75, 0.25 + pulse * 0.75)
	else:
		thirst_bar.modulate = Color(1.0, 1.0, 1.0)
	if gm.energy <= 20.0:
		energy_bar.modulate = Color(1.0, 0.25 + pulse * 0.75, 0.25 + pulse * 0.75)
	else:
		energy_bar.modulate = Color(1.0, 1.0, 1.0)
	# Кнопка «Следующий день» пульсирует когда энергия в нуле
	if gm.energy <= 0.0:
		sleep_btn.modulate = Color(1.0, 0.55 + pulse * 0.45, 0.55 + pulse * 0.45)
	else:
		sleep_btn.modulate = Color(1.0, 1.0, 1.0)

	# Прячем трекер целей, когда открыто любое окно/меню — чтобы он не
	# перекрывал кнопку «Закрыть» и содержимое окон в правом верхнем углу
	if _quest_tracker_layer:
		_quest_tracker_layer.visible = not _any_modal_open()

func _any_modal_open() -> bool:
	for w in [ach_ui, stats_ui, stock_ui, inv_ui, pause_menu, loan_ui,
			housing_shop, business_shop, quest_ui, _titles_handbook,
			_settings_ui, _journal, _dock_menu]:
		if w != null and is_instance_valid(w) and w.visible:
			return true
	var su = get_tree().get_first_node_in_group("sleep_ui")
	if su and is_instance_valid(su) and su.visible:
		return true
	var eu = get_tree().get_first_node_in_group("economy_ui")
	if eu and is_instance_valid(eu) and eu.visible:
		return true
	var reui = get_tree().get_first_node_in_group("realestate_ui")
	if reui and is_instance_valid(reui) and reui.visible:
		return true
	return false

func _on_zone_entered(zone_idx: int) -> void:
	_play_zone_fade()
	var zm := get_node_or_null("/root/ZoneManager")
	if zm == null or _zone_banner == null:
		return
	var meta: Dictionary = zm.ZONE_META[zone_idx]
	_zone_banner.text = meta.icon + "  " + meta.name
	_zone_banner.modulate.a = 0.0
	if _zone_panel: _zone_panel.modulate.a = 0.0
	var tw := create_tween()
	tw.set_parallel(true)
	tw.tween_property(_zone_banner, "modulate:a", 1.0, 0.35)
	if _zone_panel: tw.tween_property(_zone_panel, "modulate:a", 1.0, 0.35)
	tw.set_parallel(false)
	tw.tween_interval(2.5)
	tw.set_parallel(true)
	tw.tween_property(_zone_banner, "modulate:a", 0.0, 0.55)
	if _zone_panel: tw.tween_property(_zone_panel, "modulate:a", 0.0, 0.55)
	var am := get_node_or_null("/root/AudioManager")
	if am: am.notify_district(meta.name)

func _play_zone_fade() -> void:
	if _fade_rect == null:
		return
	var tw := create_tween()
	tw.tween_property(_fade_rect, "color", Color(0, 0, 0, 1.0), 0.25)
	tw.tween_interval(0.15)
	tw.tween_property(_fade_rect, "color", Color(0, 0, 0, 0.0), 0.40)

# ── Единое всплывающее меню категории дока ────────────────────────────────────
func _toggle_dock_menu(owner_btn: Control, accent: Color, items: Array, am: Node) -> void:
	var was_same: bool = _dock_menu_owner == owner_btn
	_close_dock_menu()
	if was_same:
		return
	if am: am.play_click()
	_dock_menu_owner = owner_btn

	_dock_menu = PanelContainer.new()
	var ps := StyleBoxFlat.new()
	ps.bg_color = Color(0.05, 0.06, 0.10, 0.97)
	ps.border_color = accent
	for s in [SIDE_LEFT, SIDE_RIGHT, SIDE_TOP, SIDE_BOTTOM]:
		ps.set_border_width(s, 2)
		ps.set_corner_radius(s, 8)
	ps.content_margin_left = 6; ps.content_margin_right = 6
	ps.content_margin_top = 6; ps.content_margin_bottom = 6
	_dock_menu.add_theme_stylebox_override("panel", ps)
	add_child(_dock_menu)

	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 4)
	_dock_menu.add_child(vb)
	for item in items:
		var b := Button.new()
		b.text = item.icon + "  " + item.text
		b.custom_minimum_size = Vector2(190, 30)
		b.add_theme_font_size_override("font_size", 13)
		b.focus_mode = Control.FOCUS_NONE
		_style_btn(b, item.get("col", HUD_BTN_BG), item.get("brd", HUD_BORDER))
		var cb: Callable = item.cb
		b.pressed.connect(func():
			_close_dock_menu()
			cb.call())
		vb.add_child(b)

	# Над доком, по центру у кнопки-владельца
	_dock_menu.reset_size()
	var vp := get_viewport().get_visible_rect().size
	var w: float = _dock_menu.size.x
	var anchor_x: float = vp.x * 0.5
	if is_instance_valid(owner_btn):
		anchor_x = owner_btn.get_global_rect().get_center().x
	_dock_menu.position = Vector2(clampf(anchor_x - w * 0.5, 8.0, vp.x - w - 8.0),
		vp.y - 66.0 - _dock_menu.size.y - 10.0)

	_dock_menu.modulate.a = 0.0
	_dock_menu.scale = Vector2(0.90, 0.90)
	var tw := create_tween()
	tw.set_parallel(true)
	tw.tween_property(_dock_menu, "modulate:a", 1.0, 0.18)
	tw.tween_property(_dock_menu, "scale", Vector2(1.0, 1.0), 0.18).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)

func _close_dock_menu() -> void:
	if _dock_menu and is_instance_valid(_dock_menu):
		_dock_menu.queue_free()
	_dock_menu = null
	_dock_menu_owner = null

# ── «Финансы» — бизнес, банк, биржа, кредиты, сводка ──────────────────────────
func _setup_invest_btn(am: Node) -> void:
	# Скрываем отдельные кнопки — теперь они внутри меню «Финансы»
	business_btn.visible = false
	stock_btn.visible    = false
	loan_btn.visible     = false

	_invest_btn = Button.new()
	_invest_btn.tooltip_text = "Финансы: Бизнес и Банк, Биржа, Кредиты, Сводка"
	var dock := $Dock/DockRow
	dock.add_child(_invest_btn)
	_style_dock_btn(_invest_btn, "💼")
	var accent := Color(0.25, 0.52, 0.20, 0.90)
	_invest_btn.pressed.connect(func():
		_toggle_dock_menu(_invest_btn, accent, [
			{"icon": "🏢", "text": "Бизнес и Банк", "col": Color(0.08, 0.18, 0.10), "brd": Color(0.25, 0.58, 0.25),
			 "cb": func(): business_shop.open()},
			{"icon": "📈", "text": "Биржа акций", "col": Color(0.06, 0.14, 0.22), "brd": Color(0.22, 0.45, 0.75),
			 "cb": func(): stock_ui.open()},
			{"icon": "🏦", "text": "Кредиты", "col": Color(0.16, 0.12, 0.05), "brd": Color(0.62, 0.48, 0.18),
			 "cb": func(): loan_ui.open()},
			{"icon": "📊", "text": "Финансы (сводка)", "col": HUD_BTN_BG, "brd": HUD_BORDER,
			 "cb": func():
				var eu = get_tree().get_first_node_in_group("economy_ui")
				if eu and eu.has_method("open"): eu.open()},
		], am))

# ── «Журнал» (вкладки) и «Система» (поп-ап) ───────────────────────────────────
func _setup_journal_and_system(am: Node) -> void:
	var dock: HBoxContainer = $Dock/DockRow

	# Прячем отдельные кнопки — теперь они внутри «Журнала»/«Системы»
	quest_btn.visible = false
	ach_btn.visible   = false
	stats_btn.visible = false
	menu_btn.visible  = false

	# «Журнал» с вкладками: Цели / Достижения / Титулы / Статистика
	var jr_script := load("res://scripts/JournalUI.gd")
	if jr_script:
		_journal = CanvasLayer.new()
		_journal.set_script(jr_script)
		add_child(_journal)
		_journal.setup(quest_ui, ach_ui, _titles_handbook, stats_ui)

	_journal_btn = Button.new()
	_journal_btn.tooltip_text = "Журнал: цели, достижения, титулы и статистика"
	dock.add_child(_journal_btn)
	_style_dock_btn(_journal_btn, "📖")
	_journal_btn.pressed.connect(func():
		if am: am.play_click()
		if _journal: _journal.open())

	# «Быт»: Жильё / Инвентарь — прячем их отдельные кнопки
	housing_btn.visible = false
	inv_btn.visible     = false
	_household_btn = Button.new()
	_household_btn.tooltip_text = "Быт: Жильё и Инвентарь"
	dock.add_child(_household_btn)
	_style_dock_btn(_household_btn, "🏠")
	_household_btn.pressed.connect(func():
		_toggle_dock_menu(_household_btn, HUD_BORDER, [
			{"icon": "🏠", "text": "Жильё", "col": HUD_BTN_BG, "brd": HUD_BORDER,
			 "cb": func(): housing_shop.open()},
			{"icon": "🎒", "text": "Инвентарь", "col": Color(0.10, 0.14, 0.10), "brd": Color(0.35, 0.55, 0.35),
			 "cb": func(): inv_ui.open()},
		], am))

	# «Жизнь»: личное измерение — возраст, счастье, семья
	_life_btn = Button.new()
	_life_btn.tooltip_text = "Жизнь: возраст, настроение, семья и наследие"
	dock.add_child(_life_btn)
	_style_dock_btn(_life_btn, "👤")
	_life_btn.pressed.connect(func():
		if am: am.play_click()
		var lu = get_tree().get_first_node_in_group("life_ui")
		if lu and lu.has_method("open"): lu.open())

	# «Система»: Настройки / Главное меню
	_system_btn = Button.new()
	_system_btn.tooltip_text = "Настройки и выход в главное меню"
	dock.add_child(_system_btn)
	_style_dock_btn(_system_btn, "⚙")
	_system_btn.pressed.connect(func():
		_toggle_dock_menu(_system_btn, HUD_BORDER, [
			{"icon": "⚙", "text": "Настройки", "col": HUD_BTN_BG, "brd": HUD_BORDER,
			 "cb": func(): if _settings_ui: _settings_ui.open()},
			{"icon": "🚪", "text": "Главное меню", "col": Color(0.18, 0.07, 0.07), "brd": Color(0.55, 0.20, 0.20),
			 "cb": func(): _go_to_menu()},
		], am))

	# Порядок категорий: Следующий день · Быт · Финансы · Жизнь · Журнал · Система
	var order := [sleep_btn, _household_btn, _invest_btn, _life_btn, _journal_btn, _system_btn]
	for i in order.size():
		if order[i] and is_instance_valid(order[i]):
			dock.move_child(order[i], i)

## ── Единая цветовая палитра HUD ───────────────────────────────────────────
const HUD_BG     := Color(0.045, 0.050, 0.085, 0.94)   # тёмное "стекло" панели
const HUD_BORDER := Color(0.70, 0.56, 0.18, 0.75)       # золотой акцент рамки
const HUD_BTN_BG := Color(0.075, 0.085, 0.135, 1.0)     # фон обычной кнопки
const HUD_GOLD   := Color(1.0, 0.88, 0.30)              # золотой текст/акцент

func _style_hud() -> void:
	# ── Верхняя полоса и нижний док — единое "стекло" с золотой рамкой ────────
	var bar_style := StyleBoxFlat.new()
	bar_style.bg_color     = HUD_BG
	bar_style.border_color = HUD_BORDER
	bar_style.set_border_width(SIDE_BOTTOM, 1)
	bar_style.shadow_color = Color(0, 0, 0, 0.35)
	bar_style.shadow_size = 5
	$TopBar.add_theme_stylebox_override("panel", bar_style)

	var dock_style := StyleBoxFlat.new()
	dock_style.bg_color     = HUD_BG
	dock_style.border_color = HUD_BORDER
	for side in [SIDE_LEFT, SIDE_RIGHT, SIDE_TOP, SIDE_BOTTOM]:
		dock_style.set_border_width(side, 1)
		dock_style.set_corner_radius(side, 12)
	dock_style.shadow_color = Color(0, 0, 0, 0.35)
	dock_style.shadow_size = 6
	$Dock.add_theme_stylebox_override("panel", dock_style)

	# ── Деньги — крупно, золото ───────────────────────────────────────────────
	money_label.add_theme_font_size_override("font_size", 19)
	money_label.add_theme_color_override("font_color", HUD_GOLD)
	money_label.add_theme_constant_override("outline_size", 2)
	money_label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.55))
	# Тултип при наведении на деньги: доход / расход / капитал
	var money_col: Control = $TopBar/Row/MoneyCol
	money_col.mouse_filter = Control.MOUSE_FILTER_STOP
	money_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	income_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	money_col.mouse_entered.connect(_show_money_tooltip)
	money_col.mouse_exited.connect(_hide_money_tooltip)

	# ── Информационные метки — единый светлый серо-голубой тон ───────────────
	for lbl in [title_label, housing_label, day_label, time_label,
				transport_label, reputation_label, education_label, income_label]:
		lbl.add_theme_font_size_override("font_size", 12)
		lbl.add_theme_color_override("font_color", Color(0.78, 0.80, 0.88))

	# ── Полоски: fill + background с скруглением ──────────────────────────────
	_style_bar_fancy(health_bar,  Color(0.85, 0.15, 0.15), Color(0.20, 0.06, 0.07))
	_style_bar_fancy(hunger_bar,  Color(0.92, 0.58, 0.12), Color(0.22, 0.14, 0.05))
	_style_bar_fancy(thirst_bar,  Color(0.18, 0.52, 0.95), Color(0.06, 0.13, 0.24))
	_style_bar_fancy(energy_bar,  Color(0.28, 0.82, 0.28), Color(0.07, 0.19, 0.08))

	# Показывать значение на полосках (% = значение, т.к. max=100)
	for bar in [health_bar, hunger_bar, thirst_bar, energy_bar]:
		bar.show_percentage = true
		bar.add_theme_font_size_override("font_size", 8)
		bar.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0, 0.90))
		bar.add_theme_color_override("font_shadow_color", Color(0.0, 0.0, 0.0, 0.70))
		bar.add_theme_constant_override("font_shadow_offset_x", 1)
		bar.add_theme_constant_override("font_shadow_offset_y", 1)

	# ── Кнопки-иконки в доке ──────────────────────────────────────────────────
	_style_dock_btn(housing_btn, "🏠")
	_style_dock_btn(quest_btn,   "📋")
	_style_dock_btn(ach_btn,     "🏆")
	_style_dock_btn(stats_btn,   "📊")
	_style_dock_btn(inv_btn,     "🎒")
	_style_dock_btn(menu_btn,    "🚪")
	# Кнопка «Следующий день» — золотое CTA, чуть крупнее
	_style_dock_btn(sleep_btn,   "😴", true)

	# ── TitlePopup — то же "стекло" с золотой рамкой ─────────────────────────
	var pop_style := StyleBoxFlat.new()
	pop_style.bg_color     = HUD_BG
	pop_style.border_color = HUD_BORDER
	for side in [SIDE_LEFT, SIDE_RIGHT, SIDE_TOP, SIDE_BOTTOM]:
		pop_style.set_border_width(side, 1)
		pop_style.set_corner_radius(side, 8)
	title_popup.add_theme_stylebox_override("normal", pop_style)
	title_popup.add_theme_font_size_override("font_size", 15)
	title_popup.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	title_popup.custom_minimum_size.x = 320

# ── Полоски потребностей с иконкой-подписью ───────────────────────────────────
func _setup_labeled_bars() -> void:
	var bars_col: VBoxContainer = $TopBar/Row/BarsCol
	bars_col.add_theme_constant_override("separation", 3)
	var defs: Array = [
		[health_bar, "❤"],
		[hunger_bar, "🍖"],
		[thirst_bar, "💧"],
		[energy_bar, "⚡"],
	]
	for d in defs:
		var bar: ProgressBar = d[0]
		var hb := HBoxContainer.new()
		hb.add_theme_constant_override("separation", 6)
		hb.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var ic := Label.new()
		ic.text = d[1]
		ic.add_theme_font_size_override("font_size", 13)
		ic.custom_minimum_size = Vector2(20, 0)
		ic.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		ic.mouse_filter = Control.MOUSE_FILTER_IGNORE
		bars_col.remove_child(bar)
		hb.add_child(ic)
		bar.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		hb.add_child(bar)
		bars_col.add_child(hb)

# ── Компактная верхняя панель: «Титул · День · Время · ⓘ» + поповер ──────────
func _setup_compact_topbar() -> void:
	var status_col: VBoxContainer = $TopBar/Row/StatusCol
	var row1: HBoxContainer = $TopBar/Row/StatusCol/StatusRow1
	var row2: HBoxContainer = $TopBar/Row/StatusCol/StatusRow2
	var row3: HBoxContainer = $TopBar/Row/StatusCol/StatusRow3

	# Видимый компактный ряд: Титул · День · Время · кнопка «Подробнее»
	var primary := HBoxContainer.new()
	primary.name = "PrimaryRow"
	primary.add_theme_constant_override("separation", 14)
	for lbl in [title_label, day_label, time_label]:
		lbl.get_parent().remove_child(lbl)
		primary.add_child(lbl)

	_info_btn = Button.new()
	_info_btn.text = "ⓘ Подробнее"
	_info_btn.tooltip_text = "Жильё, транспорт, репутация, образование, сезон, экономика и баффы"
	_style_btn(_info_btn)
	_info_btn.custom_minimum_size = Vector2(0, 22)
	_info_btn.add_theme_font_size_override("font_size", 12)
	_info_btn.focus_mode = Control.FOCUS_NONE
	_info_btn.pressed.connect(_toggle_info_popover)
	primary.add_child(_info_btn)

	status_col.remove_child(row1)
	status_col.remove_child(row2)
	status_col.remove_child(row3)
	status_col.add_child(primary)

	# Поповер с второстепенными чипами
	_info_popover = PanelContainer.new()
	_info_popover.add_theme_stylebox_override("panel", UITheme.panel_box())
	_info_popover.z_index = 30
	_info_popover.visible = false
	_info_popover.custom_minimum_size = Vector2(270, 0)
	add_child(_info_popover)
	var pv := VBoxContainer.new()
	pv.add_theme_constant_override("separation", 7)
	_info_popover.add_child(pv)
	var hdr := Label.new()
	hdr.text = "ⓘ Подробности"
	hdr.add_theme_font_size_override("font_size", 13)
	hdr.add_theme_color_override("font_color", HUD_GOLD)
	pv.add_child(hdr)
	pv.add_child(UITheme.gold_rule())
	for r in [row1, row2, row3]:
		r.add_theme_constant_override("separation", 16)
		pv.add_child(r)

func _toggle_info_popover() -> void:
	if _info_popover == null:
		return
	if _info_popover.visible:
		_info_popover.visible = false
		return
	_info_popover.visible = true
	_info_popover.reset_size()
	var bp: Rect2 = _info_btn.get_global_rect()
	_info_popover.position = Vector2(bp.position.x, bp.position.y + bp.size.y + 6)

func _section_divider() -> Control:
	var d := ColorRect.new()
	d.custom_minimum_size = Vector2(0, 1)
	d.color = Color(HUD_BORDER.r, HUD_BORDER.g, HUD_BORDER.b, 0.35)
	d.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return d

func _style_btn_primary(btn: Button) -> void:
	var sn := StyleBoxFlat.new()
	sn.bg_color = Color(0.62, 0.48, 0.08)
	sn.border_color = Color(0.95, 0.80, 0.30, 0.95)
	for s in [SIDE_LEFT, SIDE_RIGHT, SIDE_TOP, SIDE_BOTTOM]:
		sn.set_border_width(s, 1)
		sn.set_corner_radius(s, 6)
	btn.add_theme_stylebox_override("normal", sn)
	var sh := sn.duplicate() as StyleBoxFlat
	sh.bg_color = sn.bg_color.lightened(0.15)
	btn.add_theme_stylebox_override("hover", sh)
	btn.add_theme_color_override("font_color", Color(0.12, 0.08, 0.0))
	btn.add_theme_font_size_override("font_size", 12)
	btn.custom_minimum_size.y = 26

func _style_bar_fancy(bar: ProgressBar, fill_col: Color, bg_col: Color) -> void:
	var fill := StyleBoxFlat.new()
	fill.bg_color = fill_col
	for s in [SIDE_LEFT, SIDE_RIGHT, SIDE_TOP, SIDE_BOTTOM]:
		fill.set_corner_radius(s, 4)
	bar.add_theme_stylebox_override("fill", fill)

	var bg := StyleBoxFlat.new()
	bg.bg_color = bg_col
	for s in [SIDE_LEFT, SIDE_RIGHT, SIDE_TOP, SIDE_BOTTOM]:
		bg.set_corner_radius(s, 4)
	bar.add_theme_stylebox_override("background", bg)

func _style_btn(btn: Button, bg: Color = HUD_BTN_BG, border: Color = HUD_BORDER) -> void:
	var sn := StyleBoxFlat.new()
	sn.bg_color = bg
	sn.border_color = border
	for s in [SIDE_LEFT, SIDE_RIGHT, SIDE_TOP, SIDE_BOTTOM]:
		sn.set_border_width(s, 1)
		sn.set_corner_radius(s, 6)
	btn.add_theme_stylebox_override("normal", sn)

	var sh := StyleBoxFlat.new()
	sh.bg_color = bg.lightened(0.10)
	sh.border_color = border.lightened(0.2)
	for s in [SIDE_LEFT, SIDE_RIGHT, SIDE_TOP, SIDE_BOTTOM]:
		sh.set_border_width(s, 1)
		sh.set_corner_radius(s, 6)
	btn.add_theme_stylebox_override("hover", sh)

	btn.add_theme_font_size_override("font_size", 11)
	btn.add_theme_color_override("font_color", Color(0.85, 0.86, 0.92))
	btn.custom_minimum_size.y = 24

# Кнопка-иконка для нижнего дока: только эмодзи, квадратная, тултип уже задан
func _style_dock_btn(btn: Button, icon: String, primary: bool = false) -> void:
	btn.text = icon
	btn.custom_minimum_size = Vector2(56, 44) if not primary else Vector2(64, 44)
	btn.add_theme_font_size_override("font_size", 24 if not primary else 26)
	var bg: Color = Color(0.62, 0.48, 0.08) if primary else HUD_BTN_BG
	var border: Color = Color(0.95, 0.80, 0.30, 0.95) if primary else HUD_BORDER
	var sn := StyleBoxFlat.new()
	sn.bg_color = bg
	sn.border_color = border
	for s in [SIDE_LEFT, SIDE_RIGHT, SIDE_TOP, SIDE_BOTTOM]:
		sn.set_border_width(s, 1)
		sn.set_corner_radius(s, 8)
	btn.add_theme_stylebox_override("normal", sn)
	var sh := sn.duplicate() as StyleBoxFlat
	sh.bg_color = bg.lightened(0.18)
	sh.border_color = border.lightened(0.20)
	btn.add_theme_stylebox_override("hover", sh)
	var sp := sn.duplicate() as StyleBoxFlat
	sp.bg_color = bg.darkened(0.10)
	btn.add_theme_stylebox_override("pressed", sp)

var _season_lbl: Label = null
var _econ_lbl: Label = null

func _setup_season_label() -> void:
	if gm == null or not gm.has_method("get_season"):
		return
	_season_lbl = Label.new()
	_season_lbl.add_theme_font_size_override("font_size", 12)
	_season_lbl.add_theme_color_override("font_color", Color(0.78, 0.80, 0.88))
	$TopBar/Row/StatusCol/StatusRow2.add_child(_season_lbl)
	# Индикатор фазы экономики (виден только в бум/рецессию)
	_econ_lbl = Label.new()
	_econ_lbl.add_theme_font_size_override("font_size", 12)
	_econ_lbl.visible = false
	$TopBar/Row/StatusCol/StatusRow2.add_child(_econ_lbl)
	_refresh_season()
	_refresh_econ()
	if gm.has_signal("season_changed"):
		gm.season_changed.connect(func(_i): _refresh_season())
	gm.day_changed.connect(func(_d): _refresh_season(); _refresh_econ())

func _refresh_season() -> void:
	if _season_lbl == null:
		return
	var s: Dictionary = gm.get_season()
	var date_str: String = gm.get_date_string() if gm.has_method("get_date_string") else ""
	_season_lbl.text = "%s %s · %s" % [s.get("icon", ""), s.get("name", ""), date_str]

func _refresh_econ() -> void:
	if _econ_lbl == null:
		return
	var cb = get_node_or_null("/root/CentralBankManager")
	if cb == null or not cb.has_method("phase_label"):
		_econ_lbl.visible = false
		return
	if cb.is_recession():
		_econ_lbl.text = "  ·  📉 Рецессия"
		_econ_lbl.add_theme_color_override("font_color", Color(0.95, 0.45, 0.40))
		_econ_lbl.visible = true
	elif cb.is_boom():
		_econ_lbl.text = "  ·  📈 Бум"
		_econ_lbl.add_theme_color_override("font_color", Color(0.45, 0.90, 0.55))
		_econ_lbl.visible = true
	else:
		_econ_lbl.visible = false

func _setup_autosave_label() -> void:
	_autosave_lbl = Label.new()
	_autosave_lbl.text = "💾 Сохранено"
	_autosave_lbl.add_theme_font_size_override("font_size", 12)
	_autosave_lbl.add_theme_color_override("font_color", Color(0.55, 0.90, 0.55))
	_autosave_lbl.add_theme_constant_override("outline_size", 2)
	_autosave_lbl.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.70))
	_autosave_lbl.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	_autosave_lbl.position = Vector2(-130, -32)
	_autosave_lbl.modulate.a = 0.0
	_autosave_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_autosave_lbl)

func show_autosave_toast() -> void:
	if _autosave_lbl == null:
		return
	_autosave_lbl.modulate.a = 0.0
	var tw := _autosave_lbl.create_tween()
	tw.tween_property(_autosave_lbl, "modulate:a", 1.0, 0.25)
	tw.tween_interval(1.2)
	tw.tween_property(_autosave_lbl, "modulate:a", 0.0, 0.50)

func _refresh() -> void:
	money_label.text  = "💰 " + gm.format_money(gm.money)
	title_label.text  = "🏅 " + gm.get_title()
	housing_label.text = "🏠 " + gm.get_housing()
	health_bar.value  = gm.health
	hunger_bar.value  = gm.hunger
	thirst_bar.value  = gm.thirst
	energy_bar.value  = gm.energy
	day_label.text    = "📅 День " + str(gm.day)
	time_label.text   = _time_str(gm.current_hour, gm.current_minute)
	_refresh_income()
	_refresh_transport()
	_refresh_reputation()
	_refresh_education()
	_refresh_bar_labels()
	_refresh_meal_buff()

func _refresh_bar_labels() -> void:
	hunger_bar.modulate = Color(1.0, 0.3, 0.3) if gm.hunger <= 20 else Color(1.0, 1.0, 1.0)
	thirst_bar.modulate = Color(1.0, 0.3, 0.3) if gm.thirst <= 20 else Color(1.0, 1.0, 1.0)
	energy_bar.modulate = Color(1.0, 0.3, 0.3) if gm.energy <= 20 else Color(1.0, 1.0, 1.0)

func _refresh_transport() -> void:
	var player = get_tree().get_first_node_in_group("player")
	if player and player.has_method("get_transport_name"):
		transport_label.text = player.get_transport_name()

func _refresh_education() -> void:
	var em: Node = get_node_or_null("/root/EducationManager")
	if em:
		education_label.text = em.get_level_icon() + " " + em.get_level_name()

func _refresh_reputation() -> void:
	reputation_label.text = "⭐ " + rm.get_level_name() + " (%d)" % rm.reputation
	reputation_label.add_theme_color_override("font_color", rm.get_level_color())

var _money_tip: PanelContainer = null
var _money_tip_vb: VBoxContainer = null

func _show_money_tooltip() -> void:
	if gm == null:
		return
	if _money_tip == null:
		_money_tip = PanelContainer.new()
		_money_tip.add_theme_stylebox_override("panel", UITheme.panel_box())
		_money_tip.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_money_tip.z_index = 30
		_money_tip.custom_minimum_size = Vector2(248, 0)
		add_child(_money_tip)
		_money_tip_vb = VBoxContainer.new()
		_money_tip_vb.add_theme_constant_override("separation", 4)
		_money_tip.add_child(_money_tip_vb)
	for c in _money_tip_vb.get_children():
		c.queue_free()
	var fin: Dictionary = gm.get_finance()
	_tip_row("📈 Доход",  "+" + gm.format_money(fin.income) + " /день", UITheme.GREEN)
	_tip_row("📉 Расход", "−" + gm.format_money(fin.expense) + " /день", UITheme.RED)
	var net: float = fin.income - fin.expense
	var net_col: Color = UITheme.GREEN if net >= 0 else UITheme.RED
	_tip_row("≈ Итог", ("+" if net >= 0 else "−") + gm.format_money(absf(net)) + " /день", net_col)
	_money_tip_vb.add_child(UITheme.gold_rule())
	_tip_row("💼 Капитал", gm.format_money(fin.networth), UITheme.GOLD)
	_money_tip.visible = true
	_money_tip.reset_size()
	_money_tip.position = Vector2(14, 172)

func _hide_money_tooltip() -> void:
	if _money_tip:
		_money_tip.visible = false

func _tip_row(label_text: String, value_text: String, col: Color) -> void:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 18)
	var l := Label.new()
	l.text = label_text
	l.add_theme_font_size_override("font_size", 13)
	l.add_theme_color_override("font_color", UITheme.TEXT_DIM)
	l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(l)
	var v := Label.new()
	v.text = value_text
	v.add_theme_font_size_override("font_size", 13)
	v.add_theme_color_override("font_color", col)
	v.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	row.add_child(v)
	_money_tip_vb.add_child(row)

func _refresh_income() -> void:
	var income = bm.get_daily_income()
	if income > 0:
		income_label.text = "📈 Доход: +" + gm.format_money(income) + "/день"
		income_label.visible = true
	else:
		income_label.visible = false

var _last_money: float = 0.0

func _on_money_changed(amount: float) -> void:
	var gained: bool = amount >= _last_money
	_last_money = amount
	money_label.text = "💰 " + gm.format_money(amount)
	var flash_col: Color = Color(1.0, 0.95, 0.35) if gained else Color(1.0, 0.30, 0.30)
	var rest_col: Color  = Color(1.0, 0.88, 0.25) if gained else Color(1.0, 0.55, 0.55)
	var scale_peak: float = 1.20 if gained else 1.10
	var _mtw := money_label.create_tween()
	_mtw.set_parallel(true)
	_mtw.tween_property(money_label, "scale", Vector2(scale_peak, scale_peak), 0.08).set_ease(Tween.EASE_OUT)
	_mtw.tween_property(money_label, "scale", Vector2(1.0, 1.0), 0.22).set_ease(Tween.EASE_IN_OUT).set_delay(0.08)
	_mtw.tween_property(money_label, "modulate", flash_col, 0.08)
	_mtw.tween_property(money_label, "modulate", rest_col, 0.30).set_delay(0.08)
	_mtw.set_parallel(false)
	_mtw.tween_property(money_label, "modulate", Color(1.0, 0.88, 0.25), 0.55)

func _on_title_changed(title: String) -> void:
	title_label.text = "🏅 " + title
	var gm_ref: Node = get_node_or_null("/root/GameManager")
	var popup_text: String = "🎉 Новый титул: " + title + "!"
	if gm_ref:
		var t: Dictionary = gm_ref.TITLES[gm_ref.current_title_index]
		var icon: String = t.get("icon", "🏅")
		var desc: String = t.get("desc", "")
		title_label.text = icon + " " + title
		popup_text = icon + " " + title + "\n" + desc
	_show_popup(popup_text)
	qm.add_diary_entry("🏅 Получен титул: " + title)
	var am = get_node_or_null("/root/AudioManager")
	if am: am.play_level_up()
	_refresh_transport()
	var player = get_tree().get_first_node_in_group("player")
	if player:
		FloatingText.spawn(get_tree(), player.global_position + Vector2(0, -80), "🏅 " + title + "!", Color(1.0, 0.85, 0.1))
	# Золотая вспышка на весь экран
	var gold_flash := ColorRect.new()
	gold_flash.set_anchors_preset(Control.PRESET_FULL_RECT)
	gold_flash.color = Color(1.0, 0.84, 0.08, 0.0)
	gold_flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	gold_flash.z_index = 9
	add_child(gold_flash)
	var gtw := gold_flash.create_tween()
	gtw.tween_property(gold_flash, "modulate:a", 0.52, 0.16)
	gtw.tween_property(gold_flash, "modulate:a", 0.0,  0.70)
	gtw.tween_callback(gold_flash.queue_free)
	# Пульс метки титула
	var ttw := title_label.create_tween()
	ttw.set_parallel(true)
	ttw.tween_property(title_label, "scale", Vector2(1.25, 1.25), 0.14).set_ease(Tween.EASE_OUT)
	ttw.tween_property(title_label, "scale", Vector2(1.0, 1.0), 0.30).set_ease(Tween.EASE_IN_OUT).set_delay(0.14)

func _on_reputation_changed(_val: int) -> void:
	_refresh_reputation()

func _on_housing_changed(housing: String) -> void:
	housing_label.text = "🏠 " + housing

func _on_health_changed(hp: float) -> void:
	health_bar.value = hp
	if hp < _last_hp:
		var dmg: float = _last_hp - hp
		if dmg >= 5.0:
			var player = get_tree().get_first_node_in_group("player")
			if player and player.has_method("shake_camera"):
				player.shake_camera(minf(dmg * 0.8, 12.0), 0.25)
	_last_hp = hp
	if hp <= 0 and not _game_over_shown:
		if gm.is_hardcore():
			_game_over_shown = true
			_show_game_over()
		else:
			# Лёгкая/средняя/тяжёлая: не смерть, а коллапс со штрафом максимума
			gm.survive_collapse()

var _quest_tracker: Panel = null
var _quest_tracker_vbox: VBoxContainer = null

var _quest_tracker_layer: CanvasLayer = null

func _setup_quest_tracker() -> void:
	# Дерево сцены ещё занято собственной инициализацией (мы внутри HUD._ready,
	# который вызван из цепочки _ready всей World-сцены) — синхронный add_child
	# в root в этот момент тихо проваливается ("Parent node is busy setting up
	# children"), из-за чего трекер раньше не появлялся вообще. Откладываем.
	call_deferred("_build_quest_tracker")

func _build_quest_tracker() -> void:
	_quest_tracker_layer = CanvasLayer.new()
	_quest_tracker_layer.layer = 12
	get_tree().root.add_child(_quest_tracker_layer)

	_quest_tracker = Panel.new()
	_quest_tracker.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var ps := StyleBoxFlat.new()
	ps.bg_color = Color(0.06, 0.07, 0.10, 0.80)
	ps.border_color = Color(0.85, 0.70, 0.25, 0.65)
	for s in [SIDE_LEFT, SIDE_RIGHT, SIDE_TOP, SIDE_BOTTOM]:
		ps.set_border_width(s, 1)
		ps.set_corner_radius(s, 8)
	ps.content_margin_left = 10; ps.content_margin_right = 10
	ps.content_margin_top = 8; ps.content_margin_bottom = 8
	_quest_tracker.add_theme_stylebox_override("panel", ps)
	_quest_tracker_layer.add_child(_quest_tracker)
	# Анкеры не используем вообще — позицию считаем вручную от размера вьюпорта
	# в _refresh_quest_tracker(), чтобы не зависеть от тонкостей пересчёта
	# офсетов у anchored Control при добавлении в дерево (из-за этого панель
	# ранее улетала за экран и была невидима)
	_quest_tracker.size = Vector2(284, 10)

	var header := Label.new()
	header.text = "📜 ЦЕЛИ"
	header.add_theme_font_size_override("font_size", 12)
	header.add_theme_color_override("font_color", Color(0.90, 0.78, 0.35))
	header.position = Vector2(10, 6)
	_quest_tracker.add_child(header)

	_quest_tracker_vbox = VBoxContainer.new()
	_quest_tracker_vbox.position = Vector2(10, 28)
	_quest_tracker_vbox.add_theme_constant_override("separation", 4)
	_quest_tracker.add_child(_quest_tracker_vbox)
	get_tree().root.size_changed.connect(_refresh_quest_tracker)
	_refresh_quest_tracker()

func _refresh_quest_tracker() -> void:
	if _quest_tracker_vbox == null:
		return
	for c in _quest_tracker_vbox.get_children():
		c.queue_free()
	var shown: int = 0
	for q in qm.active_quests:
		if shown >= 3:
			break
		var lbl := Label.new()
		lbl.text = "• %s" % q.get("desc", q.get("title", ""))
		lbl.add_theme_font_size_override("font_size", 12)
		lbl.add_theme_color_override("font_color", Color(0.88, 0.88, 0.88))
		lbl.custom_minimum_size = Vector2(264, 0)
		lbl.autowrap_mode = TextServer.AUTOWRAP_WORD
		_quest_tracker_vbox.add_child(lbl)
		shown += 1
	_quest_tracker.size = Vector2(284, 28 + shown * 22 + 10)
	var vp_w: float = get_viewport().get_visible_rect().size.x
	# Ниже верхней полосы статуса (74px), чтобы не перекрывать шкалы справа
	_quest_tracker.position = Vector2(vp_w - _quest_tracker.size.x - 16, 84)

func _on_quest_completed(q: Dictionary) -> void:
	_refresh_quest_tracker()
	var toast := CanvasLayer.new()
	toast.layer = 14
	get_tree().root.add_child(toast)

	var panel := Panel.new()
	panel.position = Vector2(900.0, 690.0)
	panel.size = Vector2(340.0, 80.0)
	var ps := StyleBoxFlat.new()
	ps.bg_color = Color(0.04, 0.13, 0.06, 0.96)
	ps.border_color = Color(0.24, 0.72, 0.28, 0.95)
	for s in [SIDE_LEFT, SIDE_RIGHT, SIDE_TOP, SIDE_BOTTOM]:
		ps.set_border_width(s, 2)
		ps.set_corner_radius(s, 8)
	ps.content_margin_left = 10; ps.content_margin_right = 10
	ps.content_margin_top = 6; ps.content_margin_bottom = 6
	panel.add_theme_stylebox_override("panel", ps)
	toast.add_child(panel)

	var hbox := HBoxContainer.new()
	hbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	hbox.add_theme_constant_override("separation", 8)
	panel.add_child(hbox)

	var icon_lbl := Label.new()
	icon_lbl.text = "✅"
	icon_lbl.add_theme_font_size_override("font_size", 30)
	icon_lbl.custom_minimum_size = Vector2(44, 0)
	icon_lbl.scale = Vector2(0.4, 0.4)
	hbox.add_child(icon_lbl)

	var vbox := VBoxContainer.new()
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hbox.add_child(vbox)

	var top_lbl := Label.new()
	top_lbl.text = "Цель выполнена!"
	top_lbl.add_theme_font_size_override("font_size", 10)
	top_lbl.add_theme_color_override("font_color", Color(0.50, 1.0, 0.55))
	top_lbl.add_theme_constant_override("outline_size", 2)
	top_lbl.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.60))
	vbox.add_child(top_lbl)

	var name_lbl := Label.new()
	name_lbl.text = q.get("title", "")
	name_lbl.add_theme_font_size_override("font_size", 14)
	name_lbl.add_theme_color_override("font_color", Color(0.85, 1.0, 0.85))
	name_lbl.add_theme_constant_override("outline_size", 2)
	name_lbl.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.60))
	vbox.add_child(name_lbl)

	if q.get("reward_money", 0) > 0:
		var rew := Label.new()
		rew.text = "💰 +" + gm.format_money(q.reward_money)
		rew.add_theme_font_size_override("font_size", 11)
		rew.add_theme_color_override("font_color", Color(1.0, 0.90, 0.35))
		vbox.add_child(rew)

	panel.modulate.a = 0.0
	var tw := toast.create_tween()
	tw.set_parallel(true)
	tw.tween_property(panel, "modulate:a", 1.0, 0.28)
	tw.tween_property(panel, "position:y", 600.0, 0.28).set_ease(Tween.EASE_OUT)
	tw.tween_property(icon_lbl, "scale", Vector2(1.0, 1.0), 0.35).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK).set_delay(0.22)
	tw.set_parallel(false)
	tw.tween_interval(3.5)
	tw.tween_property(panel, "modulate:a", 0.0, 0.45)
	tw.tween_callback(toast.queue_free)

	# Зелёные частицы-конфетти
	for i in 8:
		var c := ColorRect.new()
		c.size = Vector2(randf_range(3.0, 6.0), randf_range(3.0, 6.0))
		c.color = Color(0.30, 1.0, 0.42, 0.92)
		c.position = Vector2(randf_range(910.0, 1200.0), randf_range(600.0, 660.0))
		toast.add_child(c)
		var sc := Vector2(randf_range(-65, 65), randf_range(-85, -8))
		var ctw := toast.create_tween()
		ctw.set_parallel(true)
		ctw.tween_property(c, "position", c.position + sc, 0.55).set_ease(Tween.EASE_OUT).set_delay(0.22)
		ctw.tween_property(c, "modulate:a", 0.0, 0.44).set_delay(0.35)
		ctw.set_parallel(false)
		ctw.tween_callback(c.queue_free)

func _show_game_over() -> void:
	get_tree().paused = false
	var go_layer := CanvasLayer.new()
	go_layer.layer = 15
	go_layer.process_mode = Node.PROCESS_MODE_ALWAYS
	get_tree().root.add_child(go_layer)

	var dimmer := ColorRect.new()
	dimmer.set_anchors_preset(Control.PRESET_FULL_RECT)
	dimmer.color = Color(0.06, 0.0, 0.0, 0.0)
	dimmer.mouse_filter = Control.MOUSE_FILTER_STOP
	go_layer.add_child(dimmer)
	dimmer.create_tween().tween_property(dimmer, "color", Color(0.06, 0.0, 0.0, 0.93), 1.4)

	# Заголовок
	var title := Label.new()
	title.text = "☠  КОНЕЦ ИГРЫ"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.set_anchors_preset(Control.PRESET_CENTER)
	title.position = Vector2(-420, -230)
	title.size = Vector2(840, 90)
	title.add_theme_font_size_override("font_size", 54)
	title.add_theme_color_override("font_color", Color(0.88, 0.07, 0.07))
	title.add_theme_constant_override("outline_size", 7)
	title.add_theme_color_override("font_outline_color", Color(0.0, 0.0, 0.0, 0.92))
	title.modulate.a = 0.0
	title.scale = Vector2(0.55, 0.55)
	go_layer.add_child(title)
	var ttw := title.create_tween()
	ttw.set_parallel(true)
	ttw.tween_property(title, "modulate:a", 1.0, 0.55).set_delay(0.9)
	ttw.tween_property(title, "scale", Vector2(1.0, 1.0), 0.55).set_delay(0.9).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)

	# Подзаголовок
	var sub := Label.new()
	sub.text = "Ты не выдержал испытаний жизни..."
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sub.set_anchors_preset(Control.PRESET_CENTER)
	sub.position = Vector2(-360, -110)
	sub.size = Vector2(720, 40)
	sub.add_theme_font_size_override("font_size", 20)
	sub.add_theme_color_override("font_color", Color(0.70, 0.50, 0.50))
	sub.modulate.a = 0.0
	go_layer.add_child(sub)
	sub.create_tween().tween_property(sub, "modulate:a", 1.0, 0.40).set_delay(1.6)

	# Карточка со статистикой
	var card := Panel.new()
	card.set_anchors_preset(Control.PRESET_CENTER)
	card.position = Vector2(-280, -58)
	card.size = Vector2(560, 150)
	var cs := StyleBoxFlat.new()
	cs.bg_color = Color(0.08, 0.02, 0.02, 0.88)
	cs.border_color = Color(0.55, 0.12, 0.12, 0.75)
	for s in [SIDE_LEFT, SIDE_RIGHT, SIDE_TOP, SIDE_BOTTOM]:
		cs.set_border_width(s, 2)
		cs.set_corner_radius(s, 10)
	cs.content_margin_left = 20; cs.content_margin_right = 20
	cs.content_margin_top = 14; cs.content_margin_bottom = 14
	card.add_theme_stylebox_override("panel", cs)
	card.modulate.a = 0.0
	go_layer.add_child(card)

	var stat_vbox := VBoxContainer.new()
	stat_vbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	stat_vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	stat_vbox.add_theme_constant_override("separation", 8)
	card.add_child(stat_vbox)

	var rm_node: Node = get_node_or_null("/root/ReputationManager")
	var stat_rows := [
		["💰 Наличные",      gm.format_money(gm.money)],
		["📊 Чистые активы", gm.format_money(gm.get_net_worth())],
		["📅 Дней прожито",  str(gm.day)],
		["🏅 Титул",         gm.get_title()],
		["🏠 Жильё",         gm.get_housing()],
		["⭐ Репутация",     rm_node.get_level_name() if rm_node else "—"],
	]
	for row_data in stat_rows:
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 12)
		stat_vbox.add_child(row)
		var k := Label.new()
		k.text = row_data[0]
		k.add_theme_font_size_override("font_size", 13)
		k.add_theme_color_override("font_color", Color(0.60, 0.55, 0.55))
		k.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(k)
		var v := Label.new()
		v.text = row_data[1]
		v.add_theme_font_size_override("font_size", 13)
		v.add_theme_color_override("font_color", Color(0.90, 0.85, 0.85))
		row.add_child(v)

	card.create_tween().tween_property(card, "modulate:a", 1.0, 0.40).set_delay(1.9)

	# Кнопки
	var btn_row := HBoxContainer.new()
	btn_row.set_anchors_preset(Control.PRESET_CENTER)
	btn_row.position = Vector2(-225, 115)
	btn_row.size = Vector2(450, 52)
	btn_row.alignment = BoxContainer.ALIGNMENT_CENTER
	btn_row.add_theme_constant_override("separation", 16)
	btn_row.modulate.a = 0.0
	go_layer.add_child(btn_row)

	var restart_btn := Button.new()
	restart_btn.text = "🔄 Начать заново"
	restart_btn.custom_minimum_size = Vector2(210, 50)
	restart_btn.add_theme_font_size_override("font_size", 16)
	restart_btn.add_theme_color_override("font_color", Color(1.0, 0.82, 0.82))
	var rbs := StyleBoxFlat.new()
	rbs.bg_color = Color(0.28, 0.04, 0.04)
	rbs.border_color = Color(0.72, 0.14, 0.14, 0.90)
	for s in [SIDE_LEFT, SIDE_RIGHT, SIDE_TOP, SIDE_BOTTOM]:
		rbs.set_border_width(s, 2)
		rbs.set_corner_radius(s, 8)
	restart_btn.add_theme_stylebox_override("normal", rbs)
	var rbsh := rbs.duplicate() as StyleBoxFlat
	rbsh.bg_color = rbs.bg_color.lightened(0.12)
	restart_btn.add_theme_stylebox_override("hover", rbsh)
	restart_btn.pressed.connect(func():
		get_tree().paused = false
		Engine.time_scale = 1.0
		var lb2 = get_node_or_null("/root/LeaderboardManager")
		if lb2: lb2.try_add_entry()
		gm.reset_game()
		_game_over_shown = false
		SceneTransition.go("res://scenes/World.tscn")
	)
	btn_row.add_child(restart_btn)

	var menu_btn2 := Button.new()
	menu_btn2.text = "🏠 В главное меню"
	menu_btn2.custom_minimum_size = Vector2(210, 50)
	menu_btn2.add_theme_font_size_override("font_size", 16)
	menu_btn2.add_theme_color_override("font_color", Color(0.82, 0.82, 1.0))
	var mbs := StyleBoxFlat.new()
	mbs.bg_color = Color(0.08, 0.08, 0.22)
	mbs.border_color = Color(0.30, 0.30, 0.72, 0.90)
	for s in [SIDE_LEFT, SIDE_RIGHT, SIDE_TOP, SIDE_BOTTOM]:
		mbs.set_border_width(s, 2)
		mbs.set_corner_radius(s, 8)
	menu_btn2.add_theme_stylebox_override("normal", mbs)
	var mbsh := mbs.duplicate() as StyleBoxFlat
	mbsh.bg_color = mbs.bg_color.lightened(0.12)
	menu_btn2.add_theme_stylebox_override("hover", mbsh)
	menu_btn2.pressed.connect(func():
		get_tree().paused = false
		Engine.time_scale = 1.0
		var lb2 = get_node_or_null("/root/LeaderboardManager")
		if lb2: lb2.try_add_entry()
		SceneTransition.go("res://scenes/MainMenu.tscn")
	)
	btn_row.add_child(menu_btn2)

	btn_row.create_tween().tween_property(btn_row, "modulate:a", 1.0, 0.40).set_delay(2.4)

func _on_hunger_changed(val: float) -> void:
	hunger_bar.value = val
	_refresh_bar_labels()
	if val <= 0:
		_show_popup("😵 Ты голоден! Поешь что-нибудь!")
	elif val <= 25:
		_pulse_bar(hunger_bar, Color(1.0, 0.45, 0.15))

func _on_thirst_changed(val: float) -> void:
	thirst_bar.value = val
	_refresh_bar_labels()
	if val <= 0:
		_show_popup("🥵 Ты обезвожен! Выпей воды!")
	elif val <= 25:
		_pulse_bar(thirst_bar, Color(0.2, 0.6, 1.0))

func _pulse_bar(bar: ProgressBar, col: Color) -> void:
	var ptw := bar.create_tween()
	ptw.tween_property(bar, "modulate", col, 0.12)
	ptw.tween_property(bar, "modulate", Color(1.0, 0.3, 0.3), 0.20)
	ptw.tween_property(bar, "modulate", col, 0.12)
	ptw.tween_property(bar, "modulate", Color(1.0, 0.3, 0.3), 0.20)

func _on_energy_changed(val: float) -> void:
	energy_bar.value = val
	_refresh_bar_labels()
	if val <= 0:
		_show_popup("😴 Энергия на нуле! Нажми «Следующий день» чтобы поспать.")

# Масштаб интерфейса растёт вместе с приближением камеры (Ctrl+колесо мыши)
func _on_view_zoom_changed(zoom: float) -> void:
	var t: float = clampf((zoom - gm.VIEW_ZOOM_MIN) / (gm.VIEW_ZOOM_MAX - gm.VIEW_ZOOM_MIN), 0.0, 1.0)
	var ui_scale: float = lerpf(0.88, 1.12, t)
	# Масштабируем только нижний док от его центра — верхняя полоса во всю
	# ширину при масштабировании уехала бы за экран
	var dock: Control = $Dock
	dock.pivot_offset = dock.size * 0.5
	var stw := dock.create_tween()
	stw.tween_property(dock, "scale", Vector2(ui_scale, ui_scale), 0.15).set_ease(Tween.EASE_OUT)

func _on_day_changed(d: int) -> void:
	day_label.text = "📅 День " + str(d)
	_refresh_income()
	_refresh_meal_buff()
	var dtw := day_label.create_tween()
	dtw.set_parallel(true)
	dtw.tween_property(day_label, "modulate", Color(1.0, 0.94, 0.40), 0.18)
	dtw.tween_property(day_label, "modulate", Color(1.0, 1.0, 1.0), 0.55).set_delay(0.18)
	dtw.tween_property(day_label, "scale", Vector2(1.15, 1.15), 0.14).set_ease(Tween.EASE_OUT)
	dtw.tween_property(day_label, "scale", Vector2(1.0, 1.0), 0.28).set_ease(Tween.EASE_IN_OUT).set_delay(0.14)

var _meal_buff_lbl: Label = null
var _penalty_lbl: Label = null

func _refresh_meal_buff() -> void:
	if _meal_buff_lbl == null:
		_meal_buff_lbl = Label.new()
		_meal_buff_lbl.add_theme_font_size_override("font_size", 11)
		_meal_buff_lbl.add_theme_color_override("font_color", Color(0.55, 1.0, 0.65))
		$TopBar/Row/StatusCol/StatusRow3.add_child(_meal_buff_lbl)
	if gm.meal_buff_days > 0:
		_meal_buff_lbl.text = "🍴 -%.0f%% расход (%d дн.)" % [gm.meal_drain_bonus * 100, gm.meal_buff_days]
		_meal_buff_lbl.visible = true
	else:
		_meal_buff_lbl.visible = false
	# Индикатор штрафа истощения (ограничение максимума показателей)
	if _penalty_lbl == null:
		_penalty_lbl = Label.new()
		_penalty_lbl.add_theme_font_size_override("font_size", 11)
		_penalty_lbl.add_theme_color_override("font_color", Color(1.0, 0.5, 0.45))
		$TopBar/Row/StatusCol/StatusRow3.add_child(_penalty_lbl)
	if gm.max_stat_days > 0:
		_penalty_lbl.text = "🩹 Истощение: макс %d (%d дн.)" % [int(gm.max_stat), gm.max_stat_days]
		_penalty_lbl.visible = true
	else:
		_penalty_lbl.visible = false

func _on_event(event: Dictionary) -> void:
	var sm := get_node_or_null("/root/SettingsManager")
	var icon = "📰"
	var ev_money: float = event.get("money", 0)
	var ev_health: float = event.get("health", 0)
	if ev_money > 0: icon = "🎉"
	elif ev_money < 0: icon = "😱"
	elif ev_health < 0: icon = "🤒"
	if not sm or sm.notify_events:
		_show_popup(icon + " " + event.text)
	qm.add_diary_entry(icon + " " + event.text)
	var player = get_tree().get_first_node_in_group("player")
	if player and ev_money != 0:
		var col := Color(0.4, 1.0, 0.4) if ev_money > 0 else Color(1.0, 0.4, 0.4)
		var prefix := "+" if ev_money > 0 else ""
		FloatingText.spawn(get_tree(), player.global_position + Vector2(0, -60), prefix + gm.format_money(ev_money), col)

func _go_to_menu() -> void:
	Engine.time_scale = 1.0
	gm.save_game()
	var lb: Node = get_node_or_null("/root/LeaderboardManager")
	if lb: lb.try_add_entry()
	SceneTransition.go("res://scenes/MainMenu.tscn")

func _on_time_changed(h: int, m: int) -> void:
	time_label.text = _time_str(h, m)

func _time_str(h: int, m: int) -> String:
	var icon: String
	if h < 6:    icon = "🌙"
	elif h < 9:  icon = "🌅"
	elif h < 18: icon = "☀️"
	elif h < 21: icon = "🌆"
	else:        icon = "🌙"
	return "%s %02d:%02d" % [icon, h, m]

var _popup_tween: Tween = null
var _popup_queue: Array = []
var _popup_active: bool = false

func _on_survival_warning(text: String) -> void:
	# Предупреждение о голоде/жажде — важнее экономических уведомлений,
	# показываем его следующим (в начало очереди).
	_show_popup(text, true)

# Уведомления показываются по очереди: если за один день срабатывает несколько
# событий (аренда, налоги, ставка ЦБ, шоки…), игрок видит каждое, а не только
# последнее. При длинной очереди показ короче.
func _show_popup(text: String, priority: bool = false) -> void:
	# Не плодим дубликаты подряд (например, одинаковые предупреждения)
	if _popup_queue.has(text):
		return
	if _popup_queue.size() >= 12:
		return
	if priority:
		_popup_queue.push_front(text)   # выживание — следующим
	else:
		_popup_queue.append(text)
	if not _popup_active:
		_pump_popups()

func _pump_popups() -> void:
	if _popup_queue.is_empty():
		_popup_active = false
		title_popup.visible = false
		return
	_popup_active = true
	var text: String = _popup_queue.pop_front()
	var hold: float = 1.4 if _popup_queue.size() > 0 else 3.2
	title_popup.text = text
	title_popup.visible = true
	title_popup.modulate.a = 0.0
	if _popup_tween and _popup_tween.is_valid():
		_popup_tween.kill()
	_popup_tween = create_tween()
	_popup_tween.tween_property(title_popup, "modulate:a", 1.0, 0.18)
	_popup_tween.tween_interval(hold)
	_popup_tween.tween_property(title_popup, "modulate:a", 0.0, 0.28)
	_popup_tween.tween_callback(_pump_popups)

func _setup_titles_handbook() -> void:
	# Создаём TitlesHandbook и добавляем как дочерний узел HUD
	var th_script := load("res://scripts/TitlesHandbook.gd")
	if th_script == null:
		return
	_titles_handbook = CanvasLayer.new()
	_titles_handbook.set_script(th_script)
	add_child(_titles_handbook)
	# Кнопки в доке нет — справочник титулов открывается через «Журнал»

func _setup_settings_ui() -> void:
	# Создаём SettingsUI и добавляем как дочерний узел HUD
	var st_script := load("res://scripts/SettingsUI.gd")
	if st_script == null:
		return
	_settings_ui = CanvasLayer.new()
	_settings_ui.set_script(st_script)
	add_child(_settings_ui)
	# Кнопки в доке нет — настройки открываются через «Система»
