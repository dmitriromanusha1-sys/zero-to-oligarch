extends Node

var _music_player: AudioStreamPlayer
var _sfx_player: AudioStreamPlayer
var _rain_player: AudioStreamPlayer

const MUSIC_DIR := "res://music/"
var _playlist: Array[String] = []
var _playlist_idx: int = 0

# ── Радио (станции) ──────────────────────────────────────────────────────────
# "Стандартное радио" доступно всем с начала игры (текущая музыка).
# "Французское радио" покупается в магазине радио в зоне 5 (Элитный район).
const RADIO_STATIONS: Array = [
	{
		"id": "standard", "name": "Стандартное радио", "icon": "📻", "freq": "88.5", "cost": 0, "zone_req": 0,
		"desc": "Обычный плейлист: эмбиент и саундтреки из «Метро».",
		"files": [
			"res://music/metro_last_light_17 Echoes of the Past (Guitar Version).mp3",
			"res://music/metro_last_light_09 Echoes of the Past.mp3",
			"res://music/metro_last_light_35 Into Sunset.mp3",
			"res://music/metro_last_light_36 The Farewell.mp3",
			"res://music/metro_last_light_37 Mobius (Based on La Reveuse by Marin Marais).mp3",
		],
	},
	{
		"id": "cold_will", "name": "Холодная воля", "icon": "❄", "freq": "95.3", "cost": 180000, "zone_req": 3,
		"desc": "Frostpunk — суровый оркестровый саундтрек о выживании и стойкости.",
		"files": [
			"res://music/frostpunk_01. Frostpunk Theme.mp3",
			"res://music/frostpunk_02. Are We Alone!.mp3",
			"res://music/frostpunk_08. Into The Storm.mp3",
			"res://music/frostpunk_09. The City Must Survive.mp3",
		],
	},
	{
		"id": "french", "name": "Французское радио", "icon": "🇫🇷", "freq": "101.2", "cost": 250000, "zone_req": 5,
		"desc": "Indila — атмосферная французская эстрада для элитного района.",
		"files": [
			"res://music/Indila - Ainsi Bas La Vida.mp3",
			"res://music/Indila - Derniere Dance.mp3",
			"res://music/Indila - Tourner Dans Le Vide (Version Orchestrale).mp3",
		],
	},
	{
		"id": "mix", "name": "МИКС", "icon": "🎧", "freq": "108.0", "cost": 250000, "zone_req": 0,
		"desc": "ABBA, Plenka, Sayfalse — разношёрстная подборка хитов.",
		"files": [
			"res://music/ABBA, Benny Andersson, Bjrn Ulvaeus - Money, Money, Money.mp3",
			"res://music/Plenka - Nightmare.mp3",
			"res://music/Sayfalse, cape, JXNDRO - MONTAGEM RUGADA.mp3",
		],
	},
]

var current_station: String = "standard"
# Радио как устройство: уровень = сколько волн ловит антенна.
# Уровень 0 — только базовая волна (индекс 0). Каждый апгрейд открывает
# следующую волну по порядку RADIO_STATIONS. Волна i доступна если i <= radio_level.
var radio_level: int = 0


const DISTRICT_COLORS := {
	"Промзона":              Color(0.3, 0.3, 0.5),
	"Рабочий квартал":       Color(0.35, 0.4, 0.35),
	"Спальный район":        Color(0.3, 0.45, 0.5),
	"Район среднего класса": Color(0.4, 0.5, 0.4),
	"Бизнес-квартал":        Color(0.45, 0.45, 0.3),
	"Элитный район":         Color(0.5, 0.4, 0.3),
	"Район олигархов":       Color(0.5, 0.45, 0.2),
}

func _ready() -> void:
	_ensure_buses()

	_music_player = AudioStreamPlayer.new()
	_music_player.bus = "Music"
	_music_player.volume_db = -18.0
	add_child(_music_player)

	_sfx_player = AudioStreamPlayer.new()
	_sfx_player.bus = "SFX"
	_sfx_player.volume_db = -10.0
	add_child(_sfx_player)

	_rain_player = AudioStreamPlayer.new()
	_rain_player.bus = "Music"
	_rain_player.volume_db = -99.0
	add_child(_rain_player)
	_build_rain_stream()
	_music_player.finished.connect(_on_track_finished)
	_load_station_playlist(current_station)
	_play_next_track()

