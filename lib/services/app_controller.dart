import 'dart:async';

import 'package:flutter/material.dart';

import '../domain/audio_models.dart';
import 'audio_backend.dart';
import 'desktop_integration.dart';
import 'preferences_store.dart';
import 'wireplumber_rules.dart';

class AppController extends ChangeNotifier with WidgetsBindingObserver {
  AppController({
    AudioBackend? backend,
    PreferencesStore? store,
    DesktopAppearance? appearance,
    DesktopIntegration? desktop,
    WirePlumberRules? rules,
  })  : backend = backend ?? const PipeWirePulseBackend(),
        store = store ?? PreferencesStore(),
        appearance = appearance ?? DesktopAppearance(),
        desktop = desktop ?? DesktopIntegration(),
        rules = rules ?? WirePlumberRules();

  final AudioBackend backend;
  final PreferencesStore store;
  final DesktopAppearance appearance;
  final DesktopIntegration desktop;
  final WirePlumberRules rules;

  AppData data = const AppData();
  AudioSnapshot? snapshot;
  Color accent = DesktopAppearance.fallback;
  String? audioError;
  String? storageError;
  bool ready = false;
  bool busy = false;
  bool refreshing = false;
  Timer? _timer;
  bool _disposed = false;

  UserSettings get settings => data.settings;

  Future<void> initialize() async {
    WidgetsBinding.instance.addObserver(this);
    try {
      data = await store.load();
    } catch (error) {
      storageError = '$error';
      // Do not overwrite corrupt stored data. Saving is blocked until the user
      // recovers their file; discovery remains available read-only.
    }
    ready = true;
    _emit();
    await refresh();
    await updateAccent();
    _timer = Timer.periodic(const Duration(seconds: 3), (_) {
      if (settings.liveSync) refresh();
      updateAccent();
    });
  }

  Future<void> updateAccent() async {
    final value = await appearance.readAccent();
    if (value != accent) {
      accent = value;
      _emit();
    }
  }

  Future<void> refresh() async {
    if (refreshing || busy) return;
    refreshing = true;
    final previous = snapshot;
    try {
      final next = await backend.discover();
      snapshot = next;
      audioError = null;
      if (previous != null && settings.notifications) {
        if (previous.defaultSinkName != next.defaultSinkName) {
          final endpoint = next.endpointForName(next.defaultSinkName);
          if (endpoint != null) {
            await desktop.notifyDeviceChanged(displayName(endpoint));
          }
        }
      }
    } catch (error) {
      audioError = '$error';
    } finally {
      refreshing = false;
      _emit();
    }
  }

  String displayName(AudioEndpoint endpoint) {
    final alias = data.overrides[endpoint.key]?.alias;
    return alias != null && alias.isNotEmpty ? alias : endpoint.description;
  }

  DeviceSymbol displaySymbol(AudioEndpoint endpoint) {
    final selected = data.overrides[endpoint.key]?.symbol;
    return selected == null || selected == DeviceSymbol.automatic
        ? suggestedSymbol(endpoint)
        : selected;
  }

  Future<void> _save(AppData next) async {
    if (storageError != null) {
      throw StateError('Saved preferences need recovery: $storageError');
    }
    await store.save(next);
    data = next;
    _emit();
  }

  Future<void> setOverride(
    AudioEndpoint endpoint,
    String? alias,
    DeviceSymbol symbol,
    {bool systemWide = false}
  ) async {
    final trimmed = alias?.trim();
    if (trimmed != null && trimmed.length > 80) {
      throw const FormatException('Device name exceeds 80 characters');
    }
    if (trimmed != null && RegExp(r'[\x00-\x1f\x7f]').hasMatch(trimmed)) {
      throw const FormatException('Device name contains a control character');
    }
    final overrides = Map<String, DeviceOverride>.of(data.overrides);
    final value = DeviceOverride(
      alias: trimmed == null || trimmed.isEmpty ? null : trimmed,
      symbol: symbol,
      systemWide: systemWide && trimmed != null && trimmed.isNotEmpty,
    );
    if (value.isEmpty) {
      overrides.remove(endpoint.key);
    } else {
      overrides[endpoint.key] = value;
    }
    // Synchronize the isolated WirePlumber fragment when system-wide renames
    // have been opted into. No automatic service restart or native-UI claim.
    final oldOverrides = data.overrides;
    final hostChanged = oldOverrides.values.any((item) => item.systemWide) ||
        value.systemWide;
    if (hostChanged) await rules.replace(overrides);
    try {
      await _save(data.copyWith(overrides: overrides, clearActiveProfile: true));
    } catch (_) {
      if (hostChanged) {
        try {
          await rules.replace(oldOverrides);
        } catch (_) {
          // The original exception is retained. The .bak is recoverable.
        }
      }
      rethrow;
    }
  }

