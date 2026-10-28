import 'dart:io';

import 'package:flutter/material.dart';

/// Best-effort system accent detection. Unknown implementations fall back to
/// the purple brand accent; polling is controlled by the app lifecycle.
class DesktopAppearance {
  static const fallback = Color(0xFF6851DD);

  Future<Color> readAccent() async {
    final portal = await _execute('gdbus', [
      'call',
      '--session',
      '--dest', 'org.freedesktop.portal.Desktop',
      '--object-path', '/org/freedesktop/portal/desktop',
      '--method', 'org.freedesktop.portal.Settings.Read',
      'org.freedesktop.appearance', 'accent-color',
    ]);
    // Portal accent-color is a normalized RGB triple: (double, double, double).
    if (portal != null) {
      final matches = RegExp(r'([01](?:\.\d+)?)').allMatches(portal).toList();
      if (matches.length >= 3) {
        final rgb = matches.skip(matches.length - 3).map((m) =>
            double.tryParse(m.group(1) ?? '')).toList();
        if (rgb.every((n) => n != null && n >= 0 && n <= 1)) {
          return Color.fromARGB(
            255,
            (rgb[0]! * 255).round(),
            (rgb[1]! * 255).round(),
            (rgb[2]! * 255).round(),
          );
        }
      }
    }

    final kde = await _execute('kreadconfig6', [
      '--file', 'kdeglobals', '--group', 'General', '--key', 'AccentColor',
    ]) ?? await _execute('kreadconfig5', [
      '--file', 'kdeglobals', '--group', 'General', '--key', 'AccentColor',
    ]);
    if (kde != null) {
      final parts = kde.trim().split(',');
      if (parts.length == 3) {
        final rgb = parts.map((s) => int.tryParse(s.trim())).toList();
        if (rgb.every((n) => n != null && n >= 0 && n <= 255)) {
          return Color.fromARGB(255, rgb[0]!, rgb[1]!, rgb[2]!);
        }
      }
      final hex = RegExp(r'#([0-9a-fA-F]{6})').firstMatch(kde);
      if (hex != null) return Color(int.parse('ff${hex.group(1)}', radix: 16));
    }

    final gnome = await _execute('gsettings', [
      'get', 'org.gnome.desktop.interface', 'accent-color',
    ]);
    const colors = {
      'blue': Color(0xFF3584E4),
      'teal': Color(0xFF2190A4),
      'green': Color(0xFF2D9B50),
      'yellow': Color(0xFFE5A50A),
      'orange': Color(0xFFED7725),
      'red': Color(0xFFE64646),
      'pink': Color(0xFFD56199),
      'purple': Color(0xFF9141AC),
      'slate': Color(0xFF6F8396),
    };
    return colors[gnome?.replaceAll("'", '').trim()] ?? fallback;
  }

  static Future<String?> _execute(String command, List<String> args) async {
    try {
      final result = await Process.run(command, args);
      return result.exitCode == 0 ? result.stdout.toString().trim() : null;
    } on ProcessException {
      return null;
    }
  }
}

class DesktopIntegration {
  static String get _configDirectory {
    final xdg = Platform.environment['XDG_CONFIG_HOME'];
    if (xdg != null && xdg.startsWith('/')) return xdg;
    final home = Platform.environment['HOME'];
    if (home == null || !home.startsWith('/')) {
      throw const FileSystemException('HOME is missing');
    }
    return '$home/.config';
  }

  static File get _autostartFile =>
      File('$_configDirectory/autostart/sound-labels.desktop');

  Future<void> setAutostart(bool enabled) async {
    final file = _autostartFile;
    if (!enabled) {
      if (await file.exists()) await file.delete();
      return;
    }
    final executable = Platform.resolvedExecutable;
    final escaped = executable.replaceAll('\\', '\\\\').replaceAll('"', '\\"');
    await file.parent.create(recursive: true);
    final temp = File('${file.path}.tmp');
    await temp.writeAsString('''[Desktop Entry]
Type=Application
Name=Sound Labels
Comment=Audio devices and routes
Exec="$escaped"
Terminal=false
Categories=AudioVideo;Audio;Settings;
X-GNOME-Autostart-enabled=true
''', flush: true);
    await temp.rename(file.path);
  }

  Future<void> notifyDeviceChanged(String name) async {
    try {
      await Process.run('notify-send', ['Sound Labels', name]);
    } on ProcessException {
      // Notifications are optional; never fail an otherwise successful switch.
    }
  }
}
