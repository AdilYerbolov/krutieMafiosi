class_name WineGame
extends PanelContainer
## Мини-игра «Налить вино»: удерживайте кнопку/пробел, отпустите в золотой зоне.
## Недолив или перелив — штраф (результат уходит в DinnerView/Story).

signal done(result: Dictionary)

var dinner_no := 1
var guest := ""

var level := 0.0
var pouring := false
var finished := false
var time_left := 9.0
var target := 0.65
var half := 0.07
var rate := 0.33
var _t := 0.0
var _canvas: Control
var _info: Label
var _btn: Button
var _space_down := false

func setup(d: int, g: String) -> void:
	dinner_no = d
	guest = g
	rate = 0.30 + 0.025 * d
	half = maxf(0.045, 0.085 - 0.006 * d)
	target = randf_range(0.5, 0.78)
	if int(GameState.v("wine_tip")) > 0:
		half *= 1.3     # подсказка Бенито: золотая зона шире

func _ready() -> void:
	set_anchors_preset(Control.PRESET_CENTER)
	custom_minimum_size = Vector2(520, 520)
	offset_left = -260
	offset_right = 260
	offset_top = -260
	offset_bottom = 260
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.06, 0.05, 0.06, 0.96)
	sb.border_color = Color(0.7, 0.58, 0.3)
	sb.set_border_width_all(2)
	sb.set_corner_radius_all(8)
	sb.set_content_margin_all(16)
	add_theme_stylebox_override("panel", sb)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 8)
	add_child(v)
	var title := Label.new()
	title.text = "Налить вино: %s" % Chars.full_title(guest)
	title.add_theme_font_size_override("font_size", 22)
	title.add_theme_color_override("font_color", Color(0.95, 0.85, 0.55))
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(title)
	var hint := Label.new()
	hint.text = "Удерживайте ПРОБЕЛ или кнопку — вино льётся.\nОтпустите, когда уровень в золотой зоне. Не переполните бокал!"
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.add_theme_font_size_override("font_size", 15)
	v.add_child(hint)
	_canvas = Control.new()
	_canvas.custom_minimum_size = Vector2(300, 300)
	_canvas.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_canvas.draw.connect(_on_draw)
	v.add_child(_canvas)
	_info = Label.new()
	_info.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_info.add_theme_font_size_override("font_size", 18)
	v.add_child(_info)
	_btn = Button.new()
	_btn.text = "ЛИТЬ (удерживать)"
	_btn.custom_minimum_size = Vector2(0, 56)
	_btn.focus_mode = Control.FOCUS_NONE
	_btn.add_theme_font_size_override("font_size", 20)
	_btn.button_down.connect(func(): _start_pour())
	_btn.button_up.connect(func(): _stop_pour())
	v.add_child(_btn)

func _start_pour() -> void:
	if not finished:
		pouring = true

func _stop_pour() -> void:
	if finished or not pouring:
		return
	pouring = false
	_evaluate()

func _input(event: InputEvent) -> void:
	if finished:
		return
	if event is InputEventKey and event.keycode == KEY_SPACE and not event.echo:
		if event.pressed and not _space_down:
			_space_down = true
			_start_pour()
		elif not event.pressed and _space_down:
			_space_down = false
			_stop_pour()
		get_viewport().set_input_as_handled()

func _process(delta: float) -> void:
	if finished:
		return
	_t += delta
	time_left -= delta
	if pouring:
		var wobble := 1.0 + 0.35 * sin(_t * 7.0) * (0.4 + 0.1 * dinner_no)
		level += rate * wobble * delta
		if level >= 1.0:
			level = 1.0
			pouring = false
			_finish("spill")
	if time_left <= 0.0 and not finished:
		pouring = false
		_evaluate()
	_info.text = "Время: %.1f" % maxf(0.0, time_left)
	_canvas.queue_redraw()

func _evaluate() -> void:
	var d := absf(level - target)
	if level <= 0.02:
		_finish("under")
	elif d <= half * 0.45:
		_finish("perfect")
	elif d <= half:
		_finish("good")
	elif level < target:
		_finish("under")
	else:
		_finish("over")

func _finish(grade: String) -> void:
	if finished:
		return
	finished = true
	var msg := {
		"perfect": "Идеально! Ни капли мимо.",
		"good": "Хорошо. Рука не дрогнула.",
		"under": "Недолив. Гость заметил.",
		"over": "Перелив! Вино у самого края.",
		"spill": "Пролили! Вино на скатерти.",
	}
	_info.text = msg.get(grade, "")
	_info.add_theme_color_override("font_color", Color(0.6, 0.9, 0.6) if grade in ["perfect", "good"] else Color(0.95, 0.5, 0.45))
	_canvas.queue_redraw()
	await get_tree().create_timer(1.3).timeout
	done.emit({"grade": grade})

func _on_draw() -> void:
	var gx := 100.0
	var gw := 100.0
	var top := 70.0
	var bot := 285.0
	var gh := bot - top
	# бокал
	_canvas.draw_rect(Rect2(gx, top, gw, gh), Color(0.75, 0.8, 0.9, 0.12))
	var fill_h := gh * level
	var col := Color(0.55, 0.05, 0.12, 0.95)
	_canvas.draw_rect(Rect2(gx, bot - fill_h, gw, fill_h), col)
	# целевая зона
	var y_hi := bot - gh * (target + half)
	var y_lo := bot - gh * (target - half)
	_canvas.draw_rect(Rect2(gx - 14, y_hi, gw + 28, y_lo - y_hi), Color(0.95, 0.8, 0.3, 0.25))
	var y_in_hi := bot - gh * (target + half * 0.45)
	var y_in_lo := bot - gh * (target - half * 0.45)
	_canvas.draw_rect(Rect2(gx - 14, y_in_hi, gw + 28, y_in_lo - y_in_hi), Color(0.95, 0.8, 0.3, 0.55))
	# контур
	var oc := Color(0.85, 0.9, 1.0)
	_canvas.draw_line(Vector2(gx, top), Vector2(gx, bot), oc, 3.0)
	_canvas.draw_line(Vector2(gx + gw, top), Vector2(gx + gw, bot), oc, 3.0)
	_canvas.draw_line(Vector2(gx, bot), Vector2(gx + gw, bot), oc, 3.0)
	_canvas.draw_line(Vector2(gx - 8, top), Vector2(gx + gw + 8, top), Color(0.9, 0.5, 0.5), 2.0)
	# бутылка
	var ang := -0.9 if pouring else -0.35
	_canvas.draw_set_transform(Vector2(gx + gw + 40, 30), ang)
	_canvas.draw_rect(Rect2(-18, 0, 36, 110), Color(0.1, 0.25, 0.12))
	_canvas.draw_rect(Rect2(-8, -34, 16, 36), Color(0.1, 0.25, 0.12))
	_canvas.draw_set_transform(Vector2.ZERO, 0.0)
	if pouring:
		_canvas.draw_line(Vector2(gx + gw * 0.5, top - 20), Vector2(gx + gw * 0.5, bot - fill_h), col, 4.0)
