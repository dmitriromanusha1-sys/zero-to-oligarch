extends CanvasLayer
# Интерактивное стартовое обучение с подсветкой целей.
# Показывается только при новой игре (gm.tutorial_done == false).
# Шаги "move"/"approach" ждут реального действия игрока; "info" — кнопку «Далее».

const SpotScript = preload("res://scripts/TutorialSpot.gd")

var gm
var _active: bool = false
var _step_i: int = 0
var _steps: Array = []
var _pulse: float = 0.0
var _move_accum: float = 0.0
var _target_building = null   # цель для шага approach/работа

# UI
var _spot: Control
var _panel: PanelContainer
var _title_lbl: Label
var _text_lbl: Label
var _step_lbl: Label
var _next_btn: Button
var _skip_btn: Button

func _ready() -> void:
	layer = 30
	gm = get_node_or_null("/root/GameManager")
	set_process(false)
	# Ждём, пока HUD и мир построятся
	get_tree().create_timer(0.4).timeout.connect(_try_start)

func _try_start() -> void:
	if not is_instance_valid(self):
		return
	if not gm or gm.tutorial_done:
		queue_free()
		return
	_build_ui()
	_define_steps()
	_active = true
	set_process(true)
	_show_step(0)

# ---------------------------------------------------------------- построение UI
func _build_ui() -> void:
	_spot = Control.new()
	_spot.set_script(SpotScript)
	_spot.set_anchors_preset(Control.PRESET_FULL_RECT)
	_spot.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_spot)

	_panel = PanelContainer.new()
	_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.09, 0.11, 0.18, 0.97)
	sb.border_color = Color(1.0, 0.84, 0.26, 0.85)
	sb.set_border_width_all(2)
	sb.set_corner_radius_all(14)
	sb.set_content_margin_all(18)
	sb.shadow_color = Color(0, 0, 0, 0.5)
	sb.shadow_size = 12
	_panel.add_theme_stylebox_override("panel", sb)
	add_child(_panel)

	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 10)
	vb.custom_minimum_size = Vector2(540, 0)
	_panel.add_child(vb)

	_step_lbl = Label.new()
	_step_lbl.add_theme_font_size_override("font_size", 14)
	_step_lbl.add_theme_color_override("font_color", Color(1.0, 0.84, 0.26))
	vb.add_child(_step_lbl)

	_title_lbl = Label.new()
	_title_lbl.add_theme_font_size_override("font_size", 24)
	_title_lbl.add_theme_color_override("font_color", Color(1, 1, 1))
	vb.add_child(_title_lbl)

	_text_lbl = Label.new()
	_text_lbl.add_theme_font_size_override("font_size", 18)
	_text_lbl.add_theme_color_override("font_color", Color(0.85, 0.88, 0.95))
	_text_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_text_lbl.custom_minimum_size = Vector2(540, 0)
	vb.add_child(_text_lbl)

	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_END
	row.add_theme_constant_override("separation", 10)
	vb.add_child(row)

	_skip_btn = Button.new()
	_skip_btn.text = "Пропустить обучение"
	_style_btn(_skip_btn, Color(0.16, 0.10, 0.10), Color(0.6, 0.4, 0.4))
	_skip_btn.pressed.connect(_finish)
	row.add_child(_skip_btn)

	_next_btn = Button.new()
	_next_btn.text = "Далее ▶"
	_style_btn(_next_btn, Color(0.12, 0.20, 0.14), Color(0.3, 0.8, 0.45))
	_next_btn.pressed.connect(_on_next)
	row.add_child(_next_btn)

func _style_btn(b: Button, bg: Color, border: Color) -> void:
	var sb := StyleBoxFlat.new()
	sb.bg_color = bg
	sb.border_color = border
	sb.set_border_width_all(2)
	sb.set_corner_radius_all(10)
	sb.set_content_margin_all(10)
	b.add_theme_stylebox_override("normal", sb)
	var hov := sb.duplicate()
	hov.bg_color = bg.lightened(0.12)
	b.add_theme_stylebox_override("hover", hov)
	b.add_theme_stylebox_override("pressed", hov)
	b.add_theme_font_size_override("font_size", 16)
	b.add_theme_color_override("font_color", Color(0.95, 0.97, 1.0))

