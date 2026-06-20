extends Area2D

# Криминальное NPC в Промзоне: рискованное задание с высокой наградой
# Мини-игра: при успехе — деньги + штраф репутации; при провале — штраф деньги и здоровье

const FloatingText = preload("res://scripts/FloatingText.gd")

@export var job_name: String = "Тёмное дело"
@export var reward: float = 5000.0
@export var penalty_money: float = 1000.0
@export var penalty_health: float = 20.0
@export var success_chance: float = 0.6
@export var rep_cost: int = 10

var _hint: Control
var _player_inside: bool = false
var _e_was: bool = false
var _on_cd: bool = false
var _cd_timer: Timer

const JOBS := [
	{"name":"🕵 Передать пакет",   "reward":3000,  "pen_m":500,   "pen_h":10, "chance":0.75, "rep":5},
	{"name":"🚗 Угнать машину",    "reward":8000,  "pen_m":2000,  "pen_h":20, "chance":0.55, "rep":12},
	{"name":"🏪 Ограбить ларёк",   "reward":5000,  "pen_m":1500,  "pen_h":15, "chance":0.60, "rep":10},
	{"name":"📦 Продать контрафакт","reward":4000, "pen_m":1000,  "pen_h":5,  "chance":0.70, "rep":7},
	{"name":"💊 Химия для завода", "reward":12000, "pen_m":4000,  "pen_h":30, "chance":0.45, "rep":18},
]

var _job_idx: int = 0

func _ready() -> void:
	add_to_group("criminal_job")

	_job_idx = randi() % JOBS.size()
	var job: Dictionary = JOBS[_job_idx]

	# Тень под персонажем
	var shadow := ColorRect.new()
	shadow.color    = Color(0, 0, 0, 0.20)
	shadow.size     = Vector2(24, 6)
	shadow.position = Vector2(-12, 2)
	add_child(shadow)

	# Тело (тёмная одежда)
	var body := ColorRect.new()
	body.size     = Vector2(18, 28)
	body.position = Vector2(-9, -28)
	body.color    = Color(0.12, 0.10, 0.14)
	add_child(body)

	# Голова
	var head := ColorRect.new()
	head.size     = Vector2(16, 14)
	head.position = Vector2(-8, -43)
	head.color    = Color(0.22, 0.18, 0.24)
	add_child(head)

	# Иконка + пульсирующая аура
	var lbl := Label.new()
	lbl.text     = "🦹"
	lbl.position = Vector2(-14, -68)
	lbl.add_theme_font_size_override("font_size", 20)
	lbl.add_theme_constant_override("outline_size", 4)
	lbl.add_theme_color_override("font_outline_color", Color(0.5, 0.0, 0.5, 0.70))
	add_child(lbl)

	var name_lbl := Label.new()
	name_lbl.text = "Дилер"
	name_lbl.position = Vector2(-26, -88)
	name_lbl.add_theme_font_size_override("font_size", 10)
	name_lbl.add_theme_color_override("font_color", Color(0.75, 0.40, 0.80))
	name_lbl.add_theme_constant_override("outline_size", 3)
	name_lbl.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.80))
	add_child(name_lbl)

	# Подсказка как мини-панель
	var hint_panel := PanelContainer.new()
	hint_panel.position = Vector2(-105, 20)
	hint_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var hps := StyleBoxFlat.new()
	hps.bg_color = Color(0.08, 0.04, 0.10, 0.92)
	hps.border_color = Color(0.55, 0.20, 0.60, 0.85)
	hps.set_border_width_all(1)
	hps.set_corner_radius_all(6)
	hps.content_margin_left   = 8
	hps.content_margin_right  = 8
	hps.content_margin_top    = 5
	hps.content_margin_bottom = 5
	hint_panel.add_theme_stylebox_override("panel", hps)
	hint_panel.visible = false

	_hint = Label.new()
	_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_hint.add_theme_font_size_override("font_size", 11)
	_hint.add_theme_color_override("font_color", Color(0.88, 0.60, 0.92))
	_hint.add_theme_constant_override("outline_size", 2)
	_hint.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.70))
	_hint.text = "[E] %s\n+%s  |  риск %.0f%%" % [
		job.name, get_node("/root/GameManager").format_money(job.reward), (1.0 - job.chance) * 100
	]
	hint_panel.add_child(_hint)
	add_child(hint_panel)
	# Перенаправим hint на панель для управления видимостью
	_hint = hint_panel

	var shape := CollisionShape2D.new()
	var rect  := RectangleShape2D.new()
	rect.size = Vector2(80, 60)
	shape.shape = rect
	add_child(shape)

	_cd_timer = Timer.new()
	_cd_timer.wait_time = 30.0
	_cd_timer.one_shot  = true
	_cd_timer.timeout.connect(func(): _on_cd = false; if _player_inside: _hint.visible = true)
	add_child(_cd_timer)

	# Пульсирующая аура (фиолетовый кружок)
	var aura := ColorRect.new()
	aura.size = Vector2(36, 36)
	aura.position = Vector2(-18, -36)
	aura.color = Color(0.45, 0.05, 0.50, 0.0)
	add_child(aura)
	var aura_tw := create_tween().set_loops()
	aura_tw.tween_property(aura, "color:a", 0.28, 0.9)
	aura_tw.tween_property(aura, "color:a", 0.0,  0.9)

	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

func _process(_delta: float) -> void:
	var e_now := Input.is_key_pressed(KEY_E)
	if _player_inside and e_now and not _e_was and not _on_cd:
		_do_job()
	_e_was = e_now

func _do_job() -> void:
	_on_cd = true
	_hint.visible = false
	_cd_timer.start()

	var gm := get_node("/root/GameManager")
	var rm := get_node_or_null("/root/ReputationManager")
	var am := get_node_or_null("/root/AudioManager")
	var job: Dictionary = JOBS[_job_idx]

	# Репутация снижает шанс успеха у "честных" игроков, повышает у нечестных
	var actual_chance: float = job.chance
	if rm:
		actual_chance += (40 - rm.reputation) * 0.003

	if randf() < actual_chance:
		# Успех
		gm.add_money(job.reward)
		if rm: rm.add(-job.rep)
		if am: am.play_level_up()
		FloatingText.spawn(get_tree(), global_position, "✅ +" + gm.format_money(job.reward) + " (репутация -" + str(job.rep) + ")", Color(0.8, 0.5, 1.0))
		var qm := get_node_or_null("/root/QuestManager")
		if qm: qm.add_diary_entry("🦹 Выполнено: " + job.name + " (+" + gm.format_money(job.reward) + ")")
	else:
		# Провал
		gm.spend_money(minf(job.pen_m, gm.money))
		gm.health = maxf(5.0, gm.health - job.pen_h)
		gm.emit_signal("health_changed", gm.health)
		if rm: rm.add(-job.rep * 2)
		if am: am.play_negative()
		FloatingText.spawn(get_tree(), global_position,
			"❌ Провал! -%s, -%d hp" % [gm.format_money(job.pen_m), int(job.pen_h)],
			Color(1.0, 0.3, 0.3))

	# Меняем задание после выполнения
	_job_idx = randi() % JOBS.size()

func _on_body_entered(body: Node) -> void:
	if body.name == "Player":
		_player_inside = true
		if not _on_cd: _hint.visible = true

func _on_body_exited(body: Node) -> void:
	if body.name == "Player":
		_player_inside = false
		_hint.visible = false
