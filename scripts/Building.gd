extends Area2D

const FloatingText = preload("res://scripts/FloatingText.gd")

@export var building_name: String = "Здание"
@export var action_label: String = "Работать"
@export var money_reward: float = 100.0
@export var cooldown_seconds: float = 3.0
@export var opens_business_shop: bool = false
@export var heal_amount: float = 0.0
@export var is_casino: bool = false
@export var use_minigame: bool = false
@export var is_heavy_labor: bool = false
@export var food_shop_name: String = ""
@export var food_shop_items: Array = []
@export var opens_education_shop: bool = false
@export var edu_req: int = 0
@export var edu_max_level: int = 9
@export var opens_travel_agency: bool = false
@export var opens_transport_shop: bool = false
@export var opens_stock_ui: bool = false
@export var opens_radio_shop: bool = false

var player_inside: bool = false
var on_cooldown: bool = false
var _minigame_running: bool = false
var _e_was_pressed: bool = false

# ── UI-узлы ──────────────────────────────────────────────────────────────────
var _hint_panel: PanelContainer
var _hint_name_lbl: Label
var _hint_action_lbl: Label
var _hint_sub_lbl: Label
var _cd_bar: ProgressBar
var _cd_timer_lbl: Label
var _cooldown_timer: Timer
var _cd_remaining: float = 0.0

func _ready() -> void:
	_build_hint_panel()

	_cooldown_timer = Timer.new()
	_cooldown_timer.wait_time = cooldown_seconds
	_cooldown_timer.one_shot = true
	_cooldown_timer.timeout.connect(_on_cooldown_done)
	add_child(_cooldown_timer)

	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

# ── Панель подсказки ──────────────────────────────────────────────────────────
func _build_hint_panel() -> void:
	_hint_panel = PanelContainer.new()
	_hint_panel.position = Vector2(-115, 55)
	_hint_panel.visible = false
	_hint_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE

	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.06, 0.06, 0.10, 0.88)
	style.border_color = Color(0.4, 0.4, 0.6, 0.7)
	style.set_border_width_all(1)
	style.set_corner_radius_all(7)
	style.content_margin_left  = 10
	style.content_margin_right = 10
	style.content_margin_top   = 6
	style.content_margin_bottom = 6
	_hint_panel.add_theme_stylebox_override("panel", style)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 3)
	_hint_panel.add_child(vbox)

	_hint_name_lbl = Label.new()
	_hint_name_lbl.add_theme_font_size_override("font_size", 12)
	_hint_name_lbl.add_theme_color_override("font_color", Color(0.8, 0.8, 1.0))
	_hint_name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_hint_name_lbl.custom_minimum_size = Vector2(230, 0)
	vbox.add_child(_hint_name_lbl)

	_hint_action_lbl = Label.new()
	_hint_action_lbl.add_theme_font_size_override("font_size", 14)
	_hint_action_lbl.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0))
	_hint_action_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(_hint_action_lbl)

	_hint_sub_lbl = Label.new()
	_hint_sub_lbl.add_theme_font_size_override("font_size", 11)
	_hint_sub_lbl.add_theme_color_override("font_color", Color(0.55, 0.85, 0.55))
	_hint_sub_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(_hint_sub_lbl)

	# Полоса кулдауна
	_cd_bar = ProgressBar.new()
	_cd_bar.custom_minimum_size = Vector2(230, 8)
	_cd_bar.max_value = 1.0
	_cd_bar.value = 0.0
	_cd_bar.show_percentage = false
	_cd_bar.visible = false
	var fill := StyleBoxFlat.new()
	fill.bg_color = Color(0.9, 0.5, 0.1)
	fill.set_corner_radius_all(4)
	_cd_bar.add_theme_stylebox_override("fill", fill)
	var bg := StyleBoxFlat.new()
	bg.bg_color = Color(0.15, 0.15, 0.15)
	bg.set_corner_radius_all(4)
	_cd_bar.add_theme_stylebox_override("background", bg)
	vbox.add_child(_cd_bar)

	_cd_timer_lbl = Label.new()
	_cd_timer_lbl.add_theme_font_size_override("font_size", 11)
	_cd_timer_lbl.add_theme_color_override("font_color", Color(0.9, 0.6, 0.2))
	_cd_timer_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_cd_timer_lbl.visible = false
	vbox.add_child(_cd_timer_lbl)

	add_child(_hint_panel)

