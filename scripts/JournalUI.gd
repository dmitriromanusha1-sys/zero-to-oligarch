extends CanvasLayer

# Журнал — единая точка входа для справочных окон (Цели/Достижения/Титулы/
# Статистика). Сам по себе это плавающая панель-вкладки сверху; контент —
# существующие окна, которые мы показываем/прячем при переключении вкладок.

const TABS = [
	{"icon": "📋", "name": "Цели"},
	{"icon": "🏆", "name": "Достижения"},
	{"icon": "👑", "name": "Титулы"},
	{"icon": "📊", "name": "Статистика"},
]

const HUD_BG     := Color(0.045, 0.050, 0.085, 0.96)
const HUD_BORDER := Color(0.70, 0.56, 0.18, 0.85)
const HUD_GOLD   := Color(1.0, 0.88, 0.30)

var _windows: Array = []      # окна, параллельно TABS
var _tab_btns: Array = []
var _bar: Panel
var _current: int = -1
var _am: Node = null

func _ready() -> void:
	layer = 10
	visible = false
	_build()

func setup(quest_ui: Node, ach_ui: Node, titles_ui: Node, stats_ui: Node) -> void:
	_windows = [quest_ui, ach_ui, titles_ui, stats_ui]

func _build() -> void:
	_bar = Panel.new()
	var ps := StyleBoxFlat.new()
	ps.bg_color = HUD_BG
	ps.border_color = HUD_BORDER
	for s in [SIDE_LEFT, SIDE_RIGHT, SIDE_TOP, SIDE_BOTTOM]:
		ps.set_border_width(s, 1)
		ps.set_corner_radius(s, 10)
	ps.shadow_color = Color(0, 0, 0, 0.40)
	ps.shadow_size = 6
	ps.content_margin_left = 10; ps.content_margin_right = 10
	ps.content_margin_top = 6; ps.content_margin_bottom = 6
	_bar.add_theme_stylebox_override("panel", ps)
	add_child(_bar)

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 6)
	_bar.add_child(row)

	var head := Label.new()
	head.text = "📖"
	head.add_theme_font_size_override("font_size", 20)
	head.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	row.add_child(head)

	for i in TABS.size():
		var tab: Dictionary = TABS[i]
		var b := Button.new()
		b.text = tab.icon + " " + tab.name
		b.custom_minimum_size = Vector2(132, 34)
		b.add_theme_font_size_override("font_size", 13)
		var idx := i
		b.pressed.connect(func(): _show_tab(idx))
		row.add_child(b)
		_tab_btns.append(b)

	var close_btn := Button.new()
	close_btn.text = "✕"
	close_btn.custom_minimum_size = Vector2(34, 34)
	close_btn.add_theme_font_size_override("font_size", 14)
	var cs := StyleBoxFlat.new()
	cs.bg_color = Color(0.22, 0.07, 0.07)
	cs.border_color = Color(0.55, 0.18, 0.18)
	for s in [SIDE_LEFT, SIDE_RIGHT, SIDE_TOP, SIDE_BOTTOM]:
		cs.set_border_width(s, 1)
		cs.set_corner_radius(s, 6)
	close_btn.add_theme_stylebox_override("normal", cs)
	var csh := cs.duplicate() as StyleBoxFlat
	csh.bg_color = Color(0.32, 0.10, 0.10)
	close_btn.add_theme_stylebox_override("hover", csh)
	close_btn.add_theme_color_override("font_color", Color.WHITE)
	close_btn.pressed.connect(close_all)
	row.add_child(close_btn)

	# Позиционируем по центру сверху после расчёта размера
	row.resized.connect(_reposition)
	call_deferred("_reposition")

func _reposition() -> void:
	if _bar == null:
		return
	var content: Control = _bar.get_child(0)
	var w: float = content.size.x + 20.0
	var h: float = content.size.y + 12.0
	_bar.size = Vector2(w, h)
	var vp := get_viewport().get_visible_rect().size
	_bar.position = Vector2((vp.x - w) * 0.5, 16.0)

func open() -> void:
	visible = true
	_reposition()
	_show_tab(0)

func _show_tab(i: int) -> void:
	for w in _windows:
		if w and is_instance_valid(w):
			w.visible = false
	_current = i
	var win = _windows[i] if i < _windows.size() else null
	if win and is_instance_valid(win) and win.has_method("open"):
		win.open()
	_highlight(i)
	_reposition()

func _highlight(active: int) -> void:
	for i in _tab_btns.size():
		var b: Button = _tab_btns[i]
		var is_on: bool = (i == active)
		var sn := StyleBoxFlat.new()
		sn.bg_color = Color(0.62, 0.48, 0.08) if is_on else Color(0.075, 0.085, 0.135)
		sn.border_color = HUD_GOLD if is_on else HUD_BORDER
		for s in [SIDE_LEFT, SIDE_RIGHT, SIDE_TOP, SIDE_BOTTOM]:
			sn.set_border_width(s, 1)
			sn.set_corner_radius(s, 6)
		b.add_theme_stylebox_override("normal", sn)
		var sh := sn.duplicate() as StyleBoxFlat
		sh.bg_color = sn.bg_color.lightened(0.15)
		b.add_theme_stylebox_override("hover", sh)
		b.add_theme_color_override("font_color",
			Color(0.12, 0.08, 0.0) if is_on else Color(0.85, 0.86, 0.92))

func close_all() -> void:
	for w in _windows:
		if w and is_instance_valid(w):
			w.visible = false
	visible = false

func _process(_delta: float) -> void:
	if not visible:
		return
	# Если активное окно закрыли его собственным крестиком — прячем и панель вкладок
	var any_open: bool = false
	for w in _windows:
		if w and is_instance_valid(w) and w.visible:
			any_open = true
			break
	if not any_open:
		visible = false