func _load_station_playlist(station_id: String) -> void:
	var st := _get_station(station_id)
	if st.is_empty():
		return
	_playlist.clear()
	for f in (st.files as Array):
		_playlist.append(f as String)
	_playlist.shuffle()
	_playlist_idx = 0

func _get_station(station_id: String) -> Dictionary:
	for st in RADIO_STATIONS:
		if st.id == station_id: return st
	return {}

# ── Радио: публичный API ──────────────────────────────────────────────────────
func station_index(station_id: String) -> int:
	for i in RADIO_STATIONS.size():
		if RADIO_STATIONS[i].id == station_id:
			return i
	return -1

# Волна доступна, если её индекс не выше текущего уровня радио
func is_station_owned(station_id: String) -> bool:
	var idx := station_index(station_id)
	return idx >= 0 and idx <= radio_level

func max_radio_level() -> int:
	return RADIO_STATIONS.size() - 1

func is_radio_maxed() -> bool:
	return radio_level >= max_radio_level()

# Волна, которую откроет следующий апгрейд (или {} если уже максимум)
func next_upgrade_station() -> Dictionary:
	if is_radio_maxed():
		return {}
	return RADIO_STATIONS[radio_level + 1]

func next_upgrade_cost() -> int:
	var st := next_upgrade_station()
	return int(st.get("cost", 0)) if not st.is_empty() else 0

# Достигнута ли зона, требуемая для следующего апгрейда
func can_upgrade_radio() -> bool:
	var st := next_upgrade_station()
	if st.is_empty():
		return false
	var zm: Node = get_node_or_null("/root/ZoneManager")
	if zm and zm.max_zone_reached < int(st.get("zone_req", 0)):
		return false
	return true

func upgrade_radio() -> bool:
	var st := next_upgrade_station()
	if st.is_empty():
		return false
	var zm: Node = get_node_or_null("/root/ZoneManager")
	if zm and zm.max_zone_reached < int(st.get("zone_req", 0)):
		return false
	var gm: Node = get_node_or_null("/root/GameManager")
	if gm == null or not gm.spend_money(int(st.get("cost", 0))):
		return false
	radio_level += 1
	gm.save_game()
	return true

func select_station(station_id: String) -> bool:
	if not is_station_owned(station_id): return false
	if station_id == current_station: return true
	current_station = station_id
	_load_station_playlist(station_id)
	_play_next_track()
	var gm: Node = get_node_or_null("/root/GameManager")
	if gm: gm.save_game()
	return true

func save(cfg: ConfigFile) -> void:
	cfg.set_value("audio", "current_station", current_station)
	cfg.set_value("audio", "radio_level", radio_level)

func load_data(cfg: ConfigFile) -> void:
	current_station = cfg.get_value("audio", "current_station", "standard")
	radio_level = cfg.get_value("audio", "radio_level", -1)
	# Миграция со старой системы (owned_stations): уровень = самый дальний открытый
	if radio_level < 0:
		var owned: Array = cfg.get_value("audio", "owned_stations", ["standard"])
		var maxidx := 0
		for i in RADIO_STATIONS.size():
			if RADIO_STATIONS[i].id in owned:
				maxidx = maxi(maxidx, i)
		radio_level = maxidx
	radio_level = clampi(radio_level, 0, max_radio_level())
	if not is_station_owned(current_station):
		current_station = "standard"
	# GameManager стоит раньше AudioManager в автозагрузке и может вызвать
	# load_game() до того, как у AudioManager отработает _ready() — в этом
	# случае _music_player ещё не создан, и собственный _ready() сам подхватит
	# уже выставленный current_station, как только дойдёт очередь до него.
	if _music_player == null:
		return
	_load_station_playlist(current_station)
	_play_next_track()

