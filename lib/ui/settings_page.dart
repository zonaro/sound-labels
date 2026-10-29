import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../l10n/app_localizations.dart';
import '../services/app_controller.dart';
import '../services/diagnostics.dart';
import 'app_theme.dart';
import 'widgets.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key, required this.controller});
  final AppController controller;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final settings = controller.settings;
    final themeOptions = {
      'system': l.automatic,
      'light': l.light,
      'dark': l.dark,
    };
    final languageOptions = {
      'system': l.automatic,
      'pt': l.ptBr,
      'en': l.english,
      'es': l.spanish,
    };
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      PageHeading(title: l.settings, subtitle: l.settingsSubtitle),
      _group(context, l.general, [
        SwitchListTile.adaptive(
          contentPadding: const EdgeInsets.symmetric(horizontal: 18),
          title: Text(l.autostart),
          subtitle: Text(l.autostartDescription),
          value: settings.autostart,
          onChanged: (value) => performAction(context, () => controller.updateSettings(
            settings.copyWith(autostart: value),
          )),
        ),
        SwitchListTile.adaptive(
          contentPadding: const EdgeInsets.symmetric(horizontal: 18),
          title: Text(l.liveSync),
          subtitle: Text(l.liveSyncDescription),
          value: settings.liveSync,
          onChanged: (value) => performAction(context, () => controller.updateSettings(
            settings.copyWith(liveSync: value),
          )),
        ),
        SwitchListTile.adaptive(
          contentPadding: const EdgeInsets.symmetric(horizontal: 18),
          title: Text(l.notifications),
          subtitle: Text(l.notificationsDescription),
          value: settings.notifications,
          onChanged: (value) => performAction(context, () => controller.updateSettings(
            settings.copyWith(notifications: value),
          )),
        ),
      ]),
      const SizedBox(height: AppSpacing.lg),
      _group(context, l.appearance, [
        _choice(context, l.theme, settings.theme, themeOptions,
            (value) => controller.updateSettings(settings.copyWith(theme: value))),
        Padding(padding: const EdgeInsets.fromLTRB(18, 0, 18, 16),
          child: InlineMessage(message: l.inheritedAccent)),
      ]),
      const SizedBox(height: AppSpacing.lg),
      _group(context, l.languageGroup, [
        _choice(context, l.language, settings.language, languageOptions,
            (value) => controller.updateSettings(settings.copyWith(language: value))),
      ]),
      const SizedBox(height: AppSpacing.lg),
      _group(context, l.about, [
        ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 18),
          leading: const Icon(Icons.info_outline),
          title: Text(l.appName),
          subtitle: Text(l.version),
        ),
        ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 18),
          leading: const Icon(Icons.code),
          title: Text(l.project),
          subtitle: const Text('github.com/zonaro/sound-labels'),
          trailing: const Icon(Icons.open_in_new),
          onTap: () => performAction(context, () async {
            final result = await Process.run('xdg-open', [
              'https://github.com/zonaro/sound-labels',
            ]);
            if (result.exitCode != 0) throw StateError(result.stderr.toString());
          }),
        ),
        ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 18),
          leading: const Icon(Icons.bug_report_outlined),
          title: Text(l.copyDiagnostics),
          trailing: const Icon(Icons.copy),
          onTap: () => performAction(context, () => Clipboard.setData(
            ClipboardData(text: diagnosticSummary(
              controller.snapshot,
              controller.audioError,
            )),
          ), success: l.diagnosticsCopied),
        ),
      ]),
    ]);
  }

  Widget _group(BuildContext context, String title, List<Widget> children) =>
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Padding(padding: const EdgeInsets.only(bottom: 10),
          child: Text(title, style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
          ))),
        SectionSurface(children: children),
      ]);

  Widget _choice(
    BuildContext context,
    String label,
    String value,
    Map<String, String> options,
    Future<void> Function(String) onChanged,
  ) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
        child: Wrap(alignment: WrapAlignment.spaceBetween,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 16, runSpacing: 8,
          children: [
            Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
            SizedBox(width: 235, child: DropdownButtonFormField<String>(
              initialValue: value,
              isExpanded: true,
              items: [for (final entry in options.entries)
                DropdownMenuItem(value: entry.key, child: Text(entry.value,
                    overflow: TextOverflow.ellipsis))],
              onChanged: (chosen) {
                if (chosen != null) performAction(context, () => onChanged(chosen));
              },
            )),
          ],
        ),
      );
}
