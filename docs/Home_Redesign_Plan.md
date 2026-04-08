# Jools Home + Scheduled Plan

## Objective

Replace the current `Dashboard` with a coherent `Home` screen that uses official Jules terminology and makes the app feel native on iPhone.

This change must:

- keep the shipped Jools visual language
- introduce `Suggested` and `Scheduled` cleanly
- avoid inventing a fake backend model that drifts from Jules reality
- stay honest about the current public API gap for scheduled tasks

## Product Positioning

Jools should act as a mobile control plane for Jules, not a compressed copy of the web app.

`Home` should answer three questions immediately:

1. What needs me right now?
2. What useful work can Jules do next?
3. What recurring work should I schedule?

That maps to:

1. `Needs Attention`
2. `Suggested`
3. `Scheduled`

## IA

### Tabs

- `Home`
- `Sessions`
- `Settings`

### Home Sections

1. Usage
2. Needs Attention
3. Suggested
4. Scheduled
5. Sources
6. Recent Sessions

## Naming Rules

- Use `Scheduled` as the canonical product term everywhere user-facing.
- Keep official preset names from Jules web:
  - `Bolt`
  - `Palette`
  - `Sentinel`
- Do not introduce `Autopilot` as a feature noun unless Jools adds functionality beyond Jules Scheduled tasks.

## Scope

### Included now

- Rename `Dashboard` tab to `Home`
- Redesign Home hierarchy to match the new product spine
- Make `Suggested` actionable through prefilled session creation
- Add native `Scheduled` preset cards and composer sheet
- Add explicit web handoff messaging for final schedule creation
- Add UI tests for Home sections and scheduled composer

### Explicitly deferred

- Native scheduled-task CRUD
- Scheduled-task syncing from Jules backend
- Suggestion syncing from Jules backend
- Repo detail `Overview / Suggested / Scheduled` segmented surface
- Private web-RPC integration

## Architecture

### Current backend reality

The public Jules REST API in use by Jools still exposes:

- sources
- sessions
- activities

It does not currently expose scheduled-task or suggested-task resources.

### Implementation approach

Use a split model:

- `Suggested`
  - native and actionable now
  - backed by curated templates that open a real session composer with prefilled prompts
- `Scheduled`
  - native discovery and preparation now
  - final creation handed off to Jules web until official API support lands

This keeps the UI stable while preserving a clean future migration path.

## UI Design Constraints

### Preserve

- the white / pale-lilac system-card look
- rounded surfaces
- SF-based iconography
- the restrained purple accent
- the calm, low-noise tab bar

### Improve

- stronger section hierarchy
- less repo-grid dominance
- more obvious priority ordering
- compact, glanceable action rows

### Avoid

- dense web-like tables
- emoji iconography
- a fourth `Scheduled` tab
- pretending unsupported backend features already exist natively

## Component Plan

### Usage Card

- keep existing shape and progress bar
- tighten copy and spacing

### Needs Attention

Derived from live session state:

- awaiting plan approval
- awaiting user input
- failed
- running

Each card must include:

- state-specific icon treatment
- short title
- short explanation
- tap-through into the session

### Suggested

Suggested cards must include:

- category icon
- short title
- rationale
- confidence bars
- `Start` action

`Start` opens `CreateSessionView` with:

- source preselected
- prompt prefilled
- title prefilled
- review-oriented mode selected

### Scheduled

Scheduled section must include:

- one small info banner explaining the current backend limitation
- three preset cards:
  - `Bolt`
  - `Palette`
  - `Sentinel`
- a native `Scheduled Task` composer sheet

The composer must expose:

- role
- cadence
- time
- timezone
- repo
- branch
- prompt details

The composer must not fake backend creation. It should instead:

- copy the prepared prompt
- open Jules web
- explain why the handoff exists

### Sources

- change from dominant grid to secondary source chips
- keep one-tap repo selection
- keep one-tap session creation per source

## Testing Strategy

### Build verification

Run before simulator work:

1. `xcodebuild` compile check
2. `swift test` for `JoolsKit`
3. `JoolsUITests` run

### Simulator verification

Use the iOS simulator plus AXe / Xcode automation.

#### Home UI pass

Verify:

- tab label changed to `Home`
- `Needs Attention` is above `Suggested`
- `Suggested` is above `Scheduled`
- sources no longer dominate the first screen
- colors and surfaces remain consistent with existing Jools theme
- confidence bars render cleanly
- SF symbols feel visually consistent

Capture screenshots for:

- default Home state
- Home scrolled to `Scheduled`
- Scheduled composer sheet
- Suggested prefilled create-session flow

#### Navigation pass

Verify:

- Home -> suggested `Start` opens prefilled session composer
- Home -> source quick-create opens composer
- Home -> attention card opens chat session
- Home -> scheduled preset opens scheduled composer

#### UX quality pass

Verify:

- spacing rhythm is consistent
- section headers align correctly
- tab bar still feels light and balanced
- no clipped text on iPhone simulator
- no accidental dark surfaces or off-theme cards
- buttons remain tappable without crowding

### Live web parity verification

Use Chrome DevTools MCP against the authenticated Jules web UI.

Verify:

- `Scheduled` is the official label
- the three preset names match web
- the skill intent for each preset matches web:
  - performance
  - design
  - security
- Jools copy and affordances do not contradict the web product

### Live short-lived schedule verification

Create one short-lived schedule in `hews` or `namefix` on Jules web.

Verification steps:

1. Open the repo in Jules web.
2. Open `Scheduled`.
3. Pick one preset, preferably `Bolt`.
4. Configure a near-term run window for test purposes.
5. Confirm the schedule appears in web UI.
6. Capture screenshots of:
   - empty / setup state if visible
   - composer state
   - created schedule card/list row
7. Return to Jools and confirm:
   - the same preset exists
   - the naming matches
   - the handoff explanation remains accurate

Note:

Jools will not show the created schedule natively yet because the public API does not expose it. The parity target in this phase is terminology, preset intent, and handoff correctness.

## Acceptance Criteria

- `Home` feels like a native control plane rather than a source browser.
- Official Jules terms are used consistently.
- Suggested work is actionable inside Jools.
- Scheduled work is discoverable and understandable inside Jools.
- The scheduled composer is honest about the current web handoff.
- The visual system remains recognizably Jools.
- Navigation and layout are stable on simulator.

## Rollout Sequence

1. Land Home shell and supporting models.
2. Land Suggested actions and scheduled composer.
3. Add and pass UI tests.
4. Verify in simulator with screenshots.
5. Verify live Jules web parity and create a real short-lived schedule.
6. Only then iterate on deeper repo-level surfaces.
