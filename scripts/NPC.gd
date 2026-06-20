extends Area2D

@export var npc_name: String = "Прохожий"
@export var dialogues: Array = []

# Диалоги по титулу: Array of Array (индекс = title_index, пустой = fallback к dialogues)
@export var title_dialogues: Array = []

# Карта имён NPC → файл портрета
const PORTRAIT_MAP: Dictionary = {
	"🧔 Дядя Коля":            "res://assets/npc/npc_01_dyadya_kolya.png",
	"👵 Баба Нюра":            "res://assets/npc/npc_02_baba_nyura.png",
	"👮 Участковый":           "res://assets/npc/npc_03_uchastkoviy.png",
	"🧒 Димка":                "res://assets/npc/npc_04_dimka.png",
	"👷 Бригадир Степаныч":    "res://assets/npc/npc_05_stepanych.png",
	"👩‍🏭 Работница Галя":       "res://assets/npc/npc_06_galya.png",
	"🚛 Водила Вася":           "res://assets/npc/npc_07_vasya.png",
	"🔩 Слесарь Митя":         "res://assets/npc/npc_08_mitya.png",
	"👩 Продавщица Люда":      "res://assets/npc/npc_09_lyuda.png",
	"🧑 Алёша (молодой папа)": "res://assets/npc/npc_10_alyosha.png",
	"👴 Дедушка Иван":         "res://assets/npc/npc_11_dedushka_ivan.png",
	"🧕 Тётя Зина":            "res://assets/npc/npc_12_tyotya_zina.png",
	"🧑‍💻 IT-специалист Антон": "res://assets/npc/npc_13_it_anton.png",
	"👩‍💼 Менеджер Катя":        "res://assets/npc/npc_14_katya.png",
	"🔧 Автомеханик Серёга":   "res://assets/npc/npc_15_seryoga.png",
	"👩‍🎓 Студентка Маша":        "res://assets/npc/npc_16_masha.png",
	"💼 Бизнесмен Петрович":   "res://assets/npc/npc_17_petrovich.png",
	"🧑‍💼 Брокер Антон":         "res://assets/npc/npc_18_broker_anton.png",
	"👩‍🔬 Аналитик Виктория":    "res://assets/npc/npc_19_viktoriya.png",
	"👨‍💻 Разработчик Макс":     "res://assets/npc/npc_20_max.png",
	"🧑‍💰 Инвестор Борис":       "res://assets/npc/npc_21_boris.png",
	"🏖 Олигарх":              "res://assets/npc/npc_22_oligarh.png",
	"👩 Светская дама":        "res://assets/npc/npc_23_svetskaya_dama.png",
	"🧔 Телохранитель":        "res://assets/npc/npc_24_telohranitel.png",
	"🤴 Мультимиллионер":      "res://assets/npc/npc_25_multimillioner.png",
	"🧑‍🎨 Архитектор":           "res://assets/npc/npc_26_arhitektor.png",
	"👩‍💼 Советник":              "res://assets/npc/npc_27_sovetnik.png",
	"🕴 Министр":              "res://assets/npc/npc_28_ministr.png",
	"💂 Охранник КПП":         "res://assets/npc/npc_29_ohrannik.png",
	"👩‍💼 Чиновница":             "res://assets/npc/npc_30_chinovnitsa.png",
	"👑 Сенатор":              "res://assets/npc/npc_31_senator.png",
	"🧑‍✈️ Пилот":                "res://assets/npc/npc_32_pilot.png",
	"🤖 ИИ-консультант":       "res://assets/npc/npc_33_ii_consultant.png",
	"🗺 Турист Игорь":         "res://assets/npc/npc_34_helpful.png",
	"🧢 Шустрый Лёха":         "res://assets/npc/npc_35_thief.png",
	"🥃 Алкаш Толик":          "res://assets/npc/npc_36_drunk.png",
	"🛠 Торговец Семёныч":     "res://assets/npc/npc_37_vendor.png",
}

var hint_label: Label
var dialog_layer: CanvasLayer
var dialog_panel: Panel
var dialog_name_lbl: Label
var dialog_text_lbl: Label
var dialog_portrait: TextureRect
var dialog_portrait_frame: PanelContainer
var next_btn: Button

