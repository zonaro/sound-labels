import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../l10n/app_localizations.dart';
import '../services/app_controller.dart';
import 'widgets.dart';

/// Launch the same executable with `--quick` for a small independent window.
/// This works without a GNOME Shell extension or system tray provider.
class QuickSwitcher extends StatelessWidget {
  const QuickSwitcher({super.key, required this.controller});
  final AppController controller;

  Future<void> _openFullApp() async {
    await Process.start(
      Platform.resolvedExecutable,
      const [],
      mode: ProcessStartMode.detached,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final outputs = controller.snapshot?.outputs.toList() ?? [];
    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.escape): () => exit(0),
      },
      child: Focus(autofocus: true, child: Scaffold(
        appBar: AppBar(title: Text(l.quickOutput), actions: [
          IconButton(
            tooltip: l.refresh,
            onPressed: controller.refresh,
            icon: const Icon(Icons.refresh),
          ),
        ]),
        body: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(children: [
            if (controller.audioError != null)
              InlineMessage(message: l.audioUnavailable, isError: true),
            Expanded(child: ListView(children: [
              if (outputs.isEmpty)
                InlineMessage(message: l.noOutputs)
              else
                for (final output in outputs)
                  Card(
                    color: controller.snapshot?.isDefault(output) == true
                        ? scheme.primaryContainer : null,
                    child: ListTile(
                      enabled: output.available && !controller.busy &&
                          controller.audioError == null,
                      leading: EndpointGlyph(symbol: controller.displaySymbol(output)),
                      title: Text(controller.displayName(output) ?? l.noLabel,
                          maxLines: 1, overflow: TextOverflow.ellipsis),
                      subtitle: Text(output.description, maxLines: 1,
                          overflow: TextOverflow.ellipsis),
                      trailing: controller.snapshot?.isDefault(output) == true
                          ? Icon(Icons.check_circle, color: scheme.primary)
                          : const Icon(Icons.radio_button_unchecked),
                      onTap: () => performAction(context, () => controller.changeDefault(output)),
                    ),
                  ),
            ])),
            const SizedBox(height: 8),
            SizedBox(width: double.infinity, child: FilledButton.tonalIcon(
              onPressed: () => performAction(context, _openFullApp),
              icon: const Icon(Icons.settings_outlined),
              label: Text(l.openApp),
            )),
          ]),
        ),
      )),
    );
  }
}
