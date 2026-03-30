extends Node
# VAULTED — Run Manager


var current_floor: int = 0
var active_cards: Array = []
var active_curses: Array = []
var score: int = 0
var enemies_killed: int = 0
var known_synergies: Array = []
var deaths: int = 0


func reset_run() -> void:
	current_floor = 0
	active_cards = []
	active_curses = []
	score = 0
	enemies_killed = 0
	known_synergies = []
