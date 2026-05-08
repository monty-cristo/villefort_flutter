import 'package:villefort/villefort.dart';

import 'recording.dart';

class MachineRecorder<S extends Object, E extends Object> {
  final S _initial;

  final TransitionFunction<S, E> _inner;
  final List<(E, S)> _transitions = [];

  MachineRecorder({
    required S initial,
    required TransitionFunction<S, E> transition,
  }) : _initial = initial,
       _inner = transition;

  /// Pass this as the `transition:` argument to [MachineViewer].
  Option<S> call(S state, E event) {
    final result = _inner(state, event);

    if (result case Some(value: final next)) {
      _transitions.add((event, next));
    }

    return result;
  }

  /// Stops recording and returns the captured session.
  MachineRecording<S, E> stop() => MachineRecording(
    initial: _initial,
    transitions: List.unmodifiable(_transitions),
  );
}

class RotatingMachineRecorder<S extends Object, E extends Object> {
  final int limit;

  final TransitionFunction<S, E> _inner;
  final List<(E, S)> _transitions = [];

  S _windowInitial;

  RotatingMachineRecorder({
    required S initial,
    required TransitionFunction<S, E> transition,
    required this.limit,
  }) : _windowInitial = initial,
       _inner = transition;

  /// Pass this as the `transition:` argument to [MachineViewer].
  Option<S> call(S state, E event) {
    final result = _inner(state, event);

    if (result case Some(value: final next)) {
      _transitions.add((event, next));

      if (_transitions.length > limit) {
        _windowInitial = _transitions.removeAt(0).$2;
      }
    }

    return result;
  }

  /// Returns a snapshot of the current recording window.
  MachineRecording<S, E> stop() => MachineRecording(
    initial: _windowInitial,
    transitions: List.unmodifiable(_transitions),
  );
}
