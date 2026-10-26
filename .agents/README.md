# Agent instructions

Read ARCHITECTURE.md, ROADMAP.md and UI.md before changing code. This directory is the source of truth for implementation agents.

Rules:
1. Prioritize a simple, maintainable Flutter Linux application; no GNOME Shell extension.
2. Keep OS-specific audio operations behind a testable adapter. No audio-server replacement.
3. Never claim a label is permanent until tested across WirePlumber restart, reboot and unplug/replug.
4. Use stable identifiers when possible; do not persist ephemeral PipeWire numeric node IDs.
5. Respect user files: never clobber WirePlumber rules. Use isolated managed files, validation, backup, atomic write and rollback.
6. Avoid root, privileged daemons, arbitrary shell interpolation and broad filesystem permissions.
7. Provide meaningful errors and dry-run/previews for any system configuration change.
8. Prefer Flutter's built-in state management until complexity justifies a package.
9. Keep UI accessible, keyboard navigable and adaptive. All user-facing strings must use Flutter localization in pt-BR, English and Spanish. Detect OS locale and support persistent manual override.
10. Support automatic (system), light and dark theme modes throughout the app, including persistent manual override.
11. Each issue must have reproducible acceptance criteria and tests. Do not invent verified integration behavior.


## System accent color (MVP)
Follow the configured desktop accent color on GNOME and KDE when detectable, ideally through supported XDG Desktop Portal appearance settings. Update on changes when possible. If unavailable, fall back to Sound Labels purple. Apply consistently in light and dark modes with accessible contrast. See issue #28.


## Mandatory visual specification
Before implementing any Flutter screen, read [UI_IMPLEMENTATION.md](UI_IMPLEMENTATION.md). It provides a complete text-only screen-by-screen blueprint for agents that cannot inspect images. The owner uploaded the approved UI concept under root `assets/`; use the exact file `assets/concept.png` and use it as a visual reference. The logo SVG at `assets/icons/sound-labels.svg` is a different asset. All approved screens are MVP scope.

**Approved visual reference:** [`assets/concept.png`](../assets/concept.png). This is the canonical UI mockup; agents with image support should inspect it, and text-only agents must follow `UI_IMPLEMENTATION.md`.
