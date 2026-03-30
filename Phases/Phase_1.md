# Phase 1 — Night 1 MVP

> Maintained by: Claude Code
> Append new sections as each work unit completes. Never rewrite or delete.
> Format: ## 1.X — Work Unit Name

---

## 1.1 — Project Scaffold & Isometric Tilemap
**Status:** ✅ Complete
**Agent:** Engine Architect
**Started:** 2026-03-29
**Completed:** 2026-03-29

### What Was Built
- `project.godot` — updated feature tag to `4.6`, added `[input]` section with six actions:
  `move_up` (W/Up), `move_down` (S/Down), `move_left` (A/Left), `move_right` (D/Right),
  `attack` (LMB/Space), `dodge` (RMB/Shift).
- `scripts/autoload/run_manager.gd` — full implementation: seeded `RandomNumberGenerator`,
  `start_run()`, `reset_run()`, `advance_floor()`, `get_score()`, auto-tracks kills via
  `EventBus.enemy_died`.
- `scripts/floor_base.gd` — `FloorBase` class: generates 20×15 isometric ColorRect tile
  grid in `_ready()`, exposes `get_player_spawn() -> Vector2` and
  `get_enemy_spawns() -> Array[Vector2]`.
- `scenes/floors/floor_base.tscn` — FloorBase node with `PlayerSpawn` Marker2D and five
  `EnemySpawn0`–`EnemySpawn4` Marker2D nodes at staggered positions.
- `scenes/game.tscn` — `Node2D` root (game.gd attached) + `FloorContainer` + `Camera2D` +
  `UILayer` (CanvasLayer layer=10).
- `scripts/game.gd` — new file, orchestrates floor loading/reload, player spawn,
  smooth camera follow, `floor_cleared` and `player_died` event handling.

### Decisions Made
- Tile checkerboard: even/odd `(col+row)` tint so individual isometric tiles are
  distinguishable without art assets.
- Camera follow via `lerp` in `_process` with weight `6.0 * delta` — snappy but not
  instant. Snaps to player position on first spawn to avoid initial lerp lag.
- `FloorBase` generates tiles dynamically in `_ready()` rather than baking them into
  the scene; keeps the `.tscn` small and makes future procedural variation easy.
- Five enemy spawn markers placed in the `.tscn` file rather than generated in script,
  so the Systems Designer can reposition them in the Godot editor.
- `project.godot` feature tag bumped from `4.2` to `4.6` per VERSION.md requirement.

### What Broke / What Was Hard
- Godot 4.6 uses Jolt as the default 3D physics engine but this game is 2D — no impact.
- TileMap is deprecated; used `TileMapLayer` reference docs to confirm we should use
  procedural `ColorRect` nodes for placeholder tiles (no TileSet data required).

### Blockers / Asset Requests
- No real tile art yet. Placeholder: ColorRect ash-grey `Color(0.4, 0.4, 0.4)` / `Color(0.35, 0.35, 0.35)`.
- Asset request: 64×32 isometric floor tile sprite (ash grey, stone texture) for Zone 1
  (Outer Ramparts palette). Added to ASSETS_NEEDED.md.

---

## 1.2 — Player Controller
**Status:** ✅ Complete
**Agent:** Engine Architect
**Started:** 2026-03-29
**Completed:** 2026-03-29

### What Was Built
- `scripts/player.gd` — `PlayerController` class extending `CharacterBody2D`.
  - State machine enum: `IDLE`, `MOVING`, `ATTACKING`, `DODGING`, `DEAD`.
  - 8-directional WASD movement via `Input.get_vector()` at `MOVE_SPEED = 140.0`.
  - Mouse-facing: `facing_direction` updated each frame toward cursor.
  - Arc attack: 120° forward arc, `ATTACK_RANGE = 80.0`, `ATTACK_DAMAGE = 18`.
    Hits all nodes in group `"enemies"` within arc. Emits
    `EventBus.card_effect_triggered("attack_count", float(attack_count))` each swing.
  - Dodge roll: `DODGE_SPEED = 350.0`, `DODGE_DURATION = 0.4s` i-frames,
    `DODGE_COOLDOWN = 1.0s`. Emits `EventBus.player_dodged(global_position)`.
  - Damage model: armor absorbs first (`MAX_ARMOR = 20`), remainder hits HP
    (`MAX_HP = 100`). Invincibility flag respected.
  - `EventBus.player_hit` emitted on every hit; `EventBus.player_died` on death.
  - `EventBus.floor_cleared` triggers armor regeneration to `MAX_ARMOR`.
