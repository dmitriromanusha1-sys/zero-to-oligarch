extends SceneTree
func _initialize() -> void:
	await process_frame
	var gm = root.get_node_or_null("/root/GameManager")
	var bm = root.get_node_or_null("/root/BusinessManager")
	gm.tutorial_done = true; gm.current_slot = 1; gm.reset_game()
	gm.money = 1_000_000_000.0; gm.current_title_index = 9
	var w = load("res://scenes/World.tscn").instantiate()
	root.add_child(w)
	await create_timer(0.5).timeout
	var bs = w.get_tree().get_first_node_in_group("business_shop")
	bs.open()
	print("opened, count=%d" % bm.business_count())
	# открыть бизнесы как из UI
	bm.open_business("latok"); bm.open_business("ip"); bm.open_business("cafe")
	await process_frame
	print("after opening 3: count=%d active=%d cap=%d" % [bm.business_count(), bm.active_index, bm.max_businesses()])
	# переключить активный
	bm.set_active(0)
	await process_frame
	print("switched active to 0: owned=%s" % bm.owned_business_id)
	print("OK"); quit(0)
