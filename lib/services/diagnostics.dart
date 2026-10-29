import 'dart:convert';

import '../domain/audio_models.dart';

/// Privacy-conscious operational summary for support. Avoid hostnames, device
/// names, MAC addresses, app identities, file paths and user-defined labels.
String diagnosticSummary(AudioSnapshot? snapshot, String? audioError) {
  final data = {
    'application': 'Sound Labels 0.1.0',
    'schema': 1,
    'audioAvailable': snapshot != null && audioError == null,
    'outputCount': snapshot?.outputs.length ?? 0,
    'inputCount': snapshot?.inputs.length ?? 0,
    'activeStreamCount': snapshot?.streams.length ?? 0,
    'defaultOutputPresent': snapshot != null &&
        snapshot.endpointForName(snapshot.defaultSinkName) != null,
    'defaultInputPresent': snapshot != null &&
        snapshot.endpointForName(snapshot.defaultSourceName) != null,
    'endpointTypes': [
      for (final endpoint in snapshot?.endpoints ?? <AudioEndpoint>[])
        {
          'direction': endpoint.direction.name,
          'available': endpoint.available,
          'hasPort': endpoint.activePort != null,
          'hasDeviceMetadata': endpoint.properties.isNotEmpty,
        },
    ],
    'audioErrorPresent': audioError != null,
  };
  return const JsonEncoder.withIndent('  ').convert(data);
}
