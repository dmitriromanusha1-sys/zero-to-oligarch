extends Node

signal locale_changed(new_locale: String)

var locale: String = "ru"

const STRINGS := {
	"ru": {
		# Настройки — общее
		"settings_title":    "⚙  Настройки",
		"tab_sound":         "🔊 Звук",
		"tab_screen":        "🖥 Экран",
		"tab_controls":      "⌨ Управление",
		# Звук
		"volume_section":    "ГРОМКОСТЬ",
		"fps_section":       "ОГРАНИЧЕНИЕ FPS",
		"master":            "Мастер",
		"music":             "Музыка",
		"sounds":            "Звуки",
		"reset_settings":    "↺  Сбросить все настройки",
		# Экран
		"window_mode":       "РЕЖИМ ОКНА",
		"resolution":        "РАЗРЕШЕНИЕ ОКНА",
		"fullscreen":        "🖥  Полный экран",
		"vsync":             "⟳  VSync",
		"window_only":       "Применяется только в оконном режиме",
		"language_section":  "ЯЗЫК ИНТЕРФЕЙСА",
		# Управление
		"keybinds":          "ГОРЯЧИЕ КЛАВИШИ",
		"rebind_hint":       "Нажми кнопку → затем нажми нужную клавишу",
		"waiting_key":       "[ нажми клавишу ]",
		"action_up":         "Вверх",
		"action_down":       "Вниз",
		"action_left":       "Влево",
		"action_right":      "Вправо",
		"action_interact":   "Взаимодействие",
		"action_pause":      "Пауза / Закрыть",
		"action_sleep":      "Сон",
		# Диалог сброса
		"confirm_reset_msg": "Сбросить все настройки\nна значения по умолчанию?",
		"confirm_reset_yes": "✓  Сбросить",
		"confirm_reset_no":  "✕  Отмена",
		# Тогглы
		"on":                "ВКЛ",
		"off":               "ВЫКЛ",
		# Главное меню
		"menu_new_game":     "▶   Новая игра",
		"menu_continue":     "⏩   Продолжить",
		"menu_leaderboard":  "🏆   Таблица рекордов",
		"menu_settings":     "⚙   Настройки",
		"menu_hint":         "WASD / стрелки — движение     •     E — взаимодействие     •     ESC — пауза",
		# Таблица рекордов
		"lb_title":          "🏆 Лучшие забеги (Топ-5)",
		"lb_empty":          "Рекордов пока нет.\nСыграй и выйди в главное меню!",
		# Геймплей
		"tab_gameplay":           "🎮 Геймплей",
		"difficulty_section":     "СЛОЖНОСТЬ",
		"diff_easy":              "🌱 Лёгкая",
		"diff_normal":            "⚖ Нормальная",
		"diff_hardcore":          "💀 Хардкор",
		"diff_easy_desc":         "Штрафы и налоги ×0.5\nГолод убывает медленнее",
		"diff_normal_desc":       "Стандартный баланс",
		"diff_hardcore_desc":     "Штрафы и налоги ×1.5\nГолод убывает быстрее",
		"speed_section":          "СКОРОСТЬ ВРЕМЕНИ ПО УМОЛЧАНИЮ",
		"autopause_section":      "ПРОЧЕЕ",
		"autopause_label":        "⏸  Пауза при открытии меню",
		# Доступность
		"tab_access":             "♿ Доступн.",
		"font_size_section":      "РАЗМЕР ТЕКСТА",
		"font_normal":            "Обычный",
		"font_large":             "Крупный",
		"font_xlarge":            "Очень крупный",
		"contrast_section":       "КОНТРАСТ",
		"high_contrast_label":    "⬛  Высокий контраст",
		"anim_section":           "АНИМАЦИИ",
		"ui_anim_label":          "✨  Анимации интерфейса",
		"access_note":            "Изменения шрифта применяются\nпри следующем открытии панелей",
		# История
		"tab_history":            "📋 История",
		"history_empty":          "Изменений пока нет.\nОткрой настройки и что-нибудь измени.",
		"history_clear":          "🗑  Очистить журнал",
	},
	"en": {
		# Settings — general
		"settings_title":    "⚙  Settings",
		"tab_sound":         "🔊 Sound",
		"tab_screen":        "🖥 Screen",
		"tab_controls":      "⌨ Controls",
		# Sound
		"volume_section":    "VOLUME",
		"fps_section":       "FPS LIMIT",
		"master":            "Master",
		"music":             "Music",
		"sounds":            "SFX",
		"reset_settings":    "↺  Reset all settings",
		# Screen
		"window_mode":       "WINDOW MODE",
		"resolution":        "WINDOW RESOLUTION",
		"fullscreen":        "🖥  Fullscreen",
		"vsync":             "⟳  VSync",
		"window_only":       "Applies in windowed mode only",
		"language_section":  "INTERFACE LANGUAGE",
		# Controls
		"keybinds":          "KEY BINDINGS",
		"rebind_hint":       "Click a button → then press a key",
		"waiting_key":       "[ press key ]",
		"action_up":         "Up",
		"action_down":       "Down",
		"action_left":       "Left",
		"action_right":      "Right",
		"action_interact":   "Interact",
		"action_pause":      "Pause / Close",
		"action_sleep":      "Sleep",
		# Reset dialog
		"confirm_reset_msg": "Reset all settings\nto default values?",
		"confirm_reset_yes": "✓  Reset",
		"confirm_reset_no":  "✕  Cancel",
		# Toggles
		"on":                "ON",
		"off":               "OFF",
		# Main menu
		"menu_new_game":     "▶   New Game",
		"menu_continue":     "⏩   Continue",
		"menu_leaderboard":  "🏆   Leaderboard",
		"menu_settings":     "⚙   Settings",
		"menu_hint":         "WASD / arrows — move     •     E — interact     •     ESC — pause",
		# Leaderboard
		"lb_title":          "🏆 Best Runs (Top-5)",
		"lb_empty":          "No records yet.\nPlay and go back to main menu!",
		# Gameplay
		"tab_gameplay":           "🎮 Gameplay",
		"difficulty_section":     "DIFFICULTY",
		"diff_easy":              "🌱 Easy",
		"diff_normal":            "⚖ Normal",
		"diff_hardcore":          "💀 Hardcore",
		"diff_easy_desc":         "Fines and taxes ×0.5\nHunger drains slower",
		"diff_normal_desc":       "Standard balance",
		"diff_hardcore_desc":     "Fines and taxes ×1.5\nHunger drains faster",
		"speed_section":          "DEFAULT TIME SPEED",
		"autopause_section":      "OTHER",
		"autopause_label":        "⏸  Pause when opening menu",
		# Accessibility
		"tab_access":             "♿ Access.",
		"font_size_section":      "TEXT SIZE",
		"font_normal":            "Normal",
		"font_large":             "Large",
		"font_xlarge":            "Extra Large",
		"contrast_section":       "CONTRAST",
		"high_contrast_label":    "⬛  High Contrast",
		"anim_section":           "ANIMATIONS",
		"ui_anim_label":          "✨  UI Animations",
		"access_note":            "Font size changes apply\nwhen panels are next opened",
		# History
		"tab_history":            "📋 History",
		"history_empty":          "No changes yet.\nOpen settings and change something.",
		"history_clear":          "🗑  Clear log",
	},
}

func t(key: String) -> String:
	var d: Dictionary = STRINGS.get(locale, STRINGS["ru"])
	return d.get(key, STRINGS["ru"].get(key, key))

func set_locale(loc: String) -> void:
	if loc == locale:
		return
	locale = loc
	emit_signal("locale_changed", locale)
