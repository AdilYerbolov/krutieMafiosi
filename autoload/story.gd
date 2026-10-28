extends StoryInterludes
## Главный автозагружаемый объект сюжета: метаданные ужинов, правила рассадки,
## эффекты вина/блюда/ножа, штрафы и выбор концовки.

const DINNERS := [
	{"n": 1, "title": "Обычный вечер", "sub": "Всё выглядит нормально. Почти."},
	{"n": 2, "title": "Тень на скатерти", "sub": "Кое-что идёт не так — и вы не уверены, что именно."},
	{"n": 3, "title": "Ужин «по-домашнему»", "sub": "Старые истории звучат слишком живо."},
	{"n": 4, "title": "Пустое кресло", "sub": "Дона нет. Приходит тот, кого не звали."},
	{"n": 5, "title": "Все делают вид", "sub": "Стол помнит больше, чем люди."},
	{"n": 6, "title": "Последний стол", "sub": "Кто остался — тот и есть семья."},
]

const SEAT_TITLES := {
	1: "Голова стола — самое сильное место (у камина)",
	2: "Верхний ряд, рядом с головой — слышно главу стола",
	7: "Верхний ряд, второе место от головы",
	4: "Верхний ряд, дальше от главы",
	8: "Верхний ряд, у дальнего конца",
	3: "Нижний ряд, рядом с головой · спиной к главной двери",
	9: "Нижний ряд, второе место · спиной к двери",
	5: "Нижний ряд, дальше от главы · спиной к двери",
	10: "Нижний ряд, у дальнего конца · спиной к двери",
	6: "Конец стола — самое слабое место",
}

# «Рядом» — соседи по ряду и по торцам; «напротив» — через стол.
const ADJ := [[1, 2], [1, 3], [2, 7], [7, 4], [4, 8], [3, 9], [9, 5], [5, 10], [6, 8], [6, 10]]
const OPP := [[2, 3], [7, 9], [4, 5], [8, 10]]
const BACK_TO_DOOR := [3, 9, 5, 10]

const SEAT_FLAGS := ["don_head", "don_displaced", "sara_head", "sara_right", "sara_angry",
	"luigi_humiliated", "tension_ml", "table_soft", "marco_careful", "emil_humiliated",
	"rose_near_sara", "rose_near_joe", "stranger_head"]

# Вино и особое блюдо: что означает «подать первому» для каждого гостя.
const WINE_FIRST := {
	"don": {"add": {"order": 1}, "txt": "Дон кивает: порядок соблюдён."},
	"sara": {"add": {"sara": 1}, "txt": "Сара едва заметно удовлетворена: вы признали её место."},
	"luigi": {"add": {"luigi_nervous": 1}, "txt": "Луи вздрагивает: почему он, а не Дон?"},
	"marco": {"add": {"marco_sign": 1}, "txt": "Марко улыбается шире. Для него это знак."},
	"nora": {"add": {"table_soft_wine": 1}, "txt": "Тётя Нора растроганно хлопает вас по руке."},
	"frank": {"add": {"frank_noticed": 1}, "txt": "Фрэнк смотрит на бокал, но не пьёт."},
	"emil": {"add": {"emil_pleased": 1}, "txt": "Эмиль принимает бокал с лёгким поклоном."},
	"rose": {"add": {"rose_trust": 1}, "txt": "Роза смущена: она не ожидала быть первой."},
	"joe": {"add": {"joe_pleased": 1}, "txt": "Джо поднимает бокал: «В моё время так и было»."},
	"stranger": {"add": {"stranger": 1}, "txt": "Незнакомец принимает бокал как должное."},
}

