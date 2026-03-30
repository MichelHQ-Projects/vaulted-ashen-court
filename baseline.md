# baseline.md — VAULTED: The Ashen Court

> Permanent game bible. Written once. Never modified.
> Current build state: CURRENT_STATE.md
> Session work logs: Phases/Phase_X.md
> Last written: March 29, 2026

---

## Notion HQ

Root: https://www.notion.so/3328da649fb881ac9c0cdb82fdda3be2

| Page | URL |
|---|---|
| Game Design Bible | https://www.notion.so/3328da649fb8813db76fe6b3511ae77d |
| Build Log & Sprint Tracker | https://www.notion.so/3328da649fb881adad6ce1343622cf96 |
| Agent Team Roster & Prompts | https://www.notion.so/3328da649fb8813cb9efd9bab59b8074 |
| Asset Library | https://www.notion.so/3328da649fb881a8a398c70c6a16ac7d |
| Roadmap: MVP → Steam | https://www.notion.so/3328da649fb881af88c3c04e14ceda9c |
| Master Prompt — Claude Code CEO | https://www.notion.so/3328da649fb88143bfecfbebd75d5b75 |
| Full Build Plan | https://www.notion.so/3328da649fb881f08bdaced981ae7459 |

---

## Studio

| Role | Who |
|---|---|
| Founder & Ideator | Carlos (only human) |
| Prompt Architect / Notion Maintainer | Claude.ai |
| CEO / Orchestrator | Claude Code Opus 4.6 |
| Studio Infrastructure | Claude Code Game Studios repo (48 agents, 37 skills) |

---

## Studio Infrastructure

Repo: https://github.com/Donchitos/Claude-Code-Game-Studios
48 agents · 37 skills · 8 hooks · 11 rules · Godot 4 native · 7.2k stars

This repo is the Claude Code studio foundation. Our context system sits inside it.

Setup:
```bash
git clone https://github.com/Donchitos/Claude-Code-Game-Studios.git vaulted-game
cd vaulted-game
# Drop baseline.md, CURRENT_STATE.md into root
# Create Phases/ folder and add Phase_1.md
# Append Design Authority block to repo's CLAUDE.md
# Run /start
```

Key repo capabilities:
- session-start.sh — auto-loads sprint context on every Claude Code session open
- session-stop.sh — logs accomplishments at session close
- pre-compact.sh — preserves session notes on context compression
- log-agent.sh — full audit trail of every subagent invocation
- validate-commit.sh — catches hardcoded values, missing design doc sections
- /balance-check — dedicated skill for synergy testing
- /team-combat /team-ui — coordinated multi-agent workflows pre-wired
- Godot 4 specialist agent set native to our stack

---

## Design Authority Block — Append to Repo's CLAUDE.md

```
## Design Authority

This studio has an external Design Partner (Claude.ai) who maintains the
high-level design context and bridges decisions to Carlos (the Founder).

Files you must respect:
- baseline.md — permanent game bible. Read at session start. Never modify.
- CURRENT_STATE.md — rolling build state. Overwrite at session end. Always.
- Phases/Phase_X.md — per-phase work logs. Append per work unit. Never rewrite.

Notion HQ (source of truth for design decisions):
https://www.notion.so/3328da649fb881ac9c0cdb82fdda3be2

When you need a design decision not in baseline.md:
- Log it under Pending Design Decisions in CURRENT_STATE.md
- Continue with a reasonable documented assumption
- Never block progress waiting for a response

Session end — mandatory before closing:
1. Overwrite CURRENT_STATE.md with current state
2. Append completed work unit to Phases/Phase_X.md
3. Update ASSETS_NEEDED.md if new assets identified
```

---

## Context System

Four files. One protocol.

| File | Owner | Rule |
|---|---|---|
| baseline.md | Nobody | Read only. Never modified after today. |
| CURRENT_STATE.md | Claude Code | Overwritten end of every session. |
| Phases/Phase_X.md | Claude Code | Appended per work unit. Never rewritten. |
| CLAUDE.md | Nobody | Read only after initial setup. |

### Claude Code — Session Start Protocol
1. Read baseline.md
2. Read CURRENT_STATE.md
3. Read Phases/Phase_X.md (current phase only, if continuing active work)

### Claude Code — Session End Protocol
1. Overwrite CURRENT_STATE.md
2. Append to Phases/Phase_X.md
3. Update ASSETS_NEEDED.md

### Claude.ai — Session Protocol
- baseline.md is always loaded via project instructions
- At conversation start: ask Carlos to paste CURRENT_STATE.md if build context needed
- At conversation end: log decisions to Notion Build Log

