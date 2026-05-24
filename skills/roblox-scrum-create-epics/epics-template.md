---
stepsCompleted: []
inputDocuments: []
---

# {{project_name}} - Audited Epic Breakdown

## Overview

This document provides the complete epic and story breakdown for {{project_name}}, decomposing the requirements from the GDD, UX Design if it exists, and Architecture requirements into implementable stories.

**AI Development & MCP Strategy:**
Throughout all Epics, the development process MUST actively utilize the configured Roblox Studio MCP server (`mcp__Roblox_Studio__*`). This provides full engine and workspace control.
- **Verification Rule**: After every visual change, UI update, or asset insertion, run visual evidence collection (e.g. `screen_capture` or manual playtests).
- **TDD Requirement**: Failing TestEZ spec scripts must be written before any production Luau implementation.

---

## Requirements Inventory

### Functional Requirements

{{fr_list}}

### Non-Functional Requirements

{{nfr_list}}

### FR Coverage Map

{{requirements_coverage_map}}

---

## Epic List

{{epics_list}}

<!-- Repeat for each epic in epics_list (N = 1, 2, 3...) -->

## Epic {{N}}: {{epic_title_N}}
**Focus**: {{epic_focus_N}}
**Player Value**: {{epic_value_N}}

<!-- Repeat for each story (M = 1, 2, 3...) within epic N -->

### Story {{N}}.{{M}}: {{story_title_N_M}}

As a {{user_type}},
I want {{capability}},
So that {{value_benefit}}.

**Acceptance Criteria:**

- **Given** {{precondition}}
- **When** {{action}}
- **Then** {{expected_outcome}}
- **And** {{additional_criteria}}

<!-- End story repeat -->
