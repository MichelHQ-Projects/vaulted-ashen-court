extends CanvasLayer
## VAULTED — HUD
##
## Displays HP bar, Armor bar, Floor number, Wave indicator,
## Active Cards list, and Active Curses list.
## Connects to EventBus signals for live updates.
## Reads initial state from RunManager and the player node (group "player").

class_name HUD

# ---------------------------------------------------------------------------
# Color constants
# ---------------------------------------------------------------------------

const COLOR_PARCHMENT: Color = Color(0.9, 0.85, 0.7)
const COLOR_PANEL_BG: Color = Color(0.1, 0.1, 0.12, 0.85)
const COLOR_HP_FILL: Color = Color(0.75, 0.15, 0.15)
const COLOR_ARMOR_FILL: Color = Color(0.3, 0.5, 0.75)
const COLOR_CURSE_TEXT: Color = Color(0.85, 0.2, 0.2)
const COLOR_LABEL: Color = Color(0.65, 0.6, 0.5)

# ---------------------------------------------------------------------------
# Node references
# ---------------------------------------------------------------------------

@onready var _hp_bar: ProgressBar = $StatsPanel/VBox/HPRow/HPBar
@onready var _hp_label: Label = $StatsPanel/VBox/HPRow/HPLabel
@onready var _armor_bar: ProgressBar = $StatsPanel/VBox/ArmorRow/ArmorBar
@onready var _armor_label: Label = $StatsPanel/VBox/ArmorRow/ArmorLabel

@onready var _floor_label: Label = $FloorPanel/FloorLabel
@onready var _wave_label: Label = $FloorPanel/WaveLabel

@onready var _cards_list: VBoxContainer = $CardsPanel/ScrollContainer/CardsList
@onready var _curses_list: VBoxContainer = $CursesPanel/ScrollContainer/CursesList

# ---------------------------------------------------------------------------
# Cached player stats (for bar maxima)
# ---------------------------------------------------------------------------

var _max_hp: int = 100
var _max_armor: int = 20

# ---------------------------------------------------------------------------
# Lifecycle
# ---------------------------------------------------------------------------

func _ready() -> void:
	_connect_signals()
	# Defer initial read so player node has time to enter the tree
	call_deferred("_init_from_state")


func _connect_signals() -> void:
	EventBus.player_hit.connect(_on_player_hit)
	EventBus.floor_cleared.connect(_on_floor_cleared)
	EventBus.wave_started.connect(_on_wave_started)
	EventBus.card_picked.connect(_on_card_picked)
	EventBus.curse_applied.connect(_on_curse_applied)


# ---------------------------------------------------------------------------
# Initial state bootstrap
# ---------------------------------------------------------------------------

func _init_from_state() -> void:
	# Read max values from RunManager constants if available, else defaults
	var players: Array[Node] = get_tree().get_nodes_in_group(&"player")
	if players.size() > 0:
		var p: Node = players[0]
		if p.get_script() != null:
			_max_hp = p.get("MAX_HP") if p.get("MAX_HP") != null else 100
			_max_armor = p.get("MAX_ARMOR") if p.get("MAX_ARMOR") != null else 20
			var current_hp: int = p.get("hp") if p.get("hp") != null else _max_hp
			var current_armor: int = p.get("armor") if p.get("armor") != null else _max_armor
			_set_hp(current_hp, _max_hp)
			_set_armor(current_armor, _max_armor)
	else:
		_set_hp(_max_hp, _max_hp)
		_set_armor(_max_armor, _max_armor)

	_update_floor_label(RunManager.current_floor)
	_wave_label.text = "Wave 0/3"

	# Populate any cards already active (e.g., if HUD is late-loaded)
	for card_id: String in RunManager.active_cards:
		_add_card_entry(card_id)

	for curse_id: String in RunManager.active_curses:
		_add_curse_entry(curse_id)


# ---------------------------------------------------------------------------
# Public API — called by game.gd when a new floor loads
# ---------------------------------------------------------------------------

## Refresh all stat bars. Called after floor transitions when player stats reset.
func refresh_player_stats() -> void:
	var players: Array[Node] = get_tree().get_nodes_in_group(&"player")
	if players.size() > 0:
		var p: Node = players[0]
		var current_hp: int = p.get("hp") if p.get("hp") != null else _max_hp
		var current_armor: int = p.get("armor") if p.get("armor") != null else _max_armor
		_set_hp(current_hp, _max_hp)
		_set_armor(current_armor, _max_armor)


# ---------------------------------------------------------------------------
# Bar helpers
# ---------------------------------------------------------------------------

func _set_hp(current: int, maximum: int) -> void:
	_hp_bar.max_value = float(maximum)
	_hp_bar.value = float(current)
	_hp_label.text = "%d / %d" % [current, maximum]


func _set_armor(current: int, maximum: int) -> void:
	_armor_bar.max_value = float(maximum)
	_armor_bar.value = float(current)
	_armor_label.text = "%d / %d" % [current, maximum]


func _update_floor_label(floor_number: int) -> void:
	_floor_label.text = "Floor %d" % floor_number


# ---------------------------------------------------------------------------
# EventBus signal handlers
# ---------------------------------------------------------------------------

func _on_player_hit(_damage: float) -> void:
	# Re-read live values from player node
	var players: Array[Node] = get_tree().get_nodes_in_group(&"player")
	if players.size() == 0:
		return
	var p: Node = players[0]
	var current_hp: int = p.get("hp") if p.get("hp") != null else 0
	var current_armor: int = p.get("armor") if p.get("armor") != null else 0
	_set_hp(current_hp, _max_hp)
	_set_armor(current_armor, _max_armor)


func _on_floor_cleared(floor_number: int) -> void:
	_update_floor_label(floor_number)


func _on_wave_started(wave_number: int) -> void:
	_wave_label.text = "Wave %d/3" % wave_number


func _on_card_picked(card_id: String) -> void:
	_add_card_entry(card_id)


func _on_curse_applied(curse_id: String) -> void:
	_add_curse_entry(curse_id)


# ---------------------------------------------------------------------------
# List entry helpers
# ---------------------------------------------------------------------------

func _add_card_entry(card_id: String) -> void:
	# Find display name from GameData
	var display_name: String = _get_card_display_name(card_id)
	var lbl: Label = Label.new()
	lbl.text = "- " + display_name
	lbl.add_theme_color_override(&"font_color", COLOR_PARCHMENT)
	lbl.add_theme_font_size_override(&"font_size", 13)
	_cards_list.add_child(lbl)


func _add_curse_entry(curse_id: String) -> void:
	var display_name: String = _get_curse_display_name(curse_id)
	var lbl: Label = Label.new()
	lbl.text = "- " + display_name
	lbl.add_theme_color_override(&"font_color", COLOR_CURSE_TEXT)
	lbl.add_theme_font_size_override(&"font_size", 13)
	_curses_list.add_child(lbl)


func _get_card_display_name(card_id: String) -> String:
	for entry: Variant in GameData.cards:
		if entry is Dictionary and entry.get("id", "") == card_id:
			return entry.get("name", card_id)
	return card_id


func _get_curse_display_name(curse_id: String) -> String:
	for entry: Variant in GameData.curses:
		if entry is Dictionary and entry.get("id", "") == curse_id:
			return entry.get("name", curse_id)
	return curse_id