### Phase File Rules
- One file per phase: Phases/Phase_1.md, Phases/Phase_2.md etc.
- Sections indexed inside: ## 1.1, ## 1.2, ## 2.1 etc.
- Append only. Never rewrite past sections.
- Claude Code loads current phase file only unless debugging history.

---

## Game Identity

Title: VAULTED: The Ashen Court
Genre: Roguelike Isometric Action RPG
Platform: Steam — Windows / Linux
Logline: A cursed immortal descends through the ruins of a fallen kingdom,
collecting blood-pact cards that rewrite the rules of combat while the Ashen
Court curses him deeper with every floor.
Hook: You grow more powerful and more cursed at the same rate.
Making curses work for you is the game.
Inspirations: Vampire Survivors · Dead Cells · Elden Ring · Balatro · Slay the Spire

---

## Protagonist — The Cursed Knight

Heavy, armored, slow but devastating.
Lore: Last knight of the Ashen Court, cursed with immortality for a broken oath.
Visual: Tarnished gold armor, deep maroon cape, cracked visor.

| Stat | Value | Notes |
|---|---|---|
| HP | 100 | Armor absorbs first ~20% of hits |
| Armor | 20 | Separate pool, regens between floors |
| Move Speed | 140 px/s | Deliberately heavy |
| Attack Speed | 0.8/sec | Slow, weighty |
| Attack Damage | 18 | Per hit |
| Attack Arc | 120° forward | Directional — not 360° |
| Dodge Roll | 0.4s i-frames | No resource cost |

---

## Core Loop

```
Enter Floor → Fight waves (auto-attack + dodge)
    ↓
Clear all enemies
    ↓
[Every 3rd floor] Receive CURSE from Ashen Court
    ↓
Pick 1 of 3 PACT CARDS — activates INSTANTLY on pickup, same floor
    ↓
Next floor — harder enemies + damage scaling
    ↓
[Every 3rd floor] BOSS encounter
    ↓
Die → Choose 1 LEGACY RELIC → New run begins
```

---

## Card System

- Always-active passives. No hand. No play mechanic.
- Activate instantly on pickup — mid-floor, same wave.
- Offered 3-at-a-time. Pick 1. No skipping (MVP).
- Emit/consume tag architecture for emergent synergies.

| Type | Rune | Function |
|---|---|---|
| Augment | Blue | Adds behavior to existing attacks |
| Mutation | Purple | Changes HOW a mechanic works |
| Covenant | Red | Adds a new resource or mechanic |

Card schema (cards.json):
```json
{
  "id": "iron_echo",
  "name": "Iron Echo",
  "type": "augment",
  "rune_color": "blue",
  "description": "Every 5th attack releases a knockback shockwave",
  "emits": ["shockwave"],
  "consumes": ["attack_count"],
  "tags": ["attack_modifier", "knockback"],
  "effect": {
    "trigger": "every_nth_attack",
    "n": 5,
    "action": "shockwave_knockback",
    "radius": 120,
    "force": 300
  }
}
```

### MVP Card List (30 cards)

AUGMENTS
1. Iron Echo — Every 5th attack: knockback shockwave
2. Grave Chill — 15% chance to slow enemy 2s on hit
3. Ashen Trail — Dodge roll leaves damaging ash cloud 3s
4. Split Strike — Secondary projectile at nearest out-of-arc enemy
5. Weight of Guilt — +1 damage per active Curse carried
6. The Reaper's Arc — Attack arc widens to 160°
7. Chain Rattle — Kill shockwave stuns adjacent enemies briefly
8. Bone Splinter — 20% of damage dealt also hits nearby enemies
9. Cruelty Mark — First hit on each enemy deals double damage
10. Hollow Point — Attacks pierce through enemies in arc

MUTATIONS
1. Phantom Step — Dodge roll afterimage blocks 1 projectile
2. Inverse Guard — Armor absorbs from behind instead of front
3. Glass Knight — Armor removed. Attack speed +60%.
4. Berserker's Math — Damage scales inversely with current HP
5. Still Waters — No dodge roll. 1s immunity bubble every 8s.
6. The Slow Blade — Attack speed halved. Each attack 3× damage.
7. Echoing Vault — Dodge roll becomes cursor-position blink
8. Reversed Hunger — Healing damages you. Damage heals you 5%.
9. Oath of Stillness — While standing still: attack speed +100%
10. The Last Wall — HP capped at 40. Armor capped at 80. Regens passively.

