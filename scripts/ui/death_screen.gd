extends CanvasLayer
## VAULTED — Death Screen
##
## Full-screen overlay shown when the player dies.
## Displays score breakdown, legacy relic selection (UI only — no persistence
## in MVP), and a "Begin New Run" button that reloads the game scene.

class_name DeathScreen

# ---------------------------------------------------------------------------
# Color constants
# ---------------------------------------------------------------------------

const COLOR_PARCHMENT: Color = Color(0.9, 0.85, 0.7)
const COLOR_PANEL_BG: Color = Color(0.06, 0.06, 0.08, 0.95)
const COLOR_TITLE: Color = Color(0.85, 0.2, 0.2)
const COLOR_SCORE_LABEL: Color = Color(0.65, 0.6, 0.5)
const COLOR_RELIC_BG: Color = Color(0.2, 0.18, 0.22)
const COLOR_RELIC_SELECTED: Color = Color(0.55, 0.2, 0.85)

# Legacy relics data — from baseline.md Legacy Relics table
const LEGACY_RELICS: Array[Dictionary] = [
	{
		"id": "ashen_crown",
		"name": "Ashen Crown",
		"effect": "Start every run with 1 extra card pick"
	},
	{
		"id": "unmarked_grave",
		"name": "The Unmarked Grave",
		"effect": "First death per run: revive at 25% HP"
	},
	{
		"id": "blood_memory",
		"name": "Blood Memory",
		"effect": "Covenant held 3+ runs: available from floor 1"
	},
	{
		"id": "void_shard",
		"name": "Void Shard",
		"effect": "Start with Void Hunger curse + Cursed Mirror card"
	},
	{
		"id": "knights_debt",
		"name": "Knight's Debt",
		"effect": "Start at 50% HP, attack damage +40%"
	},
	{
		"id": "hollow_seal",
		"name": "The Hollow Seal",
		"effect": "Armor starts at 0, dodge roll +2 charges"
	},
	{
		"id": "courts_brand",
		"name": "The Court's Brand",
		"effect": "Start with 1 random Curse, score multiplier +0.5x"
	},
	{
		"id": "echo_fragment",
		"name": "Echo Fragment",
		"effect": "Start with Shadow Clone active for floor 1"
	},
]

# ---------------------------------------------------------------------------
# Node references
# ---------------------------------------------------------------------------

@onready var _floors_label: Label = $Panel/VBox/ScoreSection/FloorsLabel
@onready var _kills_label: Label = $Panel/VBox/ScoreSection/KillsLabel
@onready var _curses_label: Label = $Panel/VBox/ScoreSection/CursesLabel
@onready var _total_label: Label = $Panel/VBox/ScoreSection/TotalLabel
@onready var _relic_container: HBoxContainer = $Panel/VBox/RelicSection/RelicContainer
@onready var _new_run_btn: Button = $Panel/VBox/NewRunButton

# ---------------------------------------------------------------------------
# State
# ---------------------------------------------------------------------------

var _selected_relic_id: String = ""

# ---------------------------------------------------------------------------
# Lifecycle
# ---------------------------------------------------------------------------

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false
	_new_run_btn.pressed.connect(_on_new_run_pressed)


# ---------------------------------------------------------------------------
# Public API
# ---------------------------------------------------------------------------

## Show the death screen, populate score data, and pause the game.
func show_death() -> void:
	_populate_score()
	_populate_relics()
	visible = true
	get_tree().paused = true


# ---------------------------------------------------------------------------
# Score display
# ---------------------------------------------------------------------------

func _populate_score() -> void:
	var floors: int = RunManager.current_floor
	var kills: int = RunManager.enemies_killed
	var curse_count: int = RunManager.active_curses.size()
	var total: int = RunManager.get_score()

	_floors_label.text = "Floors Cleared: %d" % floors
	_kills_label.text = "Enemies Killed: %d" % kills
	_curses_label.text = "Curses Carried: %d" % curse_count
	_total_label.text = "Total Score: %d" % total


# ---------------------------------------------------------------------------
# Legacy relic picker (UI only — no persistence in MVP)
# ---------------------------------------------------------------------------

func _populate_relics() -> void:
	# Clear previous
	for child: Node in _relic_container.get_children():
		child.queue_free()

	# Offer 3 random relics using seeded RNG
	var shuffled: Array[Dictionary] = LEGACY_RELICS.duplicate()
	for i: int in range(shuffled.size() - 1, 0, -1):
		var j: int = RunManager.rng.randi_range(0, i)
		var tmp: Dictionary = shuffled[i]
		shuffled[i] = shuffled[j]
		shuffled[j] = tmp

	for idx: int in range(mini(3, shuffled.size())):
		_build_relic_button(shuffled[idx])


