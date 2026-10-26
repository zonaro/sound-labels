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
9. Keep UI accessible, keyboard navigable and adaptive. PT-BR and English strings should be externalized.
10. Each issue must have reproducible acceptance criteria and tests. Do not invent verified integration behavior.
