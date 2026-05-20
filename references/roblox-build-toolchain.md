# Roblox Build Toolchain — Patterns & Failure Modes

Reference for `roblox-build-fix` and `roblox-git-master`. Common Roblox tooling — Rojo, Wally, Aftman / Foreman, StyLua, Selene, Luau-LSP, TestEZ / Jest-Roblox — with typical workflows, failure modes, and fixes.

## The standard stack (modern Roblox)

| Tool | Purpose | Manifest |
|------|---------|----------|
| **Rojo** | Sync `src/*.lua` ↔ Studio | `default.project.json` |
| **Wally** | Package manager | `wally.toml`, `wally.lock` |
| **Aftman** (or Foreman) | Tool version pinning | `aftman.toml` / `foreman.toml` |
| **StyLua** | Code formatter | `stylua.toml` |
| **Selene** | Linter | `selene.toml`, `roblox.toml` (standard library) |
| **Luau-LSP** | Language server (editor) | `.luaurc` per directory |
| **TestEZ** / **Jest-Roblox** | Test runner | `testez.toml` or `jest.config.luau` |
| **Lune** | Headless Luau runtime (CI / scripts) | shebang `#!/usr/bin/env lune` |

Not every project uses all of these. Detect what's present, work with it; don't force missing tools.

## Rojo

### What it does
- Watches `src/*.lua` files.
- Syncs them into a running Studio session via the Rojo Studio plugin.
- Also can `build` the project into an `.rbxl` / `.rbxlx`.

### Manifest (`default.project.json`)

```jsonc
{
  "name": "MyProject",
  "tree": {
    "$className": "DataModel",
    "ReplicatedStorage": {
      "Packages": { "$path": "Packages" },
      "Shared": { "$path": "src/shared" }
    },
    "ServerScriptService": {
      "Server": { "$path": "src/server" }
    },
    "StarterPlayer": {
      "StarterPlayerScripts": {
        "Client": { "$path": "src/client" }
      }
    }
  }
}
```

### Typical commands

```powershell
rojo serve                 # start sync server on default port (34872)
rojo build -o place.rbxlx  # build to file
rojo sourcemap default.project.json -o sourcemap.json  # for luau-lsp
```

### Common failures

| Symptom | Likely cause | Fix |
|---------|--------------|-----|
| "Studio plugin not connecting" | Version mismatch between CLI and plugin | Update both to same minor version; check `aftman.toml` |
| "Port already in use" | Another Rojo CLI session running | Kill the other or change `port` in project json |
| "Path not found" | Mistyped `$path` value | Verify path; on Windows use forward slashes |
| "Cannot sync — partition conflicts" | Two project entries claim the same Studio path | Consolidate or remove duplicate |
| "Schema error in project file" | Invalid JSON or unknown key | Run `rojo build` to get exact schema error |
| Place file diff explodes after sync | The Studio session had unsaved edits | Commit Rojo as source of truth; don't sync from Studio back to disk |

### Tips
- Always run `rojo sourcemap` after layout changes; Luau-LSP needs the latest.
- Use `$properties` in project json to set Service properties (e.g., `StreamingEnabled`).
- For projects with assets in `.rbxm` files alongside code: use `$path` pointing to a folder, Rojo will load both.

## Wally

### What it does
- Roblox-specific package manager.
- Reads `wally.toml`, resolves dependencies, fetches packages from `wally.run` registry.
- Generates `Packages/`, `DevPackages/`, `ServerPackages/`.
- Lock-file (`wally.lock`) pins exact versions.

### Manifest (`wally.toml`)

```toml
[package]
name = "myorg/myproject"
version = "0.1.0"
registry = "https://github.com/UpliftGames/wally-index"
realm = "shared"

[dependencies]
Promise = "evaera/promise@4.0.0"
Signal = "sleitnick/signal@2.0.1"

[server-dependencies]
ProfileService = "loleris/profileservice@1.6.0"

[dev-dependencies]
TestEZ = "roblox/testez@0.4.1"
```

### Typical commands