func _show_hint() -> void:
	var gm: Node = get_node_or_null("/root/GameManager")
	_hint_name_lbl.text = building_name
	_hint_action_lbl.text = "[E]  " + action_label

	var sub := ""
	if money_reward > 0 and gm:
		if is_casino:
			sub = "±" + gm.format_money(money_reward) + "  |  🎰 Казино"
		elif _is_job():
			sub = "🕒 Смена 4–12 ч  •  " + gm.format_money(_hourly_rate()) + "/ч"
		else:
			sub = "+" + gm.format_money(money_reward)
	elif heal_amount > 0:
		sub = "❤ +%.0f здоровья" % heal_amount
	elif opens_education_shop:
		sub = "📚 Образование"
	elif opens_travel_agency:
		sub = "🗺 Смена района"
	elif opens_transport_shop:
		sub = "🚗 Транспорт"
	elif opens_radio_shop:
		sub = "📻 Радио"
	elif opens_stock_ui:
		sub = "📈 Торговля акциями"
	elif opens_business_shop:
		sub = "💼 Бизнес / Банк"

	_hint_sub_lbl.text = sub
	_hint_sub_lbl.visible = sub != ""
	_cd_bar.visible = false
	_cd_timer_lbl.visible = false
	# Анимация появления: slide up + fade in
	_hint_panel.modulate.a = 0.0
	_hint_panel.position.y = 67.0
	_hint_panel.visible = true
	var tw := create_tween()
	tw.set_parallel(true)
	tw.tween_property(_hint_panel, "modulate:a", 1.0, 0.18)
	tw.tween_property(_hint_panel, "position:y", 55.0, 0.18).set_ease(Tween.EASE_OUT)

func _show_cooldown_ui() -> void:
	_hint_name_lbl.text = building_name
	_hint_action_lbl.text = "⏳ Перезарядка..."
	_hint_action_lbl.add_theme_color_override("font_color", Color(0.9, 0.6, 0.2))
	_hint_sub_lbl.visible = false
	_cd_bar.visible = true
	_cd_timer_lbl.visible = true
	_hint_panel.visible = true

func _reset_action_color() -> void:
	_hint_action_lbl.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0))

# ── Обновление кулдауна каждый кадр ──────────────────────────────────────────
func _process(_delta: float) -> void:
	var e_now := Input.is_key_pressed(KEY_E)
	if player_inside and e_now and not _e_was_pressed and not _minigame_running:
		if not _is_any_ui_open():
			_do_action()
	_e_was_pressed = e_now

	if on_cooldown and player_inside:
		_cd_remaining = _cooldown_timer.time_left
		var frac := 1.0 - (_cd_remaining / cooldown_seconds)
		_cd_bar.value = frac
		var secs := int(_cd_remaining) + 1
		_cd_timer_lbl.text = "готово через %d сек" % secs

