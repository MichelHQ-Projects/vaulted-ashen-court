extends Node
# VAULTED — Game Data


var cards: Array = []
var enemies: Array = []
var floors: Array = []
var curses: Array = []


func _ready() -> void:
	cards = _load_json("res://data/cards.json")
	enemies = _load_json("res://data/enemies.json")
	floors = _load_json("res://data/floors.json")
	curses = _load_json("res://data/curses.json")


func _load_json(path: String) -> Array:
	var file = FileAccess.open(path, FileAccess.READ)
	if file == null:
		push_error("GameData: could not load " + path)
		return []
	var data = JSON.parse_string(file.get_as_text())
	return data if data is Array else []
