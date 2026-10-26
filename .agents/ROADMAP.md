# Roadmap

## Phase 0 — Feasibility
1. Inspect device/node/card/port metadata and establish stable matching strategy.
2. Prove persistent renaming and visibility in GNOME and KDE.
3. Compare Flutter Adwaita-inspired packages against current stable Flutter.

**Gate:** do not promise persistent UI labels before a working prototype.

## Phase 1 — Foundation
4. Bootstrap Flutter Linux project, architecture and CI.
5. Implement typed audio discovery adapter and domain models.
6. Build device list and details UI, including automatic icons and custom icon picker.

## Phase 2 — MVP
7. Implement safe rename/reset with backup and rollback, and persist user-selected icons.
8. Persist mappings across restart/hotplug.
9. Add localization, diagnostics and accessibility.
10. Integration tests on Fedora and at least one non-GNOME desktop, covering labels and app icons. Investigate native desktop icon override support.

## Phase 3 — Distribution
11. Package app; research and implement Flatpak if feasible.
12. Documentation, release checklist and first tagged beta.

## Later
EDID-assisted friendly names, per-app routing, PulseAudio fallback only if independently justified. **Device icons are required for MVP**; native desktop icon overrides depend on verified support.