  Future<void> changeDefault(AudioEndpoint endpoint) async {
    if (busy) throw StateError('Another audio operation is running');
    busy = true;
    _emit();
    try {
      await backend.setDefault(endpoint);
      if (storageError == null) {
        await _save(data.copyWith(clearActiveProfile: true));
      }
    } finally {
      busy = false;
      _emit();
      await refresh();
    }
  }

  Future<void> moveStream(AudioStream stream, AudioEndpoint output) async {
    if (busy) throw StateError('Another audio operation is running');
    busy = true;
    _emit();
    try {
      await backend.moveStream(stream, output);
      // Direct routing is intentionally session-only: do not promise restart
      // persistence without a validated WirePlumber policy integration.
      if (storageError == null) {
        await _save(data.copyWith(clearActiveProfile: true));
      }
    } finally {
      busy = false;
      _emit();
      await refresh();
    }
  }

  SavedProfile captureProfile(String name, {
    String? outputKey,
    String? inputKey,
    Map<String, String> applicationRoutes = const {},
  }) {
    final current = snapshot;
    if (current == null) throw StateError('Audio devices are not available');
    final normalized = name.trim();
    if (normalized.isEmpty || normalized.length > 60) {
      throw const FormatException('Profile name must contain 1–60 characters');
    }
    return SavedProfile(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      name: normalized,
      outputKey: outputKey ?? current.endpointForName(current.defaultSinkName)?.key,
      inputKey: inputKey ?? current.endpointForName(current.defaultSourceName)?.key,
      overrides: Map.of(data.overrides),
      applicationRoutes: Map.of(applicationRoutes),
    );
  }

  Future<void> addProfile(SavedProfile profile) async {
    if (data.profiles.any((p) => p.id == profile.id)) {
      throw const FormatException('Duplicate profile identifier');
    }
    await _save(data.copyWith(profiles: [...data.profiles, profile]));
  }

  Future<void> updateProfile(SavedProfile profile) async {
    if (!data.profiles.any((entry) => entry.id == profile.id)) {
      throw StateError('Profile no longer exists');
    }
    await _save(data.copyWith(profiles: [
      for (final entry in data.profiles)
        entry.id == profile.id ? profile : entry,
    ]));
  }

  Future<void> renameProfile(SavedProfile profile, String name) async {
    final normalized = name.trim();
    if (normalized.isEmpty || normalized.length > 60) {
      throw const FormatException('Profile name must contain 1–60 characters');
    }
    final profiles = [
      for (final entry in data.profiles)
        entry.id == profile.id ? entry.copyWith(name: normalized) : entry,
    ];
    await _save(data.copyWith(profiles: profiles));
  }

  Future<void> duplicateProfile(SavedProfile profile) => addProfile(
        profile.copyWith(
          id: DateTime.now().microsecondsSinceEpoch.toString(),
          name: '${profile.name} (copy)',
        ),
      );

  Future<void> deleteProfile(SavedProfile profile) => _save(data.copyWith(
        profiles: data.profiles.where((p) => p.id != profile.id).toList(),
        clearActiveProfile: data.activeProfileId == profile.id,
      ));

