extends Node

const SAVE_PATH := "user://settings.cfg"

var music_vol:  float = 1.0
var sfx_vol:    float = 1.0
var master_vol: float = 1.0
var fullscreen: bool  = false
var vsync:      bool  = true
var fps_cap:    int   = 60   # 0 = unlimited
var locale:     String = "ru"

# Геймплей
var difficulty:      String = "normal"  # "easy" | "normal" | "hard" | "hardcore"
var default_speed:   float  = 1.0       # множитель времени при старте
var autopause:       bool   = true      # пауза при открытии меню

# Доступность
var font_size:      String = "normal"  # "normal" | "large" | "xlarge"
var high_contrast:  bool   = false
var ui_animations:  bool   = true

# Уведомления
var notify_autosave:      bool = true
var notify_events:        bool = true
var notify_achievements:  bool = true
var notify_taxes:         bool = true
var notify_police:        bool = true
var show_hints:           bool = true

# Профили: массив из 3 словарей (пустой словарь = слот свободен)
var profiles: Array = [{}, {}, {}]

# Журнал изменений (только в памяти, не сохраняется)
var change_log: Array = []
const LOG_MAX := 10

func _log(text: String) -> void:
	var t := Time.get_time_dict_from_system()
	change_log.push_front("%02d:%02d — %s" % [t.hour, t.minute, text])
	if change_log.size() > LOG_MAX:
		change_log.resize(LOG_MAX)

func clear_log() -> void:
	change_log.clear()

# Множители сложности (penalty_mult, tax_mult, drain_mult)
const DIFFICULTY_PRESETS := {
	"easy":     {"penalty": 0.50, "tax": 0.50, "drain": 0.70, "health": 0.50},
	"normal":   {"penalty": 1.00, "tax": 1.00, "drain": 1.00, "health": 1.00},
	"hard":     {"penalty": 1.25, "tax": 1.25, "drain": 1.25, "health": 1.25},
	"hardcore": {"penalty": 1.50, "tax": 1.50, "drain": 1.50, "health": 1.50},
}

func get_diff() -> Dictionary:
	return DIFFICULTY_PRESETS.get(difficulty, DIFFICULTY_PRESETS["normal"])

func _ready() -> void:
	load_settings()
	_apply_all()

func _apply_all() -> void:
	_apply_volume("Master", master_vol)
	_apply_volume("Music",  music_vol)
	_apply_volume("SFX",    sfx_vol)
	_apply_fullscreen(fullscreen)
	_apply_vsync(vsync)
	_apply_fps_cap(fps_cap)
	_apply_locale(locale)
	_apply_font_size(font_size)

# ── Setters ───────────────────────────────────────────────────────────────────

func set_master_vol(v: float) -> void:
	master_vol = clampf(v, 0.0, 1.0)
	_apply_volume("Master", master_vol)
	_log("Мастер громкость: %d%%" % int(master_vol * 100))
	save_settings()

func set_music_vol(v: float) -> void:
	music_vol = clampf(v, 0.0, 1.0)
	_apply_volume("Music", music_vol)
	_log("Музыка: %d%%" % int(music_vol * 100))
	save_settings()

func set_sfx_vol(v: float) -> void:
	sfx_vol = clampf(v, 0.0, 1.0)
	_apply_volume("SFX", sfx_vol)
	_log("Звуки: %d%%" % int(sfx_vol * 100))
	save_settings()

func set_fullscreen(on: bool) -> void:
	fullscreen = on
	_apply_fullscreen(fullscreen)
	_log("Полный экран: %s" % ("ВКЛ" if on else "ВЫКЛ"))
	save_settings()

func set_vsync(on: bool) -> void:
	vsync = on
	_apply_vsync(vsync)
	_log("VSync: %s" % ("ВКЛ" if on else "ВЫКЛ"))
	save_settings()

func set_fps_cap(cap: int) -> void:
	fps_cap = cap
	_apply_fps_cap(fps_cap)
	_log("FPS лимит: %s" % ("∞" if cap == 0 else str(cap)))
	save_settings()