var player_inside: bool = false
var dialog_open: bool = false
var current_line: int = 0
var e_was_pressed: bool = false
var _active_lines: Array = []
var _type_tween: Tween = null
var _approach_ring: ColorRect = null

func _ready() -> void:
	_build_hint()
	_build_dialog()
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

func _build_hint() -> void:
	# Иконка-облачко всегда видна над NPC
	var bubble := Label.new()
	bubble.text = "💬"
	bubble.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	bubble.position = Vector2(-14, -68)
	bubble.add_theme_font_size_override("font_size", 18)
	add_child(bubble)
	# Боб: иконка плавно покачивается вверх-вниз
	var base_y: float = bubble.position.y
	var bob_tw := create_tween()
	bob_tw.set_loops()
	bob_tw.tween_method(func(v: float): bubble.position.y = base_y + sin(v) * 4.0, 0.0, TAU, 1.5)

	# Подсказка [E] появляется только при входе в зону
	hint_label = Label.new()
	hint_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint_label.position = Vector2(-60, -90)
	hint_label.text = "[E] Поговорить"
	hint_label.add_theme_font_size_override("font_size", 11)
	hint_label.add_theme_color_override("font_color", Color(0.9, 0.9, 0.6))
	hint_label.add_theme_constant_override("outline_size", 3)
	hint_label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.85))
	hint_label.visible = false
	add_child(hint_label)

