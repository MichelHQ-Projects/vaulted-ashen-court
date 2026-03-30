extends Node
# VAULTED — Card Manager


func pick_card(card_id: String) -> void:
	EventBus.card_picked.emit(card_id)


func register_environment_hooks(card_id: String) -> void:
	pass