func set_locale(loc: String) -> void:
	locale = loc
	_apply_locale(locale)
	_log("Язык: %s" % loc.to_upper())
	save_settings()

func set_difficulty(d: String) -> void:
	difficulty = d
	_log("Сложность: %s" % d)
	save_settings()

func set_default_speed(s: float) -> void:
	default_speed = s
	_log("Скорость по умолчанию: ×%.0f" % s)
	save_settings()

func set_autopause(on: bool) -> void:
	autopause = on
	_log("Автопауза: %s" % ("ВКЛ" if on else "ВЫКЛ"))
	save_settings()

func set_font_size(s: String) -> void:
	font_size = s
	_apply_font_size(s)
	_log("Размер текста: %s" % s)
	save_settings()

func set_high_contrast(on: bool) -> void:
	high_contrast = on
	_log("Высокий контраст: %s" % ("ВКЛ" if on else "ВЫКЛ"))
	save_settings()

func set_ui_animations(on: bool) -> void:
	ui_animations = on
	_log("Анимации UI: %s" % ("ВКЛ" if on else "ВЫКЛ"))
	save_settings()

func set_notify(key: String, on: bool) -> void:
	match key:
		"autosave":     notify_autosave     = on
		"events":       notify_events       = on
		"achievements": notify_achievements = on
		"taxes":        notify_taxes        = on
		"police":       notify_police       = on
		"hints":        show_hints          = on
	_log("Уведомление «%s»: %s" % [key, "ВКЛ" if on else "ВЫКЛ"])
	save_settings()

func reset_to_defaults() -> void:
	master_vol     = 1.0
	music_vol      = 1.0
	sfx_vol        = 1.0
	fullscreen     = false
	vsync          = true
	fps_cap        = 60
	locale         = "ru"
	difficulty     = "normal"
	default_speed  = 1.0
	autopause      = true
	font_size      = "normal"
	high_contrast  = false
	ui_animations  = true
	notify_autosave     = true
	notify_events       = true
	notify_achievements = true
	notify_taxes        = true
	notify_police       = true
	show_hints          = true
	_log("Сброс до заводских настроек")
	_apply_all()
	save_settings()

# ── Apply helpers ─────────────────────────────────────────────────────────────

func _apply_volume(bus_name: String, linear: float) -> void:
	var idx := AudioServer.get_bus_index(bus_name)
	if idx >= 0:
		AudioServer.set_bus_volume_db(idx, linear_to_db(linear) if linear > 0.001 else -80.0)
		AudioServer.set_bus_mute(idx, linear <= 0.001)

func _apply_fullscreen(on: bool) -> void:
	if on:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)

func _apply_vsync(on: bool) -> void:
	DisplayServer.window_set_vsync_mode(
		DisplayServer.VSYNC_ENABLED if on else DisplayServer.VSYNC_DISABLED
	)

func _apply_fps_cap(cap: int) -> void:
	Engine.max_fps = cap

func save_profile(slot: int) -> void:
	if slot < 0 or slot >= profiles.size():
		return
	_log("Профиль %d сохранён" % (slot + 1))
	profiles[slot] = {
		"master_vol": master_vol, "music_vol": music_vol, "sfx_vol": sfx_vol,
		"fullscreen": fullscreen, "vsync": vsync, "fps_cap": fps_cap, "locale": locale,
		"difficulty": difficulty, "default_speed": default_speed, "autopause": autopause,
		"font_size": font_size, "high_contrast": high_contrast, "ui_animations": ui_animations,
	}
	save_settings()

func load_profile(slot: int) -> void:
	if slot < 0 or slot >= profiles.size() or profiles[slot].is_empty():
		return
	_log("Профиль %d загружен" % (slot + 1))
	var p: Dictionary = profiles[slot]
	master_vol = p.get("master_vol", master_vol)
	music_vol  = p.get("music_vol",  music_vol)
	sfx_vol    = p.get("sfx_vol",    sfx_vol)
	fullscreen = p.get("fullscreen", fullscreen)
	vsync      = p.get("vsync",      vsync)
	fps_cap       = p.get("fps_cap",       fps_cap)
	locale        = p.get("locale",        locale)
	difficulty    = p.get("difficulty",    difficulty)
	default_speed = p.get("default_speed", default_speed)
	autopause     = p.get("autopause",     autopause)
	font_size     = p.get("font_size",     font_size)
	high_contrast = p.get("high_contrast", high_contrast)
	ui_animations = p.get("ui_animations", ui_animations)
	_apply_all()
	save_settings()

func profile_filled(slot: int) -> bool:
	return slot >= 0 and slot < profiles.size() and not profiles[slot].is_empty()

func _apply_locale(loc: String) -> void:
	var L: Node = get_node_or_null("/root/Localization")
	if L: L.set_locale(loc)

func _apply_font_size(size_key: String) -> void:
	const SIZES := {"normal": 16, "large": 20, "xlarge": 25}
	var sz: int = SIZES.get(size_key, 16)
	var theme := Theme.new()
	theme.default_font_size = sz
	if get_tree():
		get_tree().root.theme = theme

# ── Persistence ───────────────────────────────────────────────────────────────

func save_settings() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("settings", "master_vol", master_vol)
	cfg.set_value("settings", "music_vol",  music_vol)
	cfg.set_value("settings", "sfx_vol",    sfx_vol)
	cfg.set_value("settings", "fullscreen", fullscreen)
	cfg.set_value("settings", "vsync",      vsync)
	cfg.set_value("settings", "fps_cap",    fps_cap)
	cfg.set_value("settings", "locale",        locale)
	cfg.set_value("settings", "difficulty",           difficulty)
	cfg.set_value("settings", "default_speed",        default_speed)
	cfg.set_value("settings", "autopause",            autopause)
	cfg.set_value("settings", "font_size",            font_size)
	cfg.set_value("settings", "high_contrast",        high_contrast)
	cfg.set_value("settings", "ui_animations",        ui_animations)
	cfg.set_value("settings", "notify_autosave",      notify_autosave)
	cfg.set_value("settings", "notify_events",        notify_events)
	cfg.set_value("settings", "notify_achievements",  notify_achievements)
	cfg.set_value("settings", "notify_taxes",         notify_taxes)
	cfg.set_value("settings", "notify_police",        notify_police)
	cfg.set_value("settings", "show_hints",           show_hints)
	for i in profiles.size():
		if not profiles[i].is_empty():
			cfg.set_value("profile_%d" % i, "data", profiles[i])
	cfg.save(SAVE_PATH)

func load_settings() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(SAVE_PATH) != OK:
		return
	master_vol = cfg.get_value("settings", "master_vol", 1.0)
	music_vol  = cfg.get_value("settings", "music_vol",  1.0)
	sfx_vol    = cfg.get_value("settings", "sfx_vol",    1.0)
	fullscreen = cfg.get_value("settings", "fullscreen", false)
	vsync      = cfg.get_value("settings", "vsync",      true)
	fps_cap    = cfg.get_value("settings", "fps_cap",    60)
	locale         = cfg.get_value("settings", "locale",        "ru")
	difficulty          = cfg.get_value("settings", "difficulty",          "normal")
	default_speed       = cfg.get_value("settings", "default_speed",       1.0)
	autopause           = cfg.get_value("settings", "autopause",           true)
	font_size      = cfg.get_value("settings", "font_size",      "normal")
	high_contrast  = cfg.get_value("settings", "high_contrast",  false)
	ui_animations  = cfg.get_value("settings", "ui_animations",  true)
	notify_autosave     = cfg.get_value("settings", "notify_autosave",     true)
	notify_events       = cfg.get_value("settings", "notify_events",       true)
	notify_achievements = cfg.get_value("settings", "notify_achievements", true)
	notify_taxes        = cfg.get_value("settings", "notify_taxes",        true)
	notify_police       = cfg.get_value("settings", "notify_police",       true)
	show_hints          = cfg.get_value("settings", "show_hints",          true)
	for i in profiles.size():
		var p = cfg.get_value("profile_%d" % i, "data", {})
		profiles[i] = p if p is Dictionary else {}