```powershell
wally install        # install per wally.toml + wally.lock
wally update <pkg>   # bump one package
wally update         # bump everything (review diff carefully)
wally publish        # publish a package (uncommon for game projects)
```

### Common failures

| Symptom | Likely cause | Fix |
|---------|--------------|-----|
| "Package not found" | Typo in scope or name; package not on the registry | Check `wally.run` for the canonical name |
| "Version constraint conflict" | Two dependencies want incompatible versions | Inspect with `wally install --check`; bump or pin to a compatible set |
| "Lock file out of sync" | Manifest changed without re-locking | Run `wally install` to regenerate the lock |
| "Failed to fetch package" | Network / registry unreachable | Check network; retry; pin to a specific commit if needed |
| `Packages/` missing after fresh clone | Forgot to run `wally install` | Run it; add to CONTRIBUTING.md |

### Lock-file discipline
- Commit `wally.lock` always.
- Treat as authoritative — `wally install` reads it to reproduce exact versions.
- Lockfile conflicts on merge: regenerate by re-running `wally install` on the merged manifest.

## Aftman / Foreman

### What they do
- Pin tool versions per repo so every developer / CI uses the same Rojo, Selene, StyLua, Wally, Lune.
- Aftman is the modern replacement; Foreman is the legacy one with similar role.

### Manifest (`aftman.toml`)

```toml
[tools]
rojo = "rojo-rbx/rojo@7.4.0"
wally = "UpliftGames/wally@0.3.2"
selene = "Kampfkarren/selene@0.27.1"
stylua = "JohnnyMorganz/StyLua@0.20.0"
lune = "lune-org/lune@0.8.5"
```

### Typical commands

```powershell
aftman install        # install pinned tool versions
aftman add <tool>     # add a new pinned tool
```

### Common failures

| Symptom | Likely cause | Fix |
|---------|--------------|-----|
| "Tool not in PATH" | `aftman install` not run, or PATH not set | Run install; ensure `$HOME/.aftman/bin` on PATH (Windows: `%USERPROFILE%\.aftman\bin`) |
| "GitHub rate limit" | Anonymous fetch limit hit on a fresh CI | Add `GITHUB_TOKEN` env var |
| "Version conflict between tools" | Two tools wanting incompatible Wally registry versions | Pin tool versions explicitly; rarely an issue |

## StyLua

### What it does
- Auto-formatter for Luau. Like Prettier / gofmt.

### Manifest (`stylua.toml`)

```toml
column_width = 100
line_endings = "Unix"
indent_type = "Spaces"
indent_width = 4
quote_style = "AutoPreferDouble"
call_parentheses = "Always"
```

### Commands

```powershell
stylua --check .       # check formatting (CI)
stylua .               # format in place
```

### Common failures

| Symptom | Likely cause | Fix |
|---------|--------------|-----|
| "Line ending differences" | CRLF on Windows, LF expected | Set `line_endings = "Unix"` and `.gitattributes` `* text=auto eol=lf` |
| "stylua --check fails in CI but passes locally" | Local stylua version differs | Pin via Aftman |
| "Reformats my carefully-aligned table" | StyLua doesn't preserve alignment | Accept it; or use `-- stylua: ignore` comment for the block |

## Selene

### What it does
- Linter for Luau. Catches unused variables, suspicious patterns, deprecated APIs.

### Manifest (`selene.toml`)

```toml
std = "roblox"

[lints]
unused_variable = "warn"
empty_if = "warn"
shadowing = "warn"
```

The `std = "roblox"` tells Selene the Roblox standard library shape — it knows `game`, `workspace`, `script`, `task`, etc. exist.

### Commands

```powershell
selene .          # lint all .lua files
selene src/       # lint a specific path
```

### Common failures

