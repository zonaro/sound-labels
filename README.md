# Sound Labels 🎧

A lightweight, desktop-agnostic Linux application to identify and rename audio inputs and outputs with persistent, human-friendly labels.

> **Status:** planning / pre-alpha. No working renaming functionality has been implemented yet.

## Why
HDMI/DisplayPort audio endpoints often look identical in desktop sound menus. Sound Labels aims to display labels such as **Living Room TV**, **LG Monitor** and **USB Microphone**, without replacing the system's audio server.

## Scope (MVP)
- Linux desktop app built with Flutter, responsive and keyboard-accessible.
- Detect PipeWire audio sinks and sources, their ports and relevant properties.
- Show original description, proposed custom label, connection state and technical identifier.
- Rename, reset and persist labels **only after validating that desktop selectors reflect the changes**.
- Handle hotplug, restarts and missing devices gracefully.
- Never change the default device or audio routing implicitly.

## Architecture
Flutter UI → Dart application services → replaceable Linux audio adapter → PipeWire/WirePlumber. Prefer a direct, supported interface where feasible; evaluate `wpctl`, `pw-dump`, D-Bus and WirePlumber configuration rules before selecting the production mechanism. Do not assume that a node rename always changes GNOME/KDE labels.

Configuration belongs to the current user. Avoid root and do not overwrite user-maintained WirePlumber files. Implement atomic writes, backups and rollback if rules are generated.

See [agent guidance](.agents/README.md), [architecture](.agents/ARCHITECTURE.md), [roadmap](.agents/ROADMAP.md), and [UI research](.agents/UI.md).

## Visual direction
GNOME HIG / libadwaita-inspired, not GNOME-dependent. Evaluate [adwaita_gtk](https://pub.dev/packages/adwaita_gtk) for modern Material 3 colors and [libadwaita](https://pub.dev/packages/libadwaita) for widgets; the latter has older releases and must pass a Flutter compatibility spike. [yaru](https://pub.dev/packages/yaru) is actively developed but Ubuntu-oriented. No dependency is final until tested.

## Development
Prerequisites: current stable Flutter with Linux desktop support, a Linux workstation with PipeWire and WirePlumber, and their CLI inspection tools. Bootstrap the Flutter app in a dedicated issue; do not assume the app already builds.

## Compatibility
Target PipeWire + WirePlumber on Fedora, Ubuntu, Arch and openSUSE where installed. PulseAudio-only systems are out of MVP scope. Flatpak support is a research task because access to user configuration and host services needs explicit design.

## Contributing
Start from an issue, keep changes focused, add tests and document host-side effects. See [.agents/CONTRIBUTING.md](.agents/CONTRIBUTING.md).

License: **not yet selected**; choose and add a LICENSE file before accepting external contributions.