COVENANTS
1. Bleeder's Oath — Introduces BLOOD. Taking damage → Blood. At 100: empowered burst.
2. The Iron Vow — Introduces RESOLVE. Enemies not killed in 5s → Resolve → damage bonus.
3. Pact of Echoes — Dodge roll leaves Shadow Clone that auto-attacks 4s.
4. The Collector — Enemies drop Soul Fragments. Every 100 = free card pick.
5. Marrow Pact — 20 kills charges BONE STRIKE: next attack 10× damage.
6. The Warden's Oath — Introduces WARD. 3 Wards per floor. Each absorbs 1 hit.
7. Cursed Mirror — Each Curse carried: +3% stacking damage bonus.
8. The Ashen Brand — Damaged enemies Branded. Branded kill in 3s → extra Fragments.
9. Blood Memory — Each floor cleared unhit: +5% damage. Resets on first hit.
10. The Final Covenant — Remove all cards. Gain ONE card combining all effects.

---

## The Curse Economy

Every 3 floors: Ashen Court imposes a Curse. Cannot be avoided. Scales with depth.
Intent: Curses are not just obstacles — advanced builds exploit them.

TIER 1 — Outer Ramparts (floors 1–3)
- Weighted Chains — Move speed -15%
- Cracked Visor — Enemy HP bars hidden
- Trembling Hand — Attack speed -20%
- Brittle Armor — Armor halved
- Blind Spot — Minimap disabled

TIER 2 — Cathedral Undercroft (floors 4–6)
- Blood Price — Each card pickup costs 5% max HP
- The Fog — 50% of floor shrouded until enemy aggro
- Echo Strike — Attacks deal 10% damage back to you
- Hollow Bones — Dodge roll cooldown doubled
- Cursed Sight — Projectiles invisible until 2 tiles away

TIER 3 — The Ashen Vault (floors 7–9)
- The Unraveling — One random passive card dormant for the floor
- Mirror Court — Shadow clone of player fights alongside enemies
- Void Hunger — HP drains 1%/sec; kills regenerate 5%
- Oath Broken — Attack arc flips to 180° behind you
- The Collector's Price — Every Relic Fragment costs 10% HP

---

## Synergy System

Direct — Card A explicitly feeds Card B's resource
Unexpected — Emergent interactions that feel like player discoveries
Curse — A curse that becomes an accelerant with the right cards
Environmental — Floor objects expose hooks that cards register against at pickup

Environmental interactions (MVP):
| Object | Card | Result |
|---|---|---|
| Torch pillars | Ashen Trail | Ash extinguishes torches → darkness zones |
| Crumbling walls | Iron Echo | Shockwave collapses walls → chokepoints |
| Blood pools | Bleeder's Oath | Accelerates Blood generation |
| Fog zones | Pact of Echoes | Clone navigates fog; player can't |
| Bone piles | Chain Rattle | Kill shockwave detonates → AoE |

Technical: Floor objects implement IInteractable interface.
Cards register environment hooks at pickup via card_manager.gd.

---

## Enemies

| Enemy | HP | Behavior |
|---|---|---|
| Shambler | 45 | Slow melee swarm |
| Wraith | 20 | Fast, short-range teleport |
| Arbalist | 30 | Ranged, leads shots, stays back |
| Knight (boss) | 350 | 3-phase, mirrors player moveset |

Boss phases:
- Phase 1 (100–66% HP): Learnable base patterns
- Phase 2 (66–33% HP): New mechanic (shield / teleport / minion spawn)
- Phase 3 (33–0% HP): Attacks gain modifier from current floor's active Curse

---

## Zones

| Floors | Zone | Palette |
|---|---|---|
| 1–3 | Outer Ramparts | Ash grey, amber torchlight |
| 4–6 | Cathedral Undercroft | Purple shadow, bone white |
| 7–9 | The Ashen Vault | Black, deep crimson |
| 10 | The Court | Gold and ash, full desaturation except player |

---

## Endless Mode — The Abyss

Unlocks after floor 10. No floor cap.
- Every 5 Abyss floors: 2 curses simultaneously
- Card pool shrinks progressively
- Abyss Echoes: Ghost of previous run spawns as enemy. Strength = previous best depth.

---

## Leaderboards

Score = (Floors Cleared × Enemies Killed) × (1 + Active Curses × 0.5)
      + (Known Synergy Combos × 100) - (Deaths × 500)

Boards: Global All-Time · Weekly Cursed Run (same seed all players) · Friends · Build boards

---