func _build_dialog() -> void:
	dialog_layer = CanvasLayer.new()
	dialog_layer.layer = 9
	dialog_layer.visible = false

	var dimmer = ColorRect.new()
	dimmer.set_anchors_preset(Control.PRESET_FULL_RECT)
	dimmer.color = Color(0, 0, 0, 0.5)
	dimmer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	dialog_layer.add_child(dimmer)

	# Окно диалога — по центру экрана, фиксированный размер
	var DLG_W: float = 920.0
	var DLG_H: float = 300.0
	dialog_panel = Panel.new()
	dialog_panel.set_anchors_preset(Control.PRESET_CENTER)
	dialog_panel.position = Vector2(-DLG_W * 0.5, -DLG_H * 0.5)
	dialog_panel.size = Vector2(DLG_W, DLG_H)
	dialog_panel.clip_contents = true
	var ps := StyleBoxFlat.new()
	ps.bg_color = Color(0.05, 0.05, 0.09, 0.97)
	ps.border_color = Color(0.45, 0.38, 0.70, 0.90)
	for side in [SIDE_LEFT, SIDE_RIGHT, SIDE_TOP, SIDE_BOTTOM]:
		ps.set_border_width(side, 2)
		ps.set_corner_radius(side, 10)
	dialog_panel.add_theme_stylebox_override("panel", ps)
	dialog_layer.add_child(dialog_panel)

	# Портрет NPC — во всю высоту окна, слева. Используем PanelContainer +
	# clip_contents + expand_mode = EXPAND_IGNORE_SIZE (как в справочнике
	# титулов) — иначе TextureRect требует себе место по полному пиксельному
	# размеру исходной картинки и может "вытолкнуть" портрет за рамку или
	# наоборот не отрисоваться, если родитель пересчитает размеры неверно.
	var PORTRAIT_W: float = 230.0
	var portrait_frame := PanelContainer.new()
	portrait_frame.position = Vector2(0, 0)
	portrait_frame.size = Vector2(PORTRAIT_W, DLG_H)
	portrait_frame.clip_contents = true
	var pfs := StyleBoxFlat.new()
	pfs.bg_color = Color(0.04, 0.04, 0.08)
	pfs.border_color = Color(0.45, 0.38, 0.70, 0.85)
	pfs.set_border_width(SIDE_RIGHT, 2)
	pfs.set_corner_radius(CORNER_TOP_LEFT, 10)
	pfs.set_corner_radius(CORNER_BOTTOM_LEFT, 10)
	pfs.content_margin_left = 3; pfs.content_margin_right  = 3
	pfs.content_margin_top  = 3; pfs.content_margin_bottom = 3
	portrait_frame.add_theme_stylebox_override("panel", pfs)
	dialog_portrait_frame = portrait_frame
	portrait_frame.visible = false
	dialog_panel.add_child(portrait_frame)

	dialog_portrait = TextureRect.new()
	dialog_portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	dialog_portrait.expand_mode  = TextureRect.EXPAND_IGNORE_SIZE
	dialog_portrait.visible = true
	portrait_frame.add_child(dialog_portrait)

	var dialog_portrait_placeholder := Label.new()
	dialog_portrait_placeholder.text = "👤\nФото\nпоявится позже"
	dialog_portrait_placeholder.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	dialog_portrait_placeholder.vertical_alignment   = VERTICAL_ALIGNMENT_CENTER
	dialog_portrait_placeholder.add_theme_font_size_override("font_size", 12)
	dialog_portrait_placeholder.add_theme_color_override("font_color", Color(0.35, 0.35, 0.46))
	dialog_portrait_placeholder.visible = false
	portrait_frame.add_child(dialog_portrait_placeholder)

	var portrait_path: String = PORTRAIT_MAP.get(npc_name, "")
	var portrait_tex: Texture2D = null
	if portrait_path != "" and ResourceLoader.exists(portrait_path):
		portrait_tex = load(portrait_path)
	if portrait_tex == null:
		portrait_tex = NPCAvatar.generate(npc_name)
	if portrait_tex != null:
		dialog_portrait.texture = portrait_tex
		dialog_portrait.visible = true
		dialog_portrait_placeholder.visible = false
	else:
		dialog_portrait.visible = false
		dialog_portrait_placeholder.visible = true
	dialog_portrait_frame.visible = true

	# Отступ текста — сдвигаем вправо если есть портрет
	var text_offset_x: float = PORTRAIT_W + 26.0 if dialog_portrait_frame.visible else 22.0
	var text_w: float = DLG_W - text_offset_x - 22.0

	dialog_name_lbl = Label.new()
	dialog_name_lbl.position = Vector2(text_offset_x, 18)
	dialog_name_lbl.size = Vector2(text_w, 26)
	dialog_name_lbl.add_theme_font_size_override("font_size", 19)
	dialog_name_lbl.add_theme_color_override("font_color", Color(1.0, 0.85, 0.3))
	dialog_name_lbl.add_theme_constant_override("outline_size", 2)
	dialog_name_lbl.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.7))
	dialog_name_lbl.text = npc_name
	dialog_panel.add_child(dialog_name_lbl)

	var sep = ColorRect.new()
	sep.position = Vector2(text_offset_x, 50)
	sep.size     = Vector2(text_w, 1)
	sep.color    = Color(0.3, 0.32, 0.52, 0.70)
	dialog_panel.add_child(sep)

	dialog_text_lbl = Label.new()
	dialog_text_lbl.position = Vector2(text_offset_x, 64)
	dialog_text_lbl.size     = Vector2(text_w, 150)
	dialog_text_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	dialog_text_lbl.vertical_alignment = VERTICAL_ALIGNMENT_TOP
	dialog_text_lbl.add_theme_font_size_override("font_size", 16)
	dialog_text_lbl.add_theme_color_override("font_color", Color(0.92, 0.92, 0.95))
	dialog_panel.add_child(dialog_text_lbl)

	next_btn = Button.new()
	next_btn.text = "Далее ▶"
	next_btn.position = Vector2(DLG_W - 22.0 - 150.0, DLG_H - 22.0 - 42.0)
	next_btn.size = Vector2(150, 42)
	var bs := StyleBoxFlat.new()
	bs.bg_color = Color(0.15, 0.28, 0.52)
	bs.border_color = Color(0.35, 0.55, 0.90, 0.85)
	for side in [SIDE_LEFT, SIDE_RIGHT, SIDE_TOP, SIDE_BOTTOM]:
		bs.set_border_width(side, 1)
		bs.set_corner_radius(side, 5)
	next_btn.add_theme_stylebox_override("normal", bs)
	var bsh := bs.duplicate() as StyleBoxFlat
	bsh.bg_color = Color(0.20, 0.38, 0.65)
	next_btn.add_theme_stylebox_override("hover", bsh)
	next_btn.add_theme_font_size_override("font_size", 14)
	next_btn.add_theme_color_override("font_color", Color(0.9, 0.95, 1.0))
	next_btn.pressed.connect(_next_line)
	dialog_panel.add_child(next_btn)

	get_tree().root.call_deferred("add_child", dialog_layer)

