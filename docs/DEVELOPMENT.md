# Sound Labels — local development and validation

This is pre-alpha source code. It was authored without running Flutter, compiling
the Linux runner, exercising an audio server, or performing unit/manual tests.
Do not treat the presence of a feature in source as evidence that its host
integration works on GNOME, KDE, or a particular distribution.

## Environment

- Flutter stable with Dart >=3.9 and Linux desktop support enabled.
- GTK 3 development dependencies, CMake, Ninja and C++ toolchain (per Flutter
  Linux setup documentation).
- PipeWire, WirePlumber 0.5+ for experimental host rules, pipewire-pulse,
  `pactl`; for optional settings: `gdbus`, `gsettings`, `kreadconfig6`/`5`,
  `notify-send`, `xdg-open`.
- The app intentionally does not require root and does not install a daemon.

```bash
flutter config --enable-linux-desktop
flutter pub get
flutter gen-l10n
flutter run -d linux
```

From a compiled Linux bundle, run `sound_labels --quick` to show the compact
output switcher. On the desktop this is a separate window, not a GNOME Shell
menu extension. `--quick` can be assigned to a custom keyboard shortcut.

## Data and host effects

| Feature | Mechanism | Persisted? | Caveat |
| --- | --- | --- | --- |
| Endpoint discovery | `pactl --format=json list sinks/sources` | No | Requires pipewire-pulse; port/profile exposure varies |
| Default sink/source | `pactl get-default-*`, `set-default-*` | Audio server | Does not force existing streams to move |
| Per-stream output | `pactl move-sink-input` | Current stream only | Stream IDs are ephemeral; a restarted app may route elsewhere |
| Friendly names and icons | `$XDG_CONFIG_HOME/sound-labels/state.json` | Yes | Displayed inside Sound Labels |
| Audio user profiles | Same JSON file | Yes | Fails safely if saved output/input is missing; attempts rollback |
| System-wide alias attempt | `$XDG_CONFIG_HOME/wireplumber/wireplumber.conf.d/90-sound-labels.conf` | Yes, opt-in | Experimental; requires manual WirePlumber restart; GNOME/KDE result unknown |
| Autostart | `$XDG_CONFIG_HOME/autostart/sound-labels.desktop` | Yes, opt-in | Opens the app, not a background-only process |
| Notifications | `notify-send` | Preference persisted | Requires user session notification service |
| System accent | Desktop portal, KDE configuration or GNOME GSettings | Live polling | Purple fallback; implementation varies by desktop version |

The app saves a `.bak` of prior app configuration when updating it. For
WirePlumber opt-in, it **only** owns the `90-sound-labels.conf` file; if it
already exists without the Sound Labels signature, changes are refused.
It never alters arbitrary WirePlumber rules, runs `sudo` or restarts audio.

### Before testing native rename

1. Confirm your WirePlumber version is 0.5 or newer.
2. In **Edit device**, enter a short alias and explicitly enable the
   experimental system-wide name checkbox. Saving creates the managed file.
3. Inspect the file before restarting WirePlumber yourself. Be aware that
   restarting the session audio manager may interrupt active playback.
4. Test the same physical endpoint in GNOME and KDE native selectors, then
   repeat after reconnect and reboot. Test ALSA and Bluetooth separately.
5. To revert, disable the checkbox (or restore defaults) and manually restart
   WirePlumber again. Backup: `90-sound-labels.conf.bak`.

**Do not claim persistent native renaming based on in-app labels alone.**
WirePlumber's rules, desktop labels and HDMI profiles can differ by version.

## Manual acceptance matrix (owner to complete)

| Environment | Device discovery | Default switch | Active stream move | Native alias | Accent/theme | Localization |
| --- | --- | --- | --- | --- | --- | --- |
| Fedora GNOME | Pending | Pending | Pending | Pending | Pending | Pending |
| Fedora KDE Plasma | Pending | Pending | Pending | Pending | Pending | Pending |
| Ubuntu GNOME | Pending | Pending | Pending | Pending | Pending | Pending |
| Arch KDE | Pending | Pending | Pending | Pending | Pending | Pending |
| openSUSE | Pending | Pending | Pending | Pending | Pending | Pending |

Test with HDMI/DisplayPort, USB, analog, Bluetooth, microphones, duplicate
descriptions, hotplug, offline server and multiple active streams. Also check
the app in automatic/light/dark themes, pt-BR/en/es, keyboard-only navigation
and large text. Capture actual version numbers and redacted evidence in issues.

## Scope and known gaps

- GNOME/KDE menu icon overrides have no verified cross-desktop mechanism.
  Device icons are always rendered locally; no claim of native menu support.
- Profiles can remember current active app routes, but apply those routes only
  to live streams; they are not WirePlumber per-app policies on future streams.
- The implementation uses `node.name` for local stable mapping. Some profiles,
  HDMI ports and device reconnections may change node names and need an
  enriched stable-ID matcher after collecting real sanitized fixtures (#1).
- Flatpak, distro packages, release artifacts, public installer and landing
  page are postponed until a manually verified release (#12, #13, #31).
- The test/build release gates from issue #29 remain open until the owner
  provides local evidence. No issue should be closed purely on this source.