## Legacy Relics

| Relic | Effect |
|---|---|
| Ashen Crown | Start every run with 1 extra card pick |
| The Unmarked Grave | First death per run: revive at 25% HP |
| Blood Memory | Covenant held 3+ runs: available from floor 1 |
| Void Shard | Start with Void Hunger curse + Cursed Mirror card |
| Knight's Debt | Start at 50% HP, attack damage +40% |
| The Hollow Seal | Armor starts at 0, dodge roll +2 charges |
| The Court's Brand | Start with 1 random Curse, score multiplier +0.5× |
| Echo Fragment | Start with Shadow Clone active for floor 1 |

---

## Tech Stack

| Layer | Decision |
|---|---|
| Engine | Godot 4 + GDScript |
| Data | JSON files in res://data/ |
| Config files | cards.json, enemies.json, floors.json, curses.json |
| RNG | Seeded from run start — mandatory, never unseeded |
| Steam | GodotSteam plugin (Phase 3+) |
| Leaderboard backend | Supabase (Phase 4) |
| Tile size | 64×32 isometric |
| Camera | Fixed 45°, no rotation |

---

## Godot Project Structure

```
vaulted-game/
├── CLAUDE.md                  ← repo's + Design Authority block
├── baseline.md                ← ours, permanent
├── CURRENT_STATE.md           ← ours, rolling
├── ASSETS_NEEDED.md           ← repo's, we extend
├── Phases/
│   └── Phase_1.md             ← ours, append-only
├── .claude/                   ← repo's agents/skills/hooks/rules
├── project.godot
├── scenes/
│   ├── main_menu.tscn
│   ├── game.tscn
│   ├── player/player.tscn
│   ├── enemies/shambler.tscn, wraith.tscn, arbalist.tscn
│   ├── ui/hud.tscn, card_pick.tscn, death_screen.tscn, damage_number.tscn
│   └── floors/floor_base.tscn, boss_floor.tscn
├── scripts/
│   ├── autoload/
│   │   ├── game_data.gd
│   │   ├── card_manager.gd
│   │   ├── run_manager.gd
│   │   └── event_bus.gd
│   ├── player.gd
│   ├── enemy_base.gd
│   ├── floor_controller.gd
│   └── card_effect_base.gd
├── data/
│   ├── cards.json
│   ├── enemies.json
│   ├── floors.json
│   └── curses.json
└── assets/
    ├── sprites/, tiles/, audio/, ui/
```

---

## Signal Architecture — Mandatory

All cross-system communication via event_bus.gd. Never direct node refs across systems.

```gdscript
signal player_hit(damage: float)
signal player_died()
signal player_dodged(position: Vector2)
signal card_picked(card_id: String)
signal card_effect_triggered(effect_id: String, value: float)
signal enemy_died(position: Vector2, enemy_type: String)
signal enemy_spawned(enemy_id: int)
signal floor_cleared(floor_number: int)
signal wave_started(wave_number: int)
signal boss_phase_changed(phase: int)
signal curse_applied(curse_id: String)
```

---

## Art Direction

Style: Low-poly isometric, fixed 45° camera, no rotation.

| Element | Color |
|---|---|
| Environment | Ash grey, slate blue |
| Player | Tarnished gold, deep maroon |
| Enemies | Bone white, sickly green |
| Augment cards | Iron grey + blue rune |
| Mutation cards | Iron grey + purple rune |
| Covenant cards | Iron grey + red rune |
| FX | Deep crimson → bright red |
| UI | Dark slate, parchment text |

Asset sources:
- Kenney.nl — https://kenney.nl/assets (CC0, commercial-use)
- Quaternius — https://quaternius.com (CC0)
- OpenGameArt — https://opengameart.org
- Freesound — https://freesound.org

---

## Roadmap

| Phase | Scope | Timeline at 4 hrs/day |
|---|---|---|
| 0 | Pre-production | Complete |
| 1 | Night 1 MVP | 8–12 hours |
| 2 | Alpha | 10–14 days |
| 3 | Beta | 6–10 weeks |
| 4 | Early Access | 5–8 weeks |
| 5 | 1.0 Launch | 8–12 weeks |
| Total | Start → Steam | ~5–8 months |

---

## Open Decisions (not yet resolved)

| Decision | Needed by |
|---|---|
| Controller mapping layout | Phase 3 |
| Pricing strategy | Phase 4 |
| DLC zone concept and name | Phase 5 |
| Streamer/press outreach list | Phase 5 |
| NG+ modifier set | Phase 5 |