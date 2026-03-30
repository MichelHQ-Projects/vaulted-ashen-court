extends EnemyBase
## VAULTED — Boss Knight
## Three-phase boss that mirrors the player moveset.
## Phase 1 (100–66% HP): Standard approach and swing attack.
## Phase 2 (66–33% HP): Faster attacks + charge dash.
## Phase 3 (33–0% HP): Enraged speed bonus; attacks briefly slow player when
##   Weighted Chains curse is active.
##
## Stats loaded from data/enemies.json entry "boss_knight".

class_name BossKnight

# ---------------------------------------------------------------------------
# Phase thresholds (HP percentage)
# ---------------------------------------------------------------------------

const PHASE_2_THRESHOLD: float = 0.66
const PHASE_3_THRESHOLD: float = 0.33

# ---------------------------------------------------------------------------
# Phase-specific overrides — read from base stats in _load_stats()
# ---------------------------------------------------------------------------

## Base attack cooldown used in Phase 1 (set from data).
const PHASE_1_COOLDOWN_MULT: float = 1.0
const PHASE_2_COOLDOWN_MULT: float = 0.667   # 1.5 s → 1.0 s
const PHASE_3_SPEED_BONUS: float = 0.30      # +30% move_speed

## Charge dash parameters
const CHARGE_SPEED_MULT: float = 3.0
const CHARGE_DURATION_SEC: float = 0.5
const CHARGE_DAMAGE: float = 30.0
const CHARGE_COOLDOWN_SEC: float = 4.0

# ---------------------------------------------------------------------------
# Extended state machine — adds CHARGING state on top of EnemyBase states
# ---------------------------------------------------------------------------

enum BossState { IDLE, CHASING, ATTACKING, DYING, CHARGING }

var current_phase: int = 1
var _base_attack_cooldown: float = 1.5
var _base_move_speed: float = 100.0

## Charge state
var _charge_timer: float = 0.0
var _charge_direction: Vector2 = Vector2.ZERO
var _charge_cooldown_timer: float = 0.0
var _has_hit_player_this_charge: bool = false

## Override _state type to int so we can use BossState values alongside EnemyBase State.
## We shadow EnemyBase._state by declaring our own var.
var _boss_state: int = BossState.IDLE


# ---------------------------------------------------------------------------
# Lifecycle
# ---------------------------------------------------------------------------

func _ready() -> void:
	enemy_type = "boss_knight"
	add_to_group("boss")
	super._ready()
	# Sync shadow state with base state initial value
	_boss_state = BossState.CHASING


# ---------------------------------------------------------------------------
# Stats loader
# ---------------------------------------------------------------------------

func _load_stats() -> void:
	var data: Dictionary = _get_enemy_data("boss_knight")
	if data.is_empty():
		push_error("BossKnight: could not load stats from enemies.json")
		max_hp = 350.0
		move_speed = 100.0
		attack_damage = 25.0
		attack_range = 60.0
		attack_cooldown = 1.0
		_base_attack_cooldown = 1.0
		_base_move_speed = 100.0
		return

	max_hp = float(data.get("hp", 350))
	move_speed = float(data.get("move_speed", 100))
	attack_damage = float(data.get("attack_damage", 25))
	attack_range = float(data.get("attack_range", 60))
	attack_cooldown = float(data.get("attack_cooldown", 1.5))
	_base_attack_cooldown = attack_cooldown
	_base_move_speed = move_speed


# ---------------------------------------------------------------------------
# Physics process override — runs boss-specific state machine
# ---------------------------------------------------------------------------

func _physics_process(delta: float) -> void:
	if _boss_state == BossState.DYING:
		return

	_update_player_reference()
	_check_phase_transition()
	_charge_cooldown_timer -= delta

	match _boss_state:
		BossState.IDLE:
			_process_idle(delta)
		BossState.CHASING:
			_process_chasing_boss(delta)
		BossState.ATTACKING:
			_process_attacking_boss(delta)
		BossState.CHARGING:
			_process_charging(delta)


# ---------------------------------------------------------------------------
# State processors
# ---------------------------------------------------------------------------

func _process_chasing_boss(delta: float) -> void:
	if _player == null or not _is_player_alive:
		_boss_state = BossState.IDLE
		velocity = Vector2.ZERO
		move_and_slide()
		return

	var direction: Vector2 = (_player.global_position - global_position).normalized()
	velocity = direction * move_speed
	move_and_slide()

	# Phase 2+ can initiate a charge when cooldown has elapsed
	if current_phase >= 2 and _charge_cooldown_timer <= 0.0:
		_begin_charge()


func _process_attacking_boss(delta: float) -> void:
	if _player == null or not _is_player_alive:
		_boss_state = BossState.IDLE
		return

	velocity = Vector2.ZERO
	move_and_slide()

	_attack_timer -= delta
	if _attack_timer <= 0.0:
		_perform_attack()
		_attack_timer = attack_cooldown