# ── Основное действие ─────────────────────────────────────────────────────────
func _do_action() -> void:
	if on_cooldown:
		return

	if opens_stock_ui:
		if edu_req > 0:
			var em: Node = get_node_or_null("/root/EducationManager")
			if em and not em.can_work_at(edu_req):
				_flash_sub("🎓 Нужно: " + em.LEVELS[edu_req].name, Color(1.0, 0.4, 0.4))
				return
		var sui = get_tree().get_first_node_in_group("stock_ui")
		if sui: sui.open()
		return

	if opens_business_shop:
		var shop = get_tree().get_first_node_in_group("business_shop")
		if shop: shop.open()
		return

	var gm: Node = get_node("/root/GameManager")
	var am: Node = get_node_or_null("/root/AudioManager")

	if opens_transport_shop:
		var ts = get_tree().get_first_node_in_group("transport_shop")
		if ts: ts.open()
		return

	if opens_radio_shop:
		var rs = get_tree().get_first_node_in_group("radio_shop")
		if rs: rs.open()
		return

	if opens_travel_agency:
		var tui = get_tree().get_first_node_in_group("travel_agency_ui")
		if tui: tui.open()
		return

	if opens_education_shop:
		var es = get_tree().get_first_node_in_group("education_shop")
		if es: es.open(edu_max_level)
		return

	if food_shop_name != "":
		var fs = get_tree().get_first_node_in_group("food_shop")
		if fs:
			var work_cb := Callable()
			if money_reward > 0:
				var gm_ref := gm
				var am_ref := am
				work_cb = func(): _do_simple_work(gm_ref, am_ref)
			fs.open(food_shop_name, food_shop_items, money_reward, edu_req, work_cb)
		return

	if edu_req > 0:
		var em: Node = get_node_or_null("/root/EducationManager")
		if em and not em.can_work_at(edu_req):
			_flash_sub("🎓 Нужно: " + em.LEVELS[edu_req].name, Color(1.0, 0.4, 0.4))
			return

	# Казино и лечение — без смены; обычная работа — через выбор смены
	if is_casino:
		var casino_ui = get_tree().get_first_node_in_group("casino_ui")
		if casino_ui: casino_ui.open()
		return
	if heal_amount > 0:
		_do_heal(gm, am)
		return
	_open_shift_picker(gm, am)

# ── Работа сменами ────────────────────────────────────────────────────────────
# Доход = ставка/час × часы × коэффициент мини-игры. Ставка берётся из money_reward
# (8-часовая смена ≈ старый баланс). Расход ресурсов в час:
const ENERGY_PER_H := {"light": 1.25, "heavy": 2.0}
const HUNGER_PER_H := {"light": 0.5,  "heavy": 0.9}
const THIRST_PER_H := {"light": 0.6,  "heavy": 1.1}
const HEALTH_PER_H_HEAVY := 0.4

func _hourly_rate() -> float:
	return money_reward / 8.0

func _is_job() -> bool:
	return money_reward > 0.0 and not is_casino and heal_amount <= 0.0 \
		and not opens_business_shop and not opens_stock_ui and not opens_travel_agency \
		and not opens_education_shop and not opens_transport_shop and not opens_radio_shop \
		and food_shop_name == ""

func _energy_cost(hours: int, housing_bonus: float) -> float:
	var per_h: float = ENERGY_PER_H["heavy"] if is_heavy_labor else ENERGY_PER_H["light"]
	return per_h * hours * (1.0 - housing_bonus)

func _open_shift_picker(gm: Node, am) -> void:
	if gm.energy <= 0:
		_flash_sub("😴 Энергия на нуле! Поспи.", Color(1.0, 0.4, 0.3))
		return
	var picker = get_tree().get_first_node_in_group("shift_ui")
	if picker == null:
		_begin_shift(8, gm, am)
		return
	picker.open(building_name, _hourly_rate(), is_heavy_labor, func(hours: int): _begin_shift(hours, gm, am))

func _begin_shift(hours: int, gm: Node, am) -> void:
	var housing_bonus: float = gm.get_housing_energy_drain_bonus() if gm.has_method("get_housing_energy_drain_bonus") else 0.0
	var kind := "heavy" if is_heavy_labor else "light"
	gm.energy = clamp(gm.energy - _energy_cost(hours, housing_bonus), 0.0, 100.0)
	gm.emit_signal("energy_changed", gm.energy)
	gm.hunger = clamp(gm.hunger - HUNGER_PER_H[kind] * hours, 0.0, 100.0)
	gm.emit_signal("hunger_changed", gm.hunger)
	gm.thirst = clamp(gm.thirst - THIRST_PER_H[kind] * hours, 0.0, 100.0)
	gm.emit_signal("thirst_changed", gm.thirst)
	if is_heavy_labor:
		gm.health = clamp(gm.health - HEALTH_PER_H_HEAVY * hours, 0.0, 100.0)
		gm.emit_signal("health_changed", gm.health)
	# Смена занимает игровое время
	gm.advance_time(hours)
	var base_pay: float = _hourly_rate() * hours
	if use_minigame:
		_launch_minigame(base_pay, gm, am)
	else:
		if am: am.play_coin()
		gm.add_money(base_pay)
		_flash_result("✅ +" + gm.format_money(base_pay), Color(0.4, 1.0, 0.4))
		_flash_visual(Color(0.6, 1.0, 0.5))
		FloatingText.spawn(get_tree(), global_position, "+" + gm.format_money(base_pay), Color(0.4, 1.0, 0.4))
		_start_cooldown()

func _launch_minigame(base_pay: float, gm: Node, am) -> void:
	var mg = get_tree().get_first_node_in_group("minigame")
	if mg == null:
		gm.add_money(base_pay)
		_flash_result("✅ +" + gm.format_money(base_pay), Color(0.4, 1.0, 0.4))
		_start_cooldown()
		return

	_minigame_running = true
	_hint_action_lbl.text = "⚡ Мини-игра..."
	_hint_sub_lbl.visible = false

	var title_idx: int = gm.current_title_index
	mg.start(action_label, minf(1.0 + title_idx * 0.08, 1.60))
	mg.finished.connect(_on_minigame_done.bind(base_pay, gm, am), CONNECT_ONE_SHOT)

func _on_minigame_done(mult: float, base_pay: float, gm: Node, am) -> void:
	_minigame_running = false
	var earned: float = base_pay * mult
	gm.add_money(earned)
	var col := Color(0.4, 1.0, 0.4) if mult >= 1.0 else Color(1.0, 0.5, 0.3)
	_flash_result("+" + gm.format_money(earned), col)
	FloatingText.spawn(get_tree(), global_position, "+" + gm.format_money(earned), col)
	if am:
		if mult >= 1.5: am.play_level_up()
		else: am.play_coin()
	_start_cooldown()

# Лечение (поликлиника) — без смены
func _do_heal(gm: Node, am) -> void:
	gm.health = minf(gm.health + heal_amount, 100.0)
	gm.emit_signal("health_changed", gm.health)
	_flash_result("❤ +%.0f здоровья" % heal_amount, Color(0.4, 1.0, 0.5))
	_flash_visual(Color(0.4, 1.0, 0.6))
	if am: am.play_buy()
	FloatingText.spawn(get_tree(), global_position, "❤ +%.0f" % heal_amount, Color(0.4, 1.0, 0.5))
	_start_cooldown()

# Простая подработка (например, при продуктовом) — фикс. оплата без выбора смены
func _do_simple_work(gm: Node, am) -> void:
	if gm.energy <= 0:
		_flash_sub("😴 Энергия на нуле! Поспи.", Color(1.0, 0.4, 0.3))
		return
	var housing_bonus: float = gm.get_housing_energy_drain_bonus() if gm.has_method("get_housing_energy_drain_bonus") else 0.0
	gm.energy = clamp(gm.energy - 10.0 * (1.0 - housing_bonus), 0.0, 100.0)
	gm.emit_signal("energy_changed", gm.energy)
	gm.hunger = clamp(gm.hunger - 4.0, 0.0, 100.0)
	gm.emit_signal("hunger_changed", gm.hunger)
	gm.thirst = clamp(gm.thirst - 5.0, 0.0, 100.0)
	gm.emit_signal("thirst_changed", gm.thirst)
	if am: am.play_coin()
	gm.add_money(money_reward)
	_flash_result("✅ +" + gm.format_money(money_reward), Color(0.4, 1.0, 0.4))
	FloatingText.spawn(get_tree(), global_position, "+" + gm.format_money(money_reward), Color(0.4, 1.0, 0.4))
	_start_cooldown()

# ── Кулдаун ───────────────────────────────────────────────────────────────────
func _start_cooldown() -> void:
	on_cooldown = true
	_cd_remaining = cooldown_seconds
	_cooldown_timer.start()
	if player_inside:
		_show_cooldown_ui()

func _on_cooldown_done() -> void:
	on_cooldown = false
	var am_cd = get_node_or_null("/root/AudioManager")
	if am_cd: am_cd.play_coin()
	if player_inside:
		_reset_action_color()
		_show_hint()
	else:
		var ptw := create_tween()
		ptw.tween_property(self, "scale", Vector2(1.10, 1.10), 0.12).set_ease(Tween.EASE_OUT)
		ptw.tween_property(self, "scale", Vector2(1.0, 1.0), 0.28).set_ease(Tween.EASE_IN_OUT)
	_spawn_ready_sparks()

func _spawn_ready_sparks() -> void:
	for i in 6:
		var sp := ColorRect.new()
		sp.size = Vector2(randf_range(3.0, 5.5), randf_range(3.0, 5.5))
		sp.color = Color(1.0, randf_range(0.75, 0.95), 0.18, 0.92)
		sp.position = global_position + Vector2(randf_range(-30, 30), randf_range(-20, 10))
		get_parent().add_child(sp)
		var sc := Vector2(randf_range(-28, 28), randf_range(-55, -15))
		var stw := sp.create_tween()
		stw.set_parallel(true)
		stw.tween_property(sp, "position", sp.position + sc, 0.50).set_ease(Tween.EASE_OUT)
		stw.tween_property(sp, "modulate:a", 0.0, 0.42).set_delay(0.10)
		stw.set_parallel(false)
		stw.tween_callback(sp.queue_free)

# ── Вспышка визуала здания ───────────────────────────────────────────────────
func _flash_visual(flash_col: Color) -> void:
	var vis: ColorRect = get_node_or_null("Visual")
	if vis == null:
		return
	var orig := vis.color
	var tw := create_tween()
	tw.tween_property(vis, "color", flash_col, 0.07)
	tw.tween_property(vis, "color", orig, 0.30)

# ── Флэш-эффекты текста ───────────────────────────────────────────────────────
func _flash_result(text: String, col: Color) -> void:
	_hint_action_lbl.text = text
	_hint_action_lbl.add_theme_color_override("font_color", col)
	_hint_sub_lbl.visible = false
	_cd_bar.visible = false
	_cd_timer_lbl.visible = false

func _flash_sub(text: String, col: Color) -> void:
	_hint_sub_lbl.text = text
	_hint_sub_lbl.add_theme_color_override("font_color", col)
	_hint_sub_lbl.visible = true

func _is_any_ui_open() -> bool:
	# Проверяем дочерние CanvasLayer HUD (InventoryUI, StatsUI, LoanUI, StockUI и т.д.)
	var hud := get_tree().get_first_node_in_group("hud")
	if hud:
		for child in hud.get_children():
			if child is CanvasLayer and (child as CanvasLayer).visible:
				return true
	# FoodShop живёт в World, проверяем по группе
	for n in get_tree().get_nodes_in_group("food_shop"):
		if n is CanvasLayer and n.visible:
			return true
	return false

# ── Зона игрока ───────────────────────────────────────────────────────────────
func _on_body_entered(body: Node2D) -> void:
	if body.name != "Player":
		return
	player_inside = true
	if on_cooldown:
		_show_cooldown_ui()
	else:
		_reset_action_color()
		_show_hint()
	# Лёгкий пульс масштаба здания при входе
	var tw := create_tween()
	tw.tween_property(self, "scale", Vector2(1.06, 1.06), 0.10).set_ease(Tween.EASE_OUT)
	tw.tween_property(self, "scale", Vector2(1.0, 1.0), 0.18).set_ease(Tween.EASE_IN_OUT)

func _on_body_exited(body: Node2D) -> void:
	if body.name != "Player":
		return
	player_inside = false
	var tw := create_tween()
	tw.tween_property(_hint_panel, "modulate:a", 0.0, 0.12)
	tw.tween_callback(func(): _hint_panel.visible = false; _hint_panel.modulate.a = 1.0)