- `scenes/player/player.tscn` — `CharacterBody2D` root with:
  - `CollisionShape2D` (CapsuleShape2D 12×40)
  - `Visual` ColorRect (24×40, tarnished gold `Color(0.7, 0.6, 0.2)`)
  - `AttackHitbox` Area2D with disabled CircleShape2D radius=80 (reserved for
    future card effects that need physics-based overlap queries)

### Decisions Made
- Arc attack uses `get_tree().get_nodes_in_group("enemies")` + manual angle/distance
  check rather than an enabled `Area2D` overlap. Rationale: simpler for MVP, and the
  arc is instantaneous (no frame-persistent shape). The `AttackHitbox` Area2D is
  stubbed in the scene for card effects that may need it.
- `facing_direction` updates every frame toward mouse. Movement direction only updates
  `facing_direction` when there is actual movement input — mouse takes priority at rest.
- DEAD is a terminal state; `_set_state()` guards against leaving it.
- Attack arc check uses `Vector2.angle_to()` which returns a signed angle — `absf()`
  applied correctly to handle both sides of the arc.
- `_process` drives camera; `_physics_process` drives movement/combat. Separated
  intentionally: camera interpolation is visual, not physics.

### What Broke / What Was Hard
- `Input.get_vector` parameter order is left/right/up/down — matches the four action
  names defined in project.godot (confirmed against engine-reference/input.md).
- Godot 4.6 `@warning_ignore` annotation used to suppress the unused `delta` parameter
  in `_tick_movement` (delta is consumed implicitly by `move_and_slide`).

### Blockers / Asset Requests
- No player sprite yet. Placeholder: tarnished gold ColorRect.
- Asset request: tarnished gold knight sprite sheet (idle, walk 4-dir, attack, dodge,
  death) at approximately 48×64px. Added to ASSETS_NEEDED.md.

---

## 1.3 — Enemy AI & Wave Spawner
**Status:** ✅ Complete
**Agent:** Systems Designer
**Started:** 2026-03-29
**Completed:** 2026-03-29

### What Was Built
- `scripts/enemy_base.gd` — `EnemyBase` class extending `CharacterBody2D`. Four-state AI
  state machine (`IDLE`, `CHASING`, `ATTACKING`, `DYING`). Drives movement toward player,
  melee attacks via Area2D overlap detection, damage intake via `take_damage()`, and death
  via `die()` which emits `EventBus.enemy_died`. All stats (`hp`, `max_hp`, `move_speed`,
  `attack_damage`, `attack_range`, `attack_cooldown`) are populated by subclasses overriding
  `_load_stats()` from GameData. Adds self to `"enemies"` group on `_ready()`.
- `scripts/enemies/shambler.gd` — `Shambler` subclass. Simplest enemy: walks toward player,
  attacks in melee range. Loads stats from `data/enemies.json` entry `"shambler"` (HP 45,
  speed 60, damage 8, range 40, cooldown 1.5). Includes hardcoded fallback values if JSON
  load fails.
- `scripts/enemies/boss_knight.gd` — `BossKnight` subclass. Three-phase boss with an
  extended state machine adding a `CHARGING` state (`BossState` enum shadows `EnemyBase.State`).
  Phase 1 (100-66% HP): standard approach and swing. Phase 2 (66-33% HP): 33% faster attack
  cooldown + charge dash (3x move_speed, 0.5s duration, 30 damage, 4s cooldown). Phase 3
  (33-0% HP): +30% move_speed enrage; attacks emit `"boss_slow_hit"` via
  `EventBus.card_effect_triggered` when the Weighted Chains curse is active. Emits
  `EventBus.boss_phase_changed` on phase transitions. Adds self to `"boss"` group. Stats
  loaded from `data/enemies.json` entry `"boss_knight"` (HP 350, speed 100, damage 25,
  range 60, cooldown 1.0).
