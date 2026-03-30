extends CharacterBody2D
## VAULTED — Player (The Cursed Knight)
##
## Full state-machine controller: IDLE, MOVING, ATTACKING, DODGING, DEAD.
## Handles 8-directional movement, arc attacks, dodge roll with i-frames,
## and a dual HP/Armor damage model. All stats are constants — no hardcoded
## values in logic. Communicates outward exclusively via EventBus.

class_name PlayerController

# ---------------------------------------------------------------------------
# Constants — stats (baseline.md)
# ---------------------------------------------------------------------------

const MAX_HP: int          = 100
const MAX_ARMOR: int       = 20
const MOVE_SPEED: float    = 140.0
const ATTACK_SPEED: float  = 0.8       # attacks per second
const ATTACK_DAMAGE: int   = 18
const ATTACK_ARC_DEGREES: float = 120.0
const ATTACK_RANGE: float  = 80.0

const DODGE_DURATION: float  = 0.4    # seconds of i-frames
const DODGE_SPEED: float     = 350.0
const DODGE_COOLDOWN: float  = 1.0

## Reciprocal of attack speed: seconds between attacks
const ATTACK_COOLDOWN: float = 1.0 / ATTACK_SPEED

## Duration of the boss_slow_hit speed debuff in seconds
const BOSS_SLOW_DURATION: float = 1.0
## Fractional speed penalty applied by boss_slow_hit (0.5 = 50% speed)
const BOSS_SLOW_FACTOR: float = 0.5

## Visual dimensions for the placeholder ColorRect
const VISUAL_WIDTH: float  = 24.0
const VISUAL_HEIGHT: float = 40.0

## Color for placeholder visual: tarnished gold
const PLAYER_COLOR: Color = Color(0.7, 0.6, 0.2)

# ---------------------------------------------------------------------------
# State machine
# ---------------------------------------------------------------------------

enum State { IDLE, MOVING, ATTACKING, DODGING, DEAD }

var _state: State = State.IDLE

# ---------------------------------------------------------------------------
# Runtime state
# ---------------------------------------------------------------------------

var hp: int         = MAX_HP
var armor: int      = MAX_ARMOR

var facing_direction: Vector2 = Vector2.RIGHT

var is_invincible: bool  = false
var attack_count: int    = 0

var _attack_timer: float  = 0.0
var _dodge_timer: float   = 0.0
var _dodge_cooldown_remaining: float = 0.0
var _dodge_direction: Vector2 = Vector2.ZERO

## Multiplicative modifier applied to MOVE_SPEED (1.0 = no change).
## Curses and temporary debuffs write to this variable.
var _speed_modifier: float = 1.0

## Timer node created on demand for boss_slow_hit debuff
var _slow_timer: Timer = null

# ---------------------------------------------------------------------------
# Node references
# ---------------------------------------------------------------------------

@onready var _visual: ColorRect = $Visual
@onready var _attack_hitbox: Area2D = $AttackHitbox

# ---------------------------------------------------------------------------
# Lifecycle
# ---------------------------------------------------------------------------

func _ready() -> void:
	add_to_group(&"player")
	EventBus.floor_cleared.connect(_on_floor_cleared)
	EventBus.curse_applied.connect(_on_curse_applied)
	EventBus.card_effect_triggered.connect(_on_card_effect)


func _physics_process(delta: float) -> void:
	match _state:
		State.IDLE, State.MOVING:
			_tick_movement(delta)
			_tick_attack_input()
			_tick_dodge_input()
		State.ATTACKING:
			_tick_movement(delta)      # allow movement during attack windup
			_tick_attack_cooldown(delta)
			_tick_dodge_input()
		State.DODGING:
			_tick_dodge_movement(delta)
		State.DEAD:
			velocity = Vector2.ZERO

	_tick_cooldowns(delta)
	move_and_slide()


# ---------------------------------------------------------------------------
# Movement
# ---------------------------------------------------------------------------

func _tick_movement(delta: float) -> void:
	# Suppress unused delta warning; move_and_slide handles the actual time step
	@warning_ignore("unused_parameter")
	var _d: float = delta

	var input_dir: Vector2 = Input.get_vector(
		&"move_left", &"move_right", &"move_up", &"move_down"
	)

	if input_dir != Vector2.ZERO:
		velocity = input_dir.normalized() * (MOVE_SPEED * _speed_modifier)
		facing_direction = input_dir.normalized()
		_set_state(State.MOVING)
	else:
		velocity = Vector2.ZERO
		if _state == State.MOVING:
			_set_state(State.IDLE)

	# Always track mouse facing when not dodging
	_update_facing_from_mouse()


func _update_facing_from_mouse() -> void:
	var mouse_pos: Vector2 = get_global_mouse_position()
	var to_mouse: Vector2 = mouse_pos - global_position
	if to_mouse.length_squared() > 1.0:
		facing_direction = to_mouse.normalized()


# ---------------------------------------------------------------------------
# Attack
# ---------------------------------------------------------------------------

func _tick_attack_input() -> void:
	if Input.is_action_just_pressed(&"attack") and _attack_timer <= 0.0:
		_perform_attack()


func _tick_attack_cooldown(delta: float) -> void:
	if _attack_timer > 0.0:
		_attack_timer -= delta
		if _attack_timer <= 0.0:
			_set_state(State.IDLE)


