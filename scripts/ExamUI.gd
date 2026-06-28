extends CanvasLayer

# Экзамен-викторина для получения образования. Вопросы с 4 вариантами и таймером;
# сложность зависит от уровня, который сдаёшь. Сдача при >= 60% правильных.
# По завершении эмитит finished(mult): mult >= 1.0 — сдал, < 1.0 — провал.

signal finished(multiplier: float)

const NUM_QUESTIONS := 5
const TIME_PER_Q := 12.0
const PASS_RATIO := 0.6   # доля правильных для сдачи

var _questions: Array = []
var _idx: int = 0
var _correct_count: int = 0
var _time_left: float = 0.0
var _answering: bool = false
var _level_name: String = ""

var _panel: Panel
var _title_lbl: Label
var _progress_lbl: Label
var _timer_bar: ProgressBar
var _q_lbl: Label
var _opt_btns: Array = []
var _result_box: VBoxContainer
var _quiz_box: VBoxContainer

# ── Банки знаний ──────────────────────────────────────────────────────────────
const KB_LOW := [
	["Столица России?", ["Москва", "Киев", "Минск", "Сочи"], 0],
	["Сколько копеек в рубле?", ["100", "10", "1000", "50"], 0],
	["Синий + жёлтый = какой цвет?", ["Зелёный", "Красный", "Фиолетовый", "Чёрный"], 0],
	["Сколько месяцев в году?", ["12", "10", "11", "13"], 0],
	["Какая планета — наш дом?", ["Земля", "Марс", "Венера", "Луна"], 0],
	["Сколько дней в неделе?", ["7", "5", "6", "8"], 0],
]
const KB_MID := [
	["Что такое инфляция?", ["Рост цен", "Падение цен", "Налог", "Скидка"], 0],
	["Сколько дней в обычном году?", ["365", "360", "366", "350"], 0],
	["Что такое зарплата?", ["Плата за труд", "Долг", "Налог", "Кредит"], 0],
	["Что такое бюджет?", ["План доходов и расходов", "Кредит", "Штраф", "Вклад"], 0],
	["Кто платит налоги?", ["Граждане и бизнес", "Только дети", "Никто", "Только банки"], 0],
]
const KB_HIGH := [
	["Что такое дивиденды?", ["Доход с акций", "Долг", "Штраф", "Аренда"], 0],
	["Что такое «актив»?", ["То, что приносит доход", "Долг", "Расход", "Налог"], 0],
	["Рост ставки ЦБ делает кредиты...", ["Дороже", "Дешевле", "Бесплатными", "Запрещёнными"], 0],
	["Что такое ВВП?", ["Стоимость всех товаров и услуг", "Вид налога", "Банк", "Валюта"], 0],
	["Диверсификация — это...", ["Распределение вложений", "Один крупный вклад", "Кредит", "Банкротство"], 0],
	["Что такое ликвидность?", ["Лёгкость продажи актива", "Размер долга", "Ставка налога", "Цена нефти"], 0],
]

func _ready() -> void:
	layer = 13
	visible = false
	add_to_group("exam_ui")
	_build_ui()