func _build_relic_button(relic: Dictionary) -> void:
	var relic_id: String = relic.get("id", "")
	var relic_name: String = relic.get("name", relic_id)
	var relic_effect: String = relic.get("effect", "")

	var panel: PanelContainer = PanelContainer.new()
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = COLOR_RELIC_BG
	style.corner_radius_top_left = 6
	style.corner_radius_top_right = 6
	style.corner_radius_bottom_left = 6
	style.corner_radius_bottom_right = 6
	style.content_margin_left = 14.0
	style.content_margin_right = 14.0
	style.content_margin_top = 12.0
	style.content_margin_bottom = 12.0
	panel.add_theme_stylebox_override(&"panel", style)
	panel.custom_minimum_size = Vector2(220.0, 120.0)

	var vbox: VBoxContainer = VBoxContainer.new()
	vbox.add_theme_constant_override(&"separation", 6)
	panel.add_child(vbox)

	var name_lbl: Label = Label.new()
	name_lbl.text = relic_name
	name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_lbl.add_theme_color_override(&"font_color", COLOR_PARCHMENT)
	name_lbl.add_theme_font_size_override(&"font_size", 15)
	vbox.add_child(name_lbl)

	var effect_lbl: Label = Label.new()
	effect_lbl.text = relic_effect
	effect_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	effect_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	effect_lbl.add_theme_color_override(&"font_color", COLOR_SCORE_LABEL)
	effect_lbl.add_theme_font_size_override(&"font_size", 12)
	vbox.add_child(effect_lbl)

	var btn: Button = Button.new()
	btn.text = "Choose"
	btn.add_theme_color_override(&"font_color", COLOR_PARCHMENT)
	var btn_style: StyleBoxFlat = StyleBoxFlat.new()
	btn_style.bg_color = COLOR_RELIC_SELECTED.darkened(0.4)
	btn_style.corner_radius_top_left = 4
	btn_style.corner_radius_top_right = 4
	btn_style.corner_radius_bottom_left = 4
	btn_style.corner_radius_bottom_right = 4
	btn_style.content_margin_left = 8.0
	btn_style.content_margin_right = 8.0
	btn_style.content_margin_top = 4.0
	btn_style.content_margin_bottom = 4.0
	btn.add_theme_stylebox_override(&"normal", btn_style)
	var captured_id: String = relic_id
	var captured_panel: PanelContainer = panel
	btn.pressed.connect(func() -> void: _on_relic_chosen(captured_id, captured_panel))
	vbox.add_child(btn)

	_relic_container.add_child(panel)


func _on_relic_chosen(relic_id: String, chosen_panel: PanelContainer) -> void:
	# Visual feedback — highlight chosen relic; MVP does not persist the choice
	_selected_relic_id = relic_id

	# Tint all panels back to default, highlight chosen
	for child: Node in _relic_container.get_children():
		if child is PanelContainer:
			var style: StyleBoxFlat = StyleBoxFlat.new()
			style.bg_color = COLOR_RELIC_BG
			style.corner_radius_top_left = 6
			style.corner_radius_top_right = 6
			style.corner_radius_bottom_left = 6
			style.corner_radius_bottom_right = 6
			style.content_margin_left = 14.0
			style.content_margin_right = 14.0
			style.content_margin_top = 12.0
			style.content_margin_bottom = 12.0
			(child as PanelContainer).add_theme_stylebox_override(&"panel", style)

	var chosen_style: StyleBoxFlat = StyleBoxFlat.new()
	chosen_style.bg_color = COLOR_RELIC_SELECTED.darkened(0.2)
	chosen_style.border_width_left = 2
	chosen_style.border_width_right = 2
	chosen_style.border_width_top = 2
	chosen_style.border_width_bottom = 2
	chosen_style.border_color = COLOR_RELIC_SELECTED
	chosen_style.corner_radius_top_left = 6
	chosen_style.corner_radius_top_right = 6
	chosen_style.corner_radius_bottom_left = 6
	chosen_style.corner_radius_bottom_right = 6
	chosen_style.content_margin_left = 14.0
	chosen_style.content_margin_right = 14.0
	chosen_style.content_margin_top = 12.0
	chosen_style.content_margin_bottom = 12.0
	chosen_panel.add_theme_stylebox_override(&"panel", chosen_style)

	print("DeathScreen: relic chosen (MVP no-persist) — ", relic_id)


# ---------------------------------------------------------------------------
# New Run button
# ---------------------------------------------------------------------------

func _on_new_run_pressed() -> void:
	get_tree().paused = false
	RunManager.reset_run()
	CardManager.reset()
	get_tree().change_scene_to_file("res://scenes/game.tscn")
