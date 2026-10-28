class_name VNView
extends Control
## Диалоговый движок в стиле визуальной новеллы:
## спрайты слева/по центру/справа, рамка диалога с именем, ролью и связью, выборы, досье, лог.
## Работает в двух режимах: обычный (свой фон) и overlay (поверх стола).

signal peek_changed(on: bool)

const W := 1376.0
const H := 768.0
const MAX_STAGE := 4
const CHAR_DELAY := 0.022

var overlay := false
var fx_target: Object = null
var journal: Journal = null

var _bg: TextureRect
var _dim: ColorRect
var _stage_layer: Control
var _box: PanelContainer
var _name_lbl: Label
var _tag_lbl: Label
var _rel_lbl: Label
var _text: RichTextLabel
var _cont: Label
var _choice_box: VBoxContainer
var _choice_prompt: Label
var _loc_lbl: Label
var _toast: Label
var _top_bar: HBoxContainer
var _hist_panel: PanelContainer
var _hist_text: RichTextLabel

var _sprites := {}
var _stage_ids: Array = []
var _speaker := ""
var _typing := false
var _waiting := false
var _picked := -1
var _manual_hidden := false
var _busy_peek := false
var _blink_t := 0.0

func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	_bg = TextureRect.new()
	_bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	_bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_bg.stretch_mode = TextureRect.STRETCH_SCALE
	_bg.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_bg)
	_dim = ColorRect.new()
	_dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	_dim.color = Color(0, 0, 0, 0.2)
	_dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_dim)
	_stage_layer = Control.new()
	_stage_layer.set_anchors_preset(Control.PRESET_FULL_RECT)
	_stage_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_stage_layer)
	_build_box()
	_build_choice_box()
	_build_top_bar()
	_build_overlays()

# ───────────────────────── построение UI ─────────────────────────
func _panel_style(alpha: float = 0.92) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.05, 0.04, 0.05, alpha)
	sb.border_color = Color(0.68, 0.56, 0.3)
	sb.set_border_width_all(2)
	sb.set_corner_radius_all(8)
	sb.set_content_margin_all(16)
	return sb

func _build_box() -> void:
	_box = PanelContainer.new()
	_box.anchor_left = 0.04
	_box.anchor_right = 0.96
	_box.anchor_top = 0.745
	_box.anchor_bottom = 0.975
	_box.offset_left = 0
	_box.offset_right = 0
	_box.offset_top = 0
	_box.offset_bottom = 0
	_box.mouse_filter = Control.MOUSE_FILTER_PASS
	_box.add_theme_stylebox_override("panel", _panel_style())
	add_child(_box)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 2)
	v.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_box.add_child(v)
	var hb := HBoxContainer.new()
	hb.add_theme_constant_override("separation", 14)
	hb.mouse_filter = Control.MOUSE_FILTER_IGNORE
	v.add_child(hb)
	_name_lbl = Label.new()
	_name_lbl.add_theme_font_size_override("font_size", 25)
	_name_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hb.add_child(_name_lbl)
	_tag_lbl = Label.new()
	_tag_lbl.add_theme_font_size_override("font_size", 15)
	_tag_lbl.add_theme_color_override("font_color", Color(0.72, 0.72, 0.68))
	_tag_lbl.size_flags_vertical = Control.SIZE_SHRINK_END
	_tag_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hb.add_child(_tag_lbl)
	_rel_lbl = Label.new()
	_rel_lbl.add_theme_font_size_override("font_size", 14)
	_rel_lbl.add_theme_color_override("font_color", Color(0.85, 0.7, 0.45))
	_rel_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	v.add_child(_rel_lbl)
	_text = RichTextLabel.new()
	_text.bbcode_enabled = true
	_text.scroll_active = false
	_text.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_text.add_theme_font_size_override("normal_font_size", 21)
	_text.add_theme_font_size_override("italics_font_size", 21)
	_text.mouse_filter = Control.MOUSE_FILTER_IGNORE
	v.add_child(_text)
	_cont = Label.new()
	_cont.text = "▼"
	_cont.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_cont.add_theme_color_override("font_color", Color(0.9, 0.8, 0.5))
	_cont.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_cont.visible = false
	v.add_child(_cont)