func _play_next_track() -> void:
	if _playlist.is_empty():
		return
	var path: String = _playlist[_playlist_idx]
	var stream := load(path) as AudioStream
	if stream:
		_music_player.stream = stream
		_music_player.play()
	_playlist_idx = (_playlist_idx + 1) % _playlist.size()

func _on_track_finished() -> void:
	_play_next_track()

func _ensure_buses() -> void:
	for bus_name in ["Music", "SFX"]:
		if AudioServer.get_bus_index(bus_name) < 0:
			AudioServer.add_bus()
			var idx: int = AudioServer.bus_count - 1
			AudioServer.set_bus_name(idx, bus_name)
			AudioServer.set_bus_send(idx, "Master")

# ── Дождь ────────────────────────────────────────────────────────────────────

func _build_rain_stream() -> void:
	var sample_rate := 22050
	var dur_sec := 3.0
	var samples := int(sample_rate * dur_sec)
	var data := PackedByteArray()
	data.resize(samples * 2)
	var rng := RandomNumberGenerator.new()
	rng.seed = 99
	for i in samples:
		# Белый шум с лёгким низкочастотным фильтром (скользящее среднее 4 выборки)
		var raw: float = rng.randf_range(-1.0, 1.0)
		var val := int(clamp(raw * 8000.0, -32768, 32767))
		data[i * 2]     = val & 0xFF
		data[i * 2 + 1] = (val >> 8) & 0xFF
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.stereo = false
	stream.mix_rate = sample_rate
	stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
	stream.loop_begin = 0
	stream.loop_end = samples
	stream.data = data
	_rain_player.stream = stream

func play_rain() -> void:
	_rain_player.play()
	var tw := create_tween()
	tw.tween_property(_rain_player, "volume_db", -22.0, 2.0)

func stop_rain() -> void:
	var tw := create_tween()
	tw.tween_property(_rain_player, "volume_db", -99.0, 1.5)
	tw.tween_callback(_rain_player.stop)

# ── public API ────────────────────────────────────────────────────────────────

func play_coin() -> void:
	_play_tone(880.0, 0.07)

func play_click() -> void:
	_play_tone(660.0, 0.05)

func play_buy() -> void:
	_play_tone(523.0, 0.12)

func play_level_up() -> void:
	_play_chord([523.0, 659.0, 784.0], 0.25)

func play_negative() -> void:
	_play_tone(220.0, 0.15)

func notify_district(_district_name: String) -> void:
	pass

# ── tone generators ───────────────────────────────────────────────────────────

func _play_tone(freq: float, duration: float) -> void:
	var stream := AudioStreamWAV.new()
	var sample_rate := 22050
	var samples := int(sample_rate * duration)
	var data := PackedByteArray()
	data.resize(samples * 2)
	for i in samples:
		var t := float(i) / sample_rate
		var envelope := 1.0 - (t / duration)
		var val := int(clamp(sin(TAU * freq * t) * envelope * 28000.0, -32768, 32767))
		data[i * 2]     = val & 0xFF
		data[i * 2 + 1] = (val >> 8) & 0xFF
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.stereo = false
	stream.mix_rate = sample_rate
	stream.data = data
	_sfx_player.stream = stream
	_sfx_player.play()

func _play_chord(freqs: Array, duration: float) -> void:
	var sample_rate := 22050
	var samples := int(sample_rate * duration)
	var data := PackedByteArray()
	data.resize(samples * 2)
	for i in samples:
		var t := float(i) / sample_rate
		var envelope := 1.0 - (t / duration)
		var val_f := 0.0
		for f in freqs:
			val_f += sin(TAU * f * t)
		val_f /= freqs.size()
		var val := int(clamp(val_f * envelope * 28000.0, -32768, 32767))
		data[i * 2]     = val & 0xFF
		data[i * 2 + 1] = (val >> 8) & 0xFF
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.stereo = false
	stream.mix_rate = sample_rate
	stream.data = data
	_sfx_player.stream = stream
	_sfx_player.play()
