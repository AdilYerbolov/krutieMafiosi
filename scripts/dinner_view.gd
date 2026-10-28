class_name DinnerView
extends Control
## Главная комната: подготовка ужина (рассадка, вино, особое блюдо, ножи)
## и сам ужин — диалоги в стиле новеллы поверх стола, со «странностями» на столе.

const SEAT_POS := SeatLayout.SEAT_POS
const MAIN_SEATS := SeatLayout.SEATS

signal _seating_done
signal _menu_pick(index: int)
signal _ok_pressed

var vn: VNView
var journal: Journal

var _room: TextureRect
var _items: TableItems
var _tokens_layer: Control
var _layer: Control          # UI подготовки
var _fader: ColorRect
var _caption: Label
var _journal_btn: Button

var _assign := {}            # seat:int -> id
var _sel := ""
var _slot_btns := {}
var _guest_btns := {}
var _start_btn: Button
var _hint: Label
var _guests: Array = []

var _tokens := {}            # id/tag -> GuestToken
var _dinner_no := 0
var _stand_away := false
var _knife_checks := {}

func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_room = TextureRect.new()
	_room.set_anchors_preset(Control.PRESET_FULL_RECT)
	_room.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_room.stretch_mode = TextureRect.STRETCH_SCALE
	_room.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_room.texture = SpriteFactory.background("dining_room")
	_room.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_room)
	_items = TableItems.new()
	_items.set_anchors_preset(Control.PRESET_FULL_RECT)
	_items.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_items)
	_tokens_layer = Control.new()
	_tokens_layer.set_anchors_preset(Control.PRESET_FULL_RECT)
	_tokens_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_tokens_layer)
	_layer = Control.new()
	_layer.set_anchors_preset(Control.PRESET_FULL_RECT)
	_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_layer)
	_caption = Label.new()
	_caption.anchor_left = 0.0
	_caption.anchor_right = 1.0
	_caption.anchor_top = 0.84
	_caption.anchor_bottom = 0.84
	_caption.offset_bottom = 60
	_caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_caption.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_caption.add_theme_font_size_override("font_size", 22)
	_caption.add_theme_color_override("font_color", Color(0.98, 0.9, 0.6))
	_caption.add_theme_color_override("font_outline_color", Color.BLACK)
	_caption.add_theme_constant_override("outline_size", 8)
	_caption.modulate.a = 0.0
	_caption.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_caption)
	_journal_btn = Button.new()
	_journal_btn.text = "Досье (J)"
	_journal_btn.anchor_left = 1.0
	_journal_btn.anchor_right = 1.0
	_journal_btn.offset_left = -130
	_journal_btn.offset_right = -12
	_journal_btn.offset_top = 10
	_journal_btn.offset_bottom = 44
	_journal_btn.focus_mode = Control.FOCUS_NONE
	_journal_btn.pressed.connect(func(): if journal != null: journal.toggle())
	_journal_btn.visible = false
	add_child(_journal_btn)
	_fader = ColorRect.new()
	_fader.set_anchors_preset(Control.PRESET_FULL_RECT)
	_fader.color = Color(0, 0, 0, 0)
	_fader.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_fader)

func _input(event: InputEvent) -> void:
	if not is_visible_in_tree() or vn == null or vn.visible:
		return
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_J and journal != null:
		journal.toggle()

# ───────────────────────── общий UI ─────────────────────────
func _panel_style() -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.05, 0.04, 0.05, 0.94)
	sb.border_color = Color(0.68, 0.56, 0.3)
	sb.set_border_width_all(2)
	sb.set_corner_radius_all(8)
	sb.set_content_margin_all(18)
	return sb

func _clear_layer() -> void:
	for c in _layer.get_children():
		c.queue_free()
	_slot_btns.clear()
	_guest_btns.clear()

func _label(text: String, size: int = 18, color: Color = Color(0.92, 0.9, 0.85)) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return l

func _fade(to: float, t: float = 0.5) -> void:
	var tw := create_tween()
	tw.tween_property(_fader, "color:a", to, t)
	await tw.finished

func show_caption(text: String, secs: float = 2.4) -> void:
	_caption.text = text
	var tw := create_tween()
	tw.tween_property(_caption, "modulate:a", 1.0, 0.25)
	tw.tween_interval(secs)
	tw.tween_property(_caption, "modulate:a", 0.0, 0.4)
	await tw.finished

