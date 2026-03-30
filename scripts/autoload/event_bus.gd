extends Node
# VAULTED — Event Bus
# All cross-system signals route through here. Never direct node refs.

signal player_hit(damage: float)
signal player_died()
signal player_dodged(position: Vector2)
signal card_picked(card_id: String)
signal card_effect_triggered(effect_id: String, value: float)
signal enemy_died(position: Vector2, enemy_type: String)
signal enemy_spawned(enemy_id: int)
signal floor_cleared(floor_number: int)
signal wave_started(wave_number: int)
signal boss_phase_changed(phase: int)
signal curse_applied(curse_id: String)
