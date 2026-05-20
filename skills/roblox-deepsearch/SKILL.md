---
name: roblox-deepsearch
description: Use to answer a Roblox question by grounding the answer in current Roblox Creator Docs, Wally package registry, DevForum, and existing project code — not from memory. Use when the user says "research X", "what's the current best practice for Y", "find the docs", "look it up", "is there a package for", or when an API may have changed since training.
domain: process
audience: creator
artifact-type: skill
---

# Roblox Deepsearch

Doc-grounded research. Roblox APIs, best practices, and packages change. Memory-based answers go stale. This skill structures the research so the answer is grounded in current sources.

Replaces `roblox-autoresearch` (autonomous variant) — they were doing the same thing. This skill is one capability, called manually when needed.

## When to use

- The user asks about a Roblox API and you're not 100% sure it's current.
- The user asks for a best-practice answer and you want to cite, not assert.
- The user asks if a Wally package exists for X.
- An API behavior is in question (e.g., "does `:WaitForChild` still throw on timeout?").
- Before writing a `roblox-blueprint` that depends on a feature you haven't used recently.

## When not to use

- The user asked a question you fully know the answer to with current knowledge.
- The work is purely about local code that doesn't depend on external info → just read the code.
- Quick lint / naming question — overkill.

## What this skill produces

A grounded research answer:
- The **question** restated precisely.
- **Sources consulted** — Creator Docs URLs, Wally registry entries, DevForum threads, project files.
- **Answer** — synthesised from sources, with inline citations.
- **Currency note** — "this answer reflects sources as of <date>; verify if more than ~6 months old".
- **Confidence level** — high / medium / low based on source agreement.

## Method

### 1. Frame the question precisely

Before searching: write the question as one sentence with all qualifiers. Vague questions produce vague answers.

❌ "How does data saving work?"
✅ "Is `UpdateAsync` still the recommended way to handle race conditions across multiple servers writing the same player key, as of 2024-2025?"

### 2. Choose the source set

For Roblox API behavior:
- **Roblox Creator Docs** — the canonical source. Use context7 if available (`mcp__plugin_context7_context7__*`) or browser-MCP / web fetch to query `create.roblox.com/docs/...`.
- **Roblox DevForum** — current community practice; especially good for "is this approach still recommended" questions.
- **GitHub** — example implementations in popular open-source Roblox projects.

For Wally packages:
- **Wally registry** — `wally.run` is the canonical index.
- The package's GitHub README for API and version compatibility.

For project-internal questions:
- The repo itself — search the codebase via available code search.
- The place file via Studio MCP `script_search` / `script_grep`.

### 3. Run the search

Use available tools:
- `context7` MCP for library docs if installed (fastest, current).
- Browser / web-fetch for Creator Docs / DevForum.
- Studio MCP `script_grep` for in-place code.
- Repo grep for codebase code.

Issue **at least two queries** with different phrasings to catch terminology mismatches.

### 4. Read the sources — don't just link them

Open the top 2–3 results and **read** them. A search snippet is not a source. Quote the relevant passage and verify it's saying what you think.

### 5. Cross-check

If sources disagree:
- Newer source > older source (publication date matters).
- Official Roblox doc > DevForum opinion > Twitter / blog.
- Code that runs > prose that describes the code.

If all sources agree → high confidence. If they disagree → medium confidence; surface the disagreement in the answer.

### 6. Synthesize

Write the answer in the user's terminology (German chat / English skill content). Cite inline. State currency. State confidence.

If you can't find a good source → say so. "I couldn't find an authoritative answer to this from current docs; the most recent DevForum thread is from 2022 and says X — verify before depending on this." That's better than confidently asserting from memory.

## Output format

```markdown
## Research — <question>

### Question
> "<the precise question>"

### Sources consulted
- Roblox Creator Docs — DataStores: <URL> (last updated by source: <date if shown>)
- DevForum thread — "DataStore retry pattern" — <URL> (2024-03)
- Wally — `Promise@v4.0.0` — <URL>
- Project file — `src/server/Wallet/Save.lua`

### Answer
<synthesised answer with inline citations like [1], [2]>

### Currency
Sources reviewed <today's date>. Stable answer; verify if revisiting in >6 months.

### Confidence
High / Medium / Low — reasoning

### Caveats
- Answer applies to <case>. For <other case> — see <other source>.
```

## Anti-pattern checks

- ❌ Citing a URL without having opened it.
- ❌ "According to my training data" — that's not a source; deepsearch exists precisely because training data is stale.
- ❌ Stopping at the first hit — always cross-check with at least one other source.
- ❌ Synthesising a confident answer from contradictory sources without noting the disagreement.
- ❌ Trusting Wikipedia for Roblox-specific API behavior — Creator Docs is canonical.
- ❌ Stale DevForum posts as authoritative for current behavior — note the date; recent > old.

## Roblox-specific framing

Generic doc search works for any topic. Roblox-specific overlays:
- **Roblox APIs change quietly** — `wait()` → `task.wait()`, `LegacyChat` → `TextChatService`, `LayoutOrder` semantics, etc. Always verify the API is current.
- **DevForum is a primary source** — Roblox engineers post there. Community posts there. It's not "just forum chatter" — it's where the live practice happens.
- **Wally is the package registry** — `npm` mental model doesn't quite apply; Wally manifests are TOML, packages are scoped, and the registry is much smaller and curated.
- **Studio behavior ≠ runtime behavior** in some cases (`RunService:IsStudio()`, plugin context). Be specific about which is being asked.

## Handoff

- Answer found → use it in `roblox-blueprint`, `roblox-plan`, or `roblox-forge`.
- Answer not found → escalate to the user with the gap clearly stated.
- Multiple credible sources disagree → present both to the user; let them decide which to follow.
- Found a Wally package the project should adopt → note it as a recommendation, but don't change `wally.toml` from within deepsearch (that's `roblox-forge`'s job).