func _title_card(title: String, sub: String) -> void:
	var cover := ColorRect.new()
	cover.set_anchors_preset(Control.PRESET_FULL_RECT)
	cover.color = Color.BLACK
	cover.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(cover)
	var vb := VBoxContainer.new()
	vb.set_anchors_preset(Control.PRESET_CENTER)
	vb.alignment = BoxContainer.ALIGNMENT_CENTER
	vb.custom_minimum_size = Vector2(900, 200)
	vb.offset_left = -450
	vb.offset_right = 450
	vb.offset_top = -100
	vb.offset_bottom = 100
	cover.add_child(vb)
	var t := _label(title, 52, Color(0.95, 0.85, 0.55))
	t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vb.add_child(t)
	var s := _label(sub, 22, Color(0.8, 0.78, 0.72))
	s.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vb.add_child(s)
	var tw := create_tween()
	tw.tween_interval(2.2)
	tw.tween_property(cover, "modulate:a", 0.0, 0.6)
	await tw.finished
	cover.queue_free()

## Универсальное меню: возвращает индекс выбранной кнопки.
func _menu(title: String, desc: String, labels: Array, cols: int = 1, width: float = 760) -> int:
	_clear_layer()
	var pc := PanelContainer.new()
	pc.set_anchors_preset(Control.PRESET_CENTER)
	pc.add_theme_stylebox_override("panel", _panel_style())
	_layer.add_child(pc)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 10)
	v.custom_minimum_size = Vector2(width, 0)
	pc.add_child(v)
	var tl := _label(title, 26, Color(0.95, 0.85, 0.55))
	tl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(tl)
	if desc != "":
		var dl := _label(desc, 16, Color(0.8, 0.78, 0.72))
		dl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		v.add_child(dl)
	var grid := GridContainer.new()
	grid.columns = cols
	grid.add_theme_constant_override("h_separation", 10)
	grid.add_theme_constant_override("v_separation", 10)
	v.add_child(grid)
	for i in range(labels.size()):
		var b := Button.new()
		b.text = labels[i]
		b.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		b.custom_minimum_size = Vector2(width / cols - 10, 52)
		b.add_theme_font_size_override("font_size", 18)
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		b.pressed.connect(func(): _menu_pick.emit(i))
		grid.add_child(b)
	pc.position = Vector2((1376 - width) * 0.5 - 18, 190)
	var idx: int = await _menu_pick
	_clear_layer()
	return idx

# ───────────────────────── ход ужина ─────────────────────────
func run_dinner(n: int) -> void:
	_dinner_no = n
	GameState.dinner_no = n
	var info: Dictionary = Story.DINNERS[n - 1]
	_guests = Story.dinner_guests(n)
	GameState.present = _guests.duplicate()
	GameState.prep.clear()
	visible = true
	vn.hide()
	_fader.color.a = 0.0
	_reset_table()
	_journal_btn.visible = false
	await _title_card("УЖИН %d — %s" % [n, info["title"]], info["sub"])
	_journal_btn.visible = true
	for id in _guests:
		GameState.meet(id)
	await _seating_phase()
	await _wine_phase()
	await _dish_phase()
	await _knife_phase()
	await _stand_phase()
	_journal_btn.visible = false
	Story.apply_seating(_assign)
	_build_table()
	var kn := {}
	for id in _guests:
		kn[id] = _knife_checks.get(id, true)
	Story.apply_knives(kn)
	_refresh_items()
	await get_tree().create_timer(0.6).timeout
	vn.set_overlay(true)
	vn.clear_stage()
	vn.reset_ui()
	vn.fx_target = self
	vn.show()
	var steps: Array = []
	if _stand_away:
		steps.append({"say": "", "t": "Вы встали у двери. Отсюда лучше видно всех, но слышно хуже: часть реплик тонет в шуме."})
	steps += Story.reaction_steps()
	steps += Story.dinner(n)
	await vn.play(steps)
	vn.hide()
	vn.clear_stage()
	vn.fx_target = null
	await _fade(1.0, 0.6)
	_reset_table()