func _build_ui() -> void:
	var dimmer := ColorRect.new()
	dimmer.set_anchors_preset(Control.PRESET_FULL_RECT)
	dimmer.color = Color(0, 0, 0, 0.80)
	dimmer.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(dimmer)

	_panel = Panel.new()
	_panel.set_anchors_preset(Control.PRESET_CENTER)
	_panel.size = Vector2(560, 440)
	_panel.position = Vector2(-280, -220)
	var ps := StyleBoxFlat.new()
	ps.bg_color = Color(0.045, 0.050, 0.095, 0.99)
	ps.border_color = UITheme.GOLD_DIM
	ps.set_border_width_all(2); ps.set_corner_radius_all(12)
	ps.content_margin_left = 18; ps.content_margin_right = 18
	ps.content_margin_top = 14; ps.content_margin_bottom = 14
	_panel.add_theme_stylebox_override("panel", ps)
	add_child(_panel)

	var root := VBoxContainer.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.add_theme_constant_override("separation", 10)
	_panel.add_child(root)

	_title_lbl = Label.new()
	_title_lbl.add_theme_font_size_override("font_size", 18)
	_title_lbl.add_theme_color_override("font_color", Color(0.6, 0.85, 1.0))
	_title_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	root.add_child(_title_lbl)

	# Прогресс + таймер
	var top := HBoxContainer.new()
	top.add_theme_constant_override("separation", 10)
	root.add_child(top)
	_progress_lbl = Label.new()
	_progress_lbl.add_theme_font_size_override("font_size", 12)
	_progress_lbl.add_theme_color_override("font_color", Color(0.75, 0.78, 0.85))
	_progress_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top.add_child(_progress_lbl)
	_timer_bar = ProgressBar.new()
	_timer_bar.custom_minimum_size = Vector2(180, 12)
	_timer_bar.max_value = TIME_PER_Q
	_timer_bar.show_percentage = false
	var tf := StyleBoxFlat.new(); tf.bg_color = Color(0.30, 0.62, 0.95); tf.set_corner_radius_all(4)
	_timer_bar.add_theme_stylebox_override("fill", tf)
	var tb := StyleBoxFlat.new(); tb.bg_color = Color(0.12, 0.14, 0.20); tb.set_corner_radius_all(4)
	_timer_bar.add_theme_stylebox_override("background", tb)
	top.add_child(_timer_bar)

	root.add_child(HSeparator.new())

	# Викторина
	_quiz_box = VBoxContainer.new()
	_quiz_box.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_quiz_box.add_theme_constant_override("separation", 12)
	root.add_child(_quiz_box)

	_q_lbl = Label.new()
	_q_lbl.add_theme_font_size_override("font_size", 17)
	_q_lbl.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0))
	_q_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_q_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD
	_q_lbl.custom_minimum_size = Vector2(0, 60)
	_quiz_box.add_child(_q_lbl)

	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 10)
	grid.add_theme_constant_override("v_separation", 10)
	_quiz_box.add_child(grid)
	for i in 4:
		var b := Button.new()
		b.custom_minimum_size = Vector2(245, 54)
		b.add_theme_font_size_override("font_size", 15)
		b.autowrap_mode = TextServer.AUTOWRAP_WORD
		var idx := i
		b.pressed.connect(func(): _answer(idx))
		grid.add_child(b)
		_opt_btns.append(b)

	# Результат
	_result_box = VBoxContainer.new()
	_result_box.set_anchors_preset(Control.PRESET_FULL_RECT)
	_result_box.alignment = BoxContainer.ALIGNMENT_CENTER
	_result_box.add_theme_constant_override("separation", 16)
	_result_box.visible = false
	root.add_child(_result_box)

# ── Запуск ────────────────────────────────────────────────────────────────────
func start(level_name: String, target_level: int) -> void:
	_level_name = level_name
	_questions = _build_questions(target_level)
	_idx = 0
	_correct_count = 0
	_answering = true
	_quiz_box.visible = true
	for c in _result_box.get_children():
		c.queue_free()
	_result_box.visible = false
	_title_lbl.text = "📝 Экзамен: " + level_name
	visible = true
	_panel.modulate.a = 0.0
	_panel.scale = Vector2(0.93, 0.93)
	var tw := create_tween()
	tw.set_parallel(true)
	tw.tween_property(_panel, "modulate:a", 1.0, 0.18)
	tw.tween_property(_panel, "scale", Vector2(1.0, 1.0), 0.18).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	_show_question()

func _show_question() -> void:
	var q: Dictionary = _questions[_idx]
	_q_lbl.text = q.q
	_progress_lbl.text = "Вопрос %d/%d   ✅ %d" % [_idx + 1, _questions.size(), _correct_count]
	for i in _opt_btns.size():
		var b: Button = _opt_btns[i]
		b.text = q.opts[i]
		b.disabled = false
		_style_opt(b, "normal")
	_time_left = TIME_PER_Q
	_timer_bar.value = TIME_PER_Q
	_answering = true

