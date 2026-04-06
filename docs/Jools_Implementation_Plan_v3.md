# Jools Implementation Plan v3

**Document Type:** Gap analysis + refreshed implementation plan  
**Version:** 3.0  
**Date:** 2026-04-05  
**Scope:** Current app audit, upstream Jules changes through April 2026, recommended next roadmap for the unofficial iOS client

## 1. Executive Summary

`Jools` currently implements the core 2025-era Jules flow reasonably well:

- API key onboarding
- source listing
- source-backed session creation
- activity polling
- basic plan approval
- basic chat/activity rendering
- PR link surfacing

That is no longer close to Jules state-of-the-art as of April 2026.

The main product shift since November 2025 is that Jules is no longer just a manually triggered repo task runner. It is now a broader continuous coding system with:

- repoless sessions
- suggested tasks
- scheduled tasks with edit/pause/resume
- CI/build failure auto-fixing
- integrations
- MCP service connections
- richer model tiers
- better incremental API consumption patterns

For Jools to remain useful, the app should pivot from “mobile wrapper around session chat” to “mobile control plane for autonomous coding work.”

## 2. Sources Reviewed

Primary sources used for this refresh:

- [Jules Docs](https://jules.google/docs/)
- [Jules Changelog](https://jules.google/docs/changelog/)
- [Jules REST Quickstart](https://jules.google/docs/api/reference/)
- [Jules Sessions API](https://jules.google/docs/api/reference/sessions/)
- [Jules Sources API](https://jules.google/docs/api/reference/sources/)
- [Jules Types Reference](https://jules.google/docs/api/reference/types/)
- [Google Developers REST Reference](https://developers.google.com/jules/api/reference/rest)

Important note:

- The Google Developers REST reference is stale. Its own page says “Last updated 2025-10-02 UTC”.
- The live `jules.google/docs` API pages and changelog contain newer capabilities not reflected there.

## 3. What Changed Since November 2025

| Date | Upstream change | Why it matters for Jools |
|---|---|---|
| 2025-11-10 | Jules Tools CLI added side-by-side diffs, repo inference, and related workflow polish | Confirms that richer diff review and lower-friction task launch are first-class Jules workflows |
| 2025-11-19 | Gemini 3 Pro introduced | Model messaging in-app is outdated |
| 2025-11-20 | “Start from scratch” repoless sessions launched in product | Jools currently cannot create repoless sessions |
| 2025-12-10 | Scheduled Tasks launched | No UI or models for recurring/autonomous tasks |
| 2025-12-10 | Suggested Tasks launched | No repo intelligence inbox or proactive task surface |
| 2025-12-10 | Render integration launched | No integrations surface at all |
| 2025-12-18 | Continuous AI guide framed Jules around suggested tasks + scheduled tasks + integrations | The app still behaves like a synchronous chat client |
| 2026-01-26 | Planning Critic added for auto-approved plans | Session states/planning UX should assume better autonomous planning, not only manual approval |
| 2026-01-26 | Performance optimization suggestions added to Suggested Tasks | Suggested tasks are broader than TODO harvesting |
| 2026-01-26 | REST API gained repoless sessions, file outputs, activity `createTime` filters | Jools networking layer is missing all three |
| 2026-01-26 | Scheduled tasks gained edit/pause/resume | Future task management UI must support lifecycle controls, not only creation |
| 2026-01-30 | Gemini 3 Flash became base model for all tiers | Plan/usage/model copy in docs and app is stale |
| 2026-02-02 | MCP support added for Linear, Stitch, Neon, Tinybird, Context7, Supabase | Settings/integrations hub now matters materially |
| 2026-02-19 | CI Fixer + configurable commit authorship shipped | Mobile PR/session monitoring should surface CI loops and authorship state |
| 2026-03-09 | Gemini 3.1 Pro became default for Pro users | Model copy is stale again |

As of **April 5, 2026**, I did not find any newer public changelog entries than **March 9, 2026**.

## 4. Official Docs Inconsistencies

These matter because the implementation should be defensive:

1. `developers.google.com/jules/api/reference/rest` is materially out of date.
   - It omits newer concepts like repoless sessions and activity timestamp filtering.
   - It does not reflect the broader live docs structure.

2. Source naming examples are inconsistent.
   - Some docs use `sources/github/{owner}/{repo}`.
   - Some newer examples show opaque values like `sources/github-myorg-myrepo`.
   - Jools should treat source names as opaque server-provided resource names and never synthesize them.

3. Repoless support is documented inconsistently.
   - The Sessions page says `sourceContext` is optional for repoless sessions.
   - The Types page still describes `SourceContext.source` as required.
   - Jools should therefore model `sourceContext` as optional both in responses and in create requests.

4. Model/plan docs lag changelog reality.
   - Limits docs still discuss Gemini 2.5 Pro and “starting with Gemini 3 Pro”.
   - Changelog later makes Gemini 3 Flash the base model and Gemini 3.1 Pro the Pro default.

## 5. Current Implementation Audit

### Implemented

- API key onboarding and validation
- source listing and local sync
- source-backed session creation
- plan approval
- send message
- list/get sessions
- list/get activities
- adaptive polling
- basic activity rendering
- basic diff summary extraction from `changeSet.gitPatch`
- PR link surfacing
- local SwiftData cache for sessions/activities/sources

### Partially implemented

- session state support
  - Handles `QUEUED`, `IN_PROGRESS`, `AWAITING_PLAN_APPROVAL`, `COMPLETED`, `FAILED`, `CANCELLED`
  - Does not appear ready for newer/alternate states like `PLANNING`, `PAUSED`, or newer user-feedback variants if they surface
- artifact rendering
  - Extracts bash output and git patch metadata
  - Does not provide a true code/diff viewer, file browser, or media viewer
- usage/limits
  - Shows a local hardcoded daily limit of `100`
  - This is not trustworthy and should not be presented as fact
- settings
  - Has basic account/about/preferences UI
  - Does not expose integrations, commit authorship, MCP connections, or autonomous features

### Not implemented

- repoless session creation and display
- incremental activity polling via `createTime`
- pagination and filtering for sources/sessions/activities
- scheduled tasks
- suggested tasks
- repo-level proactive automation controls
- integrations management
- MCP service connections
- CI fixer monitoring
- commit authorship configuration visibility
- task pause/resume controls
- session deletion UI
- richer notifications for “needs input”, “PR ready”, “CI failed/fixed”, “scheduled task ran”
- file/media artifact viewers
- repo view parity
- offline-first conflict handling from the v2 plan
- multi-account / account switching

## 6. Code-Level Gaps That Need Fixing First

These are the most important implementation mismatches between current code and current Jules reality.

### P0: API/model parity

1. Make `CreateSessionRequest.sourceContext` optional.
   - Repoless sessions are now a real product and API capability.

2. Stop constructing source resource names client-side.
   - The app currently prefixes `sources/` onto `source.id`.
   - Resource naming examples differ across docs, so Jools should persist and reuse the exact server `name`.

3. Add incremental activity polling with `createTime`.
   - Current polling always fetches full activity pages.
   - This wastes bandwidth and battery and ignores the January 2026 API improvement.

4. Refresh session state modeling.
   - Treat unknown states as displayable, not broken.
   - Add forward-compatible UI for planning/paused/waiting states.

5. Model repoless sessions explicitly in persistence and UI.
   - `SessionEntity.sourceId` and `sourceBranch` are currently effectively required.
   - Repoless sessions need nil/empty-safe rendering everywhere.

### P1: Review and output fidelity

6. Add a true patch/code viewer.
   - Today Jools only shows changed file pills and diff counts.
   - Real mobile usefulness requires readable hunks, commit message, and per-file browsing.

7. Add media artifact support.
   - Jules supports media artifacts and stronger multimodal verification than the current app exposes.

8. Support session deletion and local data deletion correctly.
   - `Delete All Data` in Settings is still TODO-backed.

## 7. Product Features That Make Sense Next

This is the important part for an unofficial iOS client. The goal is not to clone every web feature. The goal is to make Jools uniquely good on mobile.

### Phase 1: Mobile control plane

- Repoless quick task creation
- Session inbox with filters:
  - Needs approval
  - Needs feedback
  - PR ready
  - Failed
  - Auto-fixing CI
- Push notifications for high-signal state changes
- Better completion cards with PR status, commit message, diff summary, CI status
- Real diff/code viewer optimized for phone screens

Why this phase:

- It turns Jools into the thing you reach for while away from the laptop.
- It matches the strongest mobile use case: triage, review, approve, and intervene quickly.

### Phase 2: Continuous AI management

- Suggested tasks inbox
- Scheduled tasks list/detail/edit/pause/resume
- Repo-level autonomous controls
- Integration status surface
- Render/CI event history

Why this phase:

- Jules is increasingly autonomous.
- Mobile should be the best place to monitor and steer long-running automation.

### Phase 3: Settings and integration depth

- Integrations hub
- MCP connections visibility
- Commit authorship mode visibility
- Better usage/plan screen that links official limits and explains current model tier carefully

Why this phase:

- The app currently has almost no operational settings for modern Jules.

## 8. UX Recommendations Specific to iOS

These would make Jools genuinely pleasant instead of merely functional.

1. Build around an Inbox first, not around Sources first.
   - Mobile users care about “what needs me now?”
   - The default screen should be action-oriented.

2. Treat approval as a first-class gesture.
   - Swipe to approve
   - Swipe to ask for revision
   - Long-press to open full plan

3. Make code review readable on a phone.
   - Per-file diff navigator
   - Collapsible hunks
   - Syntax highlighting
   - Quick “copy patch” / “open PR” / “share summary”

4. Surface autonomous loops clearly.
   - “Scheduled”
   - “Suggested”
   - “Triggered by CI”
   - “Triggered by integration”
   - “Repoless”

5. Use rich notifications sparingly but well.
   - Plan ready
   - Needs input
   - PR created
   - CI auto-fix attempted
   - Scheduled task failed

6. Add a quick-capture flow.
   - Share sheet / Shortcut / widget / app intent to start a repoless task from selected text, a URL, or a note

7. Prefer delightful read-only power over awkward write-heavy forms.
   - Mobile is great for review, approval, monitoring, and small nudges
   - It is weaker for large prompt authoring and full settings administration

## 9. DX Recommendations

- Introduce a small compatibility layer for API drift.
- Version local docs snapshots with refresh date.
- Add snapshot fixtures for:
  - repoless sessions
  - incremental activities
  - unknown future states
  - media artifacts
- Add parser tests for opaque source names and optional source contexts.
- Add a generated “API drift watchlist” doc whenever docs are refreshed.

## 10. Proposed Next Delivery Order

### Milestone A: Correctness

- Optional `sourceContext` in create request
- Opaque source names
- incremental activity polling
- forward-compatible session states
- repoless-safe persistence/UI

### Milestone B: Reviewability

- full diff/code viewer
- better completion cards
- PR metadata and CI status affordances

### Milestone C: Continuous AI

- suggested tasks
- scheduled tasks
- integration surfaces

### Milestone D: Delight

- notifications
- quick capture
- widgets / shortcuts / share extension

## 11. Bottom Line

If Jools stays focused on “start a repo task and read chat,” it will remain technically functional but strategically obsolete.

If it pivots to:

- mobile inbox
- approval/review cockpit
- autonomous workflow monitor
- fast repoless capture

then it can become a genuinely differentiated companion to Jules rather than a partial clone of the web app.
