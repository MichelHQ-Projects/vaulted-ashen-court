extends Node
## VAULTED — Run Manager
##
## Tracks all persistent run state: floor number, active cards and curses,
## kill/death/synergy counters, and the seeded RNG instance.
## All scoring math lives here. Connects to EventBus to track enemy kills.

# ---------------------------------------------------------------------------
# Run state
# ---------------------------------------------------------------------------

var rng: RandomNumberGenerator = RandomNumberGenerator.new()

var current_floor: int = 0
var active_cards: Array[String] = []
var active_curses: Array[String] = []
var score: int = 0
var enemies_killed: int = 0
var known_synergies: int = 0
var deaths: int = 0


# ---------------------------------------------------------------------------
# Lifecycle
# ---------------------------------------------------------------------------

func _ready() -> void:
	EventBus.enemy_died.connect(_on_enemy_died)


# ---------------------------------------------------------------------------
# Public API
# ---------------------------------------------------------------------------

## Start a fresh run. Seeds RNG from wall-clock time.
## Call this once when the player begins a new run.
func start_run() -> void:
	var seed_value: int = Time.get_unix_time_from_system()
	rng.seed = seed_value
	reset_run()
	current_floor = 1


## Wipe all mutable run state back to defaults.
## Called by start_run(); may also be called directly on clean-restart flows.
func reset_run() -> void:
	current_floor = 0
	active_cards = []
	active_curses = []
	score = 0
	enemies_killed = 0
	known_synergies = 0
	deaths = 0


## Increment the floor counter. Called by game.gd when transitioning floors.
func advance_floor() -> void:
	current_floor += 1


## Calculate and return the current score.
## Formula (baseline.md):
##   (Floors Cleared x Enemies Killed) x (1 + Active Curses x 0.5)
##   + (Known Synergy Combos x 100) - (Deaths x 500)
func get_score() -> int:
	var curse_multiplier: float = 1.0 + active_curses.size() * 0.5
	var base: int = current_floor * enemies_killed
	var calculated: float = float(base) * curse_multiplier
	calculated += float(known_synergies * 100)
	calculated -= float(deaths * 500)
	score = int(calculated)
	return score


# ---------------------------------------------------------------------------
# Signal handlers
# ---------------------------------------------------------------------------

func _on_enemy_died(_position: Vector2, _enemy_type: String) -> void:
	enemies_killed += 1