# ----------------------------------------------------------------- шаги
func _define_steps() -> void:
	_steps = [
		{
			"title": "Добро пожаловать!",
			"text": "Ты на самом дне — бомж без денег и образования. Цель игры: подняться через 9 районов до олигарха.\n\n🕹 Для начала походи: клавиши WASD (или стрелки).",
			"mode": "move",
			"target": "none",
		},
		{
			"title": "Здания района",
			"text": "Отлично! По району разбросаны здания. Подойди к подсвеченному зданию работы.",
			"mode": "approach",
			"target": "job",
		},
		{
			"title": "Работа по сменам",
			"text": "Стоя рядом со зданием, нажми E. На работе выбираешь длину смены (4–12 ч): дольше — больше денег, но сильнее тратятся энергия и здоровье. А хорошая форма и воля (ветка «Жизнь») снижают усталость от смены.",
			"mode": "info",
			"target": "job",
		},
		{
			"title": "Профессия и постоянная работа",
			"text": "Кроме разовых смен есть настоящая карьера. Открой 🧑‍💼 Работа — это биржа труда: выучи профессию (квалификацию) и устройся на месячный контракт по своей специальности. Каждый день ты автоматически работаешь, копится оклад (платят раз в месяц), растёт грейд и выслуга. Режим работы: 🎲 авто (случайный результат) или 🎯 активный (мини-игра). А сама профессия даёт бонусы на всю игру — врачу дешевле лечение, юристу меньше налоги и т.д.",
			"mode": "info",
			"target": "none",
		},
		{
			"title": "Выживание и рацион",
			"text": "Следи за шкалами вверху: ❤ здоровье, 🍖 сытость, 💧 вода, ⚡ энергия. На нуле сытости или воды — теряешь здоровье. Но важно не только наесться, а ЧЕМ: здоровая еда (вода, супы, рыба) улучшает рацион 🥗 и здоровье, фастфуд и алкоголь — портят.",
			"mode": "info",
			"target": "bars",
		},
		{
			"title": "Сон, жильё и комфорт",
			"text": "Энергию восстанавливает только сон. Нажми эту кнопку и выбери, сколько часов спать. Восстановление зависит от комфорта жилья 🛋 — чем уютнее дом, тем больше энергии и здоровья за час и тем лучше настроение. Но собственное жильё нужно содержать: есть коммуналка (ЖКХ).",
			"mode": "info",
			"target": "sleep",
		},
		{
			"title": "Панель управления",
			"text": "Внизу — категории: 🏠 Быт (жильё, инвентарь), 💼 Финансы (бизнес, банк, биржа, кредиты, сводка), 👤 Жизнь, 📖 Журнал, ⚙ Система. Вверху рядом со временем нажми «ⓘ Подробнее» — там статус: жильё, репутация, образование, рацион и карьера.",
			"mode": "info",
			"target": "none",
		},
		{
			"title": "Образование",
			"text": "🎓 В школах, колледжах и университетах получаешь образование (со сдачей экзамена). Чем выше уровень — тем доходнее открываются работы. Чем выше интеллект — тем дешевле учиться, а каждый диплом, наоборот, делает тебя умнее (и общительнее на высших ступенях).",
			"mode": "info",
			"target": "none",
		},
		{
			"title": "Экономика и деньги",
			"text": "💸 Цены растут со временем (инфляция) и зависят от района — в богатых кварталах жить дороже, но и платят больше. Есть налоги с дохода и циклы (бум/спад). Открой 💼 Финансы → «Финансы (сводка)»: капитал, доходы, расходы и состояние экономики страны.",
			"mode": "info",
			"target": "none",
		},
		{
			"title": "Тёмная сторона",
			"text": "🕶 Есть и быстрый, но опасный путь — открой «Криминал» в нижней панели. Чёрный рынок, тёмные дела, рэкет, своя братва (с именными бригадирами) и контроль районов приносят «грязные» деньги (их надо отмывать через бизнесы). Периодически выпадают жирные заказы. Но каждое дело поднимает 🚨 розыск: при высоком — облавы и тюрьма, а конкуренты-ОПГ наезжают на твои активы. Держи банду сильной, копи общак, нанимай информаторов и плати ментам. Профессия «Юрист» смягчает срок. Риск против куша — решать тебе.",
			"mode": "info",
			"target": "none",
		},
		{
			"title": "Переезд и цель",
			"text": "🚌 Когда накопишь денег и репутацию, на автовокзале/в турфирме можно переехать в следующий район — там работы и жильё дороже и прибыльнее.\n\nУдачи на пути от бомжа до олигарха!",
			"mode": "info",
			"target": "none",
		},
	]

