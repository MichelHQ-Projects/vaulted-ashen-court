extends Node
## VAULTED — Card Effect Base
## Base class for all card effects. Extends Node so effects can connect to signals
## and are owned by CardManager's effect container node (added as children).
## Subclasses override _setup() and _teardown() for effect-specific logic.

class_name CardEffectBase

# ---------------------------------------------------------------------------
# State
# ---------------------------------------------------------------------------

var card_id: String = ""
var card_data: Dictionary = {}
var is_active: bool = false


# ---------------------------------------------------------------------------
# Public API
# ---------------------------------------------------------------------------

## Called by CardManager when a card is picked. Stores data and calls _setup().
func activate(data: Dictionary) -> void:
	card_data = data
	card_id = data.get("id", "")
	is_active = true
	_setup()


## Called by CardManager on run reset. Calls _teardown() then removes from tree.
func deactivate() -> void:
	is_active = false
	_teardown()
	queue_free()


# ---------------------------------------------------------------------------
# Virtual interface — override in subclasses
# ---------------------------------------------------------------------------

## Called once when the card is activated. Wire up signals and read card_data here.
func _setup() -> void:
	pass


## Called when the card is deactivated (run reset). Disconnect signals here.
func _teardown() -> void:
	pass
