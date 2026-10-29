import 'package:flutter/material.dart';

import '../domain/audio_models.dart';
import '../l10n/app_localizations.dart';
import '../services/app_controller.dart';
import 'app_theme.dart';

IconData iconForSymbol(DeviceSymbol symbol) => switch (symbol) {
      DeviceSymbol.automatic => Icons.auto_awesome_outlined,
      DeviceSymbol.tv => Icons.tv,
      DeviceSymbol.monitor => Icons.desktop_windows_outlined,
      DeviceSymbol.speakers => Icons.speaker_outlined,
      DeviceSymbol.headphones => Icons.headphones_outlined,
      DeviceSymbol.headset => Icons.headset_mic_outlined,
      DeviceSymbol.microphone => Icons.mic_none_outlined,
      DeviceSymbol.bluetooth => Icons.bluetooth,
      DeviceSymbol.usb => Icons.usb_outlined,
      DeviceSymbol.gamepad => Icons.videogame_asset_outlined,
      DeviceSymbol.soundbar => Icons.speaker_group_outlined,
      DeviceSymbol.lineOut => Icons.arrow_right_outlined,
      DeviceSymbol.lineIn => Icons.arrow_left_outlined,
      DeviceSymbol.equalizer => Icons.equalizer_outlined,
      DeviceSymbol.instrument => Icons.music_note_outlined,
      DeviceSymbol.generic => Icons.graphic_eq,
    };

String symbolLabel(AppLocalizations l, DeviceSymbol symbol) => switch (symbol) {
      DeviceSymbol.automatic => l.automatic,
      DeviceSymbol.tv => l.tv,
      DeviceSymbol.monitor => l.monitor,
      DeviceSymbol.speakers => l.speakers,
      DeviceSymbol.headphones => l.headphones,
      DeviceSymbol.headset => l.headset,
      DeviceSymbol.microphone => l.microphone,
      DeviceSymbol.bluetooth => l.bluetooth,
      DeviceSymbol.usb => l.usb,
      DeviceSymbol.gamepad => l.gamepad,
      DeviceSymbol.soundbar => l.soundbar,
      DeviceSymbol.lineOut => l.lineOut,
      DeviceSymbol.lineIn => l.lineIn,
      DeviceSymbol.equalizer => l.equalizer,
      DeviceSymbol.instrument => l.instrument,
      DeviceSymbol.generic => l.generic,
    };

class EndpointGlyph extends StatelessWidget {
  const EndpointGlyph({super.key, required this.symbol, this.size = 22});
  final DeviceSymbol symbol;
  final double size;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: scheme.primaryContainer.withValues(alpha: .55),
        borderRadius: BorderRadius.circular(AppRadii.sm),
      ),
      child: Icon(iconForSymbol(symbol), color: scheme.onPrimaryContainer, size: size),
    );
  }
}

class PageHeading extends StatelessWidget {
  const PageHeading({
    super.key,
    required this.title,
    required this.subtitle,
    this.action,
  });
  final String title;
  final String subtitle;
  final Widget? action;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: AppSpacing.lg),
        child: Wrap(
          alignment: WrapAlignment.spaceBetween,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 12,
          runSpacing: 12,
          children: [
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 560),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      )),
                  const SizedBox(height: 4),
                  Text(subtitle, style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  )),
                ],
              ),
            ),
            if (action != null) action!,
          ],
        ),
      );
}

class SectionSurface extends StatelessWidget {
  const SectionSurface({super.key, required this.children});
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => Card(
        margin: EdgeInsets.zero,
        child: Column(
          children: [
            for (var i = 0; i < children.length; i++) ...[
              if (i != 0) Divider(height: 1, indent: 16, endIndent: 16,
                  color: Theme.of(context).dividerColor),
              children[i],
            ],
          ],
        ),
      );
}

class InlineMessage extends StatelessWidget {
  const InlineMessage({
    super.key,
    required this.message,
    this.icon = Icons.info_outline,
    this.isError = false,
    this.action,
  });
  final String message;
  final IconData icon;
  final bool isError;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isError ? scheme.errorContainer : scheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(AppRadii.sm),
      ),
      child: Row(children: [
        Icon(icon, color: isError ? scheme.onErrorContainer : scheme.onSurfaceVariant),
        const SizedBox(width: 12),
        Expanded(child: SelectableText(message)),
        if (action != null) action!,
      ]),
    );
  }
}