func _get_lines() -> Array:
	var gm = get_node_or_null("/root/GameManager")
	if gm and title_dialogues.size() > gm.current_title_index:
		var td = title_dialogues[gm.current_title_index]
		if td is Array and not td.is_empty():
			return td
	return dialogues

func _process(_delta: float) -> void:
	var e_now = Input.is_key_pressed(KEY_E)
	if player_inside and e_now and not e_was_pressed:
		if not dialog_open:
			_open_dialog()
	e_was_pressed = e_now

func _open_dialog() -> void:
	_active_lines = _get_lines()
	if _active_lines.is_empty():
		return
	current_line = 0
	dialog_name_lbl.text = npc_name
	next_btn.text = "Далее ▶" if _active_lines.size() > 1 else "Закрыть"
	dialog_layer.visible = true
	dialog_panel.modulate.a = 0.0
	var orig_top: float = dialog_panel.offset_top
	dialog_panel.offset_top = orig_top + 40.0
	var tw := create_tween()
	tw.set_parallel(true)
	tw.tween_property(dialog_panel, "modulate:a", 1.0, 0.22)
	tw.tween_property(dialog_panel, "offset_top", orig_top, 0.28).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	dialog_open = true
	_type_text(str(_active_lines[current_line]))

func _type_text(text: String) -> void:
	dialog_text_lbl.text = text
	dialog_text_lbl.visible_characters = 0
	if _type_tween and _type_tween.is_valid():
		_type_tween.kill()
	_type_tween = create_tween()
	_type_tween.tween_property(dialog_text_lbl, "visible_characters", text.length(), maxf(text.length() * 0.032, 0.5))

func _next_line() -> void:
	if _type_tween and _type_tween.is_valid():
		_type_tween.kill()
		dialog_text_lbl.visible_characters = -1
		return
	current_line += 1
	if current_line >= _active_lines.size():
		var tw := create_tween()
		tw.tween_property(dialog_panel, "modulate:a", 0.0, 0.15)
		tw.tween_callback(func(): dialog_layer.visible = false; dialog_panel.modulate.a = 1.0)
		dialog_open = false
	else:
		next_btn.text = "Далее ▶" if current_line < _active_lines.size() - 1 else "Закрыть"
		var ptw := dialog_name_lbl.create_tween()
		ptw.tween_property(dialog_name_lbl, "modulate", Color(1.0, 1.0, 0.4), 0.10)
		ptw.tween_property(dialog_name_lbl, "modulate", Color(1.0, 1.0, 1.0), 0.25)
		_type_text(str(_active_lines[current_line]))

func _on_body_entered(body: Node2D) -> void:
	if body.name == "Player":
		player_inside = true
		hint_label.visible = true
		# Пульсирующее кольцо под NPC
		_approach_ring = ColorRect.new()
		_approach_ring.size = Vector2(48, 10)
		_approach_ring.position = Vector2(-24, 18)
		_approach_ring.color = Color(0.42, 0.82, 1.0, 0.70)
		_approach_ring.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(_approach_ring)
		var rtw := _approach_ring.create_tween()
		rtw.set_loops()
		rtw.tween_callback(func():
			if _approach_ring and is_instance_valid(_approach_ring):
				_approach_ring.scale = Vector2(1.0, 1.0)
				_approach_ring.modulate.a = 0.70
		)
		rtw.set_parallel(true)
		rtw.tween_property(_approach_ring, "scale", Vector2(1.7, 1.7), 0.65).set_ease(Tween.EASE_OUT)
		rtw.tween_property(_approach_ring, "modulate:a", 0.0, 0.55)
		rtw.set_parallel(false)
		rtw.tween_interval(0.10)

func _on_body_exited(body: Node2D) -> void:
	if body.name == "Player":
		player_inside = false
		hint_label.visible = false
		dialog_layer.visible = false
		dialog_open = false
		if _approach_ring and is_instance_valid(_approach_ring):
			_approach_ring.queue_free()
			_approach_ring = null
