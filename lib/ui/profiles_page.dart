import 'package:flutter/material.dart';

import '../domain/audio_models.dart';
import '../l10n/app_localizations.dart';
import '../services/app_controller.dart';
import 'app_theme.dart';
import 'widgets.dart';

class ProfilesPage extends StatelessWidget {
  const ProfilesPage({super.key, required this.controller});
  final AppController controller;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final profiles = controller.data.profiles;
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      PageHeading(
        title: l.profiles,
        subtitle: l.profilesSubtitle,
        action: FilledButton.icon(
          onPressed: controller.snapshot == null ? null : () => showDialog<void>(
            context: context,
            builder: (_) => _ProfileEditor(controller: controller),
          ),
          icon: const Icon(Icons.add),
          label: Text(l.newProfile),
        ),
      ),
      if (profiles.isEmpty)
        InlineMessage(message: l.profileEmpty, icon: Icons.bookmarks_outlined)
      else
        SectionSurface(children: [
          for (final profile in profiles)
            _ProfileRow(profile: profile, controller: controller),
        ]),
    ]);
  }
}

class _ProfileRow extends StatelessWidget {
  const _ProfileRow({required this.profile, required this.controller});
  final SavedProfile profile;
  final AppController controller;

  String _label(String? key) {
    if (key == null) return '—';
    final endpoint = controller.snapshot?.endpointForKey(key);
    return endpoint == null ? key : (controller.displayName(endpoint) ?? key);
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final active = controller.data.activeProfileId == profile.id;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Wrap(
        alignment: WrapAlignment.spaceBetween,
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 16, runSpacing: 10,
        children: [
          SizedBox(width: 310, child: Row(children: [
            EndpointGlyph(symbol: DeviceSymbol.generic),
            const SizedBox(width: 12),
            Expanded(child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  Flexible(child: Text(profile.name,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                    overflow: TextOverflow.ellipsis)),
                  if (active) ...[
                    const SizedBox(width: 8),
                    Icon(Icons.check_circle, color: scheme.primary, size: 18),
                  ],
                ]),
                Text('${l.outputs}: ${_label(profile.outputKey)}',
                  style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant),
                  overflow: TextOverflow.ellipsis),
                Text('${l.inputs}: ${_label(profile.inputKey)}',
                  style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant),
                  overflow: TextOverflow.ellipsis),
              ],
            )),
          ])),
          Row(mainAxisSize: MainAxisSize.min, children: [
            FilledButton.tonal(
              onPressed: controller.busy ? null : () => _previewAndActivate(context),
              child: Text(active ? l.current : l.activate),
            ),
            PopupMenuButton<String>(
              tooltip: l.edit,
              onSelected: (action) => _handleMenu(context, action),
              itemBuilder: (_) => [
                PopupMenuItem(value: 'edit', child: Text(l.edit)),
                PopupMenuItem(value: 'rename', child: Text(l.rename)),
                PopupMenuItem(value: 'duplicate', child: Text(l.duplicate)),
                PopupMenuItem(value: 'delete', child: Text(l.delete)),
              ],
            ),
          ]),
        ],
      ),
    );
  }

  Future<void> _previewAndActivate(BuildContext context) async {
    final l = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l.profilePreview),
        content: Column(mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l.activateConfirm),
            const SizedBox(height: 12),
            Text('${l.outputs}: ${_label(profile.outputKey)}'),
            Text('${l.inputs}: ${_label(profile.inputKey)}'),
            Text('${l.apps}: ${profile.applicationRoutes.length}'),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text(l.cancel)),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: Text(l.activate)),
        ],
      ),
    );
    if (confirmed == true && context.mounted) {
      await performAction(context, () => controller.activateProfile(profile),
          success: l.profileActivated);
    }
  }

  Future<void> _handleMenu(BuildContext context, String action) async {
    final l = AppLocalizations.of(context);
    if (action == 'edit') {
      await showDialog<void>(context: context,
          builder: (_) => _ProfileEditor(controller: controller, existing: profile));
    } else if (action == 'rename') {
      final name = await _askName(context, profile.name, l.rename);
      if (name != null && context.mounted) {
        await performAction(context, () => controller.renameProfile(profile, name),
            success: l.saved);
      }
    } else if (action == 'duplicate') {
      await performAction(context, () => controller.duplicateProfile(profile),
          success: l.copied);
    } else if (action == 'delete') {
      final confirmed = await showDialog<bool>(context: context,
        builder: (context) => AlertDialog(
          title: Text(l.delete),
          content: Text(l.deleteConfirm),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, false), child: Text(l.cancel)),
            FilledButton(onPressed: () => Navigator.pop(context, true), child: Text(l.delete)),
          ],
        ),
      );
      if (confirmed == true && context.mounted) {
        await performAction(context, () => controller.deleteProfile(profile),
            success: l.profileDeleted);
      }
    }
  }
}