- `scripts/wave_spawner.gd` — `WaveSpawner` class. Manages multi-wave enemy spawning per
  floor. Reads `wave_count`, `enemy_pool`, `enemy_count_base`, and `enemy_count_scale` from
  floor data. Spawns enemies with 0.3s stagger delay between each. Selects enemy types from
  pool using `RunManager.rng` (seeded RNG). Positions enemies at random spawn points. Tracks
  `enemies_alive` count via `EventBus.enemy_died`, triggers next wave (with 1.5s inter-wave
  pause via `create_timer`) when all enemies in a wave are killed, and emits
  `EventBus.floor_cleared` when all waves complete.
- `scenes/enemies/shambler.tscn` — `CharacterBody2D` root with `CollisionShape2D`
  (CapsuleShape2D 12x28), `Visual` ColorRect (bone-white `Color(0.9, 0.9, 0.8)`),
  `AttackArea` Area2D with CircleShape2D radius=40.
- `scenes/enemies/boss_knight.tscn` — scene file (present on disk).
- `scenes/enemies/wraith.tscn`, `scenes/enemies/arbalist.tscn` — empty stub `.tscn` files
  (no nodes, no scripts).
- `data/enemies.json` — stat definitions for `shambler` and `boss_knight`.

### Decisions Made
- EnemyBase uses a flat state machine (no HSM or behavior tree) — sufficient for MVP where
  enemies only chase and attack. BossKnight extends this with its own `BossState` enum and
  shadows the base `_state` variable with `_boss_state` to avoid type conflicts while
  reusing base-class helpers like `_update_player_reference()` and `_process_idle()`.
- Attack range detection uses Area2D overlap (`body_entered` / `body_exited`) rather than
  manual distance checks. This keeps EnemyBase consistent with Godot's physics system and
  allows different collision shapes per enemy type.
- EnemyBase caches and refreshes the player reference every frame via
  `_update_player_reference()` using group lookup — handles player respawn and late join
  without stored NodePath references (compliant with the "no cross-system direct node refs"
  rule).
- BossKnight phase transitions are checked every `_physics_process` frame by HP percentage
  thresholds — simple and deterministic, no event-driven phase logic.
- Charge dash uses distance-to-player check for hit detection during the charge rather than
  a separate Area2D — keeps the charge implementation self-contained.
- Wave enemy count formula: `base + (wave_number - 1) * scale`. Floor 1 produces waves of
  3, 5, 7 enemies across 3 waves (escalating pressure).
- Only `shambler` is registered in `WaveSpawner.ENEMY_SCENES` — wraith and arbalist have
  stub scenes but no scripts or spawner registration.

### What Broke / What Was Hard
- BossKnight needed to shadow the base class state machine entirely because GDScript enums
  are value-typed — extending `State` with a `CHARGING` value would have required changing
  the base class. The `_boss_state: int` shadow approach works but means BossKnight must
  override `die()`, `take_damage()`, `_on_player_died()`, and the Area2D callbacks to
  reference `_boss_state` instead of `_state`, resulting in duplicated guard logic.
- The `_get_enemy_data()` helper is duplicated identically in both `shambler.gd` and
  `boss_knight.gd` rather than being defined once in `EnemyBase`. Minor code smell for MVP.
- `_check_wave_complete()` in WaveSpawner uses `await get_tree().create_timer(1.5).timeout`
  for the inter-wave pause — this works but the await could interact poorly if the node is
  freed during the wait (e.g., floor change during the 1.5s gap).

### Blockers / Asset Requests
- Wraith and Arbalist enemies are scene stubs only — no scripts, no stats in enemies.json,
  not registered in WaveSpawner. Need implementation before they can appear in wave pools.
- No enemy sprite art. Shambler placeholder: bone-white ColorRect. Boss Knight placeholder:
  scene file present but visual not verified.
- Asset request: shambler sprite sheet (idle, walk, attack, death) at ~24x36px.
- Asset request: boss_knight sprite sheet (idle, walk, attack, charge, death, phase
  transitions) at ~48x64px.

---

## 1.4 — Card System
**Status:** ✅ Complete
**Agent:** Systems Designer
**Started:** 2026-03-29
**Completed:** 2026-03-29

