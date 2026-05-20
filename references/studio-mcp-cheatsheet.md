# Roblox Studio MCP — Cheatsheet

The Roblox Studio MCP (`mcp__Roblox_Studio__*` in Claude Code) gives direct read/write access to an open Studio session. Use it when it's faster and safer than asking the user to copy-paste code or screenshots.

## When to use the Studio MCP

| Situation | Tool to reach for | Why |
|-----------|------------------|-----|
| Need to see what's actually in the current place | `search_game_tree`, `inspect_instance` | Walk the live DataModel, not a stale `.rbxlx` |
| Need to read a specific script | `script_read` | Get the source as Studio sees it |
| Need to find code matching a pattern | `script_grep`, `script_search` | Cross-place text/regex search |
| Need to apply edits to multiple scripts atomically | `multi_edit` | One MCP call → one undo step in Studio |
| Need to verify behavior at runtime | `execute_luau` | Run code in server or client context for a quick check |
| Need to inspect the current viewport / UI | `screen_capture` | Visual evidence of changes |
| Need runtime logs | `get_console_output` | Catch warnings, errors, prints since last clear |
| Need to start / stop play test | `start_stop_play` | Toggle Play Solo for runtime verification |
| Need an asset | `search_creator_store`, `insert_from_creator_store` | Pull from official catalog |
| Need a custom material / mesh / model | `generate_material`, `generate_mesh`, `generate_procedural_model` | AI asset gen — be specific about constraints |
| Need to know which Studio to act on | `list_roblox_studios`, `set_active_studio` | Multiple Studios may be open |

## Default discipline

1. **`list_roblox_studios` first** when multiple Studios may be open. If more than one, ask the user which to target.
2. **Read before you write.** Use `script_read` or `inspect_instance` to confirm current state before `multi_edit`.
3. **Batch edits with `multi_edit`** rather than serial `script_edit` calls — keeps Studio's undo history clean.
4. **Use `execute_luau` for verification, not for production logic.** If a check needs to live in the game, write it into a script via `multi_edit`, then re-verify with `execute_luau`.
5. **Capture evidence after non-trivial changes.** `screen_capture` for visual, `get_console_output` for runtime errors, `execute_luau` returning a state snapshot for data changes.

## execute_luau contexts

`execute_luau` runs in either **server** or **client** context. Pick deliberately:
- **Server** for: DataStore probing, server-state reads, RemoteEvent firing as if from a player, service-level inspection.
- **Client** for: UI tests, LocalScript behavior, input simulation, replication-receive checks.

Cross-context tests need both runs.

## script_read / multi_edit tips

- Paths look like `game.ServerScriptService.MyModule` or `game.ReplicatedStorage.Shared.Inventory`.
- `script_read` returns the live source; if the user has unsaved local edits in Studio, those are what you see (good — that's the actual state).
- `multi_edit` accepts an array of `{path, old_text, new_text}` operations. Each operation must match exactly. Read first to get exact whitespace.

## screen_capture tips

- Resolution defaults match the user's viewport; call `mcp__Roblox_Studio__resize_window` if you need a specific aspect.
- Useful for: UI alignment checks, lighting / atmosphere verification, particle / VFX visual confirmation.
- Pair with `roblox-visual-verdict` skill when comparing against a reference image.

## Anti-patterns

- ❌ Looping `script_edit` once per file when `multi_edit` exists.
- ❌ Calling `execute_luau` to "implement" something — it doesn't persist.
- ❌ Trusting `inspect_instance` output from a Studio that's mid-Play-mode for "the current saved state" — Play mode is a separate DataModel.
- ❌ Calling `generate_mesh` / `generate_procedural_model` with vague prompts — be explicit about polycount, scale, style.

## Fallback when Studio MCP is unavailable

If the Studio MCP is not configured (Gemini / Codex hosts, or user hasn't installed the Studio plugin):
- Ask the user to paste relevant scripts.
- Ask for screenshots / console output as text.
- Provide changes as patches the user applies manually.
- Use `roblox-pre-action` template more strictly — verification depends on the user reporting back.
