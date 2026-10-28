# Sound Labels 🎧

A lightweight, desktop-agnostic Linux application to identify and rename audio inputs and outputs with persistent, human-friendly labels.

> **Status:** Flutter Linux pre-alpha source code is available. It has **not been compiled or manually tested** yet. Device aliases and icons are local to Sound Labels by default; native GNOME/KDE renaming is an experimental opt-in, not a verified promise.

## Run locally

Install current Flutter stable (Dart 3.9+), enable Linux desktop, and ensure your system has PipeWire, WirePlumber, `pipewire-pulse`, `pactl` (usually `pulseaudio-utils`) and the Flutter Linux GTK development dependencies. Then:

```bash
flutter pub get
flutter gen-l10n
flutter run -d linux
```

The separate compact output window can be opened from the built executable:

```bash
./build/linux/x64/debug/bundle/sound_labels --quick
```

Build a release locally with `flutter build linux --release` when ready. No CI builds or tests were executed when this initial source was written. See [development notes](docs/DEVELOPMENT.md) for platform integration and manual validation.

## Why
HDMI/DisplayPort audio endpoints often look identical in desktop sound menus. Sound Labels aims to display labels such as **Living Room TV**, **LG Monitor** and **USB Microphone**, without replacing the system's audio server.

## Scope (MVP)
- Linux desktop app built with Flutter, responsive and keyboard-accessible.
- Detect PipeWire audio sinks and sources, their ports and relevant properties.
- Show original description, proposed custom label, connection state and technical identifier.
- Save, restore and persist local aliases; optionally generate an isolated, experimental WirePlumber 0.5+ user rule for GNOME/KDE validation.
- Choose device icons in the first MVP: automatic suggestions, manual picker, preview and reset. Icons persist in Sound Labels; native GNOME/KDE icon changes are subject to feasibility testing.
- Handle hotplug, restarts and missing devices gracefully.
- Show the current default output and input, and let users **explicitly switch the system-default audio output/input from the app** (initial MVP).
- Observe external default changes and hotplug; do not silently change defaults on startup. Switching the default may not move already-running application streams.

## All approved mockup screens are MVP scope
- **Dispositivos:** outputs and inputs, rename, icons, default switching.
- **Editar dispositivo:** name, icon picker, hardware metadata and restore.
- **Aplicativos:** inspect active playback streams and change their output routing; persistence where supported.
- **Perfis:** create and apply saved user audio configurations.
- **Configurações:** autostart, system sync, notifications, **light/dark/automatic (system) theme**, and **pt-BR/en/es localization** with automatic OS locale or manual language choice.
- **Saída de Áudio:** compact quick switcher with device icons.

Features must be implemented and tested, not merely decorative mockup screens. Host-specific limitations (particularly GNOME tray and stream routing) must be documented.

## Mandatory global UX requirements
- Theme: **Automatic (follow OS)**, **Light**, **Dark**, selectable and persistent; auto mode reacts to system changes.
- Localization: **Português (Brasil)**, **English**, **Español**, using Flutter ARB/gen-l10n, system locale detection, user override and fallback.
- Both requirements apply to **all** MVP screens, quick switcher, dialogs, errors and notifications.

## Architecture
Flutter UI → Dart application services → replaceable Linux audio adapter → PipeWire/WirePlumber. Prefer a direct, supported interface where feasible; evaluate `wpctl`, `pw-dump`, D-Bus and WirePlumber configuration rules before selecting the production mechanism. Do not assume that a node rename always changes GNOME/KDE labels.

Configuration belongs to the current user. Avoid root and do not overwrite user-maintained WirePlumber files. Implement atomic writes, backups and rollback if rules are generated.

See [agent guidance](.agents/README.md), [architecture](.agents/ARCHITECTURE.md), [roadmap](.agents/ROADMAP.md), and [UI research](.agents/UI.md).

## Visual direction
GNOME HIG / libadwaita-inspired, not GNOME-dependent. Evaluate [adwaita_gtk](https://pub.dev/packages/adwaita_gtk) for modern Material 3 colors and [libadwaita](https://pub.dev/packages/libadwaita) for widgets; the latter has older releases and must pass a Flutter compatibility spike. [yaru](https://pub.dev/packages/yaru) is actively developed but Ubuntu-oriented. No dependency is final until tested.

## Development
The Flutter application and Linux runner are now included in the repository. The initial source has not been compiled by the authoring agent; report build errors and platform results as issues or PR feedback. Use `flutter analyze` and `flutter test` at your discretion locally; only manual testing can establish host-side audio behavior.

## Compatibility
Target PipeWire + WirePlumber on Fedora, Ubuntu, Arch and openSUSE where installed. PulseAudio-only systems are out of MVP scope. Flatpak support is a research task because access to user configuration and host services needs explicit design.

## Contributing
Start from an issue, keep changes focused, add tests and document host-side effects. See [.agents/CONTRIBUTING.md](.agents/CONTRIBUTING.md).

License: MIT, see [LICENSE](LICENSE).


## Mandatory appearance and language support (MVP)
- Theme modes: Automatic (follow system), Light, Dark. Manual choice persists; automatic tracks system changes.
- Languages: Brazilian Portuguese (pt-BR), English (en), Spanish (es). Detect system locale, allow manual override, use Flutter ARB/gen-l10n and fallback.
- Applies to all screens, dialogs, quick switcher, notifications and errors. See issues #26 and #27.


## System accent color (MVP)
Follow the configured desktop accent color on GNOME and KDE when detectable, ideally through supported XDG Desktop Portal appearance settings. Update on changes when possible. If unavailable, fall back to Sound Labels purple. Apply consistently in light and dark modes with accessible contrast. See issue #28.
