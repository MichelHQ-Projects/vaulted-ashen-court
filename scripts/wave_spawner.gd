extends Node
## VAULTED — Wave Spawner
## Handles enemy spawning across waves within a single floor.
## Reads floor data from GameData, staggers spawns using timers, tracks
## living enemies, and emits EventBus signals when waves/floors complete.
##
## Usage:
##   call setup(floor_data, spawn_point_positions)
##   call start_spawning() when the floor begins

class_name WaveSpawner

# ---------------------------------------------------------------------------
# Preloaded scenes — indexed by enemy id string
# ---------------------------------------------------------------------------

const ENEMY_SCENES: Dictionary = {
	"shambler": "res://scenes/enemies/shambler.tscn",
}

const SPAWN_STAGGER_SEC: float = 0.3

# ---------------------------------------------------------------------------
# State
# ---------------------------------------------------------------------------

var current_wave: int = 0
var total_waves: int = 3
var enemies_alive: int = 0
var spawn_points: Array = []     # Array[Vector2]
var floor_data: Dictionary = {}

## Cached PackedScenes keyed by enemy id.
var _loaded_scenes: Dictionary = {}

## Spawn queue used by the stagger timer.
var _pending_spawns: Array = []   # Array[String] — enemy ids to spawn
var _spawn_timer: float = 0.0
var _is_spawning: bool = false

## Flag set when all waves are done and floor_cleared has fired.
var _floor_done: bool = false


# ---------------------------------------------------------------------------
# Lifecycle
# ---------------------------------------------------------------------------

func _ready() -> void:
	EventBus.enemy_died.connect(_on_enemy_died)


func _process(delta: float) -> void:
	if not _is_spawning or _pending_spawns.is_empty():
		return

	_spawn_timer -= delta
	if _spawn_timer <= 0.0:
		_spawn_next_pending()
		_spawn_timer = SPAWN_STAGGER_SEC


# ---------------------------------------------------------------------------
# Public API
# ---------------------------------------------------------------------------

## Configure the spawner before calling start_spawning().
## floor_info — entry from GameData.floors
## spawns     — Array of Vector2 world positions used as spawn points
func setup(floor_info: Dictionary, spawns: Array) -> void:
	floor_data = floor_info
	spawn_points = spawns
	total_waves = int(floor_info.get("wave_count", 3))
	current_wave = 0
	_floor_done = false

	# Preload enemy scenes listed in the floor's enemy_pool
	var pool: Array = floor_info.get("enemy_pool", [])
	for enemy_id: Variant in pool:
		if enemy_id is String:
			_preload_enemy_scene(enemy_id)


## Begin wave progression. Call once when the floor starts.
func start_spawning() -> void:
	if total_waves <= 0:
		push_warning("WaveSpawner: total_waves is 0 — nothing to spawn")
		return
	_start_next_wave()


# ---------------------------------------------------------------------------
# Wave logic
# ---------------------------------------------------------------------------

func _start_next_wave() -> void:
	current_wave += 1
	if current_wave > total_waves:
		# All waves done — floor cleared
		_complete_floor()
		return

	EventBus.wave_started.emit(current_wave)

	var base_count: int = int(floor_data.get("enemy_count_base", 3))
	var scale: int = int(floor_data.get("enemy_count_scale", 2))
	var count: int = base_count + (current_wave - 1) * scale

	var pool: Array = floor_data.get("enemy_pool", [])
	if pool.is_empty():
		push_warning("WaveSpawner: enemy_pool is empty for wave " + str(current_wave))
		_check_wave_complete()
		return

	enemies_alive += count
	_pending_spawns.clear()

	for i: int in range(count):
		# Pick enemy type from pool using seeded RNG
		var idx: int = RunManager.rng.randi_range(0, pool.size() - 1)
		_pending_spawns.append(str(pool[idx]))

	_is_spawning = true
	_spawn_timer = 0.0  # Spawn first one immediately


func _complete_floor() -> void:
	if _floor_done:
		return
	_floor_done = true
	EventBus.floor_cleared.emit(RunManager.current_floor)


## Check whether the current wave is fully defeated. Called when enemies_alive reaches 0.
func _check_wave_complete() -> void:
	if enemies_alive <= 0 and _pending_spawns.is_empty() and not _is_spawning:
		if current_wave >= total_waves:
			_complete_floor()
		else:
			# Pause 1.5 s before the next wave
			await get_tree().create_timer(1.5).timeout
			_start_next_wave()


# ---------------------------------------------------------------------------
# Spawn helpers
# ---------------------------------------------------------------------------

func _spawn_next_pending() -> void:
	if _pending_spawns.is_empty():
		_is_spawning = false
		# Check if all spawned enemies are already dead (edge case: instant kill)
		_check_wave_complete()
		return

	var enemy_id: String = _pending_spawns.pop_front()
	_spawn_enemy(enemy_id)

	if _pending_spawns.is_empty():
		_is_spawning = false


func _spawn_enemy(enemy_id: String) -> void:
	if not _loaded_scenes.has(enemy_id):
		_preload_enemy_scene(enemy_id)

	var packed: PackedScene = _loaded_scenes.get(enemy_id) as PackedScene
	if packed == null:
		push_error("WaveSpawner: no PackedScene for enemy id '" + enemy_id + "'")
		enemies_alive -= 1
		return

	var enemy: Node = packed.instantiate()
	get_tree().current_scene.add_child(enemy)

	# Position at a random spawn point (seeded RNG)
	if not spawn_points.is_empty():
		var point_idx: int = RunManager.rng.randi_range(0, spawn_points.size() - 1)
		if enemy is Node2D:
			(enemy as Node2D).global_position = spawn_points[point_idx]

	EventBus.enemy_spawned.emit(enemy.get_instance_id())


func _preload_enemy_scene(enemy_id: String) -> void:
	if _loaded_scenes.has(enemy_id):
		return
	var path: String = ENEMY_SCENES.get(enemy_id, "") as String
	if path == "":
		push_error("WaveSpawner: no scene path registered for enemy '" + enemy_id + "'")
		return
	var packed: PackedScene = load(path) as PackedScene
	if packed == null:
		push_error("WaveSpawner: failed to load scene at '" + path + "'")
		return
	_loaded_scenes[enemy_id] = packed


# ---------------------------------------------------------------------------
# EventBus handlers
# ---------------------------------------------------------------------------

func _on_enemy_died(_position: Vector2, _enemy_type: String) -> void:
	enemies_alive -= 1
	if enemies_alive < 0:
		enemies_alive = 0

	# Only check for wave completion when the spawn queue is empty
	if _pending_spawns.is_empty() and not _is_spawning:
		_check_wave_complete()
