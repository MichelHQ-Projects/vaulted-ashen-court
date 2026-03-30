extends CardEffectBase
## VAULTED — Iron Echo (Augment Card)
## Every Nth attack releases a knockback shockwave that damages and pushes
## all enemies within a radius around the player.
##
## Listens for EventBus.card_effect_triggered with effect_id "attack_count".
## The player script emits that signal each time it lands an attack.

class_name IronEchoEffect

# ---------------------------------------------------------------------------
# Constants — defaults match cards.json; overridden from card_data in _setup()
# ---------------------------------------------------------------------------

const DEFAULT_TRIGGER_EVERY: int = 5
const DEFAULT_RADIUS: float = 120.0
const DEFAULT_FORCE: float = 300.0
const DEFAULT_DAMAGE: float = 10.0

# ---------------------------------------------------------------------------
# State
# ---------------------------------------------------------------------------

var _attack_count: int = 0
var _trigger_every: int = DEFAULT_TRIGGER_EVERY
var _shockwave_radius: float = DEFAULT_RADIUS
var _shockwave_force: float = DEFAULT_FORCE
var _shockwave_damage: float = DEFAULT_DAMAGE


# ---------------------------------------------------------------------------
# CardEffectBase overrides
# ---------------------------------------------------------------------------

func _setup() -> void:
	var effect: Dictionary = card_data.get("effect", {})
	_trigger_every = int(effect.get("n", DEFAULT_TRIGGER_EVERY))
	_shockwave_radius = float(effect.get("radius", DEFAULT_RADIUS))
	_shockwave_force = float(effect.get("force", DEFAULT_FORCE))
	_shockwave_damage = float(effect.get("damage", DEFAULT_DAMAGE))
	_attack_count = 0

	EventBus.card_effect_triggered.connect(_on_card_effect_triggered)


func _teardown() -> void:
	if EventBus.card_effect_triggered.is_connected(_on_card_effect_triggered):
		EventBus.card_effect_triggered.disconnect(_on_card_effect_triggered)


# ---------------------------------------------------------------------------
# Signal handlers
# ---------------------------------------------------------------------------

## Receives all card_effect_triggered signals. We only act on "attack_count".
func _on_card_effect_triggered(effect_id: String, _value: float) -> void:
	if not is_active:
		return
	if effect_id != "attack_count":
		return

	_attack_count += 1
	if _attack_count % _trigger_every == 0:
		_fire_shockwave()


# ---------------------------------------------------------------------------
# Shockwave logic
# ---------------------------------------------------------------------------

## Find the player and all enemies, apply knockback + damage to enemies in range.
func _fire_shockwave() -> void:
	var player: Node2D = get_tree().get_first_node_in_group("player") as Node2D
	if player == null:
		return

	var player_pos: Vector2 = player.global_position
	var enemies: Array = get_tree().get_nodes_in_group("enemies")

	for enemy_node: Variant in enemies:
		if enemy_node is Node2D:
			var enemy: Node2D = enemy_node as Node2D
			if not is_instance_valid(enemy):
				continue
			var dist: float = player_pos.distance_to(enemy.global_position)
			if dist <= _shockwave_radius:
				_apply_shockwave_to_enemy(enemy, player_pos)


## Apply knockback velocity and damage to a single enemy.
func _apply_shockwave_to_enemy(enemy: Node2D, origin: Vector2) -> void:
	# Apply damage if the enemy has a take_damage method
	if enemy.has_method("take_damage"):
		enemy.take_damage(_shockwave_damage)

	# Apply knockback velocity if CharacterBody2D
	if enemy is CharacterBody2D:
		var knock_dir: Vector2 = (enemy.global_position - origin).normalized()
		# If perfectly on top of origin, push in a random direction seeded from position
		if knock_dir == Vector2.ZERO:
			knock_dir = Vector2.RIGHT
		var char_body: CharacterBody2D = enemy as CharacterBody2D
		char_body.velocity += knock_dir * _shockwave_force
