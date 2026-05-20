---
name: roblox-deep-interview
description: Use for deep Socratic requirements gathering on complex or ambiguous Roblox briefs — beyond what roblox-brief handles. Use when the brief is large, the user is uncertain, or when "the creator vision" is hand-wavy and needs structured probing. User signals: "let's talk it through", "I'm not sure yet", "help me figure out what I want", "deep dive on this idea".
domain: process
audience: creator
artifact-type: skill
---

# Roblox Deep Interview

Socratic requirements gathering for complex creator briefs. `roblox-brief` does quick clarification — genre, audience, scale. `roblox-deep-interview` is the long-form version: when the creator is uncertain, the vision is broad, or the brief touches multiple deep design surfaces (psychology, retention, social, economy) at once.

This skill produces a **defensible creator vision document** that downstream skills (`roblox-blueprint`, `roblox-blueprint-psychology`, `roblox-plan`) can rely on without re-asking the same questions.

## When to use

- The creator's brief is high-level and ambiguous ("I want to make a Roblox game with vibes").
- The brief touches multiple psychology drivers at once (Progression + Status + Community) — they need to be untangled.
- The creator says: "let's talk it through", "I'm not sure", "help me figure out what I want", "I have ideas but they're scattered".
- Before a large `roblox-blueprint` for a multi-month project.
- The creator has a reference experience in mind but can't articulate what about it works.

## When not to use

- Brief is already concrete (audience, genre, scope all named) → run `roblox-brief` (the quick version) or skip to `roblox-blueprint`.
- The creator wants to start building immediately — push back, but acknowledge the deep interview is a real time cost.
- The creator has done this before and just wants the standard tycoon / obby / etc. — overkill.

## What this skill produces

A structured creator-vision document covering:
1. **Player desire arc** — the dominant driver and supporting drivers (per `references/psychology-framework.md`).
2. **First-session promise** — what the player feels in their first 5 minutes.
3. **The pull** — why they come back tomorrow, in a week, in a month.
4. **Reference experiences** — named Roblox titles (or non-Roblox) that capture parts of the vision, with explicit "what about them" notes.
5. **Anti-vision** — what this game is **not** trying to be. (Critical — protects against feature creep.)
6. **Monetization stance** — cosmetic-only? gamepass-driven? developer-products? Premium-only? No monetization?
7. **Audience reality** — demographics, region, session-length, social context (`references/psychology-framework.md` + `roblox-brief-audience` framework).
8. **Constraints** — solo dev / small team / budget / timeline / platform (mobile-first vs. desktop vs. console).
9. **Risks the creator already feels** — listed before we add more.

## Method

This is a conversation, not a checklist. The skill structures the conversation so it covers the surface without feeling like a form.

### 1. Open with intent, not features

Ask, **before any feature question**:
- *"If a player tells a friend about your game in one sentence, what do you want them to say?"*
- *"What's the feeling you want a player to have in their first 5 minutes?"*
- *"What experience did you play that made you want to make this one?"*

Capture the answers verbatim. They are the north star.

### 2. Probe the dominant driver

Walk `references/psychology-framework.md` mentally and ask:
- *"Is this game more about getting stronger, or showing off, or being there in the moment, or mastering a skill, or playing with friends?"*
- If they say multiple: *"If you had to pick the one this game can't live without, which one?"*

Force a primary. Allow 1–2 supporting. The skill `roblox-brief-motivation` formalises this; this interview produces the input to it.

### 3. Probe the audience reality

- *"How old is the player you're picturing?"*
- *"Where are they (region matters — session length and time of day differ)?"*
- *"Mobile, desktop, console — what do you actually expect?"*
- *"Are they playing with friends usually, or solo, or doesn't matter?"*

If the creator says "everyone" → push back. No game is for everyone. Force a specific persona.

### 4. Probe the first session

- *"Within 30 seconds of joining, what does the player do?"*
- *"Within 5 minutes, what's the first reward / payoff?"*
- *"What's the first 'oh that's cool' moment?"*

If the creator can't answer these → the game design is not yet concrete enough to plan. Stop here, summarize, and offer to revisit later.

### 5. Probe the return reason (D1, D7, D30)

- *"What makes them come back tomorrow?"*
- *"What makes them come back in a week?"*
- *"What pulls them back in a month? Is there a long arc?"*

For each: is the pull a system (progression unlock), a social pull (friends online), or a content pull (event, new map)?