func _reset_table() -> void:
	for t in _tokens.values():
		t.queue_free()
	_tokens.clear()
	_items.plates.clear()
	_items.glasses.clear()
	_items.knives.clear()
	_items.marks.clear()
	_items.extra.clear()
	_items.pulse_seat = -1
	_items.queue_redraw()
	_room.modulate = Color(1, 1, 1)
	_assign.clear()
	_knife_checks.clear()
	_stand_away = false
	_clear_layer()

func _build_table() -> void:
	for seat in _assign:
		var id: String = _assign[seat]
		_spawn_token(id, Chars.display_name(id), Chars.color_of(id), seat, 1.0)
		_items.plates[seat] = true
		_items.glasses[seat] = 1
		_items.knives[seat] = true
		var pm: Dictionary = GameState.prep.get(id, {})
		var mk := {}
		if pm.has("wine") and not (pm["wine"] in ["perfect", "good"]):
			mk["spill"] = pm["wine"] in ["over", "spill"]
		if pm.has("dish") and pm.get("dish_grade", "") != "":
			mk["dish"] = pm["dish"]
			mk["burnt"] = pm["dish_grade"] == "ruined"
		_items.marks[seat] = mk
	_refresh_items()

func _refresh_items() -> void:
	for seat in _assign:
		var id: String = _assign[seat]
		_items.knives[seat] = GameState.knives.get(id, true)
	for id in _tokens:
		var t: GuestToken = _tokens[id]
		var tn := int(GameState.tension.get(id, 0))
		t.ring = Color(0.9, 0.2, 0.2, 0.9) if tn >= 3 else (Color(0.95, 0.7, 0.2, 0.8) if tn == 2 else Color(0, 0, 0, 0))
		t.queue_redraw()
	_items.queue_redraw()

func _spawn_token(tag: String, label: String, color: Color, seat: int, alpha: float) -> GuestToken:
	var t := GuestToken.new()
	t.cid = tag if Chars.DATA.has(tag) else ""
	t.label = label
	t.color = color
	t.seat = seat
	t.position = SEAT_POS[seat] - t.size * 0.5
	t.modulate.a = 0.0
	_tokens_layer.add_child(t)
	_tokens[tag] = t
	var tw := create_tween()
	tw.tween_property(t, "modulate:a", alpha, 0.5)
	return t

# ───────────────────────── фаза: рассадка ─────────────────────────
func _seating_phase() -> void:
	_assign.clear()
	_sel = ""
	_clear_layer()
	_hint = _label("Рассадите гостей. Выберите гостя внизу, затем место за столом. Наведите на место — увидите его значение.", 20)
	_hint.anchor_left = 0.0
	_hint.anchor_right = 1.0
	_hint.offset_left = 120
	_hint.offset_right = -180
	_hint.offset_top = 14
	_hint.offset_bottom = 90
	var hbg := PanelContainer.new()
	hbg.add_theme_stylebox_override("panel", _panel_style())
	hbg.anchor_left = 0.0
	hbg.anchor_right = 1.0
	hbg.offset_left = 100
	hbg.offset_right = -150
	hbg.offset_top = 8
	hbg.offset_bottom = 84
	hbg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_layer.add_child(hbg)
	hbg.add_child(_hint)
	for seat in MAIN_SEATS:
		var b := Button.new()
		b.custom_minimum_size = Vector2(128, 40)
		b.size = Vector2(128, 40)
		b.position = SEAT_POS[seat] - Vector2(64, 20)
		b.add_theme_font_size_override("font_size", 16)
		b.pressed.connect(_on_slot.bind(seat))
		b.mouse_entered.connect(_on_slot_hover.bind(seat))
		_layer.add_child(b)
		_slot_btns[seat] = b
	var bottom := PanelContainer.new()
	bottom.add_theme_stylebox_override("panel", _panel_style())
	bottom.anchor_left = 0.0
	bottom.anchor_right = 1.0
	bottom.anchor_top = 1.0
	bottom.anchor_bottom = 1.0
	bottom.offset_left = 20
	bottom.offset_right = -20
	bottom.offset_top = -92
	bottom.offset_bottom = -12
	_layer.add_child(bottom)
	var hb := HBoxContainer.new()
	hb.add_theme_constant_override("separation", 8)
	bottom.add_child(hb)
	for id in _guests:
		var gb := Button.new()
		gb.custom_minimum_size = Vector2(150, 54)
		gb.add_theme_font_size_override("font_size", 16)
		gb.pressed.connect(_on_guest.bind(id))
		hb.add_child(gb)
		_guest_btns[id] = gb
	var sp := Control.new()
	sp.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hb.add_child(sp)
	_start_btn = Button.new()
	_start_btn.text = "Рассадка готова →"
	_start_btn.custom_minimum_size = Vector2(210, 54)
	_start_btn.add_theme_font_size_override("font_size", 18)
	_start_btn.pressed.connect(func(): _seating_done.emit())
	hb.add_child(_start_btn)
	_refresh_seating()
	await _seating_done
	_clear_layer()

