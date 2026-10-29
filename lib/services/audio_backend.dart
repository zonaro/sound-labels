import 'dart:convert';
import 'dart:io';

import '../domain/audio_models.dart';

class AudioBackendException implements Exception {
  const AudioBackendException(this.message);
  final String message;
  @override
  String toString() => message;
}

abstract class AudioBackend {
  Future<AudioSnapshot> discover();
  Future<void> setDefault(AudioEndpoint endpoint);
  Future<void> moveStream(AudioStream stream, AudioEndpoint destination);
}

/// Uses structured pactl JSON, supplied by pipewire-pulse. No shell, root or
/// parsing of translated status tables. Numeric IDs are never persisted.
class PipeWirePulseBackend implements AudioBackend {
  const PipeWirePulseBackend();

  Future<String> _run(List<String> args) async {
    ProcessResult result;
    try {
      result = await Process.run('pactl', args);
    } on ProcessException catch (error) {
      throw AudioBackendException(
        'pactl is not available: ${error.message}. Install pipewire-pulse and pulseaudio-utils.',
      );
    }
    if (result.exitCode != 0) {
      final stderr = result.stderr.toString().trim();
      throw AudioBackendException(
        stderr.isNotEmpty ? stderr : 'pactl exited with ${result.exitCode}',
      );
    }
    return result.stdout.toString().trim();
  }

  Future<List<dynamic>> _list(String type) async {
    final text = await _run(['--format=json', 'list', type]);
    try {
      final value = jsonDecode(text);
      if (value is List) return value;
      throw const FormatException('Expected a JSON array');
    } on FormatException catch (error) {
      throw AudioBackendException('Invalid pactl JSON for $type: $error');
    }
  }

  @override
  Future<AudioSnapshot> discover() async {
    // Sequential requests avoid racing a restarted audio server.
    final sinks = await _list('sinks');
    final sources = await _list('sources');
    final inputs = await _list('sink-inputs');
    final defaultSink = await _run(['get-default-sink']);
    final defaultSource = await _run(['get-default-source']);

    final endpoints = <AudioEndpoint>[
      for (final entry in sinks)
        if (entry is Map) _endpoint(entry, AudioDirection.output),
      for (final entry in sources)
        if (entry is Map && !_isMonitor(entry))
          _endpoint(entry, AudioDirection.input),
    ];
    final streams = <AudioStream>[
      for (final entry in inputs)
        if (entry is Map) _stream(entry),
    ];
    endpoints.sort((a, b) => a.description.compareTo(b.description));
    streams.sort((a, b) => a.name.compareTo(b.name));
    return AudioSnapshot(
      endpoints: endpoints,
      streams: streams,
      defaultSinkName: defaultSink,
      defaultSourceName: defaultSource,
    );
  }

  bool _isMonitor(Map data) {
    final name = data['name']?.toString() ?? '';
    return data['monitor_of_sink'] != null &&
            data['monitor_of_sink'].toString() != '4294967295' ||
        name.endsWith('.monitor');
  }

  AudioEndpoint _endpoint(Map data, AudioDirection direction) {
    final props = _properties(data['properties']);
    final nodeName = (data['name'] ?? '').toString();
    if (nodeName.isEmpty) {
      throw const AudioBackendException('Audio endpoint has no node name');
    }
    final port = data['active_port'];
    final activePort = port is Map
        ? (port['description'] ?? port['name'])?.toString()
        : port?.toString();
    final description = (data['description'] ??
            props['node.description'] ??
            props['device.description'] ??
            nodeName)
        .toString();

    // The PipeWire node.name is stable across sessions for most ALSA/BlueZ
    // nodes. Keep a namespace per direction. Never use the numeric index here.
    final key = '${direction.name}:$nodeName';
    final ports = data['ports'];
    var available = true;
    if (ports is List && port is Map) {
      final portName = port['name'];
      for (final candidate in ports) {
        if (candidate is Map && candidate['name'] == portName) {
          available = candidate['availability']?.toString() != 'no';
          break;
        }
      }
    }
    return AudioEndpoint(
      key: key,
      name: nodeName,
      index: _integer(data['index']),
      direction: direction,
      description: description,
      activePort: activePort,
      card: props['device.product.name'] ?? props['device.nick'],
      available: available,
      properties: props,
    );
  }

  AudioStream _stream(Map data) {
    final props = _properties(data['properties']);
    final name = props['application.name'] ??
        props['media.name'] ??
        'Stream ${data['index']}';
    final appId = props['application.id'] ??
        props['application.process.binary'] ??
        props['application.name'] ??
        'stream:${data['index']}';
    return AudioStream(
      index: _integer(data['index']),
      sinkIndex: _integer(data['sink']),
      name: name,
      applicationId: appId,
      properties: props,
    );
  }

  static int _integer(Object? value) =>
      value is int ? value : int.tryParse(value.toString()) ?? -1;

  static Map<String, String> _properties(Object? source) {
    if (source is! Map) return {};
    return source.map((key, value) => MapEntry(key.toString(), value.toString()));
  }

  @override
  Future<void> setDefault(AudioEndpoint endpoint) async {
    if (!endpoint.available) {
      throw const AudioBackendException('Selected device is unavailable');
    }
    await _run([
      endpoint.isOutput ? 'set-default-sink' : 'set-default-source',
      endpoint.name,
    ]);
  }

  @override
  Future<void> moveStream(
    AudioStream stream,
    AudioEndpoint destination,
  ) async {
    if (!destination.isOutput || !destination.available) {
      throw const AudioBackendException('Invalid destination output');
    }
    await _run(['move-sink-input', '${stream.index}', destination.name]);
  }
}
