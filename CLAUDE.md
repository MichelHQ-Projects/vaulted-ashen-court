# CLAUDE.md — VAULTED: The Ashen Court

> Read this file at every session start. Do not modify without Design Partner approval.

Indie game development managed through 48 coordinated Claude Code subagents.
Each agent owns a specific domain, enforcing separation of concerns and quality.

## Technology Stack

- **Engine**: Godot 4
- **Language**: GDScript
- **Version Control**: Git with trunk-based development
- **Build System**: Godot 4 headless export
- **Asset Pipeline**: Godot 4 native importer — res://assets/ (sprites, tiles, audio, ui)

## Project Structure

@.claude/docs/directory-structure.md

## Engine Version Reference

@docs/engine-reference/godot/VERSION.md

## Technical Preferences

@.claude/docs/technical-preferences.md

## Coordination Rules

@.claude/docs/coordination-rules.md

## Collaboration Protocol

**User-driven collaboration, not autonomous execution.**
Every task follows: **Question -> Options -> Decision -> Draft -> Approval**

- Agents MUST ask "May I write this to [filepath]?" before using Write/Edit tools
- Agents MUST show drafts or summaries before requesting approval
- Multi-file changes require explicit approval for the full changeset
- No commits without user instruction

See `docs/COLLABORATIVE-DESIGN-PRINCIPLE.md` for full protocol and examples.

## Coding Standards

@.claude/docs/coding-standards.md

## Context Management

@.claude/docs/context-management.md

---

## Session Start Protocol

1. Read baseline.md
2. Read CURRENT_STATE.md
3. Read Phases/Phase_X.md (current phase only)

## Session End Protocol — Mandatory

1. Overwrite CURRENT_STATE.md with current build state
2. Append completed work unit to Phases/Phase_X.md
3. Update ASSETS_NEEDED.md if new assets identified

---

## Context File Rules

| File | Rule |
|---|---|
| baseline.md | Read only. Never modified. |
| CURRENT_STATE.md | Overwrite at session end. Always. |
| Phases/Phase_X.md | Append only. Never rewrite past sections. |
| CLAUDE.md | Read only. Never modified without Design Partner approval. |

---

## Code Rules

- GDScript only. No C#.
- Seeded RNG always — never unseeded. Seed from run start.
- All game data in JSON files under res://data/
- No hardcoded stats, damage, or speeds — always reference constants or data files.
- Tile size: 64×32 isometric
- Camera: fixed 45°, no rotation
- All cross-system communication via event_bus.gd — never direct node refs across systems.
- Never add signals not in baseline.md without logging the decision first.

---

## Agent Roles — Phase 1

| Agent | Owns |
|---|---|
| Engine Architect | 1.1 Project Scaffold, 1.2 Player Controller |
| Systems Designer | 1.3 Enemy AI, 1.4 Card System, 1.5 Floor Controller |
| UI/UX Builder | 1.6 HUD & Card Pick, 1.7 Boss/Death/Menu |
| QA / Integration | 1.8 Integration, QA, Export |

---

## Pending Design Decisions

None. Log here as they arise.
Format: [ID] — [Question] — Assumed: [assumption] — Needs: Carlos review