func _process(delta: float) -> void:
	if not visible or not _answering:
		return
	_time_left -= delta
	_timer_bar.value = maxf(_time_left, 0.0)
	if _time_left <= 0.0:
		_answer(-1)   # время вышло — засчитываем как неверный

func _answer(choice: int) -> void:
	if not _answering:
		return
	_answering = false
	var q: Dictionary = _questions[_idx]
	var correct: int = q.correct
	if choice == correct:
		_correct_count += 1
	# Подсветка: верный — зелёный, выбранный неверный — красный
	for i in _opt_btns.size():
		var b: Button = _opt_btns[i]
		b.disabled = true
		if i == correct:
			_style_opt(b, "good")
		elif i == choice:
			_style_opt(b, "bad")
		else:
			_style_opt(b, "dim")
	var am := get_node_or_null("/root/AudioManager")
	if am:
		if choice == correct: am.play_coin()
		else: am.play_negative()
	var t := create_tween()
	t.tween_interval(0.7)
	t.tween_callback(_next_question)

func _next_question() -> void:
	_idx += 1
	if _idx >= _questions.size():
		_show_result()
	else:
		_show_question()

func _show_result() -> void:
	_quiz_box.visible = false
	_timer_bar.value = 0.0
	var total: int = _questions.size()
	var ratio: float = float(_correct_count) / float(total)
	var passed: bool = ratio >= PASS_RATIO
	var mult: float = float(_correct_count) / (float(total) * PASS_RATIO)  # 60% -> 1.0

	_progress_lbl.text = ""
	for c in _result_box.get_children():
		c.queue_free()
	_result_box.visible = true

	var head := Label.new()
	head.text = ("🎉 Экзамен сдан!" if passed else "❌ Экзамен не сдан")
	head.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	head.add_theme_font_size_override("font_size", 26)
	head.add_theme_color_override("font_color", Color(0.45, 1.0, 0.55) if passed else Color(1.0, 0.45, 0.45))
	_result_box.add_child(head)

	var score := Label.new()
	score.text = "Правильных: %d из %d" % [_correct_count, total]
	score.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	score.add_theme_font_size_override("font_size", 16)
	score.add_theme_color_override("font_color", Color(0.85, 0.88, 0.92))
	_result_box.add_child(score)

	if not passed:
		var hint := Label.new()
		hint.text = "Нужно минимум %d/%d. Деньги не списаны — попробуй ещё раз." % [int(ceil(total * PASS_RATIO)), total]
		hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		hint.add_theme_font_size_override("font_size", 12)
		hint.add_theme_color_override("font_color", Color(0.70, 0.65, 0.65))
		hint.autowrap_mode = TextServer.AUTOWRAP_WORD
		_result_box.add_child(hint)

	var ok := Button.new()
	ok.text = "Продолжить"
	ok.custom_minimum_size = Vector2(180, 44)
	ok.add_theme_font_size_override("font_size", 15)
	var bs := StyleBoxFlat.new()
	bs.bg_color = Color(0.10, 0.20, 0.40); bs.border_color = Color(0.30, 0.55, 0.90, 0.85)
	bs.set_border_width_all(1); bs.set_corner_radius_all(8)
	ok.add_theme_stylebox_override("normal", bs)
	var bsh := bs.duplicate() as StyleBoxFlat
	bsh.bg_color = Color(0.15, 0.28, 0.52)
	ok.add_theme_stylebox_override("hover", bsh)
	ok.pressed.connect(func():
		visible = false
		finished.emit(mult))
	var cc := CenterContainer.new()
	cc.add_child(ok)
	_result_box.add_child(cc)

