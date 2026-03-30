extends Node
# VAULTED — Floor Controller


var current_wave: int = 0
var enemies_alive: int = 0


func start_wave(wave_number: int) -> void:
	current_wave = wave_number
	EventBus.wave_started.emit(wave_number)


func on_enemy_died() -> void:
	enemies_alive -= 1
	if enemies_alive <= 0:
		EventBus.floor_cleared.emit(RunManager.current_floor)
