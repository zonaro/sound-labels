import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../domain/audio_models.dart';
import '../l10n/app_localizations.dart';
import '../services/app_controller.dart';
import '../services/icon_resolver.dart';
import 'app_theme.dart';
import 'widgets.dart';

class AppsPage extends StatelessWidget {
  const AppsPage({super.key, required this.controller});
  final AppController controller;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final snapshot = controller.snapshot;
    final outputs = snapshot?.outputs.where((e) => e.available).toList() ?? [];
    final streams = snapshot?.streams ?? [];
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      PageHeading(title: l.apps, subtitle: l.appsSubtitle),
      if (streams.isEmpty)
        InlineMessage(message: l.noStreams, icon: Icons.apps_outlined)
      else
        SectionSurface(children: [
          for (final stream in streams)
            _StreamRow(
              key: ValueKey(stream.index),
              stream: stream,
              outputs: outputs,
              current: snapshot!.outputForIndex(stream.sinkIndex),
              controller: controller,
            ),
        ]),
      const SizedBox(height: AppSpacing.md),
      InlineMessage(message: l.routeSessionOnly),
    ]);
  }
}

class _StreamRow extends StatelessWidget {
  const _StreamRow({
    super.key,
    required this.stream,
    required this.outputs,
    required this.current,
    required this.controller,
  });
  final AudioStream stream;
  final List<AudioEndpoint> outputs;
  final AudioEndpoint? current;
  final AppController controller;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final currentKey = outputs.any((e) => e.key == current?.key) ? current?.key : null;
    return Padding(
      padding: const EdgeInsets.all(14),
      child: Wrap(
        crossAxisAlignment: WrapCrossAlignment.center,
        alignment: WrapAlignment.spaceBetween,
        runSpacing: 10,
        spacing: 14,
        children: [
          SizedBox(width: 220, child: Row(children: [
            Container(
              width: 42, height: 42,
              decoration: BoxDecoration(color: scheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(10)),
              child: FutureBuilder<File?>(
                future: const AppIconResolver().find(stream),
                builder: (context, snapshot) {
                  final icon = snapshot.data;
                  if (icon == null) return const Icon(Icons.apps);
                  if (icon.path.endsWith('.svg')) {
                    return Padding(
                      padding: const EdgeInsets.all(7),
                      child: SvgPicture.file(icon),
                    );
                  }
                  return Padding(
                    padding: const EdgeInsets.all(7),
                    child: Image.file(icon, errorBuilder: (_, _, _) =>
                        const Icon(Icons.apps)),
                  );
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(stream.name, maxLines: 1, overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w700)),
                Text('${l.stream} #${stream.index}',
                    style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant)),
              ],
            )),
          ])),
          SizedBox(width: 250, child: DropdownButtonFormField<String>(
            key: ValueKey('${stream.index}:${currentKey ?? 'none'}'),
            initialValue: currentKey,
            isExpanded: true,
            decoration: InputDecoration(labelText: l.routeTo, isDense: true),
            items: [
              for (final output in outputs)
                DropdownMenuItem(
                  value: output.key,
                  child: Text(controller.displayName(output) ?? l.noLabel,
                      maxLines: 1, overflow: TextOverflow.ellipsis),
                ),
            ],
            onChanged: controller.busy || controller.audioError != null
                ? null : (value) {
              if (value == null || value == currentKey) return;
              final destination = outputs.firstWhere((e) => e.key == value);
              performAction(context, () => controller.moveStream(stream, destination));
            },
          )),
        ],
      ),
    );
  }
}
