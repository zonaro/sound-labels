import 'dart:io';

import '../domain/audio_models.dart';

class PreferencesStore {
  PreferencesStore({String? baseDirectory})
      : baseDirectory = baseDirectory ?? _xdgConfigDirectory();

  final String baseDirectory;

  static String _xdgConfigDirectory() {
    final environment = Platform.environment;
    final xdg = environment['XDG_CONFIG_HOME'];
    if (xdg != null && xdg.startsWith('/')) return xdg;
    final home = environment['HOME'];
    if (home == null || !home.startsWith('/')) {
      throw const FileSystemException('HOME or XDG_CONFIG_HOME is required');
    }
    return '$home/.config';
  }

  File get _file => File('$baseDirectory/sound-labels/state.json');

  Future<AppData> load() async {
    if (!await _file.exists()) return const AppData();
    // Corrupted state is not silently discarded: the user can recover the
    // state.json.bak file without us overwriting their original data.
    return AppData.decode(await _file.readAsString());
  }

  Future<void> save(AppData data) async {
    final file = _file;
    await file.parent.create(recursive: true);
    final temp = File('${file.path}.tmp');
    final backup = File('${file.path}.bak');
    try {
      await temp.writeAsString(data.encode(), flush: true);
      if (await file.exists()) {
        await file.copy(backup.path);
      }
      await temp.rename(file.path);
    } catch (_) {
      if (await temp.exists()) await temp.delete();
      rethrow;
    }
  }
}