func _build_choice_box() -> void:
	_choice_box = VBoxContainer.new()
	_choice_box.set_anchors_preset(Control.PRESET_CENTER)
	_choice_box.anchor_left = 0.5
	_choice_box.anchor_right = 0.5
	_choice_box.anchor_top = 0.42
	_choice_box.anchor_bottom = 0.42
	_choice_box.offset_left = -400
	_choice_box.offset_right = 400
	_choice_box.offset_top = -150
	_choice_box.offset_bottom = 150
	_choice_box.grow_vertical = Control.GROW_DIRECTION_BOTH
	_choice_box.alignment = BoxContainer.ALIGNMENT_CENTER
	_choice_box.add_theme_constant_override("separation", 10)
	_choice_box.visible = false
	add_child(_choice_box)

func _build_top_bar() -> void:
	_top_bar = HBoxContainer.new()
	_top_bar.anchor_left = 1.0
	_top_bar.anchor_right = 1.0
	_top_bar.offset_left = -330
	_top_bar.offset_right = -12
	_top_bar.offset_top = 10
	_top_bar.offset_bottom = 44
	_top_bar.add_theme_constant_override("separation", 6)
	add_child(_top_bar)
	var items := [["Досье (J)", "_open_journal"], ["Лог (L)", "_toggle_hist"], ["Скрыть (H)", "_toggle_hide"]]
	for it in items:
		var b := Button.new()
		b.text = it[0]
		b.focus_mode = Control.FOCUS_NONE
		b.pressed.connect(Callable(self, it[1]))
		_top_bar.add_child(b)

func _build_overlays() -> void:
	_loc_lbl = Label.new()
	_loc_lbl.set_anchors_preset(Control.PRESET_CENTER_TOP)
	_loc_lbl.anchor_left = 0.0
	_loc_lbl.anchor_right = 1.0
	_loc_lbl.offset_top = 60
	_loc_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_loc_lbl.add_theme_font_size_override("font_size", 34)
	_loc_lbl.add_theme_color_override("font_color", Color(0.95, 0.88, 0.65))
	_loc_lbl.add_theme_color_override("font_outline_color", Color.BLACK)
	_loc_lbl.add_theme_constant_override("outline_size", 8)
	_loc_lbl.modulate.a = 0.0
	_loc_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_loc_lbl)
	_toast = Label.new()
	_toast.anchor_left = 0.0
	_toast.anchor_right = 0.0
	_toast.offset_left = 18
	_toast.offset_top = 14
	_toast.offset_right = 520
	_toast.add_theme_font_size_override("font_size", 17)
	_toast.add_theme_color_override("font_color", Color(0.95, 0.85, 0.55))
	_toast.add_theme_color_override("font_outline_color", Color.BLACK)
	_toast.add_theme_constant_override("outline_size", 6)
	_toast.modulate.a = 0.0
	_toast.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_toast)
	_hist_panel = PanelContainer.new()
	_hist_panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	_hist_panel.offset_left = 120
	_hist_panel.offset_right = -120
	_hist_panel.offset_top = 50
	_hist_panel.offset_bottom = -50
	_hist_panel.add_theme_stylebox_override("panel", _panel_style(0.97))
	_hist_panel.visible = false
	add_child(_hist_panel)
	var hv := VBoxContainer.new()
	_hist_panel.add_child(hv)
	var hb := HBoxContainer.new()
	hv.add_child(hb)
	var hl := Label.new()
	hl.text = "ЖУРНАЛ РЕПЛИК"
	hl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hl.add_theme_font_size_override("font_size", 22)
	hb.add_child(hl)
	var hc := Button.new()
	hc.text = "Закрыть (L)"
	hc.pressed.connect(_toggle_hist)
	hb.add_child(hc)
	_hist_text = RichTextLabel.new()
	_hist_text.bbcode_enabled = true
	_hist_text.scroll_following = true
	_hist_text.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_hist_text.add_theme_font_size_override("normal_font_size", 18)
	hv.add_child(_hist_text)

# ───────────────────────── публичный API ─────────────────────────
func set_overlay(on: bool) -> void:
	overlay = on
	if _bg == null:
		return
	_bg.visible = not on
	_dim.color = Color(0, 0, 0, 0.42 if on else 0.18)

