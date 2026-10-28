class_name GuestToken
extends Control
## Сидящий за столом (вид сверху). Берёт спрайт из assets/sprites/seat/, иначе рисует заглушку.

var cid := ""            # id персонажа; пусто — «неизвестный/призрак»
var label := ""
var color := Color(0.6, 0.6, 0.6)
var seat := 1
var ring := Color(0, 0, 0, 0)
var gaze := false
var alt := false
var _t := 0.0

func _init() -> void:
	var s := SeatLayout.SEAT_SPRITE_PX
	custom_minimum_size = Vector2(s, s)
	size = Vector2(s, s)
	pivot_offset = Vector2(s, s) * 0.5
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST

func _process(delta: float) -> void:
	if gaze:
		_t += delta
		queue_redraw()

func facing() -> String:
	return SeatLayout.FACING.get(seat, "down")

func _draw() -> void:
	var c := size * 0.5
	var f := facing()
	var info := SeatLayout.seat_texture(cid if cid != "" else "unknown", f)
	var tex: Texture2D = info["tex"]
	if ring.a > 0.0:
		draw_circle(c, size.x * 0.5, ring)
	if tex != null:
		var sc := SpriteFactory.int_scale(float(tex.get_height()), size.y)
		draw_set_transform(c, info["rot"], Vector2(sc, sc))
		draw_texture(tex, -tex.get_size() * 0.5)
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
		if alt:
			draw_circle(c, size.x * 0.42, Color(0.8, 0.85, 1.0, 0.55))
		if gaze:
			draw_arc(c, size.x * 0.48 + 3.0 * sin(_t * 8.0), 0, TAU, 40, Color(1, 0.2, 0.2, 0.9), 4.0)
		return
	# заглушка: круг + «плечи» + стрелка направления взгляда
	var col := Color(0.82, 0.82, 0.9) if alt else color
	var dir := Vector2.DOWN
	match f:
		"up": dir = Vector2.UP
		"left": dir = Vector2.LEFT
		"right": dir = Vector2.RIGHT
	draw_circle(c + Vector2(3, 5), 40, Color(0, 0, 0, 0.35))
	draw_circle(c, 40, col.darkened(0.4))
	draw_circle(c, 33, col)
	draw_colored_polygon(PackedVector2Array([c + dir * 44, c + dir * 30 + dir.orthogonal() * 10, c + dir * 30 - dir.orthogonal() * 10]), col.lightened(0.3))
	var ch := "?" if (alt or cid == "") else label.substr(0, 1)
	if cid == "" and not alt:
		ch = label.substr(0, 1) if label != "" else "?"
	draw_string(ThemeDB.fallback_font, Vector2(0, c.y + 12), ch, HORIZONTAL_ALIGNMENT_CENTER, size.x, 36, Color(1, 1, 1, 0.95))
	if gaze:
		draw_circle(c + Vector2(-12, -4), 9, Color.WHITE)
		draw_circle(c + Vector2(12, -4), 9, Color.WHITE)
		draw_circle(c + Vector2(-12, -1), 4, Color.BLACK)
		draw_circle(c + Vector2(12, -1), 4, Color.BLACK)
