extends Node2D
## VAULTED — Game Scene Orchestrator
##
## Top-level scene script. Responsible for:
##   - Calling RunManager.start_run() at startup
##   - Loading and instantiating the floor scene into FloorContainer
##   - Spawning the player at the floor's PlayerSpawn point
##   - Smooth Camera2D follow on the player
##   - Handling floor_cleared → card pick screen → advance floor
##   - Handling player_died → death screen

class_name GameController

# ---------------------------------------------------------------------------
# Constants
# ---------------------------------------------------------------------------

## Camera lerp weight (0–1). Higher = snappier follow.
const CAMERA_LERP: float = 6.0

## Packed scenes — loaded once, instantiated per floor
const FLOOR_SCENE_PATH: String = "res://scenes/floors/floor_base.tscn"
const PLAYER_SCENE_PATH: String = "res://scenes/player/player.tscn"

## UI scene paths
const HUD_SCENE_PATH: String = "res://scenes/ui/hud.tscn"
const CARD_PICK_SCENE_PATH: String = "res://scenes/ui/card_pick.tscn"
const DEATH_SCREEN_SCENE_PATH: String = "res://scenes/ui/death_screen.tscn"

# ---------------------------------------------------------------------------
# Node references
# ---------------------------------------------------------------------------

@onready var _floor_container: Node2D = $FloorContainer
@onready var _camera: Camera2D = $Camera2D
@onready var _ui_layer: CanvasLayer = $UILayer

# ---------------------------------------------------------------------------
# Runtime
# ---------------------------------------------------------------------------

var _player: CharacterBody2D = null
var _floor_scene: PackedScene = null
var _player_scene: PackedScene = null

var _hud: Node = null
var _card_pick: Node = null
var _death_screen: Node = null

## Active FloorController — owns wave spawning for the current floor.
var _floor_controller: FloorController = null

# ---------------------------------------------------------------------------
# Lifecycle
# ---------------------------------------------------------------------------

func _ready() -> void:
	_floor_scene = load(FLOOR_SCENE_PATH)
	_player_scene = load(PLAYER_SCENE_PATH)

	# --- Instantiate and add UI screens ---
	var hud_scene: PackedScene = load(HUD_SCENE_PATH)
	_hud = hud_scene.instantiate()
	_ui_layer.add_child(_hud)

	var card_pick_scene: PackedScene = load(CARD_PICK_SCENE_PATH)
	_card_pick = card_pick_scene.instantiate()
	_ui_layer.add_child(_card_pick)

	var death_screen_scene: PackedScene = load(DEATH_SCREEN_SCENE_PATH)
	_death_screen = death_screen_scene.instantiate()
	_ui_layer.add_child(_death_screen)

	# --- Connect EventBus signals ---
	EventBus.player_died.connect(_on_player_died)
	EventBus.floor_cleared.connect(_on_floor_cleared)
	EventBus.card_picked.connect(_on_card_picked)

	RunManager.start_run()
	_load_floor()


func _process(delta: float) -> void:
	_follow_player(delta)


# ---------------------------------------------------------------------------
# Floor management
# ---------------------------------------------------------------------------

func _load_floor() -> void:
	# Tear down previous FloorController before clearing floor nodes
	if _floor_controller != null and is_instance_valid(_floor_controller):
		_floor_controller.queue_free()
		_floor_controller = null

	# Clear any existing floor
	for child: Node in _floor_container.get_children():
		child.queue_free()

	var floor_instance: Node2D = _floor_scene.instantiate() as Node2D
	_floor_container.add_child(floor_instance)

	# Spawn player at the floor's designated spawn point
	var spawn_pos: Vector2 = Vector2.ZERO
	if floor_instance.has_method("get_player_spawn"):
		spawn_pos = floor_instance.call("get_player_spawn") as Vector2

	_spawn_player(spawn_pos)

	# --- Create and start the FloorController for this floor ---
	_floor_controller = FloorController.new()
	_floor_controller.name = "FloorController"
	add_child(_floor_controller)

	# Feed enemy spawn positions from the floor scene if available
	if floor_instance.has_method("get_enemy_spawns"):
		var enemy_spawns: Array = floor_instance.call("get_enemy_spawns")
		if not enemy_spawns.is_empty():
			_floor_controller.set_spawn_points(enemy_spawns)

	# One-frame deferred start so the player node is fully in the tree
	_floor_controller.call_deferred("start_floor", RunManager.current_floor)


func _spawn_player(at_position: Vector2) -> void:
	# Remove any previous player instance
	if _player != null and is_instance_valid(_player):
		_player.queue_free()
		_player = null

	_player = _player_scene.instantiate() as CharacterBody2D
	_player.global_position = at_position
	add_child(_player)

	# Snap camera to player immediately on spawn (no lerp lag on first frame)
	if _camera != null:
		_camera.global_position = at_position


# ---------------------------------------------------------------------------
# Camera
# ---------------------------------------------------------------------------

func _follow_player(delta: float) -> void:
	if _player == null or not is_instance_valid(_player):
		return
	if _camera == null:
		return
	_camera.global_position = _camera.global_position.lerp(
		_player.global_position,
		CAMERA_LERP * delta
	)


# ---------------------------------------------------------------------------
# EventBus handlers
# ---------------------------------------------------------------------------

func _on_floor_cleared(_floor_number: int) -> void:
	# Show card pick screen; floor advancement happens after card is chosen
	if _card_pick != null and _card_pick.has_method("show_cards"):
		_card_pick.show_cards()


func _on_card_picked(_card_id: String) -> void:
	# Card has been picked — advance the floor and load the next one
	RunManager.advance_floor()
	_load_floor()
	# Refresh HUD stat bars — armor resets between floors
	if _hud != null and _hud.has_method("refresh_player_stats"):
		_hud.call_deferred("refresh_player_stats")


func _on_player_died() -> void:
	RunManager.deaths += 1
	if _death_screen != null and _death_screen.has_method("show_death"):
		_death_screen.show_death()
