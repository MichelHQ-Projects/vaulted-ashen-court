# Technical Preferences — VAULTED: The Ashen Court

**Engine**: Godot 4
- GDScript only, no C#
- Renderer: gl_compatibility (widest hardware support for Steam)
- Physics: Godot default 2D physics

## Naming Conventions
- Files: snake_case (player.gd, floor_controller.gd)
- Classes: PascalCase (class_name PlayerController)
- Signals: snake_case past tense (player_died, card_picked)
- Constants: SCREAMING_SNAKE_CASE (MAX_HP, ATTACK_SPEED)
- Variables: snake_case (current_floor, active_cards)

## Performance Budgets
- Target: 60fps on mid-range hardware (GTX 1060 / RX 580 equivalent)
- Max enemies on screen simultaneously: 40
- Max particle emitters active: 10
- Draw calls per frame budget: 200

## Architecture Rules
- All cross-system signals via event_bus.gd autoload
- All game data in res://data/ JSON files
- No direct node references across scene boundaries
- Seeded RNG always — seed from run_manager at run start
- Autoloads: EventBus, GameData, RunManager, CardManager

## Tile & Camera
- Tile size: 64×32 isometric
- Camera: fixed 45°, no rotation, no zoom during gameplay
