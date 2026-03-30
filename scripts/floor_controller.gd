extends Node
## VAULTED — Floor Controller
## Drives floor progression: loads floor data, delegates wave spawning to
## WaveSpawner (normal floors) or spawns a boss directly (boss floors).
## Applies Weighted Chains curse every 3rd floor via the curse economy.
##
## Attach this node to the game scene or floor scene root.
## Call start_floor(floor_number) to begin a floor.

class_name FloorController

# ---------------------------------------------------------------------------
# Default spawn point offset — used when no explicit spawn positions are set.
# The game scene should call set_spawn_points() before start_floor().
# ---------------------------------------------------------------------------

const DEFAULT_SPAWN_RADIUS: float = 300.0
const DEFAULT_SPAWN_COUNT: int = 8

# Boss scene paths by boss_id
const BOSS_SCENES: Dictionary = {
	"boss_knight": "res://scenes/enemies/boss_knight.tscn",
}

# ---------------------------------------------------------------------------
# State
# ---------------------------------------------------------------------------

var wave_spawner: WaveSpawner = null
var is_boss_floor: bool = false
var _current_floor_number: int = 0
var _spawn_points: Array = []   # Array[Vector2]


# ---------------------------------------------------------------------------
# Lifecycle
# ---------------------------------------------------------------------------

func _ready() -> void:
	wave_spawner = WaveSpawner.new()
	wave_spawner.name = "WaveSpawner"
	add_child(wave_spawner)

	EventBus.floor_cleared.connect(_on_floor_cleared)


# ---------------------------------------------------------------------------
# Public API
# ---------------------------------------------------------------------------

## Provide explicit spawn positions. If not called, default circle positions
## centred on (0, 0) are generated.
func set_spawn_points(points: Array) -> void:
	_spawn_points = points


## Begin the given floor number. Reads floor data from GameData.floors.
func start_floor(floor_number: int) -> void:
	_current_floor_number = floor_number
	RunManager.current_floor = floor_number

	var floor_data: Dictionary = _get_floor_data(floor_number)
	if floor_data.is_empty():
		push_error("FloorController: no floor data for floor " + str(floor_number))
		return

	is_boss_floor = floor_data.get("is_boss", false)

	if _spawn_points.is_empty():
		_spawn_points = _generate_default_spawn_points()

	if is_boss_floor:
		_start_boss_floor(floor_data)
	else:
		_start_normal_floor(floor_data)


# ---------------------------------------------------------------------------
# Floor startup
# ---------------------------------------------------------------------------

func _start_normal_floor(floor_data: Dictionary) -> void:
	wave_spawner.setup(floor_data, _spawn_points)
	wave_spawner.start_spawning()


func _start_boss_floor(floor_data: Dictionary) -> void:
	var boss_id: String = floor_data.get("boss_id", "")
	if boss_id == "":
		push_error("FloorController: boss floor has no boss_id")
		return

	var path: String = BOSS_SCENES.get(boss_id, "") as String
	if path == "":
		push_error("FloorController: no scene path registered for boss '" + boss_id + "'")
		return

	var packed: PackedScene = load(path) as PackedScene
	if packed == null:
		push_error("FloorController: failed to load boss scene at '" + path + "'")
		return

	var boss: Node = packed.instantiate()
	get_tree().current_scene.add_child(boss)

	# Place boss at centre of the floor
	if boss is Node2D:
		(boss as Node2D).global_position = Vector2.ZERO

	EventBus.enemy_spawned.emit(boss.get_instance_id())

	# Wave 1 signal so the HUD knows a fight has started
	EventBus.wave_started.emit(1)


# ---------------------------------------------------------------------------
# EventBus handlers
# ---------------------------------------------------------------------------

func _on_floor_cleared(floor_number: int) -> void:
	if floor_number != _current_floor_number:
		return

	# Curse economy — apply Weighted Chains every 3rd floor
	if floor_number % 3 == 0:
		_apply_weighted_chains_curse()

	# floor_cleared signal is also consumed by the HUD to show the card pick
	# screen (EventBus.floor_cleared → UI shows card_pick.tscn).
	# After the player picks a card (EventBus.card_picked), the game scene
	# calls advance_floor() and start_floor(next_floor).


# ---------------------------------------------------------------------------
# Curse application
# ---------------------------------------------------------------------------

## Apply the Weighted Chains curse: reduce move_speed on the player by 15%.
## The player script must listen for EventBus.curse_applied("weighted_chains")
## and apply the modifier itself — FloorController does not touch player nodes.
func _apply_weighted_chains_curse() -> void:
	# Guard: don't apply the same curse twice in the same run
	if RunManager.active_curses.has("weighted_chains"):
		return

	var curse_data: Dictionary = _find_curse_data("weighted_chains")
	if curse_data.is_empty():
		push_error("FloorController: weighted_chains not found in GameData.curses")
		return

	RunManager.active_curses.append("weighted_chains")
	EventBus.curse_applied.emit("weighted_chains")


# ---------------------------------------------------------------------------
# Data helpers
# ---------------------------------------------------------------------------

## Retrieve floor data from GameData.floors by 1-based floor_number index.
## Floor 1 → index 0, floor 2 → index 1, etc. Wraps if index exceeds array.
func _get_floor_data(floor_number: int) -> Dictionary:
	if GameData.floors.is_empty():
		return {}
	var index: int = (floor_number - 1) % GameData.floors.size()
	var entry: Variant = GameData.floors[index]
	return entry if entry is Dictionary else {}


func _find_curse_data(curse_id: String) -> Dictionary:
	for entry: Variant in GameData.curses:
		if entry is Dictionary and entry.get("id", "") == curse_id:
			return entry
	return {}


## Generate a ring of spawn positions around the origin when none are set.
func _generate_default_spawn_points() -> Array:
	var points: Array = []
	for i: int in range(DEFAULT_SPAWN_COUNT):
		var angle: float = (TAU / DEFAULT_SPAWN_COUNT) * i
		points.append(Vector2(cos(angle), sin(angle)) * DEFAULT_SPAWN_RADIUS)
	return points
