---
name: roblox-visual-verdict
description: Use to compare a Roblox Studio screenshot against a reference image and emit a structured pass/fail verdict with score, category match, differences, and suggested fixes. Use when iterating on UI / lighting / world-building visuals, when a reference image is provided, or as a gate during visual-iteration loops in roblox-forge.
domain: roblox-studio
audience: creator
artifact-type: skill
---

# Roblox Visual Verdict

Compares a Roblox Studio screenshot against a reference image and emits a structured verdict. Used during visual iteration (UI alignment, lighting setup, model placement) when a target image exists.

## When to use

- The user provided a reference image (mockup, target screenshot, art direction).
- Iterating on UI / lighting / world layout in Studio.
- Acting as a gate during `roblox-forge` when the task is visual.

## When not to use

- No reference image is available → use qualitative feedback instead.
- Code-only changes with no visual surface.

## Inputs

- **Current screenshot** — capture via `mcp__Roblox_Studio__screen_capture`. If multiple Studios are open, `list_roblox_studios` first.
- **Reference image** — provided by user (file path, URL, or pasted image).
- **Optional:** category hint (UI / lighting / world / character / VFX) to bias the comparison.

## Method

### 1. Capture the current state

```text
1. list_roblox_studios → if more than one, ask user which to target
2. screen_capture → save current viewport
3. (optional) resize_window to match reference aspect ratio if mismatched
```

### 2. Compare structured aspects

For each aspect, score 0–100 and write a short note:

- **Category match** — does the current image match the same kind of content (UI / lighting / world)?
- **Composition** — layout, positioning, scale, framing
- **Color** — palette match, saturation, contrast, individual key colors
- **Lighting** — direction, intensity, shadow softness, time-of-day match
- **Detail** — model fidelity, texture resolution, prop density
- **UI alignment** (if UI) — anchor points, padding, text sizing, font choice
- **VFX** (if applicable) — particle density, beam color, glow, post-fx

### 3. Compute overall score

Weighted average of aspects, weighted by what's most important for the category:

- UI: composition 30%, color 25%, alignment 30%, detail 15%
- Lighting: lighting 50%, color 30%, composition 20%
- World: composition 25%, detail 30%, color 25%, lighting 20%
- Character: detail 40%, color 30%, composition 20%, lighting 10%

### 4. Emit verdict in structured JSON

```json
{
  "score": 78,
  "verdict": "needs_revision",
  "category_match": true,
  "scores": {
    "composition": 85,
    "color": 70,
    "lighting": 60,
    "detail": 80,
    "alignment": 90
  },
  "differences": [
    {"area": "lighting", "note": "Reference uses warm 3000K key light from screen-right; current uses neutral 5500K from above."},
    {"area": "color", "note": "Reference background is desaturated teal; current is saturated blue."},
    {"area": "composition", "note": "Reference has subject centered with 1/3 vertical bias; current is centered both axes."}
  ],
  "suggestions": [
    {"area": "lighting", "action": "Add a Lighting:Color = Color3.fromRGB(255,170,100) on the key light, lower brightness to 2."},
    {"area": "color", "action": "Apply ColorCorrection -0.3 saturation on the background skybox region."},
    {"area": "composition", "action": "Move subject Y position +5 studs to match reference vertical bias."}
  ],
  "reasoning": "Composition is close; main gap is the lighting warmth and color saturation. Once those land, score should jump 15-20 points."
}
```

### 5. Apply the pass threshold

Default thresholds:
- `score >= 90` → **pass** (verdict: `pass`)
- `70 <= score < 90` → **needs revision** (verdict: `needs_revision`)
- `score < 70` → **rejected** (verdict: `rejected`)

User can override the threshold per call.

### 6. Feed suggestions into next iteration

The suggestions list is actionable. The next iteration of `roblox-forge` should apply at least the highest-impact suggestions, then re-screenshot, re-run `roblox-visual-verdict`.

## Loop guidance

A visual iteration loop:

1. Initial implementation.
2. `screen_capture` + `roblox-visual-verdict` against reference.
3. If `verdict != pass` → apply suggestions.
4. Repeat until pass or user accepts current state.

Cap at 5 iterations by default to avoid loops that diverge. After 5, stop and ask the user.

## Anti-patterns

- ❌ Emitting a verdict without an actual screenshot capture → guess, not verdict.
- ❌ Comparing against an outdated reference image when the user updated it mid-loop.
- ❌ Score inflation (calling 70 "pass" without user authorization).
- ❌ Suggestions that aren't actionable (`"improve the lighting"` → useless).

## Roblox-specific notes

- Studio viewport differs from final play view (no character, gizmos visible, viewport cube). For final-look verification, capture during Play Solo.
- Mobile aspect ratio (9:16, 9:18, 9:19.5) differs from PC (16:9). If targeting mobile, resize the window before capture.
- Color in Studio editor mode may differ from runtime due to Lighting state — re-test during Play mode.
- Particles / VFX may not render in editor view — Play Solo capture required for VFX verdict.
