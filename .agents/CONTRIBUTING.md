# Contributing and review checklist

- Discuss changes in an issue first; small focused PRs.
- Follow Flutter/Dart formatting and analyzer. Add tests for logic and mocks for host operations.
- Do not edit host audio configuration from tests without explicit opt-in.
- No sudo in normal operation; avoid shell injection and broad Flatpak permissions.
- Preserve users' existing configuration; write managed fragments atomically and support rollback.
- Report tested distro, desktop, PipeWire/WirePlumber versions and hardware.
- Keep user-facing strings ready for localization.
- No release claim without documented real-device verification.
