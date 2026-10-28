class_name Journal
extends PanelContainer
## Досье: кто есть кто, роль в игре, связи между персонажами.
## Тайные записи открываются через найденные улики (CLUE в диалогах).

const REL_WORDS := ["Вражда", "Недоверие", "Холод", "Нейтрально", "Контакт", "Доверие", "Союз"]

var _list: ItemList
var _text: RichTextLabel
var _ids: Array = []

func _ready() -> void:
	visible = false
	z_index = 100
	custom_minimum_size = Vector2(1060, 620)
	set_anchors_preset(Control.PRESET_CENTER)
	offset_left = -530
	offset_right = 530
	offset_top = -310
	offset_bottom = 310
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.06, 0.05, 0.06, 0.97)
	sb.border_color = Color(0.7, 0.58, 0.3)
	sb.set_border_width_all(2)
	sb.set_corner_radius_all(8)
	sb.set_content_margin_all(16)
	add_theme_stylebox_override("panel", sb)
	var root := VBoxContainer.new()
	add_child(root)
	var top := HBoxContainer.new()
	root.add_child(top)
	var title := Label.new()
	title.text = "ДОСЬЕ — кто есть кто за столом"
	title.add_theme_font_size_override("font_size", 24)
	title.add_theme_color_override("font_color", Color(0.9, 0.8, 0.5))
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top.add_child(title)
	var close := Button.new()
	close.text = "Закрыть (J)"
	close.pressed.connect(close_panel)
	top.add_child(close)
	var body := HBoxContainer.new()
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_child(body)
	_list = ItemList.new()
	_list.custom_minimum_size = Vector2(260, 0)
	_list.add_theme_font_size_override("font_size", 18)
	_list.item_selected.connect(_on_selected)
	body.add_child(_list)
	_text = RichTextLabel.new()
	_text.bbcode_enabled = true
	_text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_text.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_text.add_theme_font_size_override("normal_font_size", 17)
	_text.add_theme_font_size_override("bold_font_size", 17)
	body.add_child(_text)

func open_panel() -> void:
	refresh()
	visible = true

func close_panel() -> void:
	visible = false

func toggle() -> void:
	if visible:
		close_panel()
	else:
		open_panel()

func refresh() -> void:
	_list.clear()
	_ids.clear()
	for id in Chars.ORDER:
		if GameState.met.has(id):
			_ids.append(id)
			_list.add_item(Chars.full_title(id))
	if _ids.is_empty():
		_text.text = "[i]Пока вы никого не встретили.[/i]"
		return
	_list.select(0)
	_on_selected(0)

func _bar(v: int) -> String:
	var s := ""
	for i in range(-3, 4):
		s += "▮" if i <= v else "▯"
	return s

func _on_selected(i: int) -> void:
	if i < 0 or i >= _ids.size():
		return
	var id: String = _ids[i]
	var d := Chars.data(id)
	var col := Chars.color_of(id).lightened(0.2).to_html(false)
	var t := "[font_size=28][color=#%s]%s[/color][/font_size]\n" % [col, Chars.full_title(id)]
	t += "[i]%s[/i]\n\n" % d.get("tag", "")
	t += "[b]Публично:[/b] %s\n\n" % d.get("pub", "")
	t += "[b]Роль в игре:[/b] %s\n\n" % d.get("game", "")
	if str(d.get("secret", "")) != "":
		if GameState.has_clue(id + "_secret"):
			t += "[b]Тайная роль:[/b] [color=#e0a0a0]%s[/color]\n" % d["secret"]
			t += "[b]Главный интерес:[/b] [color=#e0a0a0]%s[/color]\n\n" % d.get("interest", "")
		else:
			t += "[b]Тайная роль:[/b] [color=#777777]— неизвестно. Ищите улики —[/color]\n\n"
	if d.get("dinners", []).size() > 0:
		t += "[b]Появляется на ужинах:[/b] %s\n" % ", ".join(d["dinners"].map(func(x): return str(x)))
	var tr := int(GameState.trust.get(id, 0))
	var tn := int(GameState.tension.get(id, 0))
	if GameState.trust.has(id) or GameState.tension.has(id):
		t += "[b]Отношение к вам:[/b] %+d    [b]Напряжение:[/b] %d\n" % [tr, tn]
	var rels := Chars.relations_of(id)
	if rels.size() > 0:
		t += "\n[b]Связи:[/b]\n"
		for r in rels:
			var other := Chars.other(r, id)
			if not GameState.met.has(other):
				continue
			var v := GameState.get_rel(r["a"], r["b"])
			t += "• [b]%s[/b] — %s: %s  [color=#aaaaaa](%s)[/color]\n   %s\n" % [
				Chars.display_name(other), r["label"], _bar(v), REL_WORDS[clampi(v + 3, 0, 6)], r["text"]]
			if str(r["secret"]) != "" and (GameState.has_clue(id + "_secret") or GameState.has_clue(other + "_secret")):
				t += "   [color=#e0a0a0]Скрыто: %s[/color]\n" % r["secret"]
	_text.text = t
