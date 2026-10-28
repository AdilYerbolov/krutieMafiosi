class_name TableItems
extends Control
## Предметы на столе: тарелки, бокалы, ножи, блюда, пятна от вина.
## Есть картинки в assets/props/ — используются они, иначе рисуется кодом.

var plates := {}      # seat -> true
var glasses := {}     # seat -> int
var knives := {}      # seat -> bool
var marks := {}       # seat -> {"spill": bool, "dish": String, "burnt": bool}
var extra: Array = [] # {"kind", "seat"}
var pulse_seat := -1
var _t := 0.0

const DISH_COLORS := {
	"soup": Color(0.85, 0.45, 0.2), "dolce": Color(0.9, 0.82, 0.62), "osso": Color(0.5, 0.28, 0.14),
	"fish": Color(0.85, 0.8, 0.7), "special": Color(0.82, 0.6, 0.18)}

func _ready() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST

func _process(delta: float) -> void:
	if pulse_seat > 0:
		_t += delta
		queue_redraw()

func _is_top(seat: int) -> bool:
	return SeatLayout.FACING.get(seat, "down") == "down"

func _offs(seat: int, which: String) -> Vector2:
	var sgn := 1.0 if which == "glass" else -1.0
	if seat == 1:
		return Vector2(0, -34 * sgn)
	if seat == 6:
		return Vector2(0, 34 * sgn)
	return Vector2(34 * sgn, -3 if _is_top(seat) else 3)

func _prop(prop_name: String, pos: Vector2, target_h: float) -> bool:
	var tex := SeatLayout.prop_texture(prop_name)
	if tex == null:
		return false
	var sc := SpriteFactory.int_scale(float(tex.get_height()), target_h)
	draw_set_transform(pos, 0.0, Vector2(sc, sc))
	draw_texture(tex, -tex.get_size() * 0.5)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	return true

func _plate(pos: Vector2, dish := "", burnt := false) -> void:
	if dish != "":
		var nm := "dish_burnt" if burnt else "dish_" + dish
		if _prop(nm, pos, 48.0):
			return
	elif _prop("plate", pos, 44.0):
		return
	elif not SeatLayout.DRAW_FALLBACK_PROPS:
		return
	draw_circle(pos + Vector2(2, 3), 21, Color(0, 0, 0, 0.35))
	draw_circle(pos, 20, Color(0.82, 0.8, 0.74))
	draw_circle(pos, 14, Color(0.72, 0.7, 0.64))
	if dish != "":
		var col: Color = Color(0.12, 0.1, 0.09) if burnt else DISH_COLORS.get(dish, Color(0.6, 0.4, 0.2))
		draw_circle(pos, 10, col)
		draw_circle(pos + Vector2(3, -2), 4, col.lightened(0.25))

func _glass(pos: Vector2) -> void:
	if _prop("glass", pos, 22.0) or not SeatLayout.DRAW_FALLBACK_PROPS:
		return
	draw_circle(pos, 8, Color(0.75, 0.8, 0.9, 0.8))
	draw_circle(pos, 5, Color(0.5, 0.05, 0.1))
	draw_circle(pos + Vector2(-2, -2), 1.5, Color(1, 1, 1, 0.7))

func _knife(pos: Vector2) -> void:
	if _prop("knife", pos, 34.0) or not SeatLayout.DRAW_FALLBACK_PROPS:
		return
	var a := pos + Vector2(0, -14)
	var b := pos + Vector2(0, 14)
	draw_line(a, b, Color(0.85, 0.87, 0.9), 3.0)
	draw_line(b, b + Vector2(0, 5), Color(0.35, 0.2, 0.1), 4.0)

func _spill(pos: Vector2) -> void:
	if _prop("spill", pos, 40.0):
		return
	var red := Color(0.5, 0.04, 0.1, 0.75)
	draw_circle(pos, 14, red)
	draw_circle(pos + Vector2(12, 5), 8, red)
	draw_circle(pos + Vector2(-10, 8), 6, red)
	draw_circle(pos + Vector2(4, -12), 5, red)

func _draw() -> void:
	for seat in plates:
		var p: Vector2 = SeatLayout.PLATE[seat]
		var mk: Dictionary = marks.get(seat, {})
		_plate(p, str(mk.get("dish", "")), bool(mk.get("burnt", false)))
		var gp := p + _offs(seat, "glass")
		for i in range(int(glasses.get(seat, 1))):
			_glass(gp + Vector2(0, 12 * i))
		if mk.get("spill", false):
			_spill(gp + Vector2(0, 6))
		if knives.get(seat, false):
			_knife(p + _offs(seat, "knife"))
	for e in extra:
		var pp: Vector2 = SeatLayout.PLATE[e["seat"]]
		match e["kind"]:
			"plate": _plate(pp)
			"dish": _plate(pp, "special")
			"glass": _glass(pp)
			"knife": _knife(pp)
	if pulse_seat > 0:
		var r := 52.0 + 6.0 * sin(_t * 6.0)
		draw_arc(SeatLayout.SEAT_POS[pulse_seat], r, 0, TAU, 48, Color(0.9, 0.3, 0.3, 0.8), 3.0)
