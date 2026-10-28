extends SceneTree
# Автоматический прогон игры ботом. Запуск: godot --headless --path . -s ../tools/test_run.gd -- seed
var main: Node
var t := 0.0
var started := false
var seed_v := 1
var last_progress := 0.0
var steps_seen := 0

func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	if args.size() > 0:
		seed_v = int(args[0])
	seed(seed_v)
	Engine.time_scale = 24.0
	main = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)

func _process(delta: float) -> bool:
	t += delta
	if not started and t > 0.3:
		started = true
		main._start(0)
	if main.end_layer != null:
		print("ENDING: ", root.get_node("Story").pick_ending(), " vars=", root.get_node("GameState").vars)
		quit(0)
		return true
	if t > 1500.0 and not has_meta("dumped"):
		set_meta("dumped", true)
		var vn: VNView = main.vn
		var dv: DinnerView = main.dinner
		print("DUMP dinner=", root.get_node("GameState").dinner_no, " vn.visible=", vn.visible, " choice=", vn._choice_box.visible, " typing=", vn._typing, " waiting=", vn._waiting, " dv.visible=", dv.visible, " layer=", dv._layer.get_children().map(func(c): return c.get_class() + ":" + str(c.get_script().get_global_name() if c.get_script() else "")), " fader=", main.fader.color.a, " journal=", main.journal.visible)
	if t > 1600.0:
		print("TIMEOUT dinner=", root.get_node("GameState").dinner_no)
		quit(1)
		return true
	_drive()
	return false

func _drive() -> void:
	var vn: VNView = main.vn
	var dv: DinnerView = main.dinner
	if vn.visible:
		if vn._choice_box.visible:
			var btns := []
			for c in vn._choice_box.get_children():
				if c is Button:
					btns.append(c)
			if btns.size() > 0:
				vn._on_choice(randi() % btns.size())
		else:
			vn._advance()
		return
	if dv.visible:
		var layer: Control = dv._layer
		# мини-игры
		for c in layer.get_children():
			if c is WineGame:
				var w: WineGame = c
				if not w.has_meta("bad"):
					w.set_meta("bad", randf() < 0.5)
				if not w.finished:
					if not w.pouring:
						w._start_pour()
					elif not w.get_meta("bad") and w.level >= w.target - w.half * 0.2:
						w._stop_pour()
				return
			if c is DishGame:
				var d: DishGame = c
				if not d.has_meta("bad"):
					d.set_meta("bad", randf() < 0.5)
				if d.active:
					if d.get_meta("bad"):
						if randf() < 0.2:
							d._press()
					elif absf(d.pos - d.zone_c) < d.zone_h * 0.5 or randf() < 0.05:
						d._press()
				return
		# рассадка
		if dv._start_btn != null and is_instance_valid(dv._start_btn) and dv._slot_btns.size() > 0:
			if dv._assign.size() < dv._guests.size():
				var free := []
				for s in SeatLayout.SEATS:
					if not dv._assign.has(s):
						free.append(s)
				for id in dv._guests:
					if dv._seat_of_guest(id) == 0:
						dv._assign[free.pop_at(randi() % free.size())] = id
						break
				dv._refresh_seating()
			else:
				dv._seating_done.emit()
			return
		# меню / ножи
		for c in layer.get_children():
			if c is PanelContainer:
				var found := _find_buttons(c)
				if found.size() > 0:
					var b: Button = found[randi() % found.size()]
					if b.text.begins_with("Готово"):
						b.pressed.emit()
					else:
						b.pressed.emit()
					return

func _find_buttons(n: Node) -> Array:
	var out := []
	for c in n.get_children():
		if c is Button and not (c is CheckButton):
			out.append(c)
		out.append_array(_find_buttons(c))
	return out
