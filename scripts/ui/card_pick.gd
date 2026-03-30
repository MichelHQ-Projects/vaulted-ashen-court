extends CanvasLayer
## VAULTED — Card Pick Screen
##
## Modal overlay shown after a floor is cleared.
## Displays 3 card offers; player clicks one to pick it.
## Pauses the game tree while visible; this node runs in PROCESS_MODE_ALWAYS.

class_name CardPickScreen

# ---------------------------------------------------------------------------
# Color constants — card border by type
# ---------------------------------------------------------------------------

const COLOR_AUGMENT_BORDER: Color = Color(0.25, 0.45, 0.85)
const COLOR_MUTATION_BORDER: Color = Color(0.55, 0.2, 0.85)
const COLOR_COVENANT_BORDER: Color = Color(0.85, 0.2, 0.2)
const COLOR_CARD_BG: Color = Color(0.3, 0.3, 0.35)
const COLOR_PARCHMENT: Color = Color(0.9, 0.85, 0.7)
const COLOR_OVERLAY: Color = Color(0.0, 0.0, 0.0, 0.7)
const COLOR_TYPE_LABEL: Color = Color(0.65, 0.6, 0.5)

const BORDER_THICKNESS: float = 3.0

# ---------------------------------------------------------------------------
# Node references
# ---------------------------------------------------------------------------

@onready var _overlay: ColorRect = $Overlay
@onready var _card_container: HBoxContainer = $CenterContainer/CardContainer

# ---------------------------------------------------------------------------
# Lifecycle
# ---------------------------------------------------------------------------

func _ready() -> void:
	# This scene must run even when the game is paused
	process_mode = Node.PROCESS_MODE_ALWAYS
	# Start hidden — shown on demand
	visible = false


# ---------------------------------------------------------------------------
# Public API
# ---------------------------------------------------------------------------

## Show the card pick screen with 3 offered cards. Pauses the game.
func show_cards() -> void:
	_clear_cards()
	var offered: Array = CardManager.offer_cards(3)
	for card_data: Variant in offered:
		if card_data is Dictionary:
			_build_card_panel(card_data)
	visible = true
	get_tree().paused = true


## Hide the screen and unpause.
func hide_cards() -> void:
	visible = false
	get_tree().paused = false


# ---------------------------------------------------------------------------
# Card panel builder
# ---------------------------------------------------------------------------

func _clear_cards() -> void:
	for child: Node in _card_container.get_children():
		child.queue_free()


func _build_card_panel(card_data: Dictionary) -> void:
	var card_id: String = card_data.get("id", "")
	var card_name: String = card_data.get("name", card_id)
	var card_type: String = card_data.get("type", "augment")
	var description: String = card_data.get("description", "")

	# --- Outer panel (acts as border by being slightly larger than inner) ---
	var border_panel: PanelContainer = PanelContainer.new()
	var border_style: StyleBoxFlat = StyleBoxFlat.new()
	border_style.bg_color = _get_border_color(card_type)
	border_style.corner_radius_top_left = 6
	border_style.corner_radius_top_right = 6
	border_style.corner_radius_bottom_left = 6
	border_style.corner_radius_bottom_right = 6
	border_panel.add_theme_stylebox_override(&"panel", border_style)
	border_panel.custom_minimum_size = Vector2(200.0, 280.0)

	# --- Inner card face ---
	var inner_panel: PanelContainer = PanelContainer.new()
	var inner_style: StyleBoxFlat = StyleBoxFlat.new()
	inner_style.bg_color = COLOR_CARD_BG
	inner_style.corner_radius_top_left = 4
	inner_style.corner_radius_top_right = 4
	inner_style.corner_radius_bottom_left = 4
	inner_style.corner_radius_bottom_right = 4
	inner_style.content_margin_left = 12.0
	inner_style.content_margin_right = 12.0
	inner_style.content_margin_top = 10.0
	inner_style.content_margin_bottom = 10.0
	inner_panel.add_theme_stylebox_override(&"panel", inner_style)

	# Margins so the border shows
	var margin: MarginContainer = MarginContainer.new()
	margin.add_theme_constant_override(&"margin_left", int(BORDER_THICKNESS))
	margin.add_theme_constant_override(&"margin_right", int(BORDER_THICKNESS))
	margin.add_theme_constant_override(&"margin_top", int(BORDER_THICKNESS))
	margin.add_theme_constant_override(&"margin_bottom", int(BORDER_THICKNESS))
	margin.add_child(inner_panel)
	border_panel.add_child(margin)

	# --- Content VBox ---
	var vbox: VBoxContainer = VBoxContainer.new()
	vbox.add_theme_constant_override(&"separation", 8)
	inner_panel.add_child(vbox)

	# Card name
	var name_lbl: Label = Label.new()
	name_lbl.text = card_name
	name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	name_lbl.add_theme_color_override(&"font_color", COLOR_PARCHMENT)
	name_lbl.add_theme_font_size_override(&"font_size", 16)
	vbox.add_child(name_lbl)

	# Separator line
	var sep: HSeparator = HSeparator.new()
	vbox.add_child(sep)

	# Type label with rune color indicator
	var type_lbl: Label = Label.new()
	type_lbl.text = card_type.capitalize()
	type_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	type_lbl.add_theme_color_override(&"font_color", _get_border_color(card_type))
	type_lbl.add_theme_font_size_override(&"font_size", 12)
	vbox.add_child(type_lbl)

	# Spacer
	var spacer: Control = Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(spacer)

	# Description
	var desc_lbl: Label = Label.new()
	desc_lbl.text = description
	desc_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	desc_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc_lbl.add_theme_color_override(&"font_color", COLOR_PARCHMENT)
	desc_lbl.add_theme_font_size_override(&"font_size", 13)
	vbox.add_child(desc_lbl)

	# Spacer
	var spacer2: Control = Control.new()
	spacer2.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(spacer2)

	# Pick button
	var btn: Button = Button.new()
	btn.text = "Pick"
	btn.add_theme_color_override(&"font_color", COLOR_PARCHMENT)
	var btn_style: StyleBoxFlat = StyleBoxFlat.new()
	btn_style.bg_color = _get_border_color(card_type).darkened(0.3)
	btn_style.corner_radius_top_left = 4
	btn_style.corner_radius_top_right = 4
	btn_style.corner_radius_bottom_left = 4
	btn_style.corner_radius_bottom_right = 4
	btn_style.content_margin_left = 8.0
	btn_style.content_margin_right = 8.0
	btn_style.content_margin_top = 6.0
	btn_style.content_margin_bottom = 6.0
	btn.add_theme_stylebox_override(&"normal", btn_style)
	# Capture card_id in closure
	var captured_id: String = card_id
	btn.pressed.connect(func() -> void: _on_card_picked(captured_id))
	vbox.add_child(btn)

	_card_container.add_child(border_panel)


func _get_border_color(card_type: String) -> Color:
	match card_type:
		"augment":
			return COLOR_AUGMENT_BORDER
		"mutation":
			return COLOR_MUTATION_BORDER
		"covenant":
			return COLOR_COVENANT_BORDER
		_:
			return COLOR_PARCHMENT


# ---------------------------------------------------------------------------
# Pick handler
# ---------------------------------------------------------------------------

func _on_card_picked(card_id: String) -> void:
	CardManager.pick_card(card_id)
	# CardManager.pick_card() already emits EventBus.card_picked
	hide_cards()