func _perform_attack() -> void:
	_attack_timer = ATTACK_COOLDOWN
	_set_state(State.ATTACKING)
	attack_count += 1

	# Notify cards that track attack count
	EventBus.card_effect_triggered.emit("attack_count", float(attack_count))

	# Arc-based hit detection using the "enemies" group
	var enemies: Array[Node] = get_tree().get_nodes_in_group(&"enemies")
	var half_arc_rad: float = deg_to_rad(ATTACK_ARC_DEGREES * 0.5)

	for enemy: Node in enemies:
		if not enemy.has_method("take_damage"):
			continue

		var enemy_node: Node2D = enemy as Node2D
		if enemy_node == null:
			continue

		var to_enemy: Vector2 = enemy_node.global_position - global_position
		var dist: float = to_enemy.length()

		if dist > ATTACK_RANGE:
			continue

		# Check if the enemy is within the attack arc
		var angle_to_enemy: float = facing_direction.angle_to(to_enemy.normalized())
		if absf(angle_to_enemy) <= half_arc_rad:
			enemy_node.call("take_damage", ATTACK_DAMAGE)


# ---------------------------------------------------------------------------
# Dodge
# ---------------------------------------------------------------------------

func _tick_dodge_input() -> void:
	if Input.is_action_just_pressed(&"dodge") and _dodge_cooldown_remaining <= 0.0:
		_perform_dodge()


func _perform_dodge() -> void:
	# Dodge in movement direction if moving, otherwise use facing
	var input_dir: Vector2 = Input.get_vector(
		&"move_left", &"move_right", &"move_up", &"move_down"
	)
	_dodge_direction = input_dir if input_dir != Vector2.ZERO else facing_direction

	_set_state(State.DODGING)
	is_invincible = true
	_dodge_timer = DODGE_DURATION
	_dodge_cooldown_remaining = DODGE_COOLDOWN

	EventBus.player_dodged.emit(global_position)


func _tick_dodge_movement(delta: float) -> void:
	velocity = _dodge_direction.normalized() * DODGE_SPEED

	_dodge_timer -= delta
	if _dodge_timer <= 0.0:
		is_invincible = false
		_dodge_timer = 0.0
		_set_state(State.IDLE)


# ---------------------------------------------------------------------------
# Shared cooldown ticks
# ---------------------------------------------------------------------------

func _tick_cooldowns(delta: float) -> void:
	if _attack_timer > 0.0 and _state != State.ATTACKING:
		_attack_timer -= delta

	if _dodge_cooldown_remaining > 0.0:
		_dodge_cooldown_remaining -= delta
		if _dodge_cooldown_remaining < 0.0:
			_dodge_cooldown_remaining = 0.0


# ---------------------------------------------------------------------------
# Damage
# ---------------------------------------------------------------------------

## Apply incoming damage. Armor absorbs first, then HP.
## Returns silently if the player is currently invincible (dodge i-frames).
func take_damage(amount: int) -> void:
	if is_invincible or _state == State.DEAD:
		return

	var remaining_damage: int = amount

	# Armor absorbs first
	if armor > 0:
		var absorbed: int = mini(armor, remaining_damage)
		armor -= absorbed
		remaining_damage -= absorbed

	# Remainder hits HP
	if remaining_damage > 0:
		hp -= remaining_damage
		hp = maxi(hp, 0)

	EventBus.player_hit.emit(float(amount))

	if hp <= 0:
		_die()


func _die() -> void:
	_set_state(State.DEAD)
	velocity = Vector2.ZERO
	EventBus.player_died.emit()


# ---------------------------------------------------------------------------
# Floor events
# ---------------------------------------------------------------------------

func _on_floor_cleared(_floor_number: int) -> void:
	# Armor regenerates between floors
	armor = MAX_ARMOR


# ---------------------------------------------------------------------------
# Curse handlers
# ---------------------------------------------------------------------------

## Applies permanent or run-duration modifiers when a curse is received.
func _on_curse_applied(curse_id: String) -> void:
	match curse_id:
		"weighted_chains":
			# Weighted Chains: -15% move speed for the remainder of the run
			_speed_modifier *= 0.85


# ---------------------------------------------------------------------------
# Card effect handlers
# ---------------------------------------------------------------------------

## Handles card-triggered effects that target the player.
func _on_card_effect(effect_id: String, _value: float) -> void:
	match effect_id:
		"boss_slow_hit":
			_apply_boss_slow()


## Applies a temporary speed reduction for BOSS_SLOW_DURATION seconds.
## If a slow is already active, it is reset to full duration.
func _apply_boss_slow() -> void:
	# Cache the pre-slow modifier so we can restore exactly what was there
	var base_modifier: float = _speed_modifier / BOSS_SLOW_FACTOR if _slow_timer != null and is_instance_valid(_slow_timer) else _speed_modifier
	_speed_modifier = base_modifier * BOSS_SLOW_FACTOR

	# Reset or create the one-shot timer
	if _slow_timer != null and is_instance_valid(_slow_timer):
		_slow_timer.stop()
		_slow_timer.queue_free()

	_slow_timer = Timer.new()
	_slow_timer.wait_time = BOSS_SLOW_DURATION
	_slow_timer.one_shot = true
	add_child(_slow_timer)
	_slow_timer.timeout.connect(func() -> void:
		_speed_modifier = base_modifier
		_slow_timer = null
	)
	_slow_timer.start()


# ---------------------------------------------------------------------------
# State transitions
# ---------------------------------------------------------------------------

func _set_state(new_state: State) -> void:
	if _state == State.DEAD:
		return  # Dead is a terminal state
	_state = new_state
