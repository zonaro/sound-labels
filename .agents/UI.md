# Flutter UI design research

Goal: a compact, GNOME HIG/libadwaita-inspired application that also looks natural on KDE and other Linux desktops.

Candidates (pub.dev, checked 2026-10-26):
- **adwaita_gtk** — https://pub.dev/packages/adwaita_gtk — modern Material 3-oriented Adwaita color scheme; promising default to prototype, but theme alone is not a full widget library.
- **libadwaita** — https://pub.dev/packages/libadwaita — Adwaita-style widgets (header bars, action rows, preferences groups), latest 2.0.2 appears old; compatibility/maintenance risk. Prototype before adopting.
- **yaru** — https://pub.dev/packages/yaru — actively maintained and rich desktop widgets, but visually Ubuntu/Yaru rather than stock GNOME.
- **adwaita** — https://pub.dev/packages/adwaita — older theme package; prefer evaluating the newer fork first.

**Recommended spike:** Flutter Material 3 + adwaita_gtk, small reusable components matching GNOME HIG. Compare libadwaita widgets only if current Flutter compatibility is demonstrated. Avoid hard dependency on GNOME APIs.

Layout: header, current default output/input quick selectors, two grouped sections (Outputs / Inputs), row with device type icon, editable alias, original system description, availability and current-default indicator. Each connected device can be selected as the system default; Edit remains a separate action. Edit dialog with icon picker, automatic icon suggestion, preview, Save, Cancel, Restore original. Clear empty/error states, keyboard navigation, contrast, light/dark modes, responsive widths. **Icons are required in MVP:** choose from bundled accessible symbols (TV, monitor, speakers, headphones, microphone, USB, Bluetooth, generic), save custom selections per endpoint and provide reset-to-auto. Native GNOME/KDE menu icon override is not guaranteed.

**Approved MVP screens (all required):** Dispositivos, Editar Dispositivo, Aplicativos (per-app audio routing), Perfis (saved configurations), Configurações (startup, sync, notifications, theme, language), and compact Saída de Áudio quick switcher. All must be functional, not placeholder pages. The visual mockup is an approved direction; synthetic device data are examples, not product requirements.

Important: changing system default is explicit; already-running app streams may not move. Listen for changes made outside Sound Labels.

Important: GUI labels must reflect what the host desktop actually uses; do not merely rename rows inside the app.


## Mandatory appearance and language support (MVP)
- Theme modes: Automatic (follow system), Light, Dark. Manual choice persists; automatic tracks system changes.
- Languages: Brazilian Portuguese (pt-BR), English (en), Spanish (es). Detect system locale, allow manual override, use Flutter ARB/gen-l10n and fallback.
- Applies to all screens, dialogs, quick switcher, notifications and errors. See issues #26 and #27.


## System accent color (MVP)
Follow the configured desktop accent color on GNOME and KDE when detectable, ideally through supported XDG Desktop Portal appearance settings. Update on changes when possible. If unavailable, fall back to Sound Labels purple. Apply consistently in light and dark modes with accessible contrast. See issue #28.


## Detailed text-only implementation specification
**Required reading:** [UI_IMPLEMENTATION.md](UI_IMPLEMENTATION.md). The approved mockup is uploaded by the owner in root `assets/`; use `assets/concept.png`. Agents without vision should implement the complete screen-by-screen text specification instead of guessing from the picture. The icon SVG is a separate asset.

**Approved visual reference:** [`assets/concept.png`](../assets/concept.png). This is the canonical UI mockup; agents with image support should inspect it, and text-only agents must follow `UI_IMPLEMENTATION.md`.
