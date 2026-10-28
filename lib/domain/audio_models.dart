import 'dart:convert';

enum AudioDirection { output, input }

class AudioEndpoint {
  const AudioEndpoint({
    required this.key,
    required this.name,
    required this.index,
    required this.direction,
    required this.description,
    this.activePort,
    this.card,
    this.available = true,
    this.properties = const {},
  });

  /// Stable PipeWire/Pulse name, never the transient numeric `index`.
  final String key;
  final String name;
  final int index;
  final AudioDirection direction;
  final String description;
  final String? activePort;
  final String? card;
  final bool available;
  final Map<String, String> properties;

  bool get isOutput => direction == AudioDirection.output;
  String get details => [
        if (activePort != null && activePort!.isNotEmpty) activePort!,
        if (card != null && card!.isNotEmpty) card!,
      ].join(' · ');
}

class AudioStream {
  const AudioStream({
    required this.index,
    required this.name,
    required this.applicationId,
    required this.sinkIndex,
    this.properties = const {},
  });

  /// Ephemeral IDs are valid only for an active stream move operation.
  final int index;
  final String name;
  final String applicationId;
  final int sinkIndex;
  final Map<String, String> properties;
}

class AudioSnapshot {
  const AudioSnapshot({
    required this.endpoints,
    required this.streams,
    this.defaultSinkName,
    this.defaultSourceName,
  });

  final List<AudioEndpoint> endpoints;
  final List<AudioStream> streams;
  final String? defaultSinkName;
  final String? defaultSourceName;

  Iterable<AudioEndpoint> get outputs =>
      endpoints.where((e) => e.direction == AudioDirection.output);
  Iterable<AudioEndpoint> get inputs =>
      endpoints.where((e) => e.direction == AudioDirection.input);
  AudioEndpoint? endpointForKey(String? key) {
    for (final endpoint in endpoints) {
      if (endpoint.key == key) return endpoint;
    }
    return null;
  }

  AudioEndpoint? endpointForName(String? name) {
    for (final endpoint in endpoints) {
      if (endpoint.name == name) return endpoint;
    }
    return null;
  }

  AudioEndpoint? outputForIndex(int index) {
    for (final endpoint in outputs) {
      if (endpoint.index == index) return endpoint;
    }
    return null;
  }

  bool isDefault(AudioEndpoint endpoint) =>
      endpoint.name ==
      (endpoint.isOutput ? defaultSinkName : defaultSourceName);
}

enum DeviceSymbol {
  automatic,
  tv,
  monitor,
  speakers,
  headphones,
  headset,
  microphone,
  bluetooth,
  usb,
  generic,
}

DeviceSymbol suggestedSymbol(AudioEndpoint endpoint) {
  final value = '${endpoint.name} ${endpoint.description} '
          '${endpoint.activePort ?? ''} ${endpoint.properties.values.join(' ')}'
      .toLowerCase();
  if (value.contains('bluetooth') || value.contains('bluez')) {
    return DeviceSymbol.bluetooth;
  }
  if (value.contains('headset')) return DeviceSymbol.headset;
  if (value.contains('headphone') || value.contains('fone')) {
    return DeviceSymbol.headphones;
  }
  if (value.contains('microphone') || value.contains('mic')) {
    return DeviceSymbol.microphone;
  }
  if (value.contains('tv') || value.contains('television')) {
    return DeviceSymbol.tv;
  }
  if (value.contains('hdmi') || value.contains('displayport') ||
      value.contains('monitor')) {
    return DeviceSymbol.monitor;
  }
  if (value.contains('usb')) return DeviceSymbol.usb;
  if (value.contains('speaker') || value.contains('analog')) {
    return DeviceSymbol.speakers;
  }
  if (endpoint.direction == AudioDirection.input) {
    return DeviceSymbol.microphone;
  }
  return DeviceSymbol.generic;
}

class DeviceOverride {
  const DeviceOverride({
    this.alias,
    this.symbol = DeviceSymbol.automatic,
    this.systemWide = false,
  });
  final String? alias;
  final DeviceSymbol symbol;
  final bool systemWide;

  bool get isEmpty =>
      (alias == null || alias!.isEmpty) && symbol == DeviceSymbol.automatic;

  Map<String, Object?> toJson() => {
        'alias': alias,
        'symbol': symbol.name,
        'systemWide': systemWide,
      };

  factory DeviceOverride.fromJson(Map<String, dynamic> json) => DeviceOverride(
        alias: json['alias'] is String ? json['alias'] as String : null,
        symbol: DeviceSymbol.values.firstWhere(
          (value) => value.name == json['symbol'],
          orElse: () => DeviceSymbol.automatic,
        ),
        systemWide: json['systemWide'] == true,
      );
}

class SavedProfile {
  const SavedProfile({
    required this.id,
    required this.name,
    required this.outputKey,
    required this.inputKey,
    this.overrides = const {},
    this.applicationRoutes = const {},
  });