| Symptom | Likely cause | Fix |
|---------|--------------|-----|
| "Global `X` is not defined" | Missing `std = "roblox"` | Add to selene.toml |
| "Unused variable `_event`" | Want to keep the binding but mark it intentionally unused | Use `_` prefix or `selene: allow(unused_variable)` |
| "Selene reports `wait()` as deprecated" | Code uses `wait()` instead of `task.wait()` | Migrate to `task.wait()` |
| "Standard library file not found" | `roblox.toml` not present in repo or wrong path | Add `roblox.toml` to the repo root (or vendor it from Selene's templates) |

## Luau-LSP

### What it does
- Language server for Luau in editors (VS Code, Zed, Neovim).
- Type-checks, autocomplete, go-to-definition.

### Common failures

| Symptom | Likely cause | Fix |
|---------|--------------|-----|
| "Cannot find module `Packages.Promise`" | `sourcemap.json` missing or outdated | `rojo sourcemap default.project.json -o sourcemap.json` |
| "Types are all `any`" | Source not typed; module return type unknown | Add type annotations: `type Foo = { ... }; return Foo` |
| "Editor doesn't show errors" | LSP not configured to read repo's sourcemap | Configure editor: `"luau-lsp.sourcemap.enabled": true`, `"luau-lsp.sourcemap.sourcemapFile": "sourcemap.json"` |
| "Strict mode warnings everywhere" | `--!strict` annotation on files | Either embrace strict typing or relax to `--!nonstrict` per file |

## TestEZ / Jest-Roblox

See `references/roblox-test-patterns.md` for full setup. Common failures:

| Symptom | Likely cause | Fix |
|---------|--------------|-----|
| "Test runner finds no tests" | `spec`/`test` files in wrong location or wrong suffix | Confirm runner config (`testez.toml` or `jest.config.luau`) matches actual file paths |
| "Require fails inside test" | Sourcemap not generated; Lune can't find module | Regenerate sourcemap; pass it to Lune |
| "Tests pass in Studio but fail in Lune" | Test touches engine globals only available in Studio | Mock those surfaces; see test patterns reference |

## Lune

### What it does
- Headless Luau runtime, faster than full Studio. Great for CI and scripts.

### Common uses
- Running TestEZ / Jest-Roblox suites.
- Code-generation scripts.
- Build scripts that touch place files.

### Common failures

| Symptom | Likely cause | Fix |
|---------|--------------|-----|
| "Lune doesn't know `game`, `workspace`" | Lune is not Studio; doesn't have Roblox globals | Either mock them, or run in Studio for engine-dependent tests |
| "Lune script hangs on `task.wait`" | Lune supports `task` but behaves differently | Use `task.delay` carefully or shorten waits |

## CI pipeline (GitHub Actions)

Typical Roblox repo CI:

```yaml
name: CI
on: [push, pull_request]
jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: ok-nick/setup-aftman@v0  # or rojo-rbx/setup-foreman
      - run: aftman install
      - run: wally install
      - run: rojo sourcemap default.project.json -o sourcemap.json
      - run: stylua --check .
      - run: selene .
      - run: lune run tests/run-tests.lua
```

### CI gotchas
- **Windows vs Linux line endings** — set `.gitattributes` to normalise.
- **Aftman GitHub rate limit** — add `GITHUB_TOKEN`.
- **Wally registry rate limit** — uncommon but possible; cache `Packages/` between runs.
- **In-Studio runtime tests** — can't run in headless CI; reserve for nightly Studio plugin or manual.

## Quick fix flowchart (when something breaks)

1. **What command failed?** Get the exact line.
2. **Which tool?** Identify from the error.
3. **Version sanity check** — `rojo --version`, `wally --version`, `selene --version`. Compare against `aftman.toml`.
4. **Cache / regenerate** — `aftman install`, `wally install`, `rojo sourcemap`.
5. **Read the actual error** — don't shotgun.
6. **Cross-reference this doc** for the symptom.
7. **If still stuck** — bisect: `git log --oneline` for recent changes that might have introduced the issue.

## Anti-patterns

- ❌ `wally update` without args, casually — bumps everything; review danger.
- ❌ Pinning Rojo / Wally / Selene globally instead of per-repo — version drift.
- ❌ Suppressing Selene rules instead of fixing the underlying issue.
- ❌ Disabling StyLua because "it changes my code" — that's its job.
- ❌ Committing `sourcemap.json` or `Packages/` — both generated.
- ❌ Letting CI break for weeks; only fixing when blocking a release.
