---
name: roblox-ask-other-model
description: Use to consult a different LLM (Claude / Gemini / GPT / local) for a second opinion on a Roblox question — design choice, code review judgment, ambiguity resolution. Use when the user says "ask Gemini what it thinks", "second opinion", "consult another model", "what does Claude say", "cross-check this".
domain: process
audience: creator
artifact-type: skill
---

# Roblox Ask Other Model

Cross-model consultation. Useful when the current model is uncertain, when a design choice has no clear right answer, or when the user wants a sanity check from a different reasoning lens.

This is only meaningful in **multi-model setups** — Claude Code as primary with Gemini / GPT available, or vice versa. In single-model environments, this skill is a no-op (just note the limitation).

## When to use

- A design judgment where the current model is genuinely uncertain.
- The user says: "ask Gemini", "what does Claude say", "second opinion", "consult another model", "cross-check this".
- A `roblox-code-review` finding the user wants double-checked.
- A `roblox-security-review` edge case where another model's perspective might catch what this one missed.
- A trade-off question with no clear right answer (e.g., "should I use Attributes or RemoteEvent for this state?").

## When not to use

- Quick factual question — just answer it.
- Question with an authoritative source (Creator Docs, Wally registry) → use `roblox-deepsearch`.
- The user wants a single decisive answer — multi-model consultation introduces noise unless the user actively wants the diverse input.
- Trivial questions where consultation overhead exceeds the question's value.
- Sensitive data — be careful about what gets sent to which model. If the user has put secret game-design IP into the conversation, do not silently pipe it elsewhere.

## What this skill produces

A structured cross-model consultation:
- **Question framed for the other model** — concise, self-contained, includes necessary context.
- **The other model's response** — captured verbatim.
- **Synthesis** — what the two models agree on, where they differ, what the user should weigh.
- **Recommendation** — usually still from the primary model, informed by the second opinion.

## Method

### 1. Check what's actually available

Before claiming you'll consult another model, confirm:
- Is there a tool / MCP for the other model? (`mcp__ask-gemini`, `mcp__ask-claude`, or similar.)
- Does the user have an API key configured?
- Is the consultation cost / latency acceptable for this question?

If no other model is reachable → tell the user. Offer to **simulate a second pass** by re-reasoning the question from a deliberately different angle, but state clearly that that's not a real second model.

### 2. Frame the question for cold context

The other model will not have this conversation's history. Write the question as a self-contained prompt:
- The user's original ask.
- The relevant code / context (paste, not link — the other model can't open files).
- The current model's draft answer (so the other model is reviewing, not duplicating work).
- A specific ask: "review this answer for correctness", "propose alternatives", "identify what I missed".

### 3. Send and capture

Use the available consultation tool. Capture the response verbatim. Do not paraphrase it on the way back — the user wants the other model's actual words.

### 4. Synthesize

Read the other model's response carefully. Identify:
- **Agreements** — points where both models say the same thing. High confidence.
- **Disagreements** — points where they differ. Surface these explicitly.
- **New angles** — anything the other model raised that this one missed.
- **Errors** — if the other model is clearly wrong (e.g., cites a deprecated API as current), say so.

### 5. Make a recommendation

Usually still the current model's recommendation, informed by:
- Agreements → reinforces confidence.
- Disagreements → the user decides; surface the trade-off.
- New angles → consider whether to incorporate.
- Errors → don't follow the other model into them.

If the question genuinely is "I disagree with my code reviewer, who's right" — present both views fairly and let the user decide.

## Output format

```markdown
## Cross-model consultation — <question>

### Question sent to <other model>
> "<exact prompt sent>"

### <Other model>'s response
> "<verbatim response>"

### Synthesis
- **We agree:** ... (1-3 points)
- **We disagree:**
  - On X: this model says A, <other> says B. The trade-off is ...
- **<Other> raised that this model missed:** ...
- **<Other> got wrong:** ... (if any)

### Recommendation
<final position, informed by both views>
```

## Anti-pattern checks

- ❌ Calling this skill in a single-model environment and pretending you consulted — just be honest.
- ❌ Sending the other model bare URLs or "see file X" — it can't open them.
- ❌ Sending unrelated conversation context that bloats the cost.
- ❌ Paraphrasing the other model's answer instead of quoting it — defeats the second-opinion purpose.
- ❌ Treating other-model agreement as proof — both models can share the same bias / training-data gap.
- ❌ Treating other-model disagreement as automatic veto — sometimes this model is right and the other is wrong.
- ❌ Leaking sensitive content (game-design IP, private repos) to an external model without user awareness.

## Roblox-specific framing

Generic cross-model consultation works for any task. Roblox-specific touches:
- **Roblox APIs are niche** — both models may be equally uncertain on recent changes. `roblox-deepsearch` against Creator Docs is more reliable than asking a second model for live-API behavior.
- **Server-authority and anti-slop are unambiguous** — both models should agree; disagreement on these is a sign one is wrong, not that the question is hard.
- **Psychology / design judgment** — genuinely subjective; second opinion useful.
- **Implementation choice** (Attributes vs RemoteEvent, KnitService vs flat ModuleScript) — often legitimate ambiguity; second opinion useful.

When the question is "what does the API actually do", prefer `roblox-deepsearch`. When the question is "what's the right design", second-model consultation can help.

## Handoff

- Both models agree + user accepts → proceed.
- Models disagree + user decides → proceed with chosen path.
- New angle uncovered → incorporate into the active `roblox-plan` / `roblox-blueprint`.
- Both models were unsure → run `roblox-deepsearch` for doc-grounded answer, or ask the user for direction.
