extends Node
## VAULTED — Card Manager (Autoload)
## Manages the card pool, offers cards during floor-cleared pick phase, activates
## card effects as Node children, and resets on new run.
##
## Card effects are added as Node children of _effect_container so they can
## connect to signals and access the scene tree without being RefCounted.

# ---------------------------------------------------------------------------
# State
# ---------------------------------------------------------------------------

## Full card pool loaded from GameData at startup.
var card_pool: Array = []

## Cards active in the current run (Array of card_id strings).
var active_cards: Array[String] = []

## Container node that holds all active card effect nodes.
var _effect_container: Node = null


# ---------------------------------------------------------------------------
# Lifecycle
# ---------------------------------------------------------------------------

func _ready() -> void:
	_effect_container = Node.new()
	_effect_container.name = "CardEffects"
	add_child(_effect_container)

	# Wait one frame so GameData has finished loading its JSON files.
	await get_tree().process_frame
	card_pool = GameData.cards.duplicate()


# ---------------------------------------------------------------------------
# Public API
# ---------------------------------------------------------------------------

## Return an array of up to `count` card data Dictionaries to offer the player.
## Excludes already-active cards. Uses RunManager.rng for seeded randomness.
func offer_cards(count: int = 3) -> Array:
	var available: Array = []
	for card: Variant in card_pool:
		if card is Dictionary:
			var card_id: String = card.get("id", "")
			if card_id != "" and not active_cards.has(card_id):
				available.append(card)

	# Fisher-Yates shuffle using seeded RNG
	for i: int in range(available.size() - 1, 0, -1):
		var j: int = RunManager.rng.randi_range(0, i)
		var temp: Variant = available[i]
		available[i] = available[j]
		available[j] = temp

	return available.slice(0, min(count, available.size()))


## Called when the player picks a card from the offer screen.
## Activates the effect immediately and updates run state.
func pick_card(card_id: String) -> void:
	if active_cards.has(card_id):
		push_warning("CardManager: card already active — " + card_id)
		return

	var card_data: Dictionary = _find_card_data(card_id)
	if card_data.is_empty():
		push_error("CardManager: unknown card id — " + card_id)
		return

	active_cards.append(card_id)
	RunManager.active_cards.append(card_id)
	activate_card(card_data)
	EventBus.card_picked.emit(card_id)


## Instantiate and activate the effect node for a card.
func activate_card(card_data: Dictionary) -> void:
	var effect: CardEffectBase = _get_effect_for_card(card_data.get("id", ""))
	_effect_container.add_child(effect)
	effect.activate(card_data)


## Wipe all active cards and destroy effect nodes. Called at run start.
func reset() -> void:
	active_cards.clear()
	# Deactivate all effect nodes (they queue_free themselves in deactivate())
	for child: Node in _effect_container.get_children():
		if child is CardEffectBase:
			(child as CardEffectBase).deactivate()


# ---------------------------------------------------------------------------
# Private helpers
# ---------------------------------------------------------------------------

## Find a card dictionary from the pool by id.
func _find_card_data(card_id: String) -> Dictionary:
	for card: Variant in card_pool:
		if card is Dictionary and card.get("id", "") == card_id:
			return card
	return {}


## Factory — return the appropriate CardEffectBase subclass for a card id.
## Add new card effect classes here as they are implemented.
func _get_effect_for_card(card_id: String) -> CardEffectBase:
	match card_id:
		"iron_echo":
			return IronEchoEffect.new()
		_:
			# Fallback: base class activates but does nothing
			return CardEffectBase.new()