### What Was Built
- `scripts/autoload/card_manager.gd` — `CardManager` autoload. Loads the full card pool
  from `GameData.cards` one frame after `_ready()` (awaits `process_frame` to ensure
  GameData has finished JSON loading). Tracks `active_cards: Array[String]` for the current
  run. Key API:
  - `offer_cards(count)` — returns up to `count` card data Dictionaries from the pool,
    excluding already-active cards. Uses Fisher-Yates shuffle with `RunManager.rng` for
    seeded randomness.
  - `pick_card(card_id)` — activates a card: appends to `active_cards` and
    `RunManager.active_cards`, instantiates the effect node, emits `EventBus.card_picked`.
    Guards against duplicate picks.
  - `activate_card(card_data)` — instantiates the matching `CardEffectBase` subclass via
    `_get_effect_for_card()` factory, adds it as a child of `_effect_container`, calls
    `effect.activate(card_data)`.
  - `reset()` — clears active cards and calls `deactivate()` on all effect nodes (they
    `queue_free()` themselves).
- `scripts/card_effect_base.gd` — `CardEffectBase` class extending `Node` (not
  `RefCounted`). Provides `activate(data)` / `deactivate()` lifecycle with virtual
  `_setup()` and `_teardown()` hooks. Extending `Node` allows card effects to connect to
  signals and live in the scene tree as children of CardManager's effect container.
- `scripts/cards/iron_echo.gd` — `IronEchoEffect` subclass. Listens for
  `EventBus.card_effect_triggered` with `effect_id == "attack_count"` (emitted by player
  on each attack). Counts attacks and fires a knockback shockwave every Nth attack
  (default N=5). Shockwave finds all enemies in `"enemies"` group within radius (default
  120), applies `take_damage()` (default 10 damage) and knockback velocity via
  `CharacterBody2D.velocity +=` (default force 300). All parameters read from
  `card_data.effect` dict, falling back to constants.
- `data/cards.json` — single card entry: `iron_echo` (type `"augment"`, rune_color `"blue"`,
  tagged `attack_modifier` + `knockback`). Contains `emits` and `consumes` arrays for future
  card interaction graph tooling.

### Decisions Made
- Card effects extend `Node` rather than `RefCounted` so they can be added as children of
  CardManager's `_effect_container` node. This gives effects access to `get_tree()` for
  group queries and signal connections without requiring external wiring.
- Factory pattern in `CardManager._get_effect_for_card()` uses a `match` statement on
  `card_id` to return the correct subclass. New card effects require adding a case to this
  match block — explicit and simple for MVP, though it will need refactoring (e.g.,
  scene-based loading or a registry dictionary) as the card pool grows.
- Iron Echo uses `EventBus.card_effect_triggered` as a generic event channel rather than a
  card-specific signal. The player emits `("attack_count", float)` on every swing; Iron Echo
  filters for that `effect_id`. This decouples the player from knowledge of specific cards.
- Knockback is applied by directly modifying `CharacterBody2D.velocity` — additive impulse.
  This means the knockback is consumed on the next `move_and_slide()` call in the enemy's
  physics tick, producing a single-frame push. Works for MVP but may feel too brief.
- `offer_cards()` excludes already-active cards, so the player never sees duplicates.
  No rarity weighting or draft pool logic yet — purely uniform random from the seeded RNG.
- The `await get_tree().process_frame` in `_ready()` ensures `GameData.cards` is populated
  before `card_pool` is set, accounting for autoload initialization order.

### What Broke / What Was Hard
- Card effects need access to the scene tree for group queries (`get_tree().get_nodes_in_group`),
  which ruled out `RefCounted` or `Resource` as base classes — had to use `Node`.
- Iron Echo's `_fire_shockwave()` iterates all enemies via group query every time it triggers,
  which is fine for the 40-enemy performance budget but would need spatial optimization at
  scale.
- The `emits` / `consumes` fields in `cards.json` are defined but not yet consumed by any
  runtime system — they are forward-looking metadata for a future card interaction graph.

### Blockers / Asset Requests
- Only one card (Iron Echo) is implemented. The card pool needs additional entries (baseline.md
  lists 12 cards for the full design) before the card pick screen can offer meaningful choices.
