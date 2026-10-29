import 'package:flutter/material.dart';

import '../domain/audio_models.dart';
import '../l10n/app_localizations.dart';
import '../services/app_controller.dart';
import 'app_theme.dart';
import 'widgets.dart';

class DevicesPage extends StatelessWidget {
  const DevicesPage({super.key, required this.controller, required this.onProfiles});
  final AppController controller;
  final VoidCallback onProfiles;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final snapshot = controller.snapshot;
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      PageHeading(
        title: l.devicesTitle,
        subtitle: l.devicesSubtitle,
        action: FilledButton.tonalIcon(
          onPressed: onProfiles,
          icon: const Icon(Icons.add),
          label: Text(l.newProfile),
        ),
      ),
      _DeviceSection(
        title: l.outputs,
        icon: Icons.desktop_windows_outlined,
        devices: snapshot?.outputs.toList() ?? [],
        controller: controller,
        emptyText: l.noOutputs,
      ),
      const SizedBox(height: AppSpacing.lg),
      _DeviceSection(
        title: l.inputs,
        icon: Icons.mic_none_outlined,
        devices: snapshot?.inputs.toList() ?? [],
        controller: controller,
        emptyText: l.noInputs,
      ),
      const SizedBox(height: AppSpacing.lg),
      InlineMessage(message: l.localAliasNotice),
    ]);
  }
}

class _DeviceSection extends StatelessWidget {
  const _DeviceSection({
    required this.title,
    required this.icon,
    required this.devices,
    required this.controller,
    required this.emptyText,
  });
  final String title;
  final IconData icon;
  final List<AudioEndpoint> devices;
  final AppController controller;
  final String emptyText;

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(children: [
              Icon(icon, size: 20),
              const SizedBox(width: 8),
              Text(title, style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              )),
            ]),
          ),
          if (devices.isEmpty)
            InlineMessage(message: emptyText, icon: Icons.speaker_notes_off_outlined)
          else
            SectionSurface(children: [
              for (final endpoint in devices)
                _DeviceRow(endpoint: endpoint, controller: controller),
            ]),
        ],
      );
}

class _DeviceRow extends StatelessWidget {
  const _DeviceRow({required this.endpoint, required this.controller});
  final AudioEndpoint endpoint;
  final AppController controller;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final isDefault = controller.snapshot?.isDefault(endpoint) ?? false;
    final disabled = controller.busy || controller.audioError != null ||
        !endpoint.available;
    return Container(
      color: isDefault ? scheme.primaryContainer.withValues(alpha: .34) : null,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
        child: Row(children: [
          Tooltip(
            message: isDefault ? l.active :
                (endpoint.isOutput ? l.defaultOutput : l.defaultInput),
            child: IconButton(
              onPressed: disabled || isDefault ? null :
                  () => performAction(context, () => controller.changeDefault(endpoint)),
              icon: Icon(isDefault ? Icons.check_circle : Icons.radio_button_unchecked,
                color: isDefault ? scheme.primary : scheme.onSurfaceVariant),
            ),
          ),
          EndpointGlyph(symbol: controller.displaySymbol(endpoint)),
          const SizedBox(width: 12),
          Expanded(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(crossAxisAlignment: WrapCrossAlignment.center, spacing: 8, children: [
                Text(controller.displayName(endpoint) ?? l.noLabel,
                    style: const TextStyle(fontWeight: FontWeight.w700)),
                if (isDefault) Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: scheme.primary,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(l.active, style: TextStyle(
                    color: scheme.onPrimary, fontSize: 11, fontWeight: FontWeight.w700,
                  )),
                ),
              ]),
              const SizedBox(height: 3),
              Text([
                endpoint.description,
                if (endpoint.details.isNotEmpty) endpoint.details,
                if (!endpoint.available) l.disconnected,
              ].join(' · '),
                maxLines: 2, overflow: TextOverflow.ellipsis,
                style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 12)),
            ],
          )),
          IconButton(
            tooltip: l.edit,
            onPressed: controller.busy ? null : () => showDialog<void>(
              context: context,
              builder: (_) => DeviceEditorDialog(
                endpoint: endpoint, controller: controller,
              ),
            ),
            icon: const Icon(Icons.edit_outlined),
          ),
        ]),
      ),
    );
  }
}
