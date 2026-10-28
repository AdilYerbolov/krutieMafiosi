class_name DishGame
extends PanelContainer
## Мини-игра «Особое блюдо»: три этапа готовки. Остановите бегунок в зелёной зоне
## (СТОП / пробел). Чем ближе к центру — тем лучше. Провал портит блюдо — штраф гостю.

signal done(result: Dictionary)

var dish: Dictionary = {}
var guest := ""
var dinner_no := 1

var stage := 0
var pos := 0.0
var dir := 1.0
var speed := 1.0
var zone_c := 0.5
var zone_h := 0.1
var score := 0
var results: Array = []
var active := false
var finished := false
var _bar: Control
var _title: Label
var _stage_lbl: Label
var _res_lbl: Label
var _btn: Button
var _space := false

func setup(d: Dictionary, g: String, n: int) -> void:
	dish = d
	guest = g
	dinner_no = n

func _ready() -> void:
	set_anchors_preset(Control.PRESET_CENTER)
	custom_minimum_size = Vector2(620, 380)
	offset_left = -310
	offset_right = 310
	offset_top = -190
	offset_bottom = 190
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.06, 0.05, 0.06, 0.96)
	sb.border_color = Color(0.7, 0.58, 0.3)
	sb.set_border_width_all(2)
	sb.set_corner_radius_all(8)
	sb.set_content_margin_all(16)
	add_theme_stylebox_override("panel", sb)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 10)
	add_child(v)
	_title = Label.new()
	_title.text = "%s — для: %s" % [dish["name"], Chars.full_title(guest)]
	_title.add_theme_font_size_override("font_size", 21)
	_title.add_theme_color_override("font_color", Color(0.95, 0.85, 0.55))
	_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	v.add_child(_title)
	var hint := Label.new()
	hint.text = "Остановите бегунок в зелёной зоне: ПРОБЕЛ или кнопка «СТОП». Три этапа."
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.add_theme_font_size_override("font_size", 15)
	v.add_child(hint)
	_stage_lbl = Label.new()
	_stage_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_stage_lbl.add_theme_font_size_override("font_size", 24)
	v.add_child(_stage_lbl)
	_bar = Control.new()
	_bar.custom_minimum_size = Vector2(560, 70)
	_bar.draw.connect(_on_draw)
	v.add_child(_bar)
	_res_lbl = Label.new()
	_res_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_res_lbl.add_theme_font_size_override("font_size", 18)
	v.add_child(_res_lbl)
	_btn = Button.new()
	_btn.text = "СТОП!"
	_btn.custom_minimum_size = Vector2(0, 56)
	_btn.focus_mode = Control.FOCUS_NONE
	_btn.add_theme_font_size_override("font_size", 22)
	_btn.pressed.connect(_press)
	v.add_child(_btn)
	_begin_stage()

func _begin_stage() -> void:
	var diff: float = dish["diff"]
	speed = (0.85 + 0.1 * dinner_no + 0.22 * stage) * diff
	zone_h = clampf(0.11 / diff - 0.004 * dinner_no - 0.01 * stage, 0.035, 0.12)
	if int(GameState.v("dish_tip")) > 0:
		zone_h = minf(zone_h * 1.25, 0.15)   # подсказка Карло: зелёная зона шире
	zone_c = randf_range(0.2, 0.8)
	pos = 0.0
	dir = 1.0
	_stage_lbl.text = "Этап %d/3: %s" % [stage + 1, dish["stages"][stage]]
	active = true

func _input(event: InputEvent) -> void:
	if finished:
		return
	if event is InputEventKey and event.keycode == KEY_SPACE and event.pressed and not event.echo:
		_press()
		get_viewport().set_input_as_handled()

func _process(delta: float) -> void:
	if not active:
		_bar.queue_redraw()
		return
	pos += dir * speed * delta
	if pos >= 1.0:
		pos = 1.0
		dir = -1.0
	elif pos <= 0.0:
		pos = 0.0
		dir = 1.0
	_bar.queue_redraw()

func _press() -> void:
	if not active or finished:
		return
	active = false
	var d := absf(pos - zone_c)
	var pts := 0
	var msg := "Мимо!"
	if d <= zone_h * 0.4:
		pts = 2
		msg = "Идеально!"
	elif d <= zone_h:
		pts = 1
		msg = "Хорошо."
	score += pts
	results.append(pts)
	_res_lbl.text = msg
	_res_lbl.add_theme_color_override("font_color", Color(0.6, 0.9, 0.6) if pts > 0 else Color(0.95, 0.5, 0.45))
	await get_tree().create_timer(0.8).timeout
	_res_lbl.text = ""
	stage += 1
	if stage >= 3:
		_finish()
	else:
		_begin_stage()

func _finish() -> void:
	finished = true
	var grade := "ruined"
	if score >= 5:
		grade = "excellent"
	elif score >= 3:
		grade = "good"
	elif score == 2:
		grade = "poor"
	var names := {"excellent": "Безупречное блюдо!", "good": "Хорошее блюдо.",
		"poor": "Посредственно.", "ruined": "Блюдо испорчено!"}
	_stage_lbl.text = "Итог: %d из 6 — %s" % [score, names[grade]]
	await get_tree().create_timer(1.4).timeout
	done.emit({"grade": grade, "score": score})

func _on_draw() -> void:
	var w := 560.0
	var h := 70.0
	_bar.draw_rect(Rect2(0, 20, w, 30), Color(0.15, 0.13, 0.13))
	_bar.draw_rect(Rect2(0, 20, w, 30), Color(0.6, 0.5, 0.3), false, 2.0)
	var zx := (zone_c - zone_h) * w
	_bar.draw_rect(Rect2(zx, 20, zone_h * 2.0 * w, 30), Color(0.3, 0.7, 0.35, 0.65))
	var cx := (zone_c - zone_h * 0.4) * w
	_bar.draw_rect(Rect2(cx, 20, zone_h * 0.8 * w, 30), Color(0.55, 0.95, 0.5, 0.85))
	var px := pos * w
	_bar.draw_rect(Rect2(px - 4, 10, 8, 50), Color(1, 0.9, 0.5))
	for i in range(3):
		var col := Color(0.4, 0.4, 0.4)
		if i < results.size():
			col = Color(0.95, 0.8, 0.3) if results[i] > 0 else Color(0.8, 0.3, 0.3)
		_bar.draw_circle(Vector2(w * 0.5 + (i - 1) * 30, 62), 7, col)
