# Directory Structure — VAULTED: The Ashen Court

```text
vaulted-ashen-court/
├── CLAUDE.md                    ← Agent config. Read only.
├── baseline.md                  ← Game bible. Read only. Never modify.
├── CURRENT_STATE.md             ← Rolling build state. Overwrite each session.
├── ASSETS_NEEDED.md             ← Asset requests. Append only.
├── project.godot                ← Godot project file.
├── .gitignore
│
├── Phases/
│   └── Phase_1.md               ← Phase 1 work log. Append only.
│
├── .claude/
│   ├── agents/                  ← 48 agent definitions
│   ├── hooks/                   ← 8 event hooks
│   ├── rules/                   ← 11 path-specific rules
│   ├── skills/                  ← 37 slash-command skills
│   └── docs/                    ← Architecture docs (@ imported by CLAUDE.md)
│
├── docs/
│   ├── COLLABORATIVE-DESIGN-PRINCIPLE.md
│   ├── WORKFLOW-GUIDE.md
│   └── engine-reference/
│       └── godot/               ← Godot 4.6 API reference (LLM gap mitigation)
│
├── scenes/
│   ├── main_menu.tscn
│   ├── game.tscn
│   ├── player/
│   │   └── player.tscn
│   ├── enemies/
│   │   ├── shambler.tscn
│   │   ├── wraith.tscn
│   │   ├── arbalist.tscn
│   │   └── boss_knight.tscn
│   ├── ui/
│   │   ├── hud.tscn
│   │   ├── card_pick.tscn
│   │   ├── death_screen.tscn
│   │   └── damage_number.tscn
│   └── floors/
│       ├── floor_base.tscn
│       └── boss_floor.tscn
│
├── scripts/
│   ├── autoload/
│   │   ├── event_bus.gd         ← All signals. Never direct node refs.
│   │   ├── game_data.gd         ← Loads all JSON at startup.
│   │   ├── run_manager.gd       ← Run state: floor, cards, curses, score.
│   │   └── card_manager.gd      ← Card pickup and effect registration.
│   ├── player.gd
│   ├── enemy_base.gd
│   ├── floor_controller.gd
│   └── card_effect_base.gd
│
├── data/
│   ├── cards.json
│   ├── enemies.json
│   ├── floors.json
│   └── curses.json
│
└── assets/
    ├── sprites/
    ├── tiles/
    ├── audio/
    └── ui/
```
