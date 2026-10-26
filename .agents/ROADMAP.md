# Roadmap

## Phase 0 — Feasibility
1. Inspect device/node/card/port metadata and establish stable matching strategy.
2. Prove persistent renaming and visibility in GNOME and KDE.
3. Compare Flutter Adwaita-inspired packages against current stable Flutter.

**Gate:** do not promise persistent UI labels before a working prototype.

## Phase 1 — Foundation
4. Bootstrap Flutter Linux project, architecture and CI.
5. Implement typed audio discovery adapter and domain models.
6. Build device management UI with current-default indicators, quick-switch controls, automatic icons and custom icon picker.

## Phase 2 — MVP
7. Implement safe rename/reset with backup and rollback, and persist user-selected icons.
8. Implement explicit default output/input switching and synchronization with external changes; persist mappings across restart/hotplug.
9. Add localization, diagnostics and accessibility.
10. Integration tests on Fedora and at least one non-GNOME desktop, covering labels and app icons. Investigate native desktop icon override support.

## Phase 2b — Complete approved UI (required for MVP)
11. Implement active per-application stream routing screen, with correct PipeWire/WirePlumber move-stream behavior.
12. Implement saved user audio profiles and safe activation.
13. Implement settings: autostart, live sync, notifications, theme and language.
14. Implement compact quick output switcher, portable fallback where tray integration is unavailable.
15. Validate all approved screens with real devices and applications.

## Phase 3 — Distribution
16. Package app; research and implement Flatpak if feasible.
17. Documentation, release checklist and first tagged beta.

## Later
EDID-assisted friendly names and PulseAudio fallback only if independently justified. **Per-app routing, saved profiles, settings and compact switcher are all MVP requirements.** **Device icons are required for MVP**; native desktop icon overrides depend on verified support.


## Mandatory appearance and language support (MVP)
- Theme modes: Automatic (follow system), Light, Dark. Manual choice persists; automatic tracks system changes.
- Languages: Brazilian Portuguese (pt-BR), English (en), Spanish (es). Detect system locale, allow manual override, use Flutter ARB/gen-l10n and fallback.
- Applies to all screens, dialogs, quick switcher, notifications and errors. See issues #26 and #27.
