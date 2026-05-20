---
name: roblox-studio-bridge
description: Use to drive the Roblox Studio MCP effectively — patterns for script_read, multi_edit, execute_luau, screen_capture, search_game_tree, inspect_instance. Use during roblox-forge whenever code or state needs to be read from or written to an open Studio session, before any non-trivial Studio mutation, or when verifying changes at runtime.
domain: roblox-studio
audience: creator
artifact-type: skill
---

# Roblox Studio Bridge

Patterns for using the Roblox Studio MCP (`mcp__Roblox_Studio__*` in Claude Code, equivalent tools in Gemini / Codex when configured). Reference: `references/studio-mcp-cheatsheet.md`.

## When to use

- During `roblox-forge` when code needs to be written to a live Studio session.
- When verification depends on runtime behavior (execute Luau, capture console, screenshot).
- When walking an existing place's DataModel before proposing changes.
- Whenever asking the user to copy-paste is slower than direct MCP access.

## When not to use

- The user doesn't have the Studio MCP configured → fall back to patches + user paste-back.
- The task is purely about external assets / code without Studio state involvement.

## Discipline

### 1. Pick the right Studio

```text
list_roblox_studios
```

If more than one is open, ask the user which to target (`set_active_studio`). Don't assume.

### 2. Read before you write

Before `multi_edit`:
- `script_read` on each script you intend to modify → confirm exact current source (whitespace matters).
- For path discovery: `script_search` / `script_grep` to find by name or content.
- For state: `inspect_instance` / `search_game_tree`.

### 3. Batch writes with `multi_edit`

Atomic batch is one Studio undo step. Serial single edits clutter undo history.

```text
multi_edit with edits = [
  { path: "game.ReplicatedStorage.Shared.InventoryTypes", old: "...", new: "..." },
  { path: "game.ServerScriptService.Inventory.InventoryService", old: "...", new: "..." },
  ...
]
```

Each edit's `old` text must match the current source exactly. Use `script_read` first to copy exact whitespace.

### 4. Verify with `execute_luau` (do not implement with it)

`execute_luau` is a runtime probe, not a code-installation mechanism. Use it to:
- Print state: `print(Players:GetPlayers()[1]:GetAttribute("Level"))`
- Call a function for verification: `print(InventoryModule:GetItem(player, "sword"))`
- Trigger a remote as if from a player: `ReplicatedStorage.TradeStartRemote:FireServer({ targetUserId = 12345 })`

If a check needs to persist in the game, write it into a script via `multi_edit`.

### 5. Capture evidence

After non-trivial changes:
- `screen_capture` — visual evidence (UI changes, world / lighting changes)
- `get_console_output` — runtime warnings, errors, prints since last clear
- `execute_luau` returning a state snapshot — for data-only verification

These pair with `superpowers:verification-before-completion` — evidence before completion claims.

### 6. Choose context for `execute_luau`

- **server** context for: DataStore probes, server-state reads, RemoteEvent firing as a player, service-level inspection.
- **client** context for: UI tests, LocalScript behavior, input simulation, replication-receive checks.

Cross-context tests need both runs.

### 7. Play mode awareness

Studio has two DataModels: **Edit** and **Play** (in Play Solo / Run mode). They are separate. If you read `inspect_instance` while in Play mode, you're seeing the play DataModel, not the saved file. Surface this if relevant.

### 8. Asset insertion

For assets:
- `search_creator_store` — find by category / keyword
- `insert_from_creator_store` — drop into the open place
- `generate_material` / `generate_mesh` / `generate_procedural_model` — AI asset gen. Be **explicit** about scale, polycount, style.

### 9. Test cycle

Standard cycle when implementing in Studio:

```text
1. script_read (confirm current state)
2. multi_edit (apply changes)
3. execute_luau (run quick check) OR start_stop_play (full play test)
4. get_console_output (catch errors)
5. screen_capture (if visual)
6. iterate
```

## Common patterns

### Pattern: add a server-authoritative remote

```text
1. script_read on the target server module
2. multi_edit:
   - Add RemoteEvent under ReplicatedStorage
   - Add `OnServerEvent` handler with type + ownership + rate-limit checks
   - Update caller(s)
3. execute_luau (server context): fire the remote as a test player and check state changed
4. get_console_output: assert no warnings
```

### Pattern: refactor a script across multiple modules

```text
1. script_grep to find all references
2. script_read all affected files
3. multi_edit with all changes in one call
4. execute_luau to run the existing tests / a quick smoke check
5. get_console_output: assert clean
```

### Pattern: visual iteration

```text
1. multi_edit (apply UI / lighting / world change)
2. start_stop_play (enter Play Solo if needed for runtime view)
3. screen_capture
4. roblox-visual-verdict against reference
5. iterate or accept
```

## Anti-patterns

- ❌ `multi_edit` without prior `script_read` → mismatch on whitespace, edit rejects.
- ❌ Using `execute_luau` to "implement" — it doesn't persist.
- ❌ Multiple serial `script_edit` calls when `multi_edit` fits.
- ❌ Vague `generate_mesh` prompts → garbage output.
- ❌ Trusting `inspect_instance` from mid-Play-mode for "the saved state".
- ❌ Skipping `list_roblox_studios` and writing to the wrong place.

## Fallback when MCP is unavailable

In Gemini / Codex hosts where Studio MCP is not configured:
- Emit patches the user applies via Rojo or manual paste.
- Ask for paste-back of console output and screenshots.
- Lean on `roblox-pre-action` more strictly — without runtime verification, the design must be airtight.

## Output discipline

After any Studio session, summarize:
- Studio targeted (place name)
- Scripts touched (paths)
- Changes applied
- Verification evidence captured (console snippet, screenshot reference, test result)