func _show_step(i: int) -> void:
	_step_i = i
	if i >= _steps.size():
		_finish()
		return
	var s: Dictionary = _steps[i]
	_step_lbl.text = "Шаг %d/%d" % [i + 1, _steps.size()]
	_title_lbl.text = String(s.title)
	_text_lbl.text = String(s.text)
	_move_accum = 0.0
	_target_building = null
	if String(s.target) == "job":
		_target_building = _nearest_job()
	var mode := String(s.mode)
	if mode == "info":
		_next_btn.visible = true
		_next_btn.text = ("Готово ✓" if i == _steps.size() - 1 else "Далее ▶")
	else:
		# Шаги, ждущие действия игрока — кнопку «Далее» прячем
		_next_btn.visible = false

func _on_next() -> void:
	_show_step(_step_i + 1)

func _finish() -> void:
	_active = false
	set_process(false)
	if gm:
		gm.tutorial_done = true
		gm.save_game()
	var tw := create_tween()
	tw.tween_property(_panel, "modulate:a", 0.0, 0.25)
	tw.parallel().tween_property(_spot, "modulate:a", 0.0, 0.25)
	tw.tween_callback(queue_free)

# ----------------------------------------------------------------- процесс
func _process(delta: float) -> void:
	if not _active:
		return
	_pulse += delta
	var s: Dictionary = _steps[_step_i]
	var rect := _current_target_rect(s)
	_spot.target_rect = rect
	_spot.pulse = _pulse
	_spot.show_arrow = (String(s.target) == "job") and rect.size.y > 1.0
	_spot.queue_redraw()
	_layout_panel(rect)

	match String(s.mode):
		"move":
			var p = _player()
			if p and p.velocity.length() > 12.0:
				_move_accum += delta
				if _move_accum >= 0.7:
					_show_step(_step_i + 1)
		"approach":
			var p = _player()
			if not _target_building:
				_target_building = _nearest_job()
			if p and _target_building and is_instance_valid(_target_building):
				if p.global_position.distance_to(_target_building.global_position) < 140.0:
					_show_step(_step_i + 1)

func _current_target_rect(s: Dictionary) -> Rect2:
	match String(s.target):
		"job":
			return _building_rect(_target_building)
		"bars":
			return _hud_rect("TopBar")
		"sleep":
			return _hud_rect("Dock/DockRow/SleepBtn")
		_:
			return Rect2()

func _layout_panel(target: Rect2) -> void:
	var vp := get_viewport().get_visible_rect().size
	var sz := _panel.size
	var x := (vp.x - sz.x) * 0.5
	# По умолчанию панель снизу; если подсвечена нижняя кнопка (сон) — поднимаем выше
	var y := vp.y - sz.y - 40.0
	if target.size.y > 1.0 and target.position.y > vp.y * 0.6:
		y = vp.y * 0.30
	_panel.position = Vector2(max(20.0, x), max(20.0, y))

# ----------------------------------------------------------------- helpers
func _player():
	return get_tree().get_first_node_in_group("player")

func _hud():
	return get_tree().get_first_node_in_group("hud")

func _hud_rect(path: String) -> Rect2:
	var h = _hud()
	if not h:
		return Rect2()
	var n = h.get_node_or_null(path)
	if n and n is Control:
		return n.get_global_rect()
	return Rect2()

func _nearest_job():
	var world = get_tree().get_first_node_in_group("world")
	var p = _player()
	if not world or not p:
		return null
	var container = world.get_node_or_null("Buildings")
	if not container:
		return null
	var best = null
	var best_d := INF
	for b in container.get_children():
		if b.has_method("_is_job") and b._is_job():
			var d: float = p.global_position.distance_to(b.global_position)
			if d < best_d:
				best_d = d
				best = b
	return best

func _building_rect(b) -> Rect2:
	if not b or not is_instance_valid(b):
		return Rect2()
	var xform: Transform2D = b.get_viewport().get_canvas_transform()
	var center: Vector2 = xform * b.global_position
	var sz := Vector2(120, 120)
	return Rect2(center - sz * 0.5, sz)
