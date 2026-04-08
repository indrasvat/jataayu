# Jools Session Reliability Verification

Date: 2026-04-05

## Scope

This verification pass covers the session reliability and UX recovery work implemented for:

- send-message empty `200` handling
- structured API decode diagnostics
- polling refresh reasons and burst refresh
- foreground/manual/stale-recovery refresh flows
- explicit sync-state UX in session detail
- activity timeline preservation and query fallback
- seeded UI automation for recovery states
- live validation against the real Jules `hews` session

## Automated Verification

### JoolsKit tests

Command (run from the repo root):

```bash
swift test --package-path JoolsKit
```

Result:

- passed
- includes fallback coverage for unsupported `createTime` activity filtering
- includes fixture coverage for resumed sessions, progress artifacts, and completed-session change sets

### UI tests

Command (run from the repo root, replacing `<sim-udid>` with whatever
simulator you have available — e.g. `xcrun simctl list devices available`
or simply `name=iPhone 17 Pro`):

```bash
xcodebuild \
  -project Jools.xcodeproj \
  -scheme Jools \
  -destination 'platform=iOS Simulator,id=<sim-udid>' \
  -configuration Debug \
  -only-testing:JoolsUITests \
  test
```

Result:

- passed
- xcresult bundle landed under the local DerivedData tree (path is
  per-machine; check `xcodebuild -showBuildSettings` for `BUILT_PRODUCTS_DIR`)

Covered flows:

- running session recovery chrome
- stale session retry affordance
- background/foreground recovery

## Live Jules Validation

Simulator screenshots were captured locally during validation and intentionally left out of version control because they may contain repo names, prompts, branch names, and other user-specific session data.

Live session used (identifiers redacted; see local notes for the
exact values used during the run):

- repo: `<owner>/<repo>` (a real, mid-sized GitHub repository the
  author works in regularly)
- session: `<live-session-id>`
- title: e.g. `Concise Repository Overview and Risk Analysis`

What was reproduced and verified:

1. The real Jules API now rejects the `createTime` query parameter on `sessions/{id}/activities`.
2. Before the fallback patch, this caused repeated scheduled sync failures and stale-state banners.
3. After the fallback patch, the app logs show capability detection instead of repeated failures:
   - `Activity createTime filter unsupported; falling back to full activity fetches`
4. After the display fallback patch, the live session detail screen renders the existing timeline again instead of showing only a blank body with a correct header.

## Notes

- The live verification focused on the original reproduction case because that was the concrete stale/blank-thread regression.
- AXe was used for exploratory simulator driving and screenshots with deliberate post-action delays.
- XCTest remains the authoritative automated pass/fail mechanism.
- Local screenshot artifacts live under the ignored `artifacts/` tree and should remain untracked unless they are explicitly sanitized.
