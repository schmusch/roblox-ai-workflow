---
name: roblox-build-fix
description: Use to systematically diagnose and fix Rojo, Wally, Selene, StyLua, Luau-LSP, TestEZ, or other Roblox build / toolchain failures. Use when the user says "the build is broken", "Rojo won't sync", "Wally install fails", "selene reports", "luau-lsp errors", "tests fail", or any toolchain-level error blocks progress.
domain: process
audience: creator
artifact-type: skill
---

# Roblox Build Fix

Systematic debugging for the Roblox build toolchain: Rojo, Wally, StyLua, Selene, Luau-LSP, TestEZ / Jest-Roblox, Aftman / Foreman, GitHub Actions for these tools, and place-file sync issues.

Generic debugging works for runtime crashes inside Luau, but toolchain failures need toolchain knowledge — what `Wally install` actually does, why Rojo's port matters, what Selene's `selene.toml` shape looks like. This skill captures the Roblox-specific debugging pass.

Full toolchain reference lives in `references/roblox-build-toolchain.md` — common errors, fix patterns, manifest schemas. This skill walks the diagnostic flow.

## When to use

- The build is failing and the failure is in tooling, not in game logic.
- The user says: "Rojo won't sync", "Wally install fails", "selene reports unused", "luau-lsp can't find module", "stylua won't format", "TestEZ can't find files", "GitHub Actions fails".
- A change "looks right" but tooling rejects it.
- Onboarding a new project and tooling isn't connecting yet.

## When not to use

- The runtime is throwing inside game code → use `superpowers:systematic-debugging` for the generic systematic approach, or just trace the runtime stack.
- The toolchain works fine and the issue is gameplay logic → wrong skill.
- The user wants a fresh toolchain setup from scratch on a brand-new project → that's a `roblox-blueprint` deliverable; this skill fixes existing toolchain.

## What this skill produces

A diagnostic + fix sequence:
- **Reproduction** — the exact command and the exact error.
- **Hypothesis ladder** — most likely causes, ranked.
- **Evidence-gathering steps** — what to check first.
- **Fix** — the concrete change.
- **Verification** — re-run the failing command and confirm it now passes.

## Method

### 1. Get the exact error

Don't act on "the build is broken". Get:
- The exact command the user / CI ran.
- The exact error output (stack, line numbers, file paths).
- The platform (Windows / macOS / Linux — Windows path quirks matter for Rojo).
- The tool versions (`rojo --version`, `wally --version`, `selene --version`, etc.).

If any are missing, ask before guessing.

### 2. Classify the failure

Which tool is failing? Each has typical failure modes:

| Tool | Typical failures |
|------|------------------|
| **Rojo** | port conflict, project.json schema, missing service in tree, Studio plugin version mismatch, path separators on Windows |
| **Wally** | registry unreachable, package not found, version constraint conflict, lock file out of sync, scoped name typo |
| **Aftman / Foreman** | version pin missing, tool not in PATH, install path conflict, GitHub rate limit |
| **Selene** | config schema error, missing standard library, false positive needing config tweak |
| **StyLua** | config schema, line ending issues (CRLF / LF), conflicting `.editorconfig` |
| **Luau-LSP** | path resolution, missing definitions, FFlag mismatch, sourcemap not generated |
| **TestEZ / Jest-Roblox** | suite path glob, framework import path, missing test runner script |
| **GitHub Actions** | tool install step missing, cache key, Windows runner vs Linux runner differences |

See `references/roblox-build-toolchain.md` for detailed failure modes per tool.

### 3. Form a hypothesis ladder

Don't shotgun fixes. Rank likely causes 1-2-3:

Example for "Rojo won't sync to Studio":
1. **Studio plugin / CLI version mismatch** — most common.
2. **Port already in use** — another Rojo session is running.
3. **Project file schema** — recently edited `default.project.json` and broke it.
4. **Firewall** — Windows Defender blocking the port.

### 4. Test the top hypothesis

For each, what's the cheapest evidence?
- Version mismatch → `rojo --version` and Studio plugin "About" pane.
- Port in use → `netstat -ano | findstr 34872` (Windows) or check whether another Rojo CLI is running.
- Schema → `rojo build` (will print schema errors).
- Firewall → temporarily allow the binary; see if sync starts.

### 5. Fix and verify

Apply the smallest change that addresses the confirmed cause. Re-run the failing command. Confirm pass.

If the fix didn't work → the hypothesis was wrong; go to the next one. **Don't compound fixes** without confirmation each was needed; that creates phantom-fix codebases.

### 6. Capture the lesson if generalisable

If the same error has bitten the project before, or is likely to bite again:
- Document it in the project's `README.md` "Troubleshooting" section.
- Add a `.editorconfig` or `selene.toml` entry that prevents recurrence.
- Add a CI step that catches it earlier.

### 7. Run the full suite once green

After the targeted fix, run **all** the relevant build steps once to confirm no regression:
- `rojo build` (manifest valid).
- `wally install` (deps resolve).
- `stylua --check .` (formatting clean).
- `selene .` (lint clean).
- `luau-lsp analyze` (typecheck clean).
- The test suite (`run-tests.sh` or whatever the project uses).

If any other tool now fails, the original fix may have had a side effect — investigate.

## Common patterns (quick reference)

Full catalog in `references/roblox-build-toolchain.md`. Top 5:

1. **Rojo port in use** → kill the other process or change `port` in `default.project.json`.
2. **Wally lock-file conflict** → `wally install --check` to confirm, then `wally update <pkg>` selectively (not full `wally update` blindly).
3. **Selene unused variable** → use `_` prefix for intentionally unused, or add to `selene.toml` allowed list.
4. **Luau-LSP "cannot find module"** → confirm `sourcemap.json` is generated (`rojo sourcemap default.project.json -o sourcemap.json`) and that `luau-lsp` config points to it.
5. **StyLua / Selene disagree** → they cover different concerns. StyLua = formatting, Selene = lint. Both can run; conflicts are usually about line length and resolved in respective configs.

## Anti-pattern checks

- ❌ Shotgun fixes — changing 5 things at once and one of them happens to work. Now the codebase has 4 unnecessary changes and no learning.
- ❌ "Reinstall everything" before checking the actual error.
- ❌ Updating tool versions while debugging an unrelated error — introduces new variables.
- ❌ Committing a `wally.lock` change without verifying the dep resolution change was intended.
- ❌ Suppressing the error (e.g., adding a Selene rule to ignore it) without understanding what it caught.
- ❌ Fixing the build in dev but not adding CI coverage — same break recurs in CI.

## Roblox-specific framing

Generic build-debug works for Webpack, Vite, Maven, etc. Roblox-specific overlays:
- **Rojo is unusual** — it's a sync server, not a bundler. Failures often involve the live Studio session.
- **Wally registry is small** — packages may not exist; falling back to git submodule or vendoring is normal.
- **Studio plugins out-of-band** — the Studio side has its own version (Rojo plugin, MCP plugin) that must match the CLI.
- **Aftman / Foreman** pin tool versions per repo; the right `aftman.toml` matters.
- **`sourcemap.json`** is the bridge from Rojo paths → Luau LSP paths. If LSP is confused, regenerate.

## Handoff

- Build clean → continue with the work that was blocked (`roblox-forge`, `roblox-tdd`, etc.).
- Build clean but the original goal still needs verification → run `roblox-ultraqa`.
- Recurring breakage → document in repo README and harden CI.
- Toolchain was set up wrong from the start → flag for a config refactor (separate `roblox-plan` task).
