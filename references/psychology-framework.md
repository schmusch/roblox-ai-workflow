# Player Psychology Framework

Design Roblox experiences **from player desire backward**. Start with the dominant desire, then shape loops, rewards, UX feedback, social structure, economy pressure, and LiveOps cadence around that desire.

This framework is the canonical design lens consulted by `roblox-blueprint-psychology`, `roblox-brief-motivation`, and all `roblox-forge-<driver>` skills.

## The five drivers

### 1. Progression
- **Player desire:** visible growth, more power, more reach, more unlocked possibility.
- **In-game mechanics:** XP bars, level ladders, unlock tracks, rebirth / prestige loops, evolving tools, widening territory.
- **UI / feedback:** progress bars, claim moments, milestone unlock toasts, tier previews, "next goal" surfaces.
- **Economy implications:** acceleration items, catch-up multipliers, long-term sinks, inflation pressure if rewards scale too fast.
- **Retention implications:** strong D1 / D7 pull when next-step goals are obvious and achievable.
- **Monetization:** boosts, storage, queue speed, automation, cosmetic milestone packs.
- **Abuse / risk:** fake progress, dead levels, impossible grind walls, power compression.
- **Roblox-fit:** players switch experiences fast — the first upgrade payoff must arrive within minutes.

### 2. Status
- **Player desire:** social proof, flex, recognition, identity, rarity.
- **In-game mechanics:** titles, rare cosmetics, leaderboard placement, profile badges, visible pets, housing / trophy showcases.
- **UI / feedback:** podiums, inspection panels, showcase slots, rarity color systems, visible titles in-world.
- **Economy implications:** prestige sinks, trade-value volatility, cosmetic inflation if rare rewards become common.
- **Retention implications:** stronger return when status stays socially visible and meaningfully scarce.
- **Monetization:** cosmetics, display slots, premium profile surfaces, event exclusives.
- **Abuse / risk:** whale-only flex, unreadable rarity ladders, invisible status that players can't actually show off.
- **Roblox-fit:** status works best when other players can see it quickly in hubs, parties, or match lobbies.

### 3. FOMO (Fear Of Missing Out)
- **Player desire:** urgency, novelty, being present for the thing that matters now.
- **In-game mechanics:** timed events, rotating shops, featured quests, comeback rewards, seasonal ladders.
- **UI / feedback:** countdowns, event tabs, re-entry reminders, clearly stated end times, progress-before-expiry.
- **Economy implications:** demand spikes, hoarding, speculative pricing, burnout if cadence is relentless.
- **Retention implications:** strong short-term spikes, weaker long-term trust if players feel punished for missing days.
- **Monetization:** event passes, limited cosmetics, time-boxed bundles, convenience accelerators.
- **Abuse / risk:** manipulative timers, impossible completion windows, unfair exclusivity, loss-aversion overload.
- **Roblox-fit:** keep urgency legible and fair — many players arrive in short bursts and bounce quickly.

### 4. Mastery
- **Player desire:** skill expression, optimization, discovery, competence, outplay moments.
- **In-game mechanics:** combo systems, build paths, routing optimization, combat tech, efficiency puzzles, boss patterns.
- **UI / feedback:** damage readouts, timing ratings, replayable challenge goals, analytics screens, transparent depth.
- **Economy implications:** high-skill farms can outpace sinks — mastery loops need reward caps or prestige resets.
- **Retention implications:** strong for long-tail retention when depth keeps opening rather than collapsing into solved grind.
- **Monetization:** loadout slots, training utilities, cosmetics for proven skill — **not** raw pay-to-win power.
- **Abuse / risk:** hidden math, unreadable systems, low-skill players hard-walled by complexity.
- **Roblox-fit:** fast-to-fun onboarding matters — start with a simple loop, then layer depth.

### 5. Community
- **Player desire:** belonging, co-presence, teamwork, shared identity, shared goals.
- **In-game mechanics:** parties, guilds, trading, co-op raids, shared housing, clan goals, visit loops, invite rewards.
- **UI / feedback:** party presence, clan chat, "friends online" cues, group progress boards, visible social prompts.
- **Economy implications:** player-to-player value exchange, gifting risk, anti-abuse trade controls, social sink opportunities.
- **Retention implications:** often the strongest sticky layer — players return for people, not only systems.
- **Monetization:** group cosmetics, guild upgrades, social spaces, shared event tracks, gifting.
- **Abuse / risk:** spam invites, shallow social chores, exploit-prone trading, guild deadweight loops.
- **Roblox-fit:** Roblox is socially native — social mechanics should reduce friction to playing together fast.

## Healthy design rules (apply across all drivers)

- **Fast to fun** beats front-loaded tutorial weight.
- **Reward clarity** beats feature count.
- **Social presence** should reduce friction, not create spam.
- **FOMO** should create relevance, not punishment.
- **Monetization** should amplify desire-aligned systems, not replace them.
- Every loop needs a **fail state**, a **recovery path**, and a **burnout guardrail**.

## How to apply the framework

1. **Identify the dominant driver(s)** of the experience. Usually 1 primary + 1–2 supporting. Don't try to be all five.
2. **Sketch the player desire arc** for a first session, D1, D7, D30. What pulls them back?
3. **Design loops that satisfy the driver** (see the mechanics row).
4. **Audit fail / recovery / burnout**:
   - What happens when a player loses?
   - What's the recovery path?
   - What stops them from grinding to exhaustion?
5. **Audit social visibility:** can other players *see* the player's status / progress when relevant?
6. **Audit monetization alignment:** is the paid layer amplifying the driver or replacing it (= pay-to-win risk)?

## Cross-driver tensions

- **Progression × Mastery** — pure progression can solve mastery before depth lands. Use prestige resets, build-variant unlocks.
- **Status × Community** — status focused on solo flex can crowd out genuine community feel. Add group-status surfaces (guild leaderboards).
- **FOMO × all** — over-FOMO erodes trust. Anchor it to fair re-entry and clear next-cycle promises.

## Anti-pattern smells

- "Add XP for everything" without a clear cap or sink → inflation collapse.
- "Daily login chains with permanent penalty for missing one day" → burnout / trust erosion.
- "Top-100 leaderboard only, no mid-tier visibility" → 99% of players invisible → status driver fails.
- "Trading enabled with no anti-dupe guardrails" → economy collapse risk.
- "Cosmetic-only monetization but no in-world cosmetic visibility" → status driver disconnected from spend.