func _seat_of_guest(id: String) -> int:
	for seat in _assign:
		if _assign[seat] == id:
			return seat
	return 0

func _refresh_seating() -> void:
	for seat in _slot_btns:
		var b: Button = _slot_btns[seat]
		if _assign.has(seat):
			b.text = Chars.display_name(_assign[seat])
		else:
			b.text = "место %d" % seat if seat in [1, 6] else "· %d ·" % seat
	for id in _guest_btns:
		var gb: Button = _guest_btns[id]
		var s := _seat_of_guest(id)
		var nm := Chars.display_name(id)
		gb.text = ("%s\n[место %d]" % [nm, s]) if s > 0 else nm
		gb.modulate = Color(1, 1, 0.55) if id == _sel else (Color(0.65, 0.65, 0.65) if s > 0 else Color(1, 1, 1))
	_start_btn.disabled = _assign.size() != _guests.size()

func _on_guest(id: String) -> void:
	var s := _seat_of_guest(id)
	if s > 0:
		_assign.erase(s)
	_sel = id
	_refresh_seating()

func _on_slot(seat: int) -> void:
	if _sel != "":
		if _assign.has(seat):
			_assign.erase(seat)
		_assign[seat] = _sel
		_sel = ""
	elif _assign.has(seat):
		_sel = _assign[seat]
		_assign.erase(seat)
	_refresh_seating()
	_on_slot_hover(seat)

func _on_slot_hover(seat: int) -> void:
	var t: String = Story.SEAT_TITLES[seat]
	var cand := _sel if _sel != "" else str(_assign.get(seat, ""))
	if cand != "":
		var notes: Array = []
		for pr in Story.ADJ + Story.OPP:
			var other_seat := -1
			if pr[0] == seat:
				other_seat = pr[1]
			elif pr[1] == seat:
				other_seat = pr[0]
			if other_seat > 0 and _assign.has(other_seat) and _assign[other_seat] != cand:
				var other: String = _assign[other_seat]
				var r := Chars.find_rel(cand, other)
				if not r.is_empty():
					notes.append("%s — %s" % [Chars.display_name(other), r["label"]])
		if notes.size() > 0:
			t += "\nРядом с %s: %s" % [Chars.display_name(cand), "; ".join(notes)]
	_hint.text = t

# ───────────────────────── фаза: вино ─────────────────────────
func _wine_phase() -> void:
	var labels: Array = []
	for id in _guests:
		labels.append("%s\n%s" % [Chars.full_title(id), Chars.data(id).get("tag", "")])
	var idx := await _menu("Кому налить вино первым?",
		"Это знак уважения. Но неточная рука будет стоить вам доверия.", labels, 2, 780)
	var guest: String = _guests[idx]
	var game := WineGame.new()
	game.setup(_dinner_no, guest)
	_layer.add_child(game)
	var res: Dictionary = await game.done
	game.queue_free()
	var msg := Story.apply_wine(guest, res["grade"])
	await show_caption(msg, 2.6)

# ───────────────────────── фаза: особое блюдо ─────────────────────────
func _dish_phase() -> void:
	var labels: Array = []
	for id in _guests:
		labels.append("%s\n%s" % [Chars.full_title(id), Chars.data(id).get("tag", "")])
	var gi := await _menu("Кому подать особое блюдо?",
		"Блюдо — комплимент. Испорченное блюдо — оскорбление.", labels, 2, 780)
	var guest: String = _guests[gi]
	var dlabels: Array = []
	for d in Story.DISHES:
		var likes_names := ", ".join(d["likes"].map(func(x): return Chars.display_name(x)))
		dlabels.append("%s\n%s Любят: %s." % [d["name"], d["desc"], likes_names])
	var di := await _menu("Что приготовить для: %s?" % Chars.display_name(guest),
		"Сложное блюдо рискованнее — но если угадаете вкус, гость оценит.", dlabels, 1, 860)
	var dish: Dictionary = Story.DISHES[di]
	var game := DishGame.new()
	game.setup(dish, guest, _dinner_no)
	_layer.add_child(game)
	var res: Dictionary = await game.done
	game.queue_free()
	var msg := Story.apply_dish(guest, dish, res["grade"])
	await show_caption(msg, 3.0)

