# Sound Labels — UI Implementation Blueprint (text-only specification)

> **Status:** approved visual direction, mandatory MVP. This document is deliberately complete enough for agents without image vision. The approved UI concept image was uploaded by the project owner at `assets/concept.png`. The exact image path is **`assets/concept.png`**; do not confuse the mockup image with `assets/icons/sound-labels.svg` (the app icon). The text below is authoritative for functional scope. For fine-grained illustration/spacing details, the concept image is the visual reference. If the two conflict on real behavior, prioritize this spec and issue #29.

## 1. Overall visual language

A modern, calm desktop audio-control utility inspired by GNOME libadwaita, implemented in **Flutter**, not a GNOME Shell extension. It should feel native and efficient on GNOME and KDE: airy spacing, grouped preferences, subtle separators, softly rounded rectangular cards and buttons, low visual noise, typography with a clear hierarchy. The concept uses a light, off-white window, pale panels, a purple accent, a left navigation sidebar and clean device rows. **Purple is a fallback only**: read GNOME/KDE system accent where supported (#28), including updates. Brand icon remains purple.

Suggested implementation tokens (starting values, not exact measurements): window min width ~720 logical px; comfortable default width ~960–1080 px, height ~680–760 px; navigation rail/sidebar 200–240 px; outer padding 24 px; section gaps 20–24 px; list row min height 68–80 px; card radius 12–16 px; button radius 8–12 px; control hit targets >=44 px. At narrower widths collapse the sidebar to icons or a navigation drawer; dialogs must stay within viewport. Prefer native platform fonts and Flutter text scaling, not fixed-size screenshots.

Use Material 3 theme primitives with custom Adwaita-like components if needed; evaluate maintained libraries first. Keep visual tokens centralized (`AppTheme`, `AppColors`, `AppSpacing`, `AppRadii`). No direct hard-coded purple on screens.

## 2. Application shell and navigation

Top-level application window: subtle headerbar/title row with the Sound Labels identity and page title, navigation on the left, main scrollable content on the right. The left sidebar shows icon+label destinations in this order:
1. **Dispositivos** (devices)
2. **Aplicativos** (per-app audio routing)
3. **Perfis** (saved user configurations)
4. **Configurações** (settings)

Selected navigation item has a soft accent-tinted background and stronger foreground. Sidebar is visually distinct with a slightly tinted neutral surface. Header actions can include a compact active-output control, refresh/status and overflow/help as relevant; do not add nonfunctional buttons. On small widths, navigation collapses gracefully. Show loading, empty, offline/audio-server-unavailable and permission-error states rather than blank panes.

## 3. Dispositivos — main screen

At top show a clear heading, short descriptive subtitle and current output/input selection. Two visibly separate grouped lists: **Saídas de áudio** and **Entradas de áudio**. Each device row:
- leading icon tile indicating TV, monitor, speakers, headphones, microphone, Bluetooth, USB or generic device; custom icon selected by user overrides automatic suggestion;
- primary line: friendly custom name if set (e.g., “TV Samsung”, “Monitor LG”), otherwise host device description;
- secondary muted line: original technical/system description, connector/port or availability (only if known);
- trailing selection indicator or radio/checked state for current default; selecting the row's designated control changes the default explicitly;
- a distinct **Editar** action (pencil/overflow), not confused with selection;
- optional availability status and disconnect handling, with unavailable items clearly differentiated.

Default device stands out via accent check or “Ativo” label. Device changes from GNOME/KDE or other apps update the list live. Do not display fictional connected devices in production. Hotplug preserves custom labels/icons using stable identities; if hardware is gone, do not silently reroute.

## 4. Editar dispositivo — dialog or detail panel

Open from a device row, using a centered modal on desktop or responsive panel on narrow windows. Show device name and type at top, current icon preview, editable **Nome personalizado** text field with hint/example, and an icon selector grid. Icon choices: Auto, TV, monitor, speakers, headphones, headset, microphone, Bluetooth, USB, generic; selection shows clear focus/selected state. Display a read-only **Informações do dispositivo** group with actual original description, device identifier and connection details when available. Footer actions **Restaurar padrão**, **Cancelar**, **Salvar**. Cancel discards draft. Restore resets user override (name and/or icon, as explicitly indicated). Save validates and persists; show progress and failure/rollback messages. If host-level renaming cannot be applied to GNOME/KDE selectors, disclose the verified limitation instead of claiming success.

## 5. Aplicativos — per-application audio routing

Page heading **Aplicativos**, subtitle explaining independent routing. Present currently active audio streams as a list of rows/cards with app icon, app name, stream/status, and a right-aligned dropdown showing its selected output device. Example concept apps are illustrative; show only actual observed active streams. A selection moves the active stream using supported PipeWire/WirePlumber functionality; show pending/success/error states. Multiple streams from the same app may require grouping or separate subrows; do not assume one app equals one stream. Clearly distinguish default device from per-app override, explain session-only behavior if persistence is not supported. When streams stop or output disappears, update without crashes. Empty state: “Nenhum aplicativo reproduzindo áudio no momento.”

## 6. Perfis — saved user configurations

Page heading **Perfis**, short explanatory text and **Novo perfil** primary action. Show saved profiles as compact cards or grouped rows: profile name, short summary of output/input and optional per-app preferences, and **Ativar** action. Active profile visibly marked. Each has edit/rename, duplicate and delete actions (overflow menu acceptable). New/edit profile form selects desired default output/input and any supported routing rules. Preview before applying, handle missing devices and partial failures with clear explanations and rollback. Profiles are **user-created Sound Labels presets**, not the low-level Bluetooth/ALSA/PipeWire card profiles. Show meaningful empty state.

## 7. Configurações — grouped preferences

Page heading **Configurações**. Render clean Adwaita-like grouped settings rows with labels, concise helper text and right-aligned toggles/selectors.

Suggested groups:
- **Geral**: Iniciar com o sistema (toggle), Atualizar dispositivos automaticamente (toggle where user control makes sense), Mostrar notificações de mudança de dispositivo (toggle).
- **Aparência**: Tema with **Automático (sistema)**, **Claro**, **Escuro**; accent color is **automatically inherited** from GNOME/KDE if detectable, otherwise purple; explain fallback but do not require user to pick it. Theme override persists. System accent change propagates live where possible.
- **Idioma**: **Automático (sistema)**, **Português (Brasil)**, **English**, **Español**. Default follows OS locale; manual override persists.
- **Sobre**: version, project and license links, diagnostics/help.

Every control must function, not merely decorate the page. Prefer XDG-compatible autostart and notifications; no root or unnecessary background daemon.

## 8. Saída de Áudio — compact quick switcher

A separate small, anchored popup/window or compact layout, visually matching the main app. Title **Saída de Áudio**; list available output devices as tappable rows with icon, friendly name, active checkmark and optional secondary descriptor. Selection switches the actual default output and immediately updates the main view. Bottom action **Abrir Sound Labels** opens/focuses the main window. Keyboard accessible; arrow keys/tab/enter/escape work. Native tray availability differs on GNOME/KDE; provide a reliable small-window/shortcut fallback rather than requiring unsupported tray behavior.

## 9. Shared interaction behavior

Use reusable widgets: `AppShell`, `SidebarNavItem`, `SectionCard`, `AudioDeviceRow`, `DeviceIconPicker`, `DefaultDeviceIndicator`, `AppStreamRow`, `ProfileCard`, `SettingsRow`, `QuickOutputRow`, `InlineStatus`, `EmptyState`. Model view state explicitly (loading, success, unavailable, error). Do not use blocking synchronous shell calls from Flutter UI; backend interactions are async and testable. Use non-destructive confirmations where appropriate. Restore focus after dialogs, show tooltips and descriptive semantics. Persist preferences per user.

## 10. Appearance, accessibility and localization

Mandatory across every screen/dialog/quick switcher: system/light/dark themes (#27); GNOME/KDE accent color with purple fallback (#28); localized pt-BR/en/es via ARB/gen-l10n (#26). Follow OS theme in automatic mode and update on changes when available; manual theme override is independent of accent detection. Derive accessible foreground/on-accent colors from detected accent; verify contrast in both themes. Use scalable fonts, keyboard navigation, screen-reader labels, visible focus indicators, minimum hit targets and no color-only status. Localize dynamic messages, errors, notifications, plurals and button labels. Never translate user-supplied device names or actual app names.

## 11. Iconography and imagery

The application logo is `assets/icons/sound-labels.svg`: rounded purple hexagon with white audio bars; treat it as brand identity, independent of desktop accent. The owner's uploaded concept image under `assets/` documents the UI composition. Do not use the mockup itself as a production screenshot or ship synthetic data as real. Device icons should use a coherent, accessible vector icon family, not emoji.

## 12. Suggested Flutter component tree

`MaterialApp(theme: lightTheme, darkTheme: darkTheme, themeMode: userThemeMode, locale: userLocale, localizationsDelegates: ...)`
→ `AppShell` → adaptive `NavigationRail/Drawer` + page outlet
→ `DevicesPage` / `AppsPage` / `ProfilesPage` / `SettingsPage`
→ `DeviceEditorDialog` and `QuickOutputSwitcherWindow` as separate routes/window surfaces.

Use domain services for endpoint discovery, defaults, aliases, routing, profile persistence, desktop settings and notifications. Widgets never parse `wpctl` output themselves.

## 13. Acceptance checklist for agents without image access

- [ ] All four sidebar destinations and six approved views (including editor and compact switcher) implemented.
- [ ] Main device lists show actual endpoints with icon, alias, original descriptor, default and edit action.
- [ ] Editor can change/reset names and icons with validation, save/cancel and actual persistence.
- [ ] Apps view lists live streams and can move routing.
- [ ] Profiles view can create/edit/activate/delete presets safely.
- [ ] Settings controls work; light/dark/system themes, pt-BR/en/es and accent inheritance apply everywhere.
- [ ] Compact switcher changes real output and opens main app.
- [ ] Layout adapts to smaller windows, works with keyboard and screen readers.
- [ ] GNOME/KDE compatibility and fallback behavior tested with real devices; no unsupported claims.
- [ ] UI tests/golden tests for all pages in light and dark, including multiple accent colors and all three locales.


**Approved visual reference:** [`assets/concept.png`](../assets/concept.png). This is the canonical UI mockup; agents with image support should inspect it, and text-only agents must follow `UI_IMPLEMENTATION.md`.