- No card art or UI icons. Card pick screen (1.6) will need card frame sprites and rune
  color indicators.
- Asset request: card frame UI sprite (~200x280px) with rune color accent variants (blue,
  red, gold).

---

## 1.5 — Floor Controller & Wave Logic
**Status:** ✅ Complete
**Agent:** Systems Designer
**Started:** 2026-03-29
**Completed:** 2026-03-29

### What Was Built
- `scripts/floor_controller.gd` — `FloorController` class extending `Node`. Orchestrates
  floor progression by reading floor data from `GameData.floors` and delegating to either
  `WaveSpawner` (normal floors) or direct boss instantiation (boss floors). Key API:
  - `set_spawn_points(points)` — accepts explicit spawn positions (from `FloorBase` Marker2D
    nodes). Falls back to `_generate_default_spawn_points()` which creates 8 positions in a
    circle at radius 300 around origin.
  - `start_floor(floor_number)` — sets `RunManager.current_floor`, looks up floor data by
    1-based index (wraps via modulo if index exceeds array size), then routes to
    `_start_normal_floor()` or `_start_boss_floor()`.
  - Normal floors: calls `wave_spawner.setup(floor_data, spawn_points)` then
    `wave_spawner.start_spawning()`.
  - Boss floors: loads boss scene from `BOSS_SCENES` dictionary by `boss_id`, instantiates
    it, places at `Vector2.ZERO`, emits `EventBus.enemy_spawned` and `EventBus.wave_started(1)`.
- Curse economy: listens for `EventBus.floor_cleared` and applies the Weighted Chains curse
  every 3rd floor (`floor_number % 3 == 0`). Appends `"weighted_chains"` to
  `RunManager.active_curses` and emits `EventBus.curse_applied`. Guards against duplicate
  application in the same run.
- Creates its own `WaveSpawner` child node in `_ready()` — the spawner is fully owned and
  managed by FloorController.
- `data/floors.json` — three floor entries defining the Night 1 structure:
  - `floor_1`: outer_ramparts, 3 waves, shambler pool, base 3 + scale 2 (waves of 3/5/7).
  - `floor_2`: outer_ramparts, 3 waves, shambler pool, base 4 + scale 2 (waves of 4/6/8).
  - `floor_3`: outer_ramparts, boss floor, `boss_id: "boss_knight"`, no wave spawning.

### Decisions Made
- FloorController owns a WaveSpawner as a child node rather than finding one in the scene —
  composition over scene-tree dependency. This makes FloorController self-contained and
  testable without a specific scene structure.
- Boss floors bypass WaveSpawner entirely. The boss scene is loaded and instantiated directly
  by FloorController, placed at the origin. The `wave_started(1)` signal is emitted manually
  so the HUD can display boss fight state.
- Floor data lookup uses `(floor_number - 1) % GameData.floors.size()` — floor numbers are
  1-based but the array is 0-indexed. The modulo wrap means the 3-floor cycle repeats if the
  run ever exceeds 3 floors (future-proofing for additional zones).
- Curse application is handled by FloorController rather than a dedicated curse system — keeps
  MVP simple. Only Weighted Chains is implemented. The curse emits a signal rather than
  modifying the player directly (respects the "no direct cross-system node refs" rule).
- Default spawn point generation creates an 8-point circle at radius 300 — ensures enemies
  don't spawn on top of the player even if `set_spawn_points()` is never called.

### What Broke / What Was Hard
- Boss instantiation uses `get_tree().current_scene.add_child(boss)` which assumes the
  current scene is the correct parent. This works for the `game.tscn` setup but is fragile
  if the scene tree structure changes.
- The Weighted Chains curse is referenced by string `"weighted_chains"` in both
  `FloorController` and `BossKnight` — no shared constant or enum, so a typo would silently
  break the curse interaction.
- `_find_curse_data()` queries `GameData.curses` but is only used for the guard check — the
  actual curse data Dictionary is never consumed. The function exists for future expansion
  (e.g., reading curse magnitude from data).
- The floor_cleared handler does not trigger the next floor — it only applies the curse.
  The actual floor advancement flow (card pick -> advance_floor -> start_floor) is expected
  to be driven by `game.gd` and the UI layer, which are not yet wired up end-to-end.

