extends SceneTree
# Тест Фазы 5 недвижимости: простои, обслуживание, управляющий, save/load.
# Использует ИЗОЛИРОВАННЫЙ слот 99 и удаляет его в конце.

func _initialize() -> void:
	await process_frame
	var gm = root.get_node("/root/GameManager")
	var rem = root.get_node("/root/RealEstateManager")
	gm.current_slot = 99

	# Подготовка: даём титул и деньги, покупаем 4 квартиры.
	gm.current_title_index = 9
	gm.money = 100_000_000.0
	rem.reset()
	for i in range(4):
		rem.buy_property("apartment")
	_ok("Куплено 4 объекта", rem.property_count() == 4)
	_ok("Все заселены сразу", rem.occupied_count() == 4)

	var gross: float = rem.rental_income()
	var maint: float = rem.maintenance_cost()
	_ok("Аренда > 0", gross > 0.0)
	_ok("Обслуживание > 0", maint > 0.0)
	_ok("Без управляющего комиссия 0", rem.manager_fee() == 0.0)
	_ok("Чистый поток = аренда - обслуж", abs(rem.net_daily_income() - (gross - maint)) < 0.01)

	# Управляющий
	rem.set_manager(true)
	_ok("Управляющий нанят", rem.has_manager)
	_ok("Комиссия управляющего > 0", rem.manager_fee() > 0.0)
	var with_mgr: float = rem.net_daily_income()
	_ok("С управляющим поток меньше", with_mgr < gross - maint)

	# Простой: вручную делаем объект 0 простаивающим
	rem.properties[0]["vacant"] = true
	_ok("Объект 0 простаивает", rem.is_vacant(0))
	_ok("Заселено 3/4", rem.occupied_count() == 3)
	_ok("Аренда упала (простой не платит)", rem.rental_income() < gross)

	# save/load round-trip
	var prev_mgr: bool = rem.has_manager
	var prev_vacant: bool = rem.is_vacant(0)
	var prev_count: int = rem.property_count()
	gm.save_game()
	await create_timer(0.4).timeout   # дать фоновому потоку записать снимок на диск
	rem.reset()
	_ok("После reset портфель пуст", rem.property_count() == 0)
	_ok("После reset нет управляющего", not rem.has_manager)
	gm.current_slot = 99
	gm.load_game()
	await process_frame
	_ok("Загружено: кол-во объектов", rem.property_count() == prev_count)
	_ok("Загружено: управляющий", rem.has_manager == prev_mgr)
	_ok("Загружено: простой объекта 0", rem.is_vacant(0) == prev_vacant)

	# Месячный апдейт заселённости не падает
	for m in range(12):
		rem._update_occupancy()
	_ok("Месячные апдейты без ошибок", true)

	# Чистка изолированного слота
	var path := "user://savegame_slot99.cfg"
	if FileAccess.file_exists(path):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
	_ok("Слот 99 удалён", not FileAccess.file_exists(path))

	print("=== ТЕСТ ЗАВЕРШЁН ===")
	quit()

func _ok(label: String, cond: bool) -> void:
	print(("[OK]   " if cond else "[FAIL] "), label)
