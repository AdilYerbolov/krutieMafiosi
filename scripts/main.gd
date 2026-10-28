extends Control
## Корневой контроллер: титульный экран → пролог → 6 ужинов с интерлюдиями → концовка.

var dinner: DinnerView
var vn: VNView
var journal: Journal
var fader: ColorRect
var title_layer: Control
var end_layer: Control

func _ready() -> void:
	dinner = DinnerView.new()
	add_child(dinner)
	vn = VNView.new()
	add_child(vn)
	journal = Journal.new()
	add_child(journal)
	dinner.vn = vn
	dinner.journal = journal
	vn.journal = journal
	fader = ColorRect.new()
	fader.set_anchors_preset(Control.PRESET_FULL_RECT)
	fader.color = Color(0, 0, 0, 0)
	fader.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(fader)
	vn.hide()
	dinner.hide()
	_show_title()

func _fade(to: float, t: float = 0.5) -> void:
	var tw := create_tween()
	tw.tween_property(fader, "color:a", to, t)
	await tw.finished

func _lbl(text: String, size: int, color: Color) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	return l

func _show_title() -> void:
	if title_layer != null:
		title_layer.queue_free()
	title_layer = Control.new()
	title_layer.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(title_layer)
	move_child(title_layer, get_child_count() - 2)
	var bg := TextureRect.new()
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	bg.stretch_mode = TextureRect.STRETCH_SCALE
	bg.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	bg.texture = SpriteFactory.background("dining_room")
	bg.modulate = Color(0.45, 0.45, 0.5)
	title_layer.add_child(bg)
	var cc := CenterContainer.new()
	cc.set_anchors_preset(Control.PRESET_FULL_RECT)
	title_layer.add_child(cc)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 14)
	v.custom_minimum_size = Vector2(520, 0)
	cc.add_child(v)
	v.add_child(_lbl("ПОСЛЕДНИЙ СТОЛ", 72, Color(0.95, 0.85, 0.55)))
	v.add_child(_lbl("Шесть ужинов. Один стол. Вы накрываете — они решают, кто останется.", 20, Color(0.85, 0.82, 0.75)))
	var sp := Control.new()
	sp.custom_minimum_size = Vector2(0, 30)
	v.add_child(sp)
	var b1 := Button.new()
	b1.text = "Новая игра"
	b1.custom_minimum_size = Vector2(0, 56)
	b1.add_theme_font_size_override("font_size", 24)
	b1.pressed.connect(_start.bind(0))
	v.add_child(b1)
	var b2 := Button.new()
	b2.text = "Выход"
	b2.custom_minimum_size = Vector2(0, 46)
	b2.add_theme_font_size_override("font_size", 20)
	b2.pressed.connect(func(): get_tree().quit())
	v.add_child(b2)
	var dbg := HBoxContainer.new()
	dbg.alignment = BoxContainer.ALIGNMENT_CENTER
	v.add_child(dbg)
	var dl := Label.new()
	dl.text = "Тест, с ужина: "
	dl.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6))
	dbg.add_child(dl)
	for i in range(1, 7):
		var b := Button.new()
		b.text = str(i)
		b.pressed.connect(_start.bind(i))
		dbg.add_child(b)
	v.add_child(_lbl("Управление: клик/пробел — далее · Ctrl — пропуск · H — скрыть интерфейс · L — лог · J — досье", 15, Color(0.7, 0.7, 0.65)))

func _start(from_dinner: int) -> void:
	title_layer.queue_free()
	title_layer = null
	if end_layer != null:
		end_layer.queue_free()
		end_layer = null
	GameState.reset()
	if from_dinner == 0:
		await _play_interlude_steps(Story.interlude(0))
	for n in range(maxi(from_dinner, 1), 7):
		await _fade(1.0, 0.5)
		dinner.show()
		await dinner.run_dinner(n)
		dinner.hide()
		if n < 6:
			await _play_interlude_steps(Story.interlude(n))
	await _play_interlude_steps(Story.ending(Story.pick_ending()))
	await _show_end()

func _play_interlude_steps(steps: Array) -> void:
	await _fade(1.0, 0.5)
	dinner.hide()
	vn.set_overlay(false)
	vn.clear_stage()
	vn.reset_ui()
	vn.fx_target = null
	vn.show()
	await _fade(0.0, 0.5)
	await vn.play(steps)
	await _fade(1.0, 0.6)
	vn.hide()
	vn.clear_stage()

func _show_end() -> void:
	var code := Story.pick_ending()
	end_layer = ColorRect.new()
	(end_layer as ColorRect).color = Color(0, 0, 0, 1)
	end_layer.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(end_layer)
	move_child(end_layer, get_child_count() - 2)
	var cc := CenterContainer.new()
	cc.set_anchors_preset(Control.PRESET_FULL_RECT)
	end_layer.add_child(cc)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 18)
	v.custom_minimum_size = Vector2(760, 0)
	cc.add_child(v)
	v.add_child(_lbl("КОНЕЦ", 28, Color(0.7, 0.7, 0.7)))
	v.add_child(_lbl(Story.ending_title(code), 56, Color(0.95, 0.85, 0.55)))
	var g := GameState
	v.add_child(_lbl("Порядок %d · Сара %d · Хаос %d · Незнакомец %d · Потери %d · Неловких моментов %d" % [
		g.v("order"), g.v("sara"), g.v("chaos"), g.v("stranger"), g.v("casualties"), g.v("clumsy")], 16, Color(0.55, 0.55, 0.55)))
	var b := Button.new()
	b.text = "В главное меню"
	b.custom_minimum_size = Vector2(0, 52)
	b.add_theme_font_size_override("font_size", 22)
	b.pressed.connect(func():
		end_layer.queue_free()
		end_layer = null
		_show_title())
	v.add_child(b)
	await _fade(0.0, 0.6)
