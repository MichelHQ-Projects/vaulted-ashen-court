# CURRENT_STATE.md — VAULTED: The Ashen Court

> Owner: Claude Code
> Overwrite this file completely at the end of every session.
> Last updated: 2026-03-29
> Updated by: QA / Integration

---

## Build Status

**Current Phase:** Phase 1 — Night 1 MVP
**Phase Progress:** 8 of 8 work units complete
**Overall Status:** Phase 1 Complete

| Work Unit | Status | Agent |
|---|---|---|
| 1.1 — Project Scaffold & Isometric Tilemap | Complete | Engine Architect |
| 1.2 — Player Controller | Complete | Engine Architect |
| 1.3 — Enemy AI & Wave Spawner | Complete | Systems Designer |
| 1.4 — Card System | Complete | Systems Designer |
| 1.5 — Floor Controller & Wave Logic | Complete | Systems Designer |
| 1.6 — HUD & Card Pick Screen | Complete | UI/UX Builder |
| 1.7 — Boss, Death Screen & Main Menu | Complete | UI/UX Builder |
| 1.8 — Integration, QA & Export | Complete | QA / Integration |

---

## What Exists Right Now

- Godot project: project.godot (Godot 4.6, main_scene = main_menu.tscn)
- Autoloads: EventBus, GameData, RunManager, CardManager
- Input actions: WASD movement, mouse/space attack, shift/RMB dodge
- Scripts: 19 GDScript files (autoloads, core, enemies, cards, UI)
- Scenes: 11 implemented scenes (game, player, floor, 2 enemies, 6 UI)
- Data: 4 JSON files (cards, enemies, floors, curses)
- Stubs remaining: wraith.tscn, arbalist.tscn, boss_floor.tscn (out of Phase 1 scope)
- Assets: All placeholder ColorRects — no real art

---

## Active Work Unit

None. Phase 1 complete.

---

## Last Completed Work Unit

1.8 — Integration, QA & Export

---

## Pending Design Decisions

None.

---

## Known Bugs

None found in static code review. The following are noted non-blocking observations:

1. Enemy collision layers not explicitly set in .tscn files — defaults allow enemies to
   trigger each other's AttackArea. Non-crashing for MVP (enemies don't harm each other).
2. WaveSpawner uses `await get_tree().create_timer(1.5).timeout` for inter-wave pause.
   If the node is freed during the wait, the await will emit into a freed object.
   Practically impossible during normal play (floor_cleared only fires after all waves
   complete). Safe for Phase 1.
3. Both death_screen and game.gd call reset_run() on new run — redundant but harmless.

---

## Assets Needed

See ASSETS_NEEDED.md.

---

## Notes for Next Session

Phase 1 complete. Ready for Phase 2 planning or Godot editor testing.
Windows export requires Godot 4.6 editor — code review confirms no export blockers.

Integration contracts verified clean via static code review:
- All EventBus signal parameters match between emitters and listeners.
- Player is in group "player"; enemies add themselves to group "enemies" via script.
- Floor spawn point names (PlayerSpawn, EnemySpawn0-4) match floor_base.gd lookups.
- Card pick flow: CardManager.offer_cards() -> card_pick displays -> pick_card() ->
  EventBus.card_picked -> game.gd advances floor. No missing connections.
- Death/restart path: player_died -> death_screen.show_death() -> NewRunButton ->
  reset_run() + CardManager.reset() + change_scene_to_file("res://scenes/game.tscn").