  /// Validate the full target set before touching the audio server. Roll back
  /// defaults and moved streams if a later step fails; display the original
  /// error and any rollback failures to the caller.
  Future<void> activateProfile(SavedProfile profile) async {
    final current = snapshot;
    if (current == null) throw StateError('Audio devices are not available');
    final output = profile.outputKey == null
        ? null
        : current.endpointForKey(profile.outputKey);
    final input = profile.inputKey == null
        ? null
        : current.endpointForKey(profile.inputKey);
    if (profile.outputKey != null && (output == null || !output.available)) {
      throw StateError('Saved output is disconnected or missing');
    }
    if (profile.inputKey != null && (input == null || !input.available)) {
      throw StateError('Saved input is disconnected or missing');
    }
    final desiredMoves = <(AudioStream, AudioEndpoint)>[];
    for (final stream in current.streams) {
      final destinationKey = profile.applicationRoutes[stream.applicationId];
      if (destinationKey == null) continue;
      final destination = current.endpointForKey(destinationKey);
      if (destination == null || !destination.isOutput || !destination.available) {
        throw StateError('Saved application output is missing');
      }
      desiredMoves.add((stream, destination));
    }
    if (busy) throw StateError('Another audio operation is running');
    busy = true;
    _emit();
    final originalOutput = current.endpointForName(current.defaultSinkName);
    final originalInput = current.endpointForName(current.defaultSourceName);
    final completedMoves = <(AudioStream, AudioEndpoint)>[];
    var outputChanged = false;
    var inputChanged = false;
    var hostRulesChanged = false;
    try {
      if (output != null && output.name != current.defaultSinkName) {
        await backend.setDefault(output);
        outputChanged = true;
      }
      if (input != null && input.name != current.defaultSourceName) {
        await backend.setDefault(input);
        inputChanged = true;
      }
      for (final (stream, destination) in desiredMoves) {
        final previous = current.outputForIndex(stream.sinkIndex);
        if (previous == null) continue;
        if (previous.key != destination.key) {
          await backend.moveStream(stream, destination);
          completedMoves.add((stream, previous));
        }
      }
      hostRulesChanged = data.overrides.values.any((o) => o.systemWide) ||
          profile.overrides.values.any((o) => o.systemWide);
      if (hostRulesChanged) await rules.replace(profile.overrides);
      await _save(data.copyWith(
        overrides: Map.of(profile.overrides),
        activeProfileId: profile.id,
      ));
    } catch (error) {
      final failures = <String>[];
      if (hostRulesChanged) {
        try {
          await rules.replace(data.overrides);
        } catch (rollbackError) {
          failures.add('$rollbackError');
        }
      }
      for (final (stream, previous) in completedMoves.reversed) {
        try {
          await backend.moveStream(stream, previous);
        } catch (rollbackError) {
          failures.add('$rollbackError');
        }
      }
      if (inputChanged && originalInput != null) {
        try {
          await backend.setDefault(originalInput);
        } catch (rollbackError) {
          failures.add('$rollbackError');
        }
      }
      if (outputChanged && originalOutput != null) {
        try {
          await backend.setDefault(originalOutput);
        } catch (rollbackError) {
          failures.add('$rollbackError');
        }
      }
      throw StateError('$error${failures.isEmpty ? '' : '; rollback: ${failures.join('; ')}'}');
    } finally {
      busy = false;
      _emit();
      await refresh();
    }
  }

  Future<void> updateSettings(UserSettings value) async {
    final autostartChanged = settings.autostart != value.autostart;
    if (autostartChanged) await desktop.setAutostart(value.autostart);
    try {
      await _save(data.copyWith(settings: value));
    } catch (_) {
      if (autostartChanged) {
        try {
          await desktop.setAutostart(settings.autostart);
        } catch (_) {
          // Files can be restored from the user's config directory.
        }
      }
      rethrow;
    }
    if (value.liveSync) await refresh();
  }

  Future<void> persistCurrentSettings() => _save(data);

  void _emit() {
    if (!_disposed) notifyListeners();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      refresh();
      updateAccent();
    }
  }

  @override
  void dispose() {
    _disposed = true;
    _timer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }
}