const DISH_TO := {
	"don": {"add": {"order": 1}, "txt": "Дон благодарит кивком. Порядок соблюдён."},
	"sara": {"add": {"sara": 1}, "txt": "Сара получает блюдо первой — и считает это уважением."},
	"luigi": {"add": {"luigi_suspicious": 1}, "txt": "Луи смотрит на блюдо с подозрением: не взятка ли?"},
	"marco": {"add": {"marco_sign": 0}, "txt": "Марко ест с аппетитом и подмигивает вам."},
	"nora": {"add": {"order": 1}, "txt": "Нора светлеет. За столом становится мягче."},
	"frank": {"add": {"frank_noticed": 1}, "txt": "Фрэнк не притрагивается к блюду. Тарелка так и стоит."},
	"emil": {"add": {"emil_pleased": 1}, "txt": "Эмиль оценивает подачу взглядом врача."},
	"rose": {"add": {"rose_trust": 1}, "txt": "Роза благодарна. Она запоминает всё, что ей дают."},
	"joe": {"add": {"joe_pleased": 1}, "txt": "Джо вспоминает, как такое готовили в его время."},
	"stranger": {"add": {"stranger": 1}, "txt": "Незнакомец пробует и записывает что-то в уме."},
}

const DISHES := [
	{"id": "soup", "name": "Минестроне", "desc": "Простая домашняя еда. Хорошо прощает ошибки.",
		"likes": ["luigi", "frank"], "diff": 0.75, "stages": ["Овощи", "Бульон", "Соль"]},
	{"id": "dolce", "name": "Тирамису", "desc": "Нежный десерт. Не терпит спешки.",
		"likes": ["nora", "rose"], "diff": 0.9, "stages": ["Крем", "Кофе", "Подача"]},
	{"id": "osso", "name": "Оссобуко", "desc": "Тяжёлое, сытное. Требует терпения.",
		"likes": ["don", "marco", "joe"], "diff": 1.0, "stages": ["Обжарка", "Тушение", "Подача"]},
	{"id": "fish", "name": "Осетр с лимоном", "desc": "Изящно и дорого. Рыба не прощает перетомления.",
		"likes": ["sara", "emil"], "diff": 1.25, "stages": ["Чистка", "Огонь", "Лимон"]},
	{"id": "special", "name": "Гусь в вине — фирменное блюдо дома", "desc": "Особое блюдо. Сложно, но о нём заговорят.",
		"likes": ["don", "sara", "stranger"], "diff": 1.45, "stages": ["Маринад", "Огонь", "Глазурь"]},
]

const WINE_FAIL_LINES := {
	"don": "Аккуратнее. В этом доме вино — не вода.",
	"sara": "Аккуратнее. Манжета — не скатерть.",
	"luigi": "Это… дурной знак, да? Скажите, что это не знак.",
	"marco": "Ха! Руки дрожат? Тогда и ножи вам не доверят.",
	"nora": "Ничего, милый. Раньше и не такое проливали.",
	"frank": "",
	"emil": "Пятна — это следы. Следы нужно убирать быстро.",
	"rose": "Ой! Всё в порядке, всё в порядке.",
	"joe": "В моё время за такое вылетали из дома.",
	"stranger": "Любопытно.",
}

const DISH_FAIL_LINES := {
	"don": "Блюдо… запоминающееся.",
	"sara": "Передайте повару: я его запомню.",
	"luigi": "Это что, предупреждение? От кого?",
	"marco": "Я ел и хуже. Но в окопах.",
	"nora": "Ох, милый, соли многовато. Но я съем.",
	"frank": "",
	"emil": "Пища — тоже лекарство. Это — яд.",
	"rose": "Очень… интересный вкус.",
	"joe": "Моя жена готовила хуже. Но она хотя бы старалась.",
	"stranger": "Занятно: даже ошибки здесь последовательны.",
}

func dinner(i: int) -> Array:
	match i:
		1: return dinner1()
		2: return dinner2()
		3: return dinner3()
		4: return dinner4()
		5: return dinner5()
		6: return dinner6()
	return []

