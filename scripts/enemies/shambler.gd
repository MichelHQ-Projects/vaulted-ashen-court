extends EnemyBase
## VAULTED — Shambler
## Slow melee swarm enemy. No special abilities — walks directly toward player
## and attacks when in range. Simplest enemy in the game.
## Stats loaded from data/enemies.json entry "shambler".

class_name Shambler


# ---------------------------------------------------------------------------
# Lifecycle
# ---------------------------------------------------------------------------

func _ready() -> void:
	enemy_type = "shambler"
	super._ready()


# ---------------------------------------------------------------------------
# Stats loader
# ---------------------------------------------------------------------------

func _load_stats() -> void:
	var data: Dictionary = _get_enemy_data("shambler")
	if data.is_empty():
		push_error("Shambler: could not load stats from enemies.json")
		# Fallback values matching data file — never hardcoded in production
		max_hp = 45.0
		move_speed = 60.0
		attack_damage = 8.0
		attack_range = 40.0
		attack_cooldown = 1.5
		return

	max_hp = float(data.get("hp", 45))
	move_speed = float(data.get("move_speed", 60))
	attack_damage = float(data.get("attack_damage", 8))
	attack_range = float(data.get("attack_range", 40))
	attack_cooldown = float(data.get("attack_cooldown", 1.5))


# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

## Find enemy data entry by id in GameData.enemies array.
func _get_enemy_data(id: String) -> Dictionary:
	for entry: Variant in GameData.enemies:
		if entry is Dictionary and entry.get("id", "") == id:
			return entry
	return {}
