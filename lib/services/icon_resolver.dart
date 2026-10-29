import 'dart:io';

import '../domain/audio_models.dart';

/// Resolves a freedesktop application icon without launching external tools or
/// trusting arbitrary paths supplied by an audio stream's metadata.
class AppIconResolver {
  const AppIconResolver();

  Future<File?> find(AudioStream stream) async {
    final properties = stream.properties;
    final candidates = <String>{
      if (properties['application.icon_name'] != null)
        properties['application.icon_name']!,
      stream.applicationId,
      if (properties['application.process.binary'] != null)
        properties['application.process.binary']!,
    };
    final environment = Platform.environment;
    final home = environment['HOME'];
    final dataHome = environment['XDG_DATA_HOME'] ??
        (home != null ? '$home/.local/share' : null);
    final dirs = <String>[
      if (dataHome != null) '$dataHome/icons',
      '/usr/share/icons/hicolor',
      '/usr/share/icons/Adwaita',
      '/usr/share/icons/breeze',
      '/usr/share/pixmaps',
    ];
    final prefixes = [
      '', 'scalable/apps', '128x128/apps', '64x64/apps',
      '48x48/apps', '32x32/apps', '256x256/apps',
    ];
    for (final rawName in candidates) {
      final name = rawName.replaceAll(RegExp(r'\.desktop$'), '');
      if (!RegExp(r'^[a-zA-Z0-9_.-]+$').hasMatch(name) ||
          name == '.' || name == '..') {
        continue;
      }
      for (final directory in dirs) {
        for (final prefix in prefixes) {
          for (final ext in ['png', 'svg']) {
            final path = [directory, if (prefix.isNotEmpty) prefix, '$name.$ext']
                .join('/');
            final file = File(path);
            if (await file.exists()) return file;
          }
        }
      }
    }
    return null;
  }
}
