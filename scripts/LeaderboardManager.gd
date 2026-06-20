extends Node

const SAVE_PATH = "user://leaderboard.cfg"
const MAX_ENTRIES = 5

# Каждая запись: {money, day, title, date_str}
var entries: Array = []

func _ready() -> void:
	_load()

func try_add_entry() -> bool:
	var gm: Node = get_node_or_null("/root/GameManager")
	if gm == null:
		return false
	var entry: Dictionary = {
		"money": gm.get_net_worth(),
		"day":   gm.day,
		"title": gm.get_title(),
		"date":  _date_string(),
	}
	entries.append(entry)
	entries.sort_custom(func(a, b): return a.money > b.money)
	if entries.size() > MAX_ENTRIES:
		entries.resize(MAX_ENTRIES)
	_save()
	return true

func _date_string() -> String:
	var t: Dictionary = Time.get_datetime_dict_from_system()
	return "%02d.%02d.%04d" % [t.day, t.month, t.year]

func _save() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("lb", "count", entries.size())
	for i in entries.size():
		cfg.set_value("lb", "e%d_money" % i, entries[i].money)
		cfg.set_value("lb", "e%d_day"   % i, entries[i].day)
		cfg.set_value("lb", "e%d_title" % i, entries[i].title)
		cfg.set_value("lb", "e%d_date"  % i, entries[i].date)
	cfg.save(SAVE_PATH)

func _load() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(SAVE_PATH) != OK:
		return
	var count: int = cfg.get_value("lb", "count", 0)
	entries.clear()
	for i in count:
		entries.append({
			"money": cfg.get_value("lb", "e%d_money" % i, 0.0),
			"day":   cfg.get_value("lb", "e%d_day"   % i, 0),
			"title": cfg.get_value("lb", "e%d_title" % i, ""),
			"date":  cfg.get_value("lb", "e%d_date"  % i, ""),
		})
