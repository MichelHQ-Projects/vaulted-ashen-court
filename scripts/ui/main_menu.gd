extends Control
## VAULTED — Main Menu
##
## Entry point for the game. Shows the title, tagline, and navigation buttons.
## "Play" loads the game scene; "Quit" exits the application.

class_name MainMenu

# ---------------------------------------------------------------------------
# Node references
# ---------------------------------------------------------------------------

@onready var _play_btn: Button = $VBoxContainer/PlayButton
@onready var _quit_btn: Button = $VBoxContainer/QuitButton

# ---------------------------------------------------------------------------
# Lifecycle
# ---------------------------------------------------------------------------

func _ready() -> void:
	_play_btn.pressed.connect(_on_play_pressed)
	_quit_btn.pressed.connect(_on_quit_pressed)


# ---------------------------------------------------------------------------
# Button handlers
# ---------------------------------------------------------------------------

func _on_play_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/game.tscn")


func _on_quit_pressed() -> void:
	get_tree().quit()
