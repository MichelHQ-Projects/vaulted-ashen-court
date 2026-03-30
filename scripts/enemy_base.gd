extends CharacterBody2D
# VAULTED — Enemy Base


var hp: float = 0.0
var move_speed: float = 0.0
var enemy_type: String = ""


func die() -> void:
	EventBus.enemy_died.emit(global_position, enemy_type)
	queue_free()