func dinner_guests(i: int) -> Array:
	match i:
		1: return ["don", "sara", "luigi", "marco", "nora", "frank"]
		2: return ["don", "sara", "luigi", "marco", "nora", "emil"]
		3: return ["don", "sara", "marco", "nora", "rose", "joe"]
		4: return ["sara", "luigi", "marco", "nora", "emil", "stranger"]
		5: return ["don", "sara", "luigi", "frank", "rose", "joe"]
	# Ужин 6: состав зависит от судьбы персонажей
	var g := GameState
	var out := ["sara"]
	if not (int(g.v("sara")) >= 5 and int(g.v("order")) < 2):
		out.append("don")
	for id in ["frank", "rose", "joe"]:
		out.append(id)
	var extra := []
	if g.check("stranger_noticed"):
		extra.append("stranger")
	if g.check("louis_alive") and not g.check("louis_fled"):
		extra.append("luigi")
	if g.check("marco_alive"):
		extra.append("marco")
	extra.append("nora")
	for id in extra:
		if out.size() < 6:
			out.append(id)
	return out

func _near(a: String, b: String) -> bool:
	var so := GameState.seat_of
	if not (so.has(a) and so.has(b)):
		return false
	var sa: int = so[a]
	var sb: int = so[b]
	for pr in ADJ:
		if (pr[0] == sa and pr[1] == sb) or (pr[0] == sb and pr[1] == sa):
			return true
	return false

## Скрытые эффекты рассадки. assign: seat(int) -> id
func apply_seating(assign: Dictionary) -> void:
	var g := GameState
	g.seating = assign.duplicate()
	g.seat_of.clear()
	for seat in assign:
		g.seat_of[assign[seat]] = seat
	for k in SEAT_FLAGS:
		g.vars[k] = false
	for id in Chars.DATA.keys():
		g.vars["present_" + id] = false
	g.present = assign.values()
	for id in g.present:
		g.vars["present_" + id] = true
	var so := g.seat_of
	if so.get("don", 0) == 1:
		g.vars["don_head"] = true
		g.add_var("order", 1)
	elif so.has("don"):
		g.vars["don_displaced"] = true
		g.add_var("order", -1)
	if so.get("sara", 0) == 1:
		g.vars["sara_head"] = true
		g.add_var("sara", 2)
	if so.get("don", 0) == 1 and so.get("sara", 0) == 2:
		g.vars["sara_right"] = true
		g.add_var("sara", 1)
	if so.get("sara", 0) == 6:
		g.vars["sara_angry"] = true
		g.trust["sara"] = int(g.trust.get("sara", 0)) - 1
	if so.get("luigi", 0) == 6:
		g.vars["luigi_humiliated"] = true
	if _near("marco", "luigi"):
		g.vars["tension_ml"] = true
		g.change_rel("marco", "luigi", -1)
	if _near("nora", "don"):
		g.vars["table_soft"] = true
		g.add_var("order", 1)
	if int(so.get("frank", 0)) in BACK_TO_DOOR and g.dinner_no == 1:
		g.vars["frank_back_to_door"] = true
	if int(so.get("marco", 0)) in BACK_TO_DOOR:
		g.vars["marco_careful"] = true
	if so.get("emil", 0) == 6:
		g.vars["emil_humiliated"] = true
		g.vars["emil_grudge"] = true
	if _near("rose", "sara"):
		g.vars["rose_near_sara"] = true
		g.change_rel("rose", "sara", -1)
	if _near("rose", "joe"):
		g.vars["rose_near_joe"] = true
		g.change_rel("rose", "joe", 1)
	if so.get("stranger", 0) == 1:
		g.vars["stranger_head"] = true
		g.add_var("stranger", 2)

## Применить результат «налить вино первым».
## grade: perfect | good | under | over | spill
func apply_wine(guest: String, grade: String) -> String:
	var g := GameState
	var info: Dictionary = WINE_FIRST.get(guest, {"add": {}, "txt": ""})
	var pm: Dictionary = g.prep.get(guest, {})
	pm["wine"] = grade
	g.prep[guest] = pm
	if grade == "perfect" or grade == "good":
		for k in info["add"]:
			g.add_var(k, info["add"][k])
		g.apply_reward(guest, 1 if grade == "good" else 2)
		g.pending.append({"guest": guest, "kind": "wine_ok", "txt": info["txt"]})
		return info["txt"]
	var sev := 1 if grade == "under" else 2
	g.apply_penalty(guest, sev)
	if guest != "don" and g.present.has("don"):
		g.tension["don"] = int(g.tension.get("don", 0)) + 1
	g.pending.append({"guest": guest, "kind": "wine_fail"})
	return "Штраф: %s запомнит это (доверие −%d, напряжение +%d)." % [Chars.display_name(guest), sev, sev]