func set_bg(key: String) -> void:
	_bg.texture = SpriteFactory.background(key)
	_bg.modulate = SpriteFactory.bg_tint(key)

func clear_stage() -> void:
	for id in _sprites.keys():
		_sprites[id].queue_free()
	_sprites.clear()
	_stage_ids.clear()
	_speaker = ""

func reset_ui() -> void:
	_name_lbl.text = ""
	_tag_lbl.text = ""
	_rel_lbl.text = ""
	_text.text = ""
	_cont.visible = false
	_choice_box.visible = false
	_manual_hidden = false
	_box.modulate.a = 1.0
	_stage_layer.modulate.a = 1.0
	_top_bar.modulate.a = 1.0

func play(steps: Array) -> void:
	for step in steps:
		await _exec(step)

## Скрыть/показать интерфейс (используется эффектами стола: «посмотреть на стол»).
func set_ui_visible(on: bool, t: float = 0.35) -> void:
	var a := 1.0 if on else 0.0
	var tw := create_tween().set_parallel(true)
	tw.tween_property(_box, "modulate:a", a, t)
	tw.tween_property(_stage_layer, "modulate:a", a, t)
	tw.tween_property(_top_bar, "modulate:a", a, t)
	tw.tween_property(_dim, "color:a", (0.42 if on else 0.0) if overlay else 0.18, t)
	await tw.finished
	peek_changed.emit(not on)

# ───────────────────────── исполнение шагов ─────────────────────────
func _exec(st: Dictionary) -> void:
	if st.has("say"):
		await _say(st)
	elif st.has("stage"):
		_set_stage(st["stage"])
	elif st.has("choice"):
		await _choice(st)
	elif st.has("if"):
		var branch: Array = st["then"] if GameState.check(st["if"]) else st.get("else", [])
		await play(branch)
	elif st.has("set"):
		for k in st["set"]:
			GameState.vars[k] = st["set"][k]
	elif st.has("add"):
		for k in st["add"]:
			GameState.add_var(k, int(st["add"][k]))
	elif st.has("rel"):
		GameState.change_rel(st["rel"][0], st["rel"][1], int(st["rel"][2]))
	elif st.has("clue"):
		GameState.add_clue(st["clue"])
		var who := str(st["clue"]).replace("_secret", "")
		_show_toast("В досье новая запись: %s" % Chars.display_name(who))
	elif st.has("intro"):
		await _intro(st["intro"])
	elif st.has("loc"):
		await _loc(st)
	elif st.has("fx"):
		if fx_target != null:
			await fx_target.run_fx(st["fx"], st.get("args", []))
	elif st.has("rewrite"):
		for h in GameState.history:
			if h["t"] == st["rewrite"][0]:
				h["t"] = st["rewrite"][1]
	elif st.has("wait"):
		await get_tree().create_timer(float(st["wait"])).timeout

# ───────────────────────── сцена и спрайты ─────────────────────────
func _sprite_height() -> float:
	return 470.0 if overlay else 600.0

func _bottom_y() -> float:
	return H - 40.0 if not overlay else H - 150.0

func _set_stage(ids: Array) -> void:
	var list: Array = []
	for id in ids:
		if id != "" and id != Chars.PLAYER and not list.has(id):
			list.append(id)
	while list.size() > MAX_STAGE:
		list.pop_front()
	_stage_ids = list
	for id in _sprites.keys():
		if not list.has(id):
			var node: Control = _sprites[id]
			_sprites.erase(id)
			var tw := create_tween()
			tw.tween_property(node, "modulate:a", 0.0, 0.25)
			tw.tween_callback(node.queue_free)
	for id in list:
		GameState.meet(id)
		if not _sprites.has(id):
			var node2 := SpriteFactory.make(id, "", _sprite_height())
			node2.modulate = Color(1, 1, 1, 0)
			_stage_layer.add_child(node2)
			_sprites[id] = node2
			node2.position = Vector2(W * 0.5 - node2.size.x * 0.5, _bottom_y() - node2.size.y)
	_layout()
	_highlight(_speaker)

