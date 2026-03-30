extends CharacterBody2D
## VAULTED — Enemy Base
## Base class for all enemies. Handles AI state machine, movement, attack logic,
## and death. Subclasses override _load_stats() and may override _on_attack().
## All cross-system communication via EventBus — never direct node refs.

class_name EnemyBase

# ---------------------------------------------------------------------------
# Constants
# ---------------------------------------------------------------------------
const GROUP_PLAYER: String = "player"
const GROUP_ENEMIES: String = "enemies"

# ---------------------------------------------------------------------------
# AI States
# ---------------------------------------------------------------------------
enum State { IDLE, CHASING, ATTACKING, DYING }

# ---------------------------------------------------------------------------
# Stats — populated by subclasses via _load_stats() from GameData
# ---------------------------------------------------------------------------
var hp: float = 0.0
var max_hp: float = 0.0
var move_speed: float = 0.0
var attack_damage: float = 0.0
var attack_range: float = 0.0
var attack_cooldown: float = 1.5
var enemy_type: String = ""

# ---------------------------------------------------------------------------
# State tracking
# ---------------------------------------------------------------------------
var _state: State = State.IDLE
var _attack_timer: float = 0.0
var _player: Node2D = null
var _is_player_alive: bool = true

# Attack range area — subclasses must have an Area2D child named "AttackArea"
@onready var _attack_area: Area2D = $AttackArea


# ---------------------------------------------------------------------------
# Lifecycle
# ---------------------------------------------------------------------------

func _ready() -> void:
	add_to_group(GROUP_ENEMIES)
	_load_stats()
	hp = max_hp
	# Connect EventBus signals
	EventBus.player_died.connect(_on_player_died)
	# Connect attack area overlap
	if _attack_area:
		_attack_area.body_entered.connect(_on_attack_area_body_entered)
		_attack_area.body_exited.connect(_on_attack_area_body_exited)
	_state = State.CHASING


func _physics_process(delta: float) -> void:
	if _state == State.DYING:
		return

	_update_player_reference()

	match _state:
		State.IDLE:
			_process_idle(delta)
		State.CHASING:
			_process_chasing(delta)
		State.ATTACKING:
			_process_attacking(delta)


# ---------------------------------------------------------------------------
# State processors
# ---------------------------------------------------------------------------

func _process_idle(_delta: float) -> void:
	# Transition to chasing if player exists and is alive
	if _player != null and _is_player_alive:
		_state = State.CHASING


func _process_chasing(delta: float) -> void:
	if _player == null or not _is_player_alive:
		_state = State.IDLE
		velocity = Vector2.ZERO
		move_and_slide()
		return

	var direction: Vector2 = (_player.global_position - global_position).normalized()
	velocity = direction * move_speed
	move_and_slide()

	# Transition to attacking handled by area overlap in _on_attack_area_body_entered


func _process_attacking(delta: float) -> void:
	if _player == null or not _is_player_alive:
		_state = State.IDLE
		return

	# Stand still while attacking
	velocity = Vector2.ZERO
	move_and_slide()

	_attack_timer -= delta
	if _attack_timer <= 0.0:
		_perform_attack()
		_attack_timer = attack_cooldown


# ---------------------------------------------------------------------------
# Combat
# ---------------------------------------------------------------------------

## Called each time an attack fires. Subclasses may override for special behavior.
func _perform_attack() -> void:
	_on_attack()
	# Deliver damage directly to the player node
	if _player != null and is_instance_valid(_player) and _player.has_method("take_damage"):
		_player.take_damage(int(attack_damage))
	# EventBus.player_hit is emitted by player.take_damage() itself, so no
	# duplicate emit here — the HUD updates through the player's own signal path.


## Virtual — override in subclass to add special attack behavior.
func _on_attack() -> void:
	pass


## Apply incoming damage. Called by external systems (e.g. wave_spawner, player attack).
func take_damage(amount: float) -> void:
	if _state == State.DYING:
		return
	hp -= amount
	if hp <= 0.0:
		die()


func die() -> void:
	if _state == State.DYING:
		return
	_state = State.DYING
	velocity = Vector2.ZERO
	EventBus.enemy_died.emit(global_position, enemy_type)
	queue_free()


# ---------------------------------------------------------------------------
# Area2D attack range callbacks
# ---------------------------------------------------------------------------

func _on_attack_area_body_entered(body: Node2D) -> void:
	if body.is_in_group(GROUP_PLAYER) and _is_player_alive:
		_state = State.ATTACKING
		_attack_timer = 0.0  # Attack immediately on first contact


func _on_attack_area_body_exited(body: Node2D) -> void:
	if body.is_in_group(GROUP_PLAYER):
		if _state == State.ATTACKING:
			_state = State.CHASING


# ---------------------------------------------------------------------------
# EventBus handlers
# ---------------------------------------------------------------------------

func _on_player_died() -> void:
	_is_player_alive = false
	_state = State.IDLE
	velocity = Vector2.ZERO


# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

## Refresh the cached player reference each frame (handles respawn / late join).
func _update_player_reference() -> void:
	if _player == null or not is_instance_valid(_player):
		var players: Array = get_tree().get_nodes_in_group(GROUP_PLAYER)
		_player = players[0] if not players.is_empty() else null


## Override in subclasses — load stats from GameData into hp/max_hp/move_speed etc.
func _load_stats() -> void:
	pass
