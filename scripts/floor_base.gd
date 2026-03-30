extends Node2D
## VAULTED — Floor Base
##
## Procedurally generates a 20x15 isometric grid of ColorRect tiles in _ready().
## Exposes spawn positions for player and enemies via Marker2D children.
## Does not handle wave logic — that belongs to FloorController.

class_name FloorBase

# ---------------------------------------------------------------------------
# Constants
# ---------------------------------------------------------------------------

## Grid dimensions
const GRID_COLS: int = 20
const GRID_ROWS: int = 15

## Isometric tile pixel dimensions (baseline.md: 64x32)
const TILE_WIDTH: int = 64
const TILE_HEIGHT: int = 32

## Tile color: ash grey (placeholder art)
const TILE_COLOR: Color = Color(0.4, 0.4, 0.4)

## Slight edge tint so tiles are visually distinct from one another
const TILE_EDGE_COLOR: Color = Color(0.35, 0.35, 0.35)


# ---------------------------------------------------------------------------
# Node references (set up via _ready, not @onready — generated dynamically)
# ---------------------------------------------------------------------------

var _tile_container: Node2D
var _player_spawn: Marker2D
var _enemy_spawns: Array[Marker2D] = []


# ---------------------------------------------------------------------------
# Lifecycle
# ---------------------------------------------------------------------------

func _ready() -> void:
	_build_tile_grid()
	_collect_spawn_markers()


# ---------------------------------------------------------------------------
# Tile generation
# ---------------------------------------------------------------------------

func _build_tile_grid() -> void:
	_tile_container = Node2D.new()
	_tile_container.name = "TileContainer"
	add_child(_tile_container)

	for row: int in range(GRID_ROWS):
		for col: int in range(GRID_COLS):
			_create_tile(col, row)


func _create_tile(col: int, row: int) -> void:
	# Isometric screen position
	# x = (col - row) * half_tile_width
	# y = (col + row) * quarter_tile_height
	var screen_x: float = float(col - row) * (TILE_WIDTH / 2.0)
	var screen_y: float = float(col + row) * (TILE_HEIGHT / 2.0)

	var tile: ColorRect = ColorRect.new()
	tile.size = Vector2(TILE_WIDTH, TILE_HEIGHT)
	# Offset so the tile's top-left corner sits at the computed isometric position
	tile.position = Vector2(screen_x - TILE_WIDTH / 2.0, screen_y)
	tile.color = TILE_COLOR

	# Alternate even/odd tile tint for visual readability
	if (col + row) % 2 == 1:
		tile.color = TILE_EDGE_COLOR

	_tile_container.add_child(tile)


# ---------------------------------------------------------------------------
# Spawn point access
# ---------------------------------------------------------------------------

## Returns the world position of the player spawn marker.
## Falls back to scene center if no PlayerSpawn marker exists.
func get_player_spawn() -> Vector2:
	if _player_spawn != null:
		return _player_spawn.global_position
	# Sensible default: isometric center of the 20x15 grid
	var cx: float = float(GRID_COLS / 2 - GRID_ROWS / 2) * (TILE_WIDTH / 2.0)
	var cy: float = float(GRID_COLS / 2 + GRID_ROWS / 2) * (TILE_HEIGHT / 2.0)
	return Vector2(cx, cy)


## Returns all enemy spawn marker positions as a typed array.
func get_enemy_spawns() -> Array[Vector2]:
	var positions: Array[Vector2] = []
	for marker: Marker2D in _enemy_spawns:
		positions.append(marker.global_position)
	return positions


# ---------------------------------------------------------------------------
# Internal helpers
# ---------------------------------------------------------------------------

func _collect_spawn_markers() -> void:
	_player_spawn = get_node_or_null("PlayerSpawn") as Marker2D

	for child: Node in get_children():
		if child is Marker2D and child.name != &"PlayerSpawn":
			if child.name.begins_with("EnemySpawn"):
				_enemy_spawns.append(child as Marker2D)