func _layout() -> void:
	var n := _stage_ids.size()
	for i in range(n):
		var id: String = _stage_ids[i]
		var node: Control = _sprites[id]
		var cx := W * float(i + 1) / float(n + 1)
		var target := Vector2(cx - node.size.x * 0.5, _bottom_y() - node.size.y)
		var tw := create_tween().set_parallel(true)
		tw.tween_property(node, "position", target, 0.3).set_trans(Tween.TRANS_SINE)
		tw.tween_property(node, "modulate:a", 1.0, 0.3)

func _highlight(speaker: String) -> void:
	for id in _sprites.keys():
		var node: Control = _sprites[id]
		var is_sp: bool = (id == speaker)
		var col := Color(1, 1, 1, 1) if (is_sp or speaker == "") else Color(0.5, 0.5, 0.56, 1)
		if speaker == "":
			col = Color(0.82, 0.82, 0.86, 1)
		var cx := node.position.x
		var target_y := _bottom_y() - node.size.y - (14.0 if is_sp else 0.0)
		var tw := create_tween().set_parallel(true)
		tw.tween_property(node, "modulate", col, 0.18)
		tw.tween_property(node, "position:y", target_y, 0.18)
		node.z_index = 1 if is_sp else 0
		cx = cx

func _set_mood(id: String, mood: String) -> void:
	if mood == "" or not _sprites.has(id):
		return
	var old: Control = _sprites[id]
	if SpriteFactory.needs_swap(old, id, mood):
		var fresh := SpriteFactory.make(id, mood, _sprite_height())
		fresh.position = old.position
		fresh.modulate = old.modulate
		_stage_layer.add_child(fresh)
		_sprites[id] = fresh
		old.queue_free()

## Дрожание спрайта (используется для «сбоев» реальности).
func glitch(id: String) -> void:
	if not _sprites.has(id):
		return
	var node: Control = _sprites[id]
	var p := node.position
	var tw := create_tween()
	for i in range(6):
		tw.tween_property(node, "position", p + Vector2(randf_range(-10, 10), randf_range(-4, 4)), 0.04)
	tw.tween_property(node, "position", p, 0.04)

# ───────────────────────── реплики ─────────────────────────
func _say(st: Dictionary) -> void:
	var who: String = st["say"]
	var shown: String = st.get("as", who)
	var to: String = st.get("to", "")
	var text: String = st["t"]
	if who != "" and who != Chars.PLAYER and not _stage_ids.has(who):
		var l := _stage_ids.duplicate()
		l.append(who)
		_set_stage(l)
	_speaker = who if who != Chars.PLAYER else ""
	_set_mood(who, st.get("mood", ""))
	_highlight(_speaker)
	_update_nameplate(shown, to)
	var shown_text := text
	if who == "":
		shown_text = "[i][color=#c8c0a8]%s[/color][/i]" % text
	elif who == Chars.PLAYER:
		shown_text = "[i][color=#9fc7e8]%s[/color][/i]" % text
	GameState.history.append({"who": shown, "t": text})
	await _type(shown_text)
	await _wait_adv()

func _update_nameplate(id: String, to: String) -> void:
	if id == "":
		_name_lbl.text = ""
		_tag_lbl.text = ""
		_rel_lbl.text = ""
		return
	if id == Chars.PLAYER:
		_name_lbl.text = "Вы"
		_name_lbl.add_theme_color_override("font_color", Color(0.62, 0.78, 0.92))
		_tag_lbl.text = "тот, кто накрывает стол"
		_rel_lbl.text = ""
		return
	_name_lbl.text = Chars.full_title(id)
	_name_lbl.add_theme_color_override("font_color", Chars.color_of(id).lightened(0.25))
	var d := Chars.data(id)
	_tag_lbl.text = str(d.get("tag", ""))
	_rel_lbl.text = ""
	if to == Chars.PLAYER:
		_rel_lbl.text = "→ обращается к вам"
	elif to != "":
		var r := Chars.find_rel(id, to)
		if not r.is_empty():
			_rel_lbl.text = "→ %s · %s" % [Chars.display_name(to), r["label"]]
		else:
			_rel_lbl.text = "→ %s" % Chars.display_name(to)

func _type(bb: String) -> void:
	_cont.visible = false
	_text.text = bb
	_text.visible_characters = 0
	var total := _text.get_total_character_count()
	_typing = true
	var i := 0
	while _typing and i < total:
		i += 1
		_text.visible_characters = i
		if Input.is_key_pressed(KEY_CTRL):
			await get_tree().process_frame
		else:
			await get_tree().create_timer(CHAR_DELAY).timeout
	_typing = false
	_text.visible_characters = -1