func _process_charging(delta: float) -> void:
	_charge_timer -= delta
	velocity = _charge_direction * move_speed * CHARGE_SPEED_MULT
	move_and_slide()

	# Check for player contact during charge
	if _player != null and not _has_hit_player_this_charge:
		var dist: float = global_position.distance_to(_player.global_position)
		if dist <= attack_range:
			_has_hit_player_this_charge = true
			# Deliver damage through the player's take_damage method so armor
			# absorbs correctly and player_hit signal fires via the player itself.
			if is_instance_valid(_player) and _player.has_method("take_damage"):
				_player.take_damage(int(CHARGE_DAMAGE))

	if _charge_timer <= 0.0:
		_end_charge()


# ---------------------------------------------------------------------------
# Phase management
# ---------------------------------------------------------------------------

## Called every physics frame. Checks HP percentage and triggers phase changes.
func _check_phase_transition() -> void:
	var hp_pct: float = hp / max_hp

	var new_phase: int = current_phase
	if hp_pct > PHASE_2_THRESHOLD:
		new_phase = 1
	elif hp_pct > PHASE_3_THRESHOLD:
		new_phase = 2
	else:
		new_phase = 3

	if new_phase != current_phase:
		_enter_phase(new_phase)


func _enter_phase(phase: int) -> void:
	current_phase = phase
	EventBus.boss_phase_changed.emit(phase)

	match phase:
		2:
			# Faster attacks
			attack_cooldown = _base_attack_cooldown * PHASE_2_COOLDOWN_MULT
			# Reset charge cooldown so a charge can happen soon
			_charge_cooldown_timer = 1.0
		3:
			# Enraged: 30% faster movement
			move_speed = _base_move_speed * (1.0 + PHASE_3_SPEED_BONUS)
			attack_cooldown = _base_attack_cooldown * PHASE_2_COOLDOWN_MULT


# ---------------------------------------------------------------------------
# Charge logic
# ---------------------------------------------------------------------------

func _begin_charge() -> void:
	if _player == null:
		return
	_boss_state = BossState.CHARGING
	_charge_direction = (global_position - _player.global_position).normalized() * -1.0
	_charge_timer = CHARGE_DURATION_SEC
	_has_hit_player_this_charge = false
	_charge_cooldown_timer = CHARGE_COOLDOWN_SEC


func _end_charge() -> void:
	velocity = Vector2.ZERO
	_boss_state = BossState.CHASING


# ---------------------------------------------------------------------------
# Attack override — Phase 3 optionally applies slow via curse
# ---------------------------------------------------------------------------

func _on_attack() -> void:
	if current_phase == 3 and RunManager.active_curses.has("weighted_chains"):
		# Weighted Chains is active — the attack signal carries the slow via
		# a card_effect_triggered event that the player listens for.
		# Value 1.0 signals "apply slow this hit".
		EventBus.card_effect_triggered.emit("boss_slow_hit", 1.0)


# ---------------------------------------------------------------------------
# Area2D callbacks — reroute to boss state machine
# ---------------------------------------------------------------------------

func _on_attack_area_body_entered(body: Node2D) -> void:
	if body.is_in_group(GROUP_PLAYER) and _is_player_alive:
		_boss_state = BossState.ATTACKING
		_attack_timer = 0.0


func _on_attack_area_body_exited(body: Node2D) -> void:
	if body.is_in_group(GROUP_PLAYER):
		if _boss_state == BossState.ATTACKING:
			_boss_state = BossState.CHASING


# ---------------------------------------------------------------------------
# Death — override to use _boss_state
# ---------------------------------------------------------------------------

func die() -> void:
	if _boss_state == BossState.DYING:
		return
	_boss_state = BossState.DYING
	velocity = Vector2.ZERO
	EventBus.enemy_died.emit(global_position, enemy_type)
	queue_free()


# ---------------------------------------------------------------------------
# take_damage — override to call die() from this class
# ---------------------------------------------------------------------------

func take_damage(amount: float) -> void:
	if _boss_state == BossState.DYING:
		return
	hp -= amount
	if hp <= 0.0:
		die()


# ---------------------------------------------------------------------------
# EventBus
# ---------------------------------------------------------------------------

func _on_player_died() -> void:
	_is_player_alive = false
	_boss_state = BossState.IDLE
	velocity = Vector2.ZERO


# ---------------------------------------------------------------------------
# Helper — find enemy data in GameData by id
# ---------------------------------------------------------------------------

func _get_enemy_data(id: String) -> Dictionary:
	for entry: Variant in GameData.enemies:
		if entry is Dictionary and entry.get("id", "") == id:
			return entry
	return {}