  final String id;
  final String name;
  final String? outputKey;
  final String? inputKey;
  final Map<String, DeviceOverride> overrides;
  /// App IDs -> stable output keys. Applied to *currently active* streams only.
  final Map<String, String> applicationRoutes;

  SavedProfile copyWith({String? id, String? name}) => SavedProfile(
        id: id ?? this.id,
        name: name ?? this.name,
        outputKey: outputKey,
        inputKey: inputKey,
        overrides: Map.of(overrides),
        applicationRoutes: Map.of(applicationRoutes),
      );

  Map<String, Object?> toJson() => {
        'id': id,
        'name': name,
        'outputKey': outputKey,
        'inputKey': inputKey,
        'overrides': overrides.map((key, value) => MapEntry(key, value.toJson())),
        'applicationRoutes': applicationRoutes,
      };

  factory SavedProfile.fromJson(Map<String, dynamic> json) => SavedProfile(
        id: json['id'] as String,
        name: json['name'] as String,
        outputKey: json['outputKey'] as String?,
        inputKey: json['inputKey'] as String?,
        overrides: _overridesFromJson(json['overrides']),
        applicationRoutes: (json['applicationRoutes'] is Map)
            ? (json['applicationRoutes'] as Map).map(
                (key, value) => MapEntry(key.toString(), value.toString()),
              )
            : {},
      );
}

Map<String, DeviceOverride> _overridesFromJson(Object? source) {
  if (source is! Map) return {};
  return source.map((key, value) => MapEntry(
        key.toString(),
        DeviceOverride.fromJson(Map<String, dynamic>.from(value as Map)),
      ));
}

class UserSettings {
  const UserSettings({
    this.theme = 'system',
    this.language = 'system',
    this.liveSync = true,
    this.notifications = false,
    this.autostart = false,
  });

  final String theme;
  final String language;
  final bool liveSync;
  final bool notifications;
  final bool autostart;

  UserSettings copyWith({
    String? theme,
    String? language,
    bool? liveSync,
    bool? notifications,
    bool? autostart,
  }) => UserSettings(
        theme: theme ?? this.theme,
        language: language ?? this.language,
        liveSync: liveSync ?? this.liveSync,
        notifications: notifications ?? this.notifications,
        autostart: autostart ?? this.autostart,
      );

  Map<String, Object?> toJson() => {
        'theme': theme,
        'language': language,
        'liveSync': liveSync,
        'notifications': notifications,
        'autostart': autostart,
      };

  factory UserSettings.fromJson(Map<String, dynamic> json) => UserSettings(
        theme: ['system', 'light', 'dark'].contains(json['theme'])
            ? json['theme'] as String
            : 'system',
        language: ['system', 'pt', 'en', 'es'].contains(json['language'])
            ? json['language'] as String
            : 'system',
        liveSync: json['liveSync'] is bool ? json['liveSync'] as bool : true,
        notifications:
            json['notifications'] is bool ? json['notifications'] as bool : false,
        autostart: json['autostart'] is bool ? json['autostart'] as bool : false,
      );
}

class AppData {
  const AppData({
    this.settings = const UserSettings(),
    this.overrides = const {},
    this.profiles = const [],
    this.activeProfileId,
  });

  final UserSettings settings;
  final Map<String, DeviceOverride> overrides;
  final List<SavedProfile> profiles;
  final String? activeProfileId;

  AppData copyWith({
    UserSettings? settings,
    Map<String, DeviceOverride>? overrides,
    List<SavedProfile>? profiles,
    String? activeProfileId,
    bool clearActiveProfile = false,
  }) => AppData(
        settings: settings ?? this.settings,
        overrides: overrides ?? this.overrides,
        profiles: profiles ?? this.profiles,
        activeProfileId: clearActiveProfile ? null : activeProfileId ?? this.activeProfileId,
      );

  String encode() => const JsonEncoder.withIndent('  ').convert({
        'schema': 1,
        'settings': settings.toJson(),
        'overrides': overrides.map((key, value) => MapEntry(key, value.toJson())),
        'profiles': profiles.map((value) => value.toJson()).toList(),
        'activeProfileId': activeProfileId,
      });

  factory AppData.decode(String raw) {
    final json = jsonDecode(raw) as Map<String, dynamic>;
    if (json['schema'] != 1) {
      throw const FormatException('Unsupported settings schema');
    }
    return AppData(
      settings: UserSettings.fromJson(
        Map<String, dynamic>.from(json['settings'] as Map? ?? {}),
      ),
      overrides: _overridesFromJson(json['overrides']),
      profiles: (json['profiles'] as List? ?? [])
          .map((item) => SavedProfile.fromJson(Map<String, dynamic>.from(item as Map)))
          .toList(),
      activeProfileId: json['activeProfileId'] as String?,
    );
  }
}
