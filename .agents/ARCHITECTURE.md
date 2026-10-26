# Architecture and technical risks

## Layers
- **Presentation:** Flutter Linux desktop; list of sinks/sources, editing dialogs, state/errors.
- **Domain:** AudioEndpoint (stable key, node name, description, media class, card, port, availability, original label), LabelOverride, IconOverride and operations (list/apply/reset).
- **Application:** DiscoveryService, LabelService, PersistenceService, diagnostics.
- **Infrastructure:** AudioBackend interface, PipeWire/WirePlumber implementation, local override store, optional rule generator.

## Discovery
Start with `wpctl status`, `wpctl inspect`, `pw-dump` and `pactl list sinks/sources` to inspect actual properties on Fedora. Prototype robust structured data discovery (JSON or supported API) rather than parsing localized human-readable output. Map cards, ports, nodes and EDID metadata where available. Numeric node IDs are transient.

## Rename and persistence — must prove
Research WirePlumber 0.5+ configuration and rules matching appropriate stable node/card/port properties. A display name may come from `node.description`, `device.description` or profile/port metadata depending on desktop. Validate exactly which properties GNOME and KDE show. Different HDMI outputs on one GPU may be profiles/ports of a single card, not simultaneously exposed sinks: model that distinction explicitly.

Prototype a safe apply/revert mechanism and verify user-visible result, restart, hotplug, multiple identical devices and collisions. If a desktop ignores renamed metadata, expose the limitation instead of claiming universal support.

## Icon architecture
Icons are a first-release requirement. Store a stable icon identifier per endpoint in app-owned XDG configuration; support auto-detected defaults, custom selection and reset. Render icons in Flutter independently of host audio metadata. Research whether PipeWire icon-name properties affect native GNOME/KDE menus, but do not rely on this for MVP functionality. Validate icon licensing and accessible descriptions.

## Persistence safety
App-owned state under XDG_CONFIG_HOME; generated WirePlumber fragments only after compatibility detection. Preserve external configuration. Validate rules before activation, rollback on failure and retain original values for reset. Do not require root.

## Distribution
Start with native Linux packaging/dev workflow. Research Flatpak permissions and host config access separately; no unsafe blanket filesystem access by default.

## Tests
Unit: identifiers, collision handling, validation, serialization, rollback.
Integration: mock backend and real Fedora PipeWire/WirePlumber; verify GNOME and KDE display labels, reboot/hotplug.