# ───────────────────────── фаза: ножи ─────────────────────────
func _knife_phase() -> void:
	_clear_layer()
	_knife_checks.clear()
	var pc := PanelContainer.new()
	pc.add_theme_stylebox_override("panel", _panel_style())
	pc.position = Vector2(330, 120)
	_layer.add_child(pc)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 8)
	v.custom_minimum_size = Vector2(700, 0)
	pc.add_child(v)
	var t := _label("Ножи на столе", 26, Color(0.95, 0.85, 0.55))
	t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(t)
	v.add_child(_label("Оставить нож у гостя — выказать доверие. Убрать — обезопасить стол, но гость заметит."))
	for id in _guests:
		var cb := CheckButton.new()
		cb.text = "%s — нож остаётся" % Chars.full_title(id)
		cb.button_pressed = true
		cb.add_theme_font_size_override("font_size", 18)
		v.add_child(cb)
		_knife_checks[id] = cb
	var ok := Button.new()
	ok.text = "Готово →"
	ok.custom_minimum_size = Vector2(0, 50)
	ok.pressed.connect(func(): _ok_pressed.emit())
	v.add_child(ok)
	await _ok_pressed
	for id in _knife_checks.keys():
		_knife_checks[id] = (_knife_checks[id] as CheckButton).button_pressed
	_clear_layer()

# ───────────────────────── фаза: где стоять ─────────────────────────
func _stand_phase() -> void:
	var i := await _menu("Где вы будете стоять?",
		"У стола вы видите всё, но привлекаете внимание. У двери вас не замечают, но слышно хуже.",
		["Рядом со столом", "У двери"], 2, 720)
	_stand_away = (i == 1)
	if _stand_away:
		GameState.add_var("stood_away", 1)

# ───────────────────────── эффекты «странностей» ─────────────────────────
func _tok(id: String) -> GuestToken:
	return _tokens.get(id)

## Свободное место для эффектов (лишний гость, призрак, пустой стул). pref — желаемое.
func _free_seat(pref: int) -> int:
	var used := {}
	for s in _assign:
		used[s] = true
	for tk in _tokens.values():
		used[(tk as GuestToken).seat] = true
	if not used.has(pref):
		return pref
	for s in [7, 9, 8, 10, 4, 5, 2, 3]:
		if not used.has(s):
			return s
	return pref

func _home(t: GuestToken) -> Vector2:
	return SEAT_POS[t.seat] - t.size * 0.5

func _peek(hold: float) -> void:
	await vn.set_ui_visible(false)
	await get_tree().create_timer(hold).timeout
	await vn.set_ui_visible(true)

