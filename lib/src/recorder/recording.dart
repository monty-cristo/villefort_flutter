import 'dart:convert';
import 'dart:io';

class MachineRecording<S extends Object, E extends Object> {
  final S initial;

  final List<(E, S)> transitions;

  const MachineRecording({required this.initial, required this.transitions});

  int get length => transitions.length;

  S stateAt(int step) => switch (step == 0) {
    true => initial,
    false => transitions[step - 1].$2,
  };

  Map<String, dynamic> toJson({
    required Object? Function(S state) encodeState,
    required Object? Function(E event) encodeEvent,
  }) {
    return {
      'initial': encodeState(initial),
      'transitions': [
        for (final (event, state) in transitions)
          {'event': encodeEvent(event), 'state': encodeState(state)},
      ],
    };
  }

  factory MachineRecording.fromJson(
    Map<String, dynamic> json, {
    required S Function(Object? state) decodeState,
    required E Function(Object? event) decodeEvent,
  }) {
    return MachineRecording(
      initial: decodeState(json['initial']),
      transitions: [
        for (final t in json['transitions'] as List)
          (decodeEvent((t as Map)['event']), decodeState(t['state'])),
      ],
    );
  }

  Future<void> save(
    String path, {
    required Object? Function(S state) encodeState,
    required Object? Function(E event) encodeEvent,
  }) async {
    final json = toJson(encodeState: encodeState, encodeEvent: encodeEvent);
    await File(
      path,
    ).writeAsString(const JsonEncoder.withIndent('  ').convert(json));
  }

  static Future<MachineRecording<S, E>>
  load<S extends Object, E extends Object>(
    String path, {
    required S Function(Object?) decodeState,
    required E Function(Object?) decodeEvent,
  }) async {
    final content = await File(path).readAsString();
    final json = jsonDecode(content) as Map<String, dynamic>;
    return MachineRecording.fromJson(
      json,
      decodeState: decodeState,
      decodeEvent: decodeEvent,
    );
  }
}
