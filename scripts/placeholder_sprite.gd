class_name PlaceholderSprite
extends Control
## Временный силуэт персонажа, пока нет настоящего спрайта.
## Чтобы заменить: положите assets/sprites/<id>.png (и/или <id>_<настроение>.png).

var char_id := ""
var mood := ""
var color := Color(0.6, 0.6, 0.6)
var label_text := ""

func _draw() -> void:
	var w := size.x
	var h := size.y
	var body := PackedVector2Array([
		Vector2(w * 0.06, h), Vector2(w * 0.12, h * 0.56), Vector2(w * 0.33, h * 0.44),
		Vector2(w * 0.67, h * 0.44), Vector2(w * 0.88, h * 0.56), Vector2(w * 0.94, h)])
	draw_colored_polygon(body, color.darkened(0.45))
	var outline := body.duplicate()
	outline.append(body[0])
	draw_polyline(outline, color.lightened(0.2), 3.0)
	draw_circle(Vector2(w * 0.5, h * 0.30), w * 0.19, color)
	draw_arc(Vector2(w * 0.5, h * 0.30), w * 0.19, 0, TAU, 40, color.lightened(0.3), 3.0)
	var font := ThemeDB.fallback_font
	draw_string(font, Vector2(8, h * 0.64), label_text, HORIZONTAL_ALIGNMENT_CENTER, w - 16, 26, Color(1, 1, 1, 0.95))
	var hint := "%s%s.png" % [char_id, ("_" + mood) if mood != "" else ""]
	draw_string(font, Vector2(8, h * 0.64 + 24), hint, HORIZONTAL_ALIGNMENT_CENTER, w - 16, 14, Color(1, 1, 1, 0.5))