func run_fx(fx_name: String, args: Array) -> void:
	match fx_name:
		"peek":
			await _peek(float(args[0]) if args.size() > 0 else 1.6)
		"swap":
			var a := _tok(args[0])
			var b := _tok(args[1])
			if a != null and b != null:
				await vn.set_ui_visible(false)
				var pa := a.position
				var tw := create_tween().set_parallel(true)
				tw.tween_property(a, "position", b.position, 0.6)
				tw.tween_property(b, "position", pa, 0.6)
				var s := a.seat
				a.seat = b.seat
				b.seat = s
				await get_tree().create_timer(1.6).timeout
				await vn.set_ui_visible(true)
		"silent_swap":
			var a2 := _tok(args[0])
			var b2 := _tok(args[1])
			if a2 != null and b2 != null:
				var pa2 := a2.position
				a2.position = b2.position
				b2.position = pa2
		"blink":
			var t := _tok(args[0])
			if t != null:
				var home := t.position
				var away: Vector2 = SEAT_POS[_free_seat(int(args[1]))] - t.size * 0.5
				var delay := float(args[2]) if args.size() > 2 else 3.0
				var tw2 := create_tween()
				tw2.tween_property(t, "position", away, 0.05)
				tw2.tween_interval(delay)
				tw2.tween_property(t, "position", home, 0.05)
		"vanish":
			var t3 := _tok(args[0])
			if t3 != null:
				create_tween().tween_property(t3, "modulate:a", 0.0, 0.3)
		"appear":
			var t4 := _tok(args[0])
			if t4 != null:
				create_tween().tween_property(t4, "modulate:a", 1.0, 0.3)
		"vanish_many":
			await vn.set_ui_visible(false)
			var lst: Array = args[0]
			for id in lst:
				var tk := _tok(id)
				if tk != null:
					create_tween().tween_property(tk, "modulate:a", 0.0, 1.0)
			await get_tree().create_timer(2.0).timeout
			await vn.set_ui_visible(true)
		"extra_guest":
			_spawn_token(str(args[0]), str(args[2]), Color(0.45, 0.45, 0.5), _free_seat(int(args[1])), 0.85)
			await _peek(1.4)
		"ghost":
			_spawn_token(str(args[0]), str(args[2]), Color(0.45, 0.55, 0.7), _free_seat(int(args[1])), 0.55)
		"remove_extra":
			var te := _tok(args[0])
			if te != null:
				_tokens.erase(args[0])
				var tw3 := create_tween()
				tw3.tween_property(te, "modulate:a", 0.0, 0.4)
				tw3.tween_callback(te.queue_free)
		"item_flash":
			var item := {"kind": str(args[0]), "seat": _free_seat(int(args[1]))}
			_items.extra.append(item)
			_items.queue_redraw()
			var tw4 := create_tween()
			tw4.tween_interval(float(args[2]))
			tw4.tween_callback(func():
				_items.extra.erase(item)
				_items.queue_redraw())
			await _peek(minf(float(args[2]), 1.2))
		"flicker":
			var tw5 := create_tween()
			for i in range(3):
				tw5.tween_property(_room, "modulate", Color(0.35, 0.35, 0.4), 0.07)
				tw5.tween_property(_room, "modulate", Color(1, 1, 1), 0.07)
			await tw5.finished
		"reflect":
			var tr_ := _tok(args[0])
			if tr_ != null:
				await vn.set_ui_visible(false)
				tr_.alt = true
				tr_.queue_redraw()
				await get_tree().create_timer(0.9).timeout
				tr_.alt = false
				tr_.queue_redraw()
				await vn.set_ui_visible(true)
		"stare":
			var ts := _tok(args[0])
			if ts != null:
				await vn.set_ui_visible(false)
				ts.gaze = true
				ts.queue_redraw()
				var tw6 := create_tween().set_loops(3)
				tw6.tween_property(ts, "scale", Vector2(1.25, 1.25), 0.4)
				tw6.tween_property(ts, "scale", Vector2(1.0, 1.0), 0.4)
				await get_tree().create_timer(2.4).timeout
				ts.gaze = false
				ts.queue_redraw()
				await vn.set_ui_visible(true)
		"laugh":
			var tl := _tok(args[0])
			if tl != null:
				await vn.set_ui_visible(false)
				var tw7 := create_tween()
				for i in range(10):
					tw7.tween_property(tl, "rotation", 0.25 if i % 2 == 0 else -0.25, 0.1)
				tw7.tween_property(tl, "rotation", 0.0, 0.1)
				await tw7.finished
				await get_tree().create_timer(0.4).timeout
				await vn.set_ui_visible(true)
		"empty_chair":
			_items.pulse_seat = _free_seat(int(args[0]))
			await _peek(1.6)
			var tw8 := create_tween()
			tw8.tween_interval(float(args[1]) if args.size() > 1 else 2.0)
			tw8.tween_callback(func(): _items.pulse_seat = -1; _items.queue_redraw())
		"player_leave":
			await _fade(1.0, 0.5)
			await get_tree().create_timer(0.5).timeout
			await _fade(0.0, 0.5)
		"shake":
			var tw9 := create_tween()
			for i in range(8):
				tw9.tween_property(_room, "position", Vector2(randf_range(-6, 6), randf_range(-4, 4)), 0.04)
			tw9.tween_property(_room, "position", Vector2.ZERO, 0.04)
			await tw9.finished
