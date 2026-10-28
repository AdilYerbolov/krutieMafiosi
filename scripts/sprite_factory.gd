class_name SpriteFactory
extends RefCounted
## Загрузка спрайтов персонажей и фонов. Если файла нет — используется заглушка.

const ROOM_PATH := "res://assets/backgrounds/dining_room.jpg"

# «Виртуальные» фоны: кадры из главной комнаты. Положите assets/backgrounds/<ключ>.png —
# и он заменит кадр автоматически (hall, study, kitchen, backdoor, empty).
# Кадры заданы долями изображения (x, y, w, h), поэтому работают с любой версией комнаты.
const CROPS := {
	"hall": Rect2(0.34, 0.68, 0.32, 0.31),
	"study": Rect2(0.07, 0.02, 0.32, 0.30),
	"kitchen": Rect2(0.0, 0.32, 0.31, 0.31),
	"backdoor": Rect2(0.34, 0.68, 0.32, 0.31),
	"cellar": Rect2(0.03, 0.69, 0.32, 0.30),
	"clock": Rect2(0.72, 0.02, 0.28, 0.27),
}
const TINTS := {
	"kitchen": Color(1.25, 0.85, 0.6),
	"backdoor": Color(0.5, 0.65, 1.0),
	"empty": Color(0.45, 0.45, 0.55),
	"cellar": Color(0.6, 0.7, 1.0),
	"study": Color(0.9, 0.8, 0.7),
}

static var _cache := {}

static func load_tex(path: String) -> Texture2D:
	if _cache.has(path):
		return _cache[path]
	var t: Texture2D = null
	if ResourceLoader.exists(path):
		t = load(path)
	_cache[path] = t
	return t

static func background(key: String) -> Texture2D:
	for ext in ["png", "jpg", "webp"]:
		var t := load_tex("res://assets/backgrounds/%s.%s" % [key, ext])
		if t != null:
			return t
	var room := load_tex(ROOM_PATH)
	if room == null:
		return null
	if CROPS.has(key):
		var at := AtlasTexture.new()
		at.atlas = room
		var r: Rect2 = CROPS[key]
		var tw := float(room.get_width())
		var th := float(room.get_height())
		at.region = Rect2(r.position.x * tw, r.position.y * th, r.size.x * tw, r.size.y * th)
		return at
	return room

static func bg_tint(key: String) -> Color:
	return TINTS.get(key, Color(1, 1, 1))

static func sprite_texture(id: String, mood: String) -> Texture2D:
	var paths := []
	if mood != "":
		paths.append("res://assets/sprites/%s_%s.png" % [id, mood])
	paths.append("res://assets/sprites/%s.png" % id)
	for p in paths:
		var t := load_tex(p)
		if t != null:
			return t
	return null

## Масштаб для чёткого пиксель-арта: если арт меньше цели — целое кратное, иначе точная подгонка.
static func int_scale(src_h: float, target_h: float) -> float:
	if src_h <= 0.0:
		return 1.0
	if src_h >= target_h * 0.9:
		return target_h / src_h
	return maxf(1.0, roundf(target_h / src_h))

## Создаёт Control со спрайтом (или заглушкой) нужной высоты.
static func make(id: String, mood: String, height: float) -> Control:
	var tex := sprite_texture(id, mood)
	if tex != null:
		var tr := TextureRect.new()
		tr.texture = tex
		tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		tr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		tr.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		var sc := int_scale(float(tex.get_height()), height)
		tr.custom_minimum_size = Vector2(tex.get_width() * sc, tex.get_height() * sc)
		if float(tex.get_height()) > height:
			tr.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
		tr.size = tr.custom_minimum_size
		tr.mouse_filter = Control.MOUSE_FILTER_IGNORE
		return tr
	var ph := PlaceholderSprite.new()
	ph.char_id = id
	ph.mood = mood
	ph.color = Chars.color_of(id)
	ph.label_text = Chars.display_name(id)
	ph.custom_minimum_size = Vector2(height * 0.56, height)
	ph.size = ph.custom_minimum_size
	ph.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return ph

## Сменить настроение уже созданного спрайта: возвращает новый Control или null, если менять нечего.
static func needs_swap(node: Control, id: String, mood: String) -> bool:
	if node is PlaceholderSprite:
		var ph := node as PlaceholderSprite
		if sprite_texture(id, mood) != null:
			return true
		if ph.mood != mood:
			ph.mood = mood
			ph.queue_redraw()
		return false
	return sprite_texture(id, mood) != (node as TextureRect).texture
