# Flutter UI design research

Goal: a compact, GNOME HIG/libadwaita-inspired application that also looks natural on KDE and other Linux desktops.

Candidates (pub.dev, checked 2026-10-26):
- **adwaita_gtk** — https://pub.dev/packages/adwaita_gtk — modern Material 3-oriented Adwaita color scheme; promising default to prototype, but theme alone is not a full widget library.
- **libadwaita** — https://pub.dev/packages/libadwaita — Adwaita-style widgets (header bars, action rows, preferences groups), latest 2.0.2 appears old; compatibility/maintenance risk. Prototype before adopting.
- **yaru** — https://pub.dev/packages/yaru — actively maintained and rich desktop widgets, but visually Ubuntu/Yaru rather than stock GNOME.
- **adwaita** — https://pub.dev/packages/adwaita — older theme package; prefer evaluating the newer fork first.

**Recommended spike:** Flutter Material 3 + adwaita_gtk, small reusable components matching GNOME HIG. Compare libadwaita widgets only if current Flutter compatibility is demonstrated. Avoid hard dependency on GNOME APIs.

Layout: header, two grouped sections (Outputs / Inputs), row with device type icon, editable alias, original system description, availability. Edit dialog with preview, Save, Cancel, Restore original. Clear empty/error states, keyboard navigation, contrast, light/dark modes, responsive widths. Icons optional and secondary to names.

Important: GUI labels must reflect what the host desktop actually uses; do not merely rename rows inside the app.
