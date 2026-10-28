class_name StoryBase
extends Node
## Хелперы для описания диалогов как данных.
## Каждый шаг — Dictionary; VNView исполняет их по порядку.

# Реплика. who="" — рассказчик, who="player" — вы. to — кому адресована (показывает связь).
func s(who: String, text: String, to: String = "", mood: String = "") -> Dictionary:
	return {"say": who, "t": text, "to": to, "mood": mood}

func n(text: String) -> Dictionary:
	return {"say": "", "t": text}

func p(text: String) -> Dictionary:
	return {"say": "player", "t": text}

func st(ids: Array) -> Dictionary:
	return {"stage": ids}

func loc(title: String, bg: String = "") -> Dictionary:
	return {"loc": title, "bg": bg}

func intro(ids: Array) -> Dictionary:
	return {"intro": ids}

func clue(id: String) -> Dictionary:
	return {"clue": id}

func fx(name: String, args: Array = []) -> Dictionary:
	return {"fx": name, "args": args}

func setv(d: Dictionary) -> Dictionary:
	return {"set": d}

func addv(d: Dictionary) -> Dictionary:
	return {"add": d}

func relc(a: String, b: String, delta: int) -> Dictionary:
	return {"rel": [a, b, delta]}

func wait(sec: float) -> Dictionary:
	return {"wait": sec}

func rewrite(old_text: String, new_text: String) -> Dictionary:
	return {"rewrite": [old_text, new_text]}

func iff(cond, then_steps: Array, else_steps: Array = []) -> Dictionary:
	return {"if": cond, "then": then_steps, "else": else_steps}

# Выбор игрока. option: o("текст", [шаги], "условие")
func ch(options: Array, prompt: String = "") -> Dictionary:
	return {"choice": options, "prompt": prompt}

func o(text: String, steps: Array = [], cond = "") -> Dictionary:
	var d := {"t": text, "do": steps}
	if str(cond) != "":
		d["cond"] = cond
	return d

# Реплика, произнесённая «чужим голосом»: спрайт who, но имя на табличке as_id.
func sv(who: String, as_id: String, text: String, to: String = "") -> Dictionary:
	var d := s(who, text, to)
	d["as"] = as_id
	return d
