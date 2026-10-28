import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../l10n/app_localizations.dart';
import '../services/app_controller.dart';
import 'app_theme.dart';
import 'apps_page.dart';
import 'devices_page.dart';
import 'profiles_page.dart';
import 'settings_page.dart';
import 'widgets.dart';

class AppShell extends StatefulWidget {
  const AppShell({super.key, required this.controller});
  final AppController controller;

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int selected = 0;

  void navigate(int index) => setState(() => selected = index);

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final ctrl = widget.controller;
    final destinations = <(String, IconData)>[
      (l.devices, Icons.volume_up_outlined),
      (l.apps, Icons.apps_outlined),
      (l.profiles, Icons.bookmarks_outlined),
      (l.settings, Icons.settings_outlined),
    ];
    final pages = <Widget>[
      DevicesPage(controller: ctrl, onProfiles: () => navigate(2)),
      AppsPage(controller: ctrl),
      ProfilesPage(controller: ctrl),
      SettingsPage(controller: ctrl),
    ];
    return LayoutBuilder(builder: (context, constraints) {
      final wide = constraints.maxWidth >= 760;
      return Scaffold(
        appBar: AppBar(
          leading: wide ? null : Builder(builder: (context) => IconButton(
            tooltip: l.devices,
            icon: const Icon(Icons.menu),
            onPressed: () => Scaffold.of(context).openDrawer(),
          )),
          title: Row(mainAxisSize: MainAxisSize.min, children: [
            const _BrandMark(),
            const SizedBox(width: 10),
            Text(l.appName, style: const TextStyle(fontWeight: FontWeight.w700)),
          ]),
          actions: [
            if (ctrl.busy) const Padding(
              padding: EdgeInsets.symmetric(horizontal: 12),
              child: SizedBox(width: 18, height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2)),
            ),
            IconButton(
              tooltip: l.refresh,
              onPressed: ctrl.busy ? null : ctrl.refresh,
              icon: const Icon(Icons.refresh),
            ),
            const SizedBox(width: 12),
          ],
        ),
        drawer: wide ? null : Drawer(child: SafeArea(child: _Sidebar(
          destinations: destinations,
          selected: selected,
          onSelect: (index) {
            Navigator.of(context).pop();
            navigate(index);
          },
        ))),
        body: Row(children: [
          if (wide)
            SizedBox(width: 224, child: _Sidebar(
              destinations: destinations,
              selected: selected,
              onSelect: navigate,
            )),
          Expanded(child: SafeArea(child: Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1100),
              child: ListView(
                padding: EdgeInsets.all(wide ? AppSpacing.lg : AppSpacing.md),
                children: [
                  if (ctrl.storageError != null) ...[
                    InlineMessage(
                      message: '${l.storageError}\n${ctrl.storageError}',
                      isError: true, icon: Icons.error_outline,
                    ),
                    const SizedBox(height: 16),
                  ],
                  if (ctrl.audioError != null) ...[
                    InlineMessage(
                      message: '${l.audioUnavailable}\n${ctrl.audioError}',
                      isError: true,
                      icon: Icons.portable_wifi_off,
                      action: IconButton(
                        tooltip: l.retry,
                        onPressed: ctrl.refresh,
                        icon: const Icon(Icons.refresh),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                  if (!ctrl.ready || (ctrl.snapshot == null && ctrl.refreshing))
                    const Center(child: Padding(
                      padding: EdgeInsets.all(32), child: CircularProgressIndicator(),
                    ))
                  else
                    pages[selected],
                ],
              ),
            ),
          ))),
        ]),
      );
    });
  }
}

class _BrandMark extends StatelessWidget {
  const _BrandMark();

  @override
  Widget build(BuildContext context) => SvgPicture.asset(
        'assets/icons/sound-labels.svg',
        width: 34,
        height: 34,
        semanticsLabel: 'Sound Labels',
      );
}

class _Sidebar extends StatelessWidget {
  const _Sidebar({
    required this.destinations,
    required this.selected,
    required this.onSelect,
  });
  final List<(String, IconData)> destinations;
  final int selected;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      color: scheme.surfaceContainerLow,
      padding: const EdgeInsets.fromLTRB(12, 24, 12, 12),
      child: Column(children: [
        for (var i = 0; i < destinations.length; i++) ...[
          Semantics(
            selected: selected == i,
            button: true,
            child: Material(
              color: selected == i ? scheme.primaryContainer : Colors.transparent,
              borderRadius: BorderRadius.circular(10),
              child: InkWell(
                borderRadius: BorderRadius.circular(10),
                onTap: () => onSelect(i),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 14),
                  child: Row(children: [
                    Icon(destinations[i].$2, color: selected == i
                        ? scheme.onPrimaryContainer : scheme.onSurfaceVariant),
                    const SizedBox(width: 12),
                    Expanded(child: Text(destinations[i].$1,
                      style: TextStyle(
                        fontWeight: selected == i ? FontWeight.w700 : FontWeight.w500,
                        color: selected == i ? scheme.onPrimaryContainer : scheme.onSurface,
                      ),
                    )),
                  ]),
                ),
              ),
            ),
          ),
          const SizedBox(height: 6),
        ],
      ]),
    );
  }
}
