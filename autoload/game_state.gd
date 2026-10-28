extends Node
## Глобальное состояние: флаги, счётчики руто́в, отношения, досье.

signal clue_added(id: String)

var vars := {}            # флаги (bool) и счётчики (int)
var rel := {}             # "a|b" -> int, отношения между персонажами
var trust := {}           # id -> int, отношение к игроку
var tension := {}         # id -> int, напряжение
var clues := {}           # открытые записи досье
var met := {}             # кого игрок уже встречал
var history := []         # лог реплик
var pending := []         # реакции на прошлые действия игрока (вино, блюдо)
var seating := {}         # seat:int -> id
var seat_of := {}         # id -> seat:int
var knives := {}          # id -> bool
var present := []         # кто за столом сейчас
var dinner_no := 0
var prep := {}            # id -> {"wine": grade, "dish": id, "dish_grade": grade} — что видно на столе

func reset() -> void:
	vars = {"louis_alive": true, "marco_alive": true}
	for k in ["order", "sara", "chaos", "stranger", "rose_trust", "joe_strong", "louis_trust",
			"marco_sign", "marco_loyal", "casualties", "clumsy"]:
		vars[k] = 0
	rel.clear()
	for r in Chars.REL:
		rel[Chars.pair_key(r["a"], r["b"])] = int(r["v"])
	trust.clear()
	tension.clear()
	clues.clear()
	met.clear()
	history.clear()
	pending.clear()
	seating.clear()
	seat_of.clear()
	knives.clear()
	present.clear()
	prep.clear()
	dinner_no = 0

func v(key: String, default_value = 0):
	return vars.get(key, default_value)

func set_var(key: String, value) -> void:
	vars[key] = value

func add_var(key: String, delta: int) -> void:
	vars[key] = int(vars.get(key, 0)) + delta

func _truthy(x) -> bool:
	if x is bool:
		return x
	if x is int or x is float:
		return x != 0
	return x != null

## Условия: "flag", "!flag", "key>=3", массив = И.
func check(cond) -> bool:
	if cond is Array:
		for c in cond:
			if not check(c):
				return false
		return true
	var s := str(cond).strip_edges()
	if s == "":
		return true
	for op in [">=", "<=", "==", "!=", ">", "<"]:
		var i := s.find(op)
		if i > 0:
			var key := s.substr(0, i).strip_edges()
			var val := float(s.substr(i + op.length()).strip_edges())
			var cur := float(vars.get(key, 0))
			match op:
				">=": return cur >= val
				"<=": return cur <= val
				"==": return is_equal_approx(cur, val)
				"!=": return not is_equal_approx(cur, val)
				">": return cur > val
				"<": return cur < val
	if s.begins_with("!"):
		return not _truthy(vars.get(s.substr(1), false))
	return _truthy(vars.get(s, false))

func change_rel(a: String, b: String, delta: int) -> void:
	var k := Chars.pair_key(a, b)
	rel[k] = clampi(int(rel.get(k, 0)) + delta, -3, 3)

func get_rel(a: String, b: String) -> int:
	return int(rel.get(Chars.pair_key(a, b), 0))

func add_clue(id: String) -> void:
	if not clues.has(id):
		clues[id] = true
		clue_added.emit(id)

func has_clue(id: String) -> bool:
	return clues.has(id)

func meet(id: String) -> void:
	met[id] = true

## Штраф за провал мини-игры: недоверие и напряжение у гостя.
func apply_penalty(id: String, severity: int) -> void:
	trust[id] = int(trust.get(id, 0)) - severity
	tension[id] = int(tension.get(id, 0)) + severity
	add_var("clumsy", 1)

func apply_reward(id: String, amount: int) -> void:
	trust[id] = int(trust.get(id, 0)) + amount
	tension[id] = maxi(0, int(tension.get(id, 0)) - 1)