## Применить результат блюда. grade: excellent | good | poor | ruined
func apply_dish(guest: String, dish: Dictionary, grade: String) -> String:
	var g := GameState
	var info: Dictionary = DISH_TO.get(guest, {"add": {}, "txt": ""})
	var likes: bool = dish["likes"].has(guest)
	var pm: Dictionary = g.prep.get(guest, {})
	pm["dish"] = dish["id"]
	pm["dish_grade"] = grade
	g.prep[guest] = pm
	match grade:
		"excellent", "good":
			for k in info["add"]:
				g.add_var(k, info["add"][k])
			var bonus := 1
			if likes:
				bonus += 1
			g.apply_reward(guest, bonus)
			g.pending.append({"guest": guest, "kind": "dish_ok", "txt": info["txt"]})
			return info["txt"] + (" Блюдо пришлось по вкусу." if likes else "")
		"poor":
			g.tension[guest] = int(g.tension.get(guest, 0)) + 1
			return "Блюдо получилось посредственным. Гость промолчал, но заметил."
		_:
			g.apply_penalty(guest, 3)
			if guest == "luigi":
				g.add_var("luigi_suspicious", 1)
			g.pending.append({"guest": guest, "kind": "dish_fail"})
			return "Штраф: блюдо испорчено! %s обижен (доверие −3, напряжение +3)." % Chars.display_name(guest)

## Нож: оставить или убрать у гостя.
func apply_knives(knives: Dictionary) -> void:
	var g := GameState
	g.knives = knives.duplicate()
	for id in knives:
		if knives[id]:
			continue
		if id == "marco":
			g.vars["marco_noticed"] = true
			g.add_var("marco_loyal", 1)
			g.trust["marco"] = int(g.trust.get("marco", 0)) - 1
		elif id == "sara" or id == "don":
			g.trust[id] = int(g.trust.get(id, 0)) - 1

## Реплики-реакции на то, что игрок сделал на подготовке.
func reaction_steps() -> Array:
	var steps: Array = []
	for r in GameState.pending:
		var id: String = r["guest"]
		if not GameState.present.has(id):
			continue
		match r["kind"]:
			"wine_ok", "dish_ok":
				steps.append(n(str(r.get("txt", ""))))
			"wine_fail":
				var line: String = WINE_FAIL_LINES.get(id, "Аккуратнее.")
				steps.append(n("Вино плеснуло мимо бокала — %s замечает." % Chars.display_name(id)))
				if line == "":
					steps.append(n("%s молча отодвигает бокал." % Chars.display_name(id)))
				else:
					steps.append(s(id, line, "player", "cold"))
			"dish_fail":
				var line2: String = DISH_FAIL_LINES.get(id, "Любопытное блюдо.")
				if line2 == "":
					steps.append(n("%s отодвигает тарелку, даже не взглянув." % Chars.display_name(id)))
				else:
					steps.append(s(id, line2, "player", "cold"))
	GameState.pending.clear()
	return steps

func pick_ending() -> String:
	var g := GameState
	var o := int(g.v("order"))
	var sa := int(g.v("sara"))
	var c := int(g.v("chaos"))
	var stg := int(g.v("stranger"))
	var cas := int(g.v("casualties"))
	if stg >= 5 and g.check("stranger_noticed"):
		return "E"
	var toasted: bool = g.check("toast_order") or g.check("toast_sara") or g.check("toast_chaos") or g.check("toast_stranger")
	if cas >= 3 and (not toasted or maxi(o, maxi(sa, c)) < 8):
		return "D"
	if o >= sa and o >= c:
		return "A"
	if sa >= c:
		return "B"
	return "C"
