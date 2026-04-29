# MVP VPN Status

Last updated: 2026-04-18

## Project Goal

Build a simplified B2B VPN client based on Hiddify for end users who should not be able to break routing or advanced settings.

Current target flow:
- customer receives access
- user sees a minimal client UI
- user selects a country/location
- user connects with one main toggle button

## Done

### UI simplification
- Hidden or removed from normal user UI:
  - Logs
  - DNS configuration UI
  - TLS tricks UI
  - Inbound UI
  - WARP UI
  - profile management entry points from normal flow
  - import/export/reset config actions from settings
- Main screen still keeps:
  - connection status
  - central connect button
  - traffic/profile info block
- Connection button no longer sends the user into profile setup when no active profile is present.
- Instead, it opens a country picker.

### Country selection
- Country picker is limited to `Netherlands` for now.
- This is currently the only visible exit location in the client UI.

### Branding
- Visible app name was changed to `noda` in major user-facing places.
- Theme-aware logo switching was added.
- Intro/start screen logo size was reduced.
- Linux window/taskbar icon path was fixed.

### Routing and split tunneling
- RU split tunneling is enabled by default and hidden from the user.
- Client config now forces routing region to `ru` internally, regardless of selected exit country in UI.
- This is intended to keep RU destinations outside the tunnel by default.

### Test infrastructure
- One NL test server was brought up manually with:
  - Xray
  - VLESS
  - Reality
- Manual test `vless://...` connection was generated and used successfully.

## Partially Done

### UI against original TZ
- Sidebar is not yet exactly as requested.
- Current user navigation still includes:
  - Home
  - Settings
  - About
- Original request wanted only:
  - About
  - Exit

### Subscription flow
- Original TZ requested a visible `Subscription URL` field on the main screen.
- This is not implemented as a visible input yet.
- Current import path is still temporary/technical:
  - paste/import flow
  - deep link flow
  - manual test link flow

### Branding and platform identity
- Visible branding is partially updated.
- Technical identifiers are not fully migrated yet:
  - Android bundle/application identifiers
  - remaining internal `hiddify` naming in platform-specific places

### Safe defaults audit
- UI access to many risky settings is removed.
- However, runtime defaults still need a final audit to confirm all requested stability defaults are enforced.
- This especially includes:
  - Mux
  - fragmentation-related behavior
  - other experimental options

### Routing product model
- UI country selection exists.
- But it is still not backed by a proper server-driven country/node provisioning model.
- Right now the feature is still partly UI scaffolding around the current client architecture.

## Not Done Yet

### Final provisioning flow
- No final subscription/backend provisioning flow yet.
- No finished user-facing access delivery mechanism yet.

### Remnawave / panel side
- Remnawave panel is not installed and configured yet.
- No production node orchestration flow yet.
- No company/user management flow yet.

### Reality defaults in product flow
- Default donor/SNI behavior is not yet productized in the client/backend flow.
- Current Reality donor/SNI values were set manually for test server setup.

### Full platform branding pass
- Not all logos, icons, splash assets, and packaging metadata have been finalized across:
  - Windows
  - Android
  - macOS
  - iOS

### Release artifacts
- Final release packaging and handoff are not finished yet for:
  - APK
  - Windows portable ZIP
  - Windows installer EXE
  - macOS DMG
  - iOS build/distribution

## Current Risks

- RU split tunneling is broad and may route more RU traffic directly than desired.
- This can expose real IP in some scenarios, including browser/WebRTC-related behavior.
- For production, a narrower allowlist for banks/gov services may be better than a broad `RU -> direct` policy.

- Provisioning is still manual/test-oriented.
- Current working connection method is good for smoke testing, but not for production onboarding.

- Branding is visibly underway, but not fully complete at package/identifier level.

## Immediate Next Tasks

### P0
- Build and hand off a Windows executable for external testing.
- Stabilize the Windows test flow and confirm:
  - app launches
  - connection works
  - branding is acceptable
  - routing behavior is acceptable for test phase

### P1
- Decide the temporary provisioning path:
  - manual `vless://` import
  - temporary subscription URL
  - backend-driven subscription flow

### P1
- Finish UI cleanup against original request:
  - decide whether `Settings` stays at all
  - decide whether to add visible `Subscription URL` input on home
  - decide whether to expose only `About` and `Exit`

### P1
- Audit and hardcode safe defaults:
  - Mux off
  - fragmentation off unless explicitly needed
  - experimental features off

### P2
- Install and configure Remnawave panel.
- Connect panel/backend/node architecture.
- Move from manual test access to managed access.

### P2
- Finish cross-platform branding and packaging.

## Recommended Tracking Approach

For now, keep this file as the source of truth for project status.

If task management becomes heavier, split follow-up work into:
- product/client tasks
- infra/panel/backend tasks
- release/build tasks

Then move those into Jira or another tracker later.
