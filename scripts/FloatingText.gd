extends CanvasLayer

# Показывает всплывающий текст в позиции мира (автоматически конвертирует в экранные координаты)

static func spawn(tree: SceneTree, world_pos: Vector2, text: String, color: Color = Color.WHITE) -> void:
	var ft_layer := CanvasLayer.new()
	ft_layer.layer = 6
	tree.root.add_child(ft_layer)

	var camera: Camera2D = tree.get_first_node_in_group("player_camera")
	var screen_pos: Vector2
	if camera:
		screen_pos = camera.get_viewport().get_visible_rect().size / 2.0 + (world_pos - camera.global_position) * camera.zoom
	else:
		screen_pos = world_pos

	# Фоновый блик (тень + свечение)
	var bg := Label.new()
	bg.text = text
	bg.position = screen_pos + Vector2(-40, -20)
	bg.add_theme_font_size_override("font_size", 20)
	bg.add_theme_color_override("font_color", Color(0, 0, 0, 0))
	bg.add_theme_constant_override("outline_size", 8)
	bg.add_theme_color_override("font_outline_color", Color(color.r * 0.3, color.g * 0.3, color.b * 0.3, 0.50))
	ft_layer.add_child(bg)

	var lbl := Label.new()
	lbl.text = text
	lbl.position = screen_pos + Vector2(-40, -20)
	lbl.add_theme_font_size_override("font_size", 20)
	lbl.add_theme_color_override("font_color", color)
	lbl.add_theme_constant_override("outline_size", 4)
	lbl.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.88))
	ft_layer.add_child(lbl)

	lbl.scale = Vector2(0.35, 0.35)
	bg.scale = Vector2(0.35, 0.35)
	var drift_x: float = randf_range(-14.0, 14.0)
	var tween := ft_layer.create_tween()
	tween.set_parallel(true)
	tween.tween_property(lbl, "scale", Vector2(1.0, 1.0), 0.22).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	tween.tween_property(bg,  "scale", Vector2(1.0, 1.0), 0.22).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	tween.tween_property(lbl, "position", lbl.position + Vector2(drift_x, -82), 1.4).set_ease(Tween.EASE_OUT)
	tween.tween_property(bg,  "position", bg.position  + Vector2(drift_x, -82), 1.4).set_ease(Tween.EASE_OUT)
	tween.tween_property(lbl, "modulate:a", 0.0, 1.1).set_delay(0.40)
	tween.tween_property(bg,  "modulate:a", 0.0, 1.1).set_delay(0.40)
	tween.tween_callback(ft_layer.queue_free).set_delay(1.45)

	# Красные искры для негативных событий (красный цвет, урон/кража)
	if color.r > 0.70 and color.g < 0.50:
		for i in 4:
			var spark := ColorRect.new()
			spark.size = Vector2(3, 3)
			spark.color = Color(1.0, 0.22, 0.12, 0.90)
			spark.position = screen_pos + Vector2(randf_range(-10, 10), randf_range(-5, 5))
			ft_layer.add_child(spark)
			var stw := ft_layer.create_tween()
			var scatter := Vector2(randf_range(-32, 32), randf_range(-42, 8))
			stw.set_parallel(true)
			stw.tween_property(spark, "position", spark.position + scatter, 0.45).set_ease(Tween.EASE_OUT)
			stw.tween_property(spark, "scale", Vector2(0.3, 0.3), 0.45).set_ease(Tween.EASE_IN)
			stw.tween_property(spark, "modulate:a", 0.0, 0.36).set_delay(0.12)
			stw.set_parallel(false)
			stw.tween_callback(spark.queue_free)

	# Монетки-конфетти для позитивных событий (зелёный/золотой цвет)
	if color.g > 0.65 and color.r < 0.75:
		for i in 5:
			var coin := ColorRect.new()
			coin.size = Vector2(4, 4)
			coin.color = Color(1.0, 0.84, 0.12, 0.92)
			coin.position = screen_pos + Vector2(randf_range(-10, 10), randf_range(-6, 6))
			ft_layer.add_child(coin)
			var ctw := ft_layer.create_tween()
			var scatter := Vector2(randf_range(-40, 40), randf_range(-55, -8))
			ctw.set_parallel(true)
			ctw.tween_property(coin, "position", coin.position + scatter, 0.52).set_ease(Tween.EASE_OUT)
			ctw.tween_property(coin, "scale", Vector2(0.4, 0.4), 0.52).set_ease(Tween.EASE_IN)
			ctw.tween_property(coin, "modulate:a", 0.0, 0.45).set_delay(0.12)
			ctw.set_parallel(false)
			ctw.tween_callback(coin.queue_free)