func _wait_adv() -> void:
	_waiting = true
	_cont.visible = true
	while _waiting:
		_blink_t += 0.016
		_cont.modulate.a = 0.55 + 0.45 * sin(_blink_t * 6.0)
		await get_tree().process_frame
		if Input.is_key_pressed(KEY_CTRL):
			_waiting = false
	_cont.visible = false

func _advance() -> void:
	if _manual_hidden:
		_toggle_hide()
		return
	if _hist_panel.visible or (journal != null and journal.visible):
		return
	if _choice_box.visible:
		return
	if _typing:
		_typing = false
	elif _waiting:
		_waiting = false

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_advance()

func _input(event: InputEvent) -> void:
	if not is_visible_in_tree():
		return
	if event is InputEventKey and event.pressed and not event.echo:
		match event.keycode:
			KEY_SPACE, KEY_ENTER, KEY_KP_ENTER:
				if not _choice_box.visible:
					_advance()
					get_viewport().set_input_as_handled()
			KEY_H:
				_toggle_hide()
			KEY_L:
				_toggle_hist()
			KEY_J:
				_open_journal()
			KEY_ESCAPE:
				if journal != null and journal.visible:
					journal.close_panel()
				if _hist_panel.visible:
					_toggle_hist()

# ───────────────────────── выбор ─────────────────────────
func _choice(st: Dictionary) -> void:
	for c in _choice_box.get_children():
		c.queue_free()
	var opts: Array = []
	for o in st["choice"]:
		if not o.has("cond") or GameState.check(o["cond"]):
			opts.append(o)
	if opts.is_empty():
		return
	var prompt: String = st.get("prompt", "")
	if prompt != "":
		var pl := Label.new()
		pl.text = prompt
		pl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		pl.add_theme_font_size_override("font_size", 22)
		pl.add_theme_color_override("font_color", Color(0.95, 0.85, 0.55))
		pl.add_theme_color_override("font_outline_color", Color.BLACK)
		pl.add_theme_constant_override("outline_size", 6)
		_choice_box.add_child(pl)
	for i in range(opts.size()):
		var b := Button.new()
		b.text = opts[i]["t"]
		b.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		b.custom_minimum_size = Vector2(800, 50)
		b.add_theme_font_size_override("font_size", 19)
		b.pressed.connect(_on_choice.bind(i))
		_choice_box.add_child(b)
	_speaker = ""
	_highlight("")
	_name_lbl.text = ""
	_tag_lbl.text = ""
	_rel_lbl.text = ""
	_text.text = ""
	_cont.visible = false
	_picked = -1
	_choice_box.visible = true
	while _picked < 0:
		await get_tree().process_frame
	_choice_box.visible = false
	var chosen: Dictionary = opts[_picked]
	GameState.history.append({"who": "Вы (выбор)", "t": chosen["t"]})
	await play(chosen.get("do", []))

func _on_choice(i: int) -> void:
	_picked = i

# ───────────────────────── локация, карточки, тосты ─────────────────────────
func _loc(st: Dictionary) -> void:
	if not overlay and str(st.get("bg", "")) != "":
		set_bg(st["bg"])
	_loc_lbl.text = st["loc"]
	var tw := create_tween()
	tw.tween_property(_loc_lbl, "modulate:a", 1.0, 0.5)
	tw.tween_interval(1.1)
	tw.tween_property(_loc_lbl, "modulate:a", 0.0, 0.5)
	await tw.finished

func _show_toast(msg: String) -> void:
	_toast.text = msg
	var tw := create_tween()
	tw.tween_property(_toast, "modulate:a", 1.0, 0.3)
	tw.tween_interval(2.4)
	tw.tween_property(_toast, "modulate:a", 0.0, 0.6)