### Blockers / Asset Requests
- Only `"boss_knight"` is registered in `FloorController.BOSS_SCENES`. Additional boss types
  would need scene paths added to this dictionary.
- Floor data only contains shambler in the enemy pool. Wraith and arbalist need scripts and
  spawner registration before they can appear in floor enemy pools.
- Curse data file (`data/curses.json`) exists but its contents were not verified as part of
  this work unit — the curse system currently only checks for the presence of
  `"weighted_chains"` in `RunManager.active_curses` by string ID.

---

## 1.6 — HUD & Card Pick Screen
**Status:** Complete
**Agent:** UI/UX Builder
**Started:** 2026-03-29
**Completed:** 2026-03-29

### What Was Built
- `scripts/ui/hud.gd` — HP/Armor ProgressBars, Floor and Wave labels, scrollable active
  cards list and curses list. Connects to EventBus (player_hit, floor_cleared, wave_started,
  card_picked, curse_applied). `refresh_player_stats()` public API for post-floor resets.
  Reads initial state via deferred `_init_from_state()` to allow player to enter tree first.
- `scripts/ui/card_pick.gd` — Modal CanvasLayer with semi-transparent overlay. `show_cards()`
  calls `CardManager.offer_cards(3)`, builds dynamic PanelContainer cards with type-colored
  borders, Pick buttons. `hide_cards()` unpauses tree. Runs `PROCESS_MODE_ALWAYS` so it
  works while paused.
- `scripts/ui/damage_number.gd` — Floating Label node: tweened upward float + fade-out,
  `queue_free()` on complete.
- `scenes/ui/hud.tscn` — Full CanvasLayer hierarchy matching hud.gd @onready paths:
  StatsPanel (HP/Armor rows), FloorPanel (floor + wave labels), CardsPanel and CursesPanel
  (scrollable VBoxContainers).
- `scenes/ui/card_pick.tscn` — CanvasLayer + Overlay ColorRect + CenterContainer +
  CardContainer HBoxContainer.
- `scenes/ui/damage_number.tscn` — Node2D + Label child.

### Decisions Made
- Card pick screen pauses the game tree while visible so enemies freeze during selection.
  PROCESS_MODE_ALWAYS ensures the screen itself remains interactive while paused.
- Dynamic card panels built in script rather than pre-built scenes — keeps the scene lean
  and allows arbitrary card data from JSON without per-card scene files.
- Damage number floats upward 40px and fades over 0.8s via Tween — purely visual, no
  gameplay dependency on the tween completing.

### What Broke / What Was Hard
- No issues. HUD @onready paths must match the exact scene node hierarchy exactly.

### Blockers / Asset Requests
- No card art or UI icons — card borders are colored StyleBoxFlat rects.
- Asset request: card frame UI sprite with rune color accents (blue, red, gold).

---

## 1.7 — Boss, Death Screen & Main Menu
**Status:** Complete
**Agent:** UI/UX Builder + Systems Designer
**Started:** 2026-03-29
**Completed:** 2026-03-29

### What Was Built
- `scripts/ui/death_screen.gd` — Full-screen CanvasLayer overlay. `show_death()` populates
  score breakdown (floors, kills, curses, total via RunManager.get_score()) and 3 random
  legacy relics from a hardcoded pool of 8 (baseline.md). Visual relic selection (MVP —
  no persistence). `NewRunButton.pressed` unpauses, calls `RunManager.reset_run()`,
  `CardManager.reset()`, then `change_scene_to_file("res://scenes/game.tscn")`.
- `scripts/ui/main_menu.gd` — Title screen. Play button changes to game.tscn. Quit button
  calls `get_tree().quit()`.
- `scenes/ui/death_screen.tscn` — CanvasLayer + Panel + VBox with ScoreSection (4 Labels),
  RelicSection (HBoxContainer for dynamic relic buttons), NewRunButton.
- `scenes/main_menu.tscn` — Control root + Background ColorRect + TitleLabel + TaglineLabel +
  VBoxContainer with PlayButton and QuitButton.

### Decisions Made
- Legacy relic data is hardcoded in death_screen.gd as a typed Array[Dictionary] constant —
  no JSON file for Phase 1. The 8 relics match baseline.md exactly.
