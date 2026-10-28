class_name SeatLayout
extends RefCounted
## Раскладка 10 мест за столом под вид «сверху» (координаты в пространстве 1376×768).
## Если перерисуете комнату — правьте только эти константы.
##
## Нумерация мест (сохранена от логики рассадки):
##   1 — голова стола (левый торец, у камина), 6 — дальний торец (справа)
##   верхний ряд слева→направо: 2, 7, 4, 8
##   нижний ряд  слева→направо: 3, 9, 5, 10

const SEATS := [1, 2, 3, 4, 5, 6, 7, 8, 9, 10]

# центр сидящего персонажа
const SEAT_POS := {
	1: Vector2(292, 398),
	2: Vector2(419, 228), 7: Vector2(590, 228), 4: Vector2(770, 228), 8: Vector2(949, 228),
	3: Vector2(427, 587), 9: Vector2(599, 587), 5: Vector2(775, 587), 10: Vector2(945, 587),
	6: Vector2(1067, 402),
}

# куда «смотрит» сидящий: определяет, какой спрайт-вид-сверху берётся
const FACING := {
	1: "right", 6: "left",
	2: "down", 7: "down", 4: "down", 8: "down",
	3: "up", 9: "up", 5: "up", 10: "up",
}

# где лежат тарелка/бокал/нож перед гостем
const PLATE := {
	1: Vector2(385, 400), 6: Vector2(989, 404),
	2: Vector2(419, 310), 7: Vector2(590, 310), 4: Vector2(770, 310), 8: Vector2(949, 310),
	3: Vector2(427, 499), 9: Vector2(599, 499), 5: Vector2(775, 499), 10: Vector2(945, 499),
}

# Если тарелки/бокалы/ножи уже нарисованы в самом фоне комнаты — поставьте false:
# тогда код не рисует запасные (заглушечные) тарелки, бокалы и ножи.
# Блюда, пятна от вина и «лишний прибор» рисуются всегда.
const DRAW_FALLBACK_PROPS := true

const SEAT_SPRITE_PX := 112.0      # во сколько пикселей экрана рисуется спрайт сидящего
const FACING_ROT := {"down": 0.0, "up": PI, "right": -PI / 2.0, "left": PI / 2.0}

## Спрайт вида сверху: assets/sprites/seat/<id>_<down|up|left|right>.png
## Если нужного направления нет, но есть <id>_down.png — он поворачивается.
static func seat_texture(id: String, facing: String) -> Dictionary:
	var tex := SpriteFactory.load_tex("res://assets/sprites/seat/%s_%s.png" % [id, facing])
	if tex != null:
		return {"tex": tex, "rot": 0.0}
	tex = SpriteFactory.load_tex("res://assets/sprites/seat/%s_down.png" % id)
	if tex != null:
		return {"tex": tex, "rot": FACING_ROT.get(facing, 0.0)}
	return {"tex": null, "rot": 0.0}

## Предметы на столе: assets/props/<name>.png (plate, glass, knife, spill, dish_<id>, dish_burnt)
static func prop_texture(prop_name: String) -> Texture2D:
	return SpriteFactory.load_tex("res://assets/props/%s.png" % prop_name)
