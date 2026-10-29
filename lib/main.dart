import 'package:flutter/material.dart';
import 'l10n/app_localizations.dart';
import 'services/app_controller.dart';
import 'ui/app_shell.dart';
import 'ui/app_theme.dart';
import 'ui/quick_switcher.dart';

void main(List<String> args) {
  WidgetsFlutterBinding.ensureInitialized();
  final controller = AppController();
  runApp(SoundLabelsApp(controller: controller, quick: args.contains('--quick')));
  controller.initialize();
}

class SoundLabelsApp extends StatefulWidget {
  const SoundLabelsApp({super.key, required this.controller, required this.quick});
  final AppController controller;
  final bool quick;

  @override
  State<SoundLabelsApp> createState() => _SoundLabelsAppState();
}

class _SoundLabelsAppState extends State<SoundLabelsApp> {
  @override
  void dispose() {
    widget.controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
        animation: widget.controller,
        builder: (context, _) {
          final settings = widget.controller.settings;
          final themeMode = switch (settings.theme) {
            'light' => ThemeMode.light,
            'dark' => ThemeMode.dark,
            _ => ThemeMode.system,
          };
          final locale = switch (settings.language) {
            'pt' => const Locale('pt', 'BR'),
            'es' => const Locale('es'),
            'en' => const Locale('en'),
            _ => null,
          };
          return MaterialApp(
            title: 'Sound Labels',
            debugShowCheckedModeBanner: false,
            locale: locale,
            localeResolutionCallback: (device, supported) {
              if (locale != null) return locale;
              if (device != null) {
                for (final supportedLocale in supported) {
                  if (supportedLocale.languageCode == device.languageCode) {
                    return supportedLocale;
                  }
                }
              }
              return const Locale('en');
            },
            supportedLocales: AppLocalizations.supportedLocales,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            theme: AppTheme.build(widget.controller.accent, Brightness.light),
            darkTheme: AppTheme.build(widget.controller.accent, Brightness.dark),
            themeMode: themeMode,
            home: widget.quick
                ? QuickSwitcher(controller: widget.controller)
                : AppShell(controller: widget.controller),
          );
        },
      );
}