func _intro(ids: Array) -> void:
	var layer := ColorRect.new()
	layer.set_anchors_preset(Control.PRESET_FULL_RECT)
	layer.color = Color(0, 0, 0, 0.82)
	layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(layer)
	var cc := CenterContainer.new()
	cc.set_anchors_preset(Control.PRESET_FULL_RECT)
	cc.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(cc)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 22)
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	cc.add_child(row)
	for id in ids:
		GameState.meet(id)
		row.add_child(_make_card(id))
	var hint := Label.new()
	hint.text = "Клик или пробел — продолжить"
	hint.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	hint.anchor_left = 0.0
	hint.anchor_right = 1.0
	hint.anchor_top = 1.0
	hint.anchor_bottom = 1.0
	hint.offset_top = -40
	hint.offset_bottom = -10
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.add_theme_color_override("font_color", Color(0.8, 0.8, 0.7))
	hint.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(hint)
	_text.text = ""
	_name_lbl.text = ""
	_tag_lbl.text = ""
	_rel_lbl.text = ""
	await _wait_adv()
	layer.queue_free()

func _make_card(id: String) -> Control:
	var d := Chars.data(id)
	var card := PanelContainer.new()
	card.custom_minimum_size = Vector2(390, 470)
	card.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var sb := _panel_style(0.95)
	sb.border_color = Chars.color_of(id)
	card.add_theme_stylebox_override("panel", sb)
	var v := VBoxContainer.new()
	v.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.add_child(v)
	var top := HBoxContainer.new()
	top.mouse_filter = Control.MOUSE_FILTER_IGNORE
	v.add_child(top)
	var portrait := SpriteFactory.make(id, "", 130)
	top.add_child(portrait)
	var nv := VBoxContainer.new()
	nv.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	nv.mouse_filter = Control.MOUSE_FILTER_IGNORE
	top.add_child(nv)
	var nl := Label.new()
	nl.text = Chars.full_title(id)
	nl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	nl.add_theme_font_size_override("font_size", 22)
	nl.add_theme_color_override("font_color", Chars.color_of(id).lightened(0.25))
	nl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	nv.add_child(nl)
	var tl := Label.new()
	tl.text = str(d.get("tag", ""))
	tl.add_theme_font_size_override("font_size", 15)
	tl.add_theme_color_override("font_color", Color(0.75, 0.75, 0.7))
	tl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	nv.add_child(tl)
	var rt := RichTextLabel.new()
	rt.bbcode_enabled = true
	rt.fit_content = true
	rt.scroll_active = false
	rt.mouse_filter = Control.MOUSE_FILTER_IGNORE
	rt.add_theme_font_size_override("normal_font_size", 16)
	rt.add_theme_font_size_override("bold_font_size", 16)
	var t := "[b]Публично:[/b] %s\n" % d.get("pub", "")
	var rels := Chars.relations_of(id)
	var shown := 0
	for r in rels:
		if shown >= 3:
			break
		var o := Chars.other(r, id)
		if o == "don" or ids_visible(o):
			t += "[color=#d8b878]• %s:[/color] %s\n" % [Chars.display_name(o), r["label"]]
			shown += 1
	t += "\n[b]Роль в игре:[/b] %s\n" % d.get("game", "")
	if str(d.get("secret", "")) != "":
		t += "\n[color=#777777][b]Тайная роль:[/b] ???[/color]"
	rt.text = t
	v.add_child(rt)
	return card

func ids_visible(id: String) -> bool:
	return GameState.met.has(id) or GameState.present.has(id)

# ───────────────────────── панели ─────────────────────────
func _open_journal() -> void:
	if journal != null:
		journal.toggle()

func _toggle_hist() -> void:
	if _hist_panel.visible:
		_hist_panel.visible = false
		return
	var t := ""
	for h in GameState.history:
		var nm0 := str(h["who"])
		if nm0 == "" or nm0 == "player":
			t += "[i][color=#c8c0a8]%s[/color][/i]\n\n" % h["t"]
		else:
			var nm := Chars.display_name(nm0) if Chars.DATA.has(nm0) else nm0
			t += "[b]%s:[/b] %s\n\n" % [nm, h["t"]]
	_hist_text.text = t
	_hist_panel.visible = true

func _toggle_hide() -> void:
	_manual_hidden = not _manual_hidden
	var a := 0.0 if _manual_hidden else 1.0
	_box.modulate.a = a
	_stage_layer.modulate.a = a
	_top_bar.modulate.a = a if not _manual_hidden else 0.0
	_dim.color.a = (0.0 if _manual_hidden else (0.42 if overlay else 0.18))