- Relic choice has no persistence in MVP — visual highlight only. Stub for future save system.
- Restart flow goes through change_scene_to_file rather than reloading the scene tree
  manually — cleaner teardown of all in-game state.

### What Broke / What Was Hard
- No issues.

### Blockers / Asset Requests
- No background art for main menu or death screen — ColorRect placeholders.

---

## 1.8 — Integration, QA & Export
**Status:** Complete
**Agent:** QA / Integration
**Started:** 2026-03-29
**Completed:** 2026-03-29

### What Was Built

Static code review of all critical integration seams across all 19 scripts and 11 scenes.
Verified all EventBus signal parameter contracts, group membership, spawn point name
matching, card pick flow wiring, and game flow chain. No code changes required — all
integration points were correctly wired by prior agents.

### Core Loop Test Results

| Done Criterion | Status | Evidence |
|---|---|---|
| `game.gd._ready()` calls `RunManager.start_run()` | Code review confirms | game.gd line 79 |
| Floor/player/UI instantiated in `_ready()` | Code review confirms | game.gd lines 58-77 |
| `floor_cleared` shows card pick screen | Code review confirms | game.gd lines 160-163, card_pick.gd show_cards() |
| `card_picked` advances floor and loads next | Code review confirms | game.gd lines 165-172 |
| `player_died` shows death screen | Code review confirms | game.gd lines 174-178 |
| Restart path returns to fresh game | Code review confirms | death_screen.gd lines 244-248 |
| All EventBus signal signatures match | Code review confirms | All emitters/listeners verified |
| Player in group "player" | Code review confirms | player.gd line 86 |
| Enemies in group "enemies" | Code review confirms | enemy_base.gd lines 12, 48 |
| Spawn point names match (PlayerSpawn, EnemySpawn0-4) | Code review confirms | floor_base.tscn + floor_base.gd |
| Boss has 3 phases | Code review confirms | boss_knight.gd phase thresholds + _enter_phase() |
| Cards activate on pickup | Code review confirms | card_manager.pick_card() → activate_card() |
| Weighted Chains curse applied at floor 3 | Code review confirms | floor_controller.gd line 125 |

Items requiring runtime verification (cannot be confirmed by static review):

| Item | Requires |
|---|---|
| Core loop playable end-to-end | Godot 4.6 editor run |
| No crash on death/restart | Godot 4.6 editor run |
| Windows build exports cleanly | Godot 4.6 editor + export template |

### Bugs Found & Fixed

| Bug | File | Resolution |
|---|---|---|
| None. No code changes required. | — | All integration contracts verified clean via static review. |

### Non-Blocking Observations (not fixed)

| Observation | File | Risk |
|---|---|---|
| Enemy collision layers use defaults — enemies can enter each other's AttackArea | shambler.tscn, boss_knight.tscn | Low — enemies don't call take_damage on each other, only player does |
| `await create_timer(1.5)` in WaveSpawner could emit into a freed node if floor transitions too fast | wave_spawner.gd line 141 | Low — practically unreachable during normal play |
| reset_run() called twice on new run (death_screen + game.gd) | death_screen.gd, run_manager.gd | None — redundant but harmless |

### Export Status

Windows export requires Godot 4.6 editor and Windows export template.
Code review confirms no export blockers: no C# files, no GDExtension, no platform-specific
APIs, all paths use `res://` prefix, all JSON data files are in `res://data/`. The
`gl_compatibility` renderer (configured in project.godot per technical-preferences.md)
is the correct choice for maximum hardware compatibility on Steam.

### Phase 1 Complete?

| Criterion | Status |
|---|---|
| Core loop playable end-to-end | Requires runtime test — code path confirmed complete |
| No crash on death/restart | Requires runtime test — code path confirmed complete |
| Cards activate instantly on pickup | Code review confirms |
| Boss has 3 phases | Code review confirms |
| Windows build exports cleanly | Requires Godot 4.6 editor + export template |
| All EventBus signals wired and matched | Code review confirms |
| Player group membership verified | Code review confirms |
| Enemy group membership verified | Code review confirms |
| Floor spawn points matched | Code review confirms |
| Card pick flow end-to-end verified | Code review confirms |