# ── Стиль кнопок-ответов ──────────────────────────────────────────────────────
func _style_opt(b: Button, state: String) -> void:
	var bg: Color
	var brd: Color
	var fg := Color(0.92, 0.94, 1.0)
	match state:
		"good": bg = Color(0.10, 0.30, 0.14); brd = Color(0.35, 0.80, 0.40); fg = Color(0.7, 1.0, 0.75)
		"bad":  bg = Color(0.30, 0.10, 0.10); brd = Color(0.80, 0.30, 0.30); fg = Color(1.0, 0.7, 0.7)
		"dim":  bg = Color(0.08, 0.08, 0.12); brd = Color(0.20, 0.20, 0.28); fg = Color(0.5, 0.5, 0.55)
		_:      bg = Color(0.10, 0.13, 0.22); brd = Color(0.30, 0.40, 0.62, 0.85)
	var s := StyleBoxFlat.new()
	s.bg_color = bg; s.border_color = brd
	s.set_border_width_all(1); s.set_corner_radius_all(8)
	b.add_theme_stylebox_override("normal", s)
	b.add_theme_stylebox_override("disabled", s)
	var h := s.duplicate() as StyleBoxFlat
	h.bg_color = bg.lightened(0.12)
	b.add_theme_stylebox_override("hover", h)
	b.add_theme_color_override("font_color", fg)
	b.add_theme_color_override("font_disabled_color", fg)

# ── Генерация вопросов ────────────────────────────────────────────────────────
func _build_questions(target_level: int) -> Array:
	var out: Array = []
	# 3 арифметики + 2 на знания, сложность по уровню
	for i in 3:
		out.append(_arith(target_level))
	var bank: Array = (KB_LOW if target_level <= 2 else (KB_MID if target_level <= 4 else KB_HIGH)).duplicate()
	bank.shuffle()
	for i in 2:
		if i < bank.size():
			out.append(_static_q(bank[i]))
	out.shuffle()
	return out

func _arith(target_level: int) -> Dictionary:
	var a: int
	var b: int
	var res: int
	var text: String
	if target_level <= 2:
		# сложение/вычитание малых чисел
		if randf() < 0.5:
			a = randi_range(2, 20); b = randi_range(2, 20)
			res = a + b; text = "Сколько будет %d + %d?" % [a, b]
		else:
			a = randi_range(10, 30); b = randi_range(1, a)
			res = a - b; text = "Сколько будет %d − %d?" % [a, b]
	elif target_level <= 4:
		# умножение / большое сложение
		if randf() < 0.6:
			a = randi_range(2, 12); b = randi_range(2, 12)
			res = a * b; text = "Сколько будет %d × %d?" % [a, b]
		else:
			a = randi_range(20, 90); b = randi_range(20, 90)
			res = a + b; text = "Сколько будет %d + %d?" % [a, b]
	else:
		# проценты / крупное умножение
		if randf() < 0.6:
			var p: int = [10, 20, 25, 50][randi() % 4]
			var n: int = randi_range(2, 20) * 100
			res = int(n * p / 100.0); text = "Сколько будет %d%% от %d?" % [p, n]
		else:
			a = randi_range(11, 25); b = randi_range(11, 25)
			res = a * b; text = "Сколько будет %d × %d?" % [a, b]
	# дистракторы
	var opts: Array = [str(res)]
	var guard := 0
	while opts.size() < 4 and guard < 50:
		guard += 1
		var off: int = randi_range(-9, 9)
		if off == 0: continue
		var cand: int = res + off
		if cand < 0: continue
		var cs := str(cand)
		if not opts.has(cs):
			opts.append(cs)
	while opts.size() < 4:
		opts.append(str(res + opts.size()))
	var correct_str := str(res)
	opts.shuffle()
	return {"q": text, "opts": opts, "correct": opts.find(correct_str)}

func _static_q(entry: Array) -> Dictionary:
	var q_text: String = entry[0]
	var opts_in: Array = (entry[1] as Array).duplicate()
	var correct_str: String = opts_in[entry[2]]
	opts_in.shuffle()
	return {"q": q_text, "opts": opts_in, "correct": opts_in.find(correct_str)}