This feeds `roblox-blueprint-retention`.

### 6. Probe social mechanics

- *"How does the player encounter other players?"*
- *"Is there competition, cooperation, or both?"*
- *"Is there a guild / party / friend system?"*
- *"What happens when a player invites a friend?"*

Roblox is social-native — almost every successful experience leverages this. Even solo games have hub / leaderboard touchpoints.

### 7. Probe the anti-vision (critical)

- *"What would make you say 'this isn't my game anymore'?"*
- *"What feature would you refuse to add even if it boosted retention?"*
- *"Is this NOT a [common adjacent genre]?"*

The anti-vision protects against feature creep and AI-generated scope inflation. Capture it explicitly.

### 8. Probe monetization stance

- *"How does this game make money — or does it?"*
- *"Cosmetic only, gamepass, developer products, premium, ads?"*
- *"What would feel like pay-to-win to you and how do you avoid it?"*

This feeds `roblox-blueprint` and the security review later.

### 9. Probe constraints

- Team size, skills, available hours / week, timeline?
- Solo dev with a day job has very different scope than a 5-person team.
- Is there an art / asset budget? Or all in-engine + Creator Store?

### 10. Surface risks before adding more

- *"What worries you most about building this?"*
- *"What part feels hardest?"*
- *"What have you tried before that didn't work?"*

Acknowledge their list. The implementation will need to address it.

### 11. Synthesize and validate

Write the vision document. Read it back to the creator (or summarize the key claims). Wait for explicit *"yes, that's right"* or correction. **Do not proceed downstream** until the document is acknowledged.

## Output format

```markdown
# Creator Vision — <game name>

## The one-sentence pitch
> "<player-spoken pitch, verbatim from creator>"

## Player desire arc
- **Primary driver:** <Progression / Status / FOMO / Mastery / Community>
- **Supporting:** <0–2 others>
- **Why this combination:** <creator's words + your framing>

## First session promise
- 30 seconds: ...
- 5 minutes: ...
- First "oh cool" moment: ...

## The pull
- D1 (tomorrow): ...
- D7 (next week): ...
- D30 (next month): ...

## Reference experiences
- **<Game X>** — for <specific element>
- **<Game Y>** — for <specific element>
- Explicitly NOT trying to be: <list>

## Anti-vision
- This game is NOT: <list of nope's>
- Features the creator would refuse: <list>

## Monetization stance
- Model: <cosmetic-only / gamepass / dev-products / mixed / none>
- Pay-to-win guardrails: ...

## Audience
- Age range: ...
- Region focus: ...
- Platform mix: ...
- Social context: ...

## Constraints
- Team: ...
- Time: ...
- Skills / gaps: ...
- Asset budget: ...

## Known risks (creator-named)
- ...

## Acknowledged-by-creator: <date / yes-from-creator>
```

## Anti-pattern checks

- ❌ Asking about features before asking about feelings — leads to feature-list game design, no soul.
- ❌ Letting "everyone" pass as the audience — push back.
- ❌ Letting "all five drivers" pass — force a primary.
- ❌ Treating the interview as a checklist to march through — read the room; if the creator is energised about Q4, stay there.
- ❌ Skipping the anti-vision — the most common cause of mid-build scope explosion.
- ❌ Proceeding to blueprint without explicit creator acknowledgement of the document.

## Roblox-specific framing

Generic requirements interviews work for any software. Roblox-specific overlays:
- **Roblox is social-native** — even "solo" games have hub interaction; ask about it.
- **Platform mix matters** — mobile players have ~5-minute sessions; desktop / console players ~30+. The first-session promise must work for the dominant platform.
- **Discovery is brutal** — Roblox players bounce in seconds. The 30-second hook is real.
- **Monetization is age-sensitive** — under-13 audiences have strict rules and different psychology. Audience answer affects monetization options.
- **Pre-built psychology drivers** are the right vocabulary (see `references/psychology-framework.md`), not generic "engagement" buzzwords.

## Handoff

- Creator-acknowledged vision document exists → run `roblox-brief-audience` and `roblox-brief-motivation` to formalise the audience + driver answers (they may now be quick because the interview did the deep work).
- Vision is concrete enough → `roblox-blueprint` to turn it into an architecture plan.
- Creator is still uncertain after the interview → it's OK to stop here. Note the open questions and revisit later.