Future<bool> performAction(
  BuildContext context,
  Future<void> Function() action, {
  String? success,
}) async {
  try {
    await action();
    if (context.mounted && success != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(success)));
    }
    return true;
  } catch (error) {
    if (context.mounted) {
      final l = AppLocalizations.of(context);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('${l.operationFailed}: $error'),
        behavior: SnackBarBehavior.floating,
      ));
    }
    return false;
  }
}

class DeviceEditorDialog extends StatefulWidget {
  const DeviceEditorDialog({super.key, required this.endpoint, required this.controller});
  final AudioEndpoint endpoint;
  final AppController controller;

  @override
  State<DeviceEditorDialog> createState() => _DeviceEditorDialogState();
}

class _DeviceEditorDialogState extends State<DeviceEditorDialog> {
  late final TextEditingController nameController;
  late DeviceSymbol symbol;
  late bool systemWide;
  bool saving = false;

  @override
  void initState() {
    super.initState();
    final override = widget.controller.data.overrides[widget.endpoint.key];
    nameController = TextEditingController(text: override?.alias ?? '');
    symbol = override?.symbol ?? DeviceSymbol.automatic;
    systemWide = override?.systemWide ?? false;
  }

  @override
  void dispose() {
    nameController.dispose();
    super.dispose();
  }

  Future<void> _save({bool reset = false}) async {
    if (saving) return;
    setState(() => saving = true);
    final done = await performAction(context, () => widget.controller.setOverride(
          widget.endpoint,
          reset ? null : nameController.text,
          reset ? DeviceSymbol.automatic : symbol,
          systemWide: reset ? false : systemWide,
        ));
    if (mounted) {
      setState(() => saving = false);
      if (done) Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final endpoint = widget.endpoint;
    final scheme = Theme.of(context).colorScheme;
    return AlertDialog(
      title: Text(l.editDevice),
      content: SizedBox(
        width: 540,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(children: [
                EndpointGlyph(symbol: symbol == DeviceSymbol.automatic
                    ? suggestedSymbol(endpoint) : symbol, size: 28),
                const SizedBox(width: 12),
                Expanded(child: Text(endpoint.description,
                    style: Theme.of(context).textTheme.titleMedium)),
              ]),
              const SizedBox(height: 20),
              TextField(
                controller: nameController,
                autofocus: true,
                maxLength: 80,
                decoration: InputDecoration(labelText: l.friendlyName,
                    hintText: l.friendlyNameHint),
                onSubmitted: (_) => _save(),
              ),
              const SizedBox(height: 14),
              Text(l.deviceIcon, style: Theme.of(context).textTheme.titleSmall),
              const SizedBox(height: 8),
              Wrap(spacing: 8, runSpacing: 8, children: [
                for (final candidate in DeviceSymbol.values)
                  Tooltip(
                    message: symbolLabel(l, candidate),
                    child: Semantics(
                      label: symbolLabel(l, candidate),
                      selected: symbol == candidate,
                      child: InkWell(
                        onTap: () => setState(() => symbol = candidate),
                        borderRadius: BorderRadius.circular(10),
                        child: Container(
                          width: 55, height: 55,
                          decoration: BoxDecoration(
                            color: symbol == candidate ? scheme.primaryContainer : scheme.surface,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: symbol == candidate
                                ? scheme.primary : scheme.outlineVariant,
                                width: symbol == candidate ? 2 : 1),
                          ),
                          child: Icon(iconForSymbol(candidate)),
                        ),
                      ),
                    ),
                  ),
              ]),
              const SizedBox(height: 18),
              Text(l.deviceInformation, style: Theme.of(context).textTheme.titleSmall),
              const SizedBox(height: 6),
              _info(l.originalName, endpoint.description),
              _info(l.identifier, endpoint.name),
              if (endpoint.activePort != null)
                _info(l.connection, endpoint.activePort!),
              _info(l.deviceType, endpoint.direction.name),
              const SizedBox(height: 12),
              CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                value: systemWide,
                onChanged: saving ? null : (value) => setState(() {
                  systemWide = value ?? false;
                }),
                title: Text(l.experimentalHostRename),
                subtitle: Text(l.hostRenameWarning),
                controlAffinity: ListTileControlAffinity.leading,
              ),
              InlineMessage(message: l.localAliasNotice),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: saving ? null : () => _save(reset: true),
          child: Text(l.restore),
        ),
        const SizedBox(width: 8),
        TextButton(onPressed: saving ? null : () => Navigator.pop(context),
            child: Text(l.cancel)),
        FilledButton(onPressed: saving ? null : _save, child: Text(l.save)),
      ],
    );
  }

  Widget _info(String label, String value) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          SizedBox(width: 120, child: Text(label,
              style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant))),
          Expanded(child: SelectableText(value)),
        ]),
      );
}
