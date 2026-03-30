extends Node2D
## VAULTED — Damage Number
##
## Floating label that pops up at a world position, drifts upward, and fades
## out over FLOAT_DURATION seconds before freeing itself.
## Spawned by player.gd (damage to player → red) and enemy_base.gd (damage to
## enemy → white). Call setup() immediately after adding to the scene tree.

class_name DamageNumber

# ---------------------------------------------------------------------------
# Constants
# ---------------------------------------------------------------------------

const FLOAT_DURATION: float = 0.8
const FLOAT_DISTANCE: float = 50.0
const COLOR_ENEMY_DAMAGE: Color = Color(1.0, 1.0, 1.0)
const COLOR_PLAYER_DAMAGE: Color = Color(0.9, 0.15, 0.15)

# ---------------------------------------------------------------------------
# Node references
# ---------------------------------------------------------------------------

@onready var _label: Label = $Label

# ---------------------------------------------------------------------------
# Lifecycle
# ---------------------------------------------------------------------------

func _ready() -> void:
	# Guard: if setup() was not called before _ready, use defaults
	if not _label.text:
		_label.text = "0"


# ---------------------------------------------------------------------------
# Public API
# ---------------------------------------------------------------------------

## Configure this damage number before adding it to the scene, or call
## immediately after add_child. `is_player_damage` = true → red color.
func setup(amount: int, is_player_damage: bool = false) -> void:
	# Ensure _label is resolved before we touch it.
	# If the node is not yet ready (called before add_child), wait for it.
	# If already ready, continue immediately — awaiting an already-emitted
	# signal would hang forever.
	if not is_node_ready():
		await ready

	_label.text = str(amount)
	_label.add_theme_color_override(&"font_color",
		COLOR_PLAYER_DAMAGE if is_player_damage else COLOR_ENEMY_DAMAGE)
	_label.add_theme_font_size_override(&"font_size", 18)

	_animate()


# ---------------------------------------------------------------------------
# Animation
# ---------------------------------------------------------------------------

func _animate() -> void:
	var tween: Tween = create_tween()
	tween.set_parallel(true)

	# Float upward
	tween.tween_property(
		self, "position",
		position + Vector2(0.0, -FLOAT_DISTANCE),
		FLOAT_DURATION
	).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

	# Fade out modulate alpha
	tween.tween_property(
		self, "modulate:a",
		0.0,
		FLOAT_DURATION
	).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)

	tween.chain().tween_callback(queue_free)