Future<String?> _askName(BuildContext context, String initial, String title) async {
  final l = AppLocalizations.of(context);
  final name = TextEditingController(text: initial);
  try {
    return await showDialog<String>(context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: TextField(
          controller: name,
          autofocus: true,
          maxLength: 60,
          decoration: InputDecoration(labelText: l.profileName),
          onSubmitted: (text) {
            if (text.trim().isNotEmpty) Navigator.pop(context, text.trim());
          },
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text(l.cancel)),
          FilledButton(onPressed: () => Navigator.pop(context, name.text.trim()),
              child: Text(l.save)),
        ],
      ),
    );
  } finally {
    name.dispose();
  }
}

class _ProfileEditor extends StatefulWidget {
  const _ProfileEditor({required this.controller, this.existing});
  final AppController controller;
  final SavedProfile? existing;

  @override
  State<_ProfileEditor> createState() => _ProfileEditorState();
}

class _ProfileEditorState extends State<_ProfileEditor> {
  late final TextEditingController name;
  String? outputKey;
  String? inputKey;
  bool saveApplicationRoutes = false;
  bool saving = false;

  @override
  void initState() {
    super.initState();
    final existing = widget.existing;
    final snapshot = widget.controller.snapshot;
    name = TextEditingController(text: existing?.name ?? '');
    outputKey = existing?.outputKey ?? (snapshot == null
        ? null : snapshot.endpointForName(snapshot.defaultSinkName)?.key);
    inputKey = existing?.inputKey ?? (snapshot == null
        ? null : snapshot.endpointForName(snapshot.defaultSourceName)?.key);
    saveApplicationRoutes = existing?.applicationRoutes.isNotEmpty ?? false;
  }

  @override
  void dispose() {
    name.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final normalized = name.text.trim();
    if (normalized.isEmpty) return;
    final snapshot = widget.controller.snapshot;
    final routes = <String, String>{};
    if (saveApplicationRoutes && snapshot != null) {
      for (final stream in snapshot.streams) {
        final output = snapshot.outputForIndex(stream.sinkIndex);
        if (output != null) routes[stream.applicationId] = output.key;
      }
    }
    final profile = SavedProfile(
      id: widget.existing?.id ?? DateTime.now().microsecondsSinceEpoch.toString(),
      name: normalized,
      outputKey: outputKey,
      inputKey: inputKey,
      overrides: Map.of(widget.controller.data.overrides),
      applicationRoutes: routes,
    );
    setState(() => saving = true);
    final done = await performAction(context, () => widget.existing == null
        ? widget.controller.addProfile(profile)
        : widget.controller.updateProfile(profile));
    if (mounted) {
      setState(() => saving = false);
      if (done) Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final snap = widget.controller.snapshot;
    final outputs = snap?.outputs.toList() ?? [];
    final inputs = snap?.inputs.toList() ?? [];
    // Missing saved devices remain visible as unmatched selections and do not
    // silently switch to another real device during profile editing.
    final outputChoice = outputs.any((e) => e.key == outputKey) ? outputKey : null;
    final inputChoice = inputs.any((e) => e.key == inputKey) ? inputKey : null;
    return AlertDialog(
      title: Text(widget.existing == null ? l.newProfile : l.edit),
      content: SizedBox(width: 480, child: SingleChildScrollView(child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: name,
            autofocus: true,
            maxLength: 60,
            decoration: InputDecoration(labelText: l.profileName),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            isExpanded: true,
            initialValue: outputChoice,
            decoration: InputDecoration(labelText: l.profileOutput),
            items: [for (final output in outputs)
              DropdownMenuItem(value: output.key,
                child: Text(widget.controller.displayName(output) ?? l.noLabel, overflow: TextOverflow.ellipsis))],
            onChanged: (value) => setState(() => outputKey = value),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            isExpanded: true,
            initialValue: inputChoice,
            decoration: InputDecoration(labelText: l.profileInput),
            items: [for (final input in inputs)
              DropdownMenuItem(value: input.key,
                child: Text(widget.controller.displayName(input) ?? l.noLabel, overflow: TextOverflow.ellipsis))],
            onChanged: (value) => setState(() => inputKey = value),
          ),
          const SizedBox(height: 12),
          SwitchListTile.adaptive(
            value: saveApplicationRoutes,
            onChanged: (value) => setState(() => saveApplicationRoutes = value),
            title: Text(l.saveActiveRoutes),
            subtitle: Text(l.routeSessionOnly),
            contentPadding: EdgeInsets.zero,
          ),
        ],
      ))),
      actions: [
        TextButton(onPressed: saving ? null : () => Navigator.pop(context),
            child: Text(l.cancel)),
        FilledButton(onPressed: saving ? null : _save, child: Text(l.save)),
      ],
    );
  }
}
