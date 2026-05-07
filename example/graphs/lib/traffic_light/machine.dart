import 'package:villefort/villefort.dart';

sealed class TrafficState {
  const TrafficState();

  @override
  bool operator ==(Object other) => switch ((this, other)) {
    (TrafficStateRed(), TrafficStateRed()) => true,
    (TrafficStateGreen(), TrafficStateGreen()) => true,
    (TrafficStateYellow(), TrafficStateYellow()) => true,
    _ => false,
  };

  @override
  int get hashCode => switch (this) {
    TrafficStateRed() => 1,
    TrafficStateGreen() => 2,
    TrafficStateYellow() => 3,
  };
}

final class TrafficStateRed extends TrafficState {
  const TrafficStateRed();
}

final class TrafficStateGreen extends TrafficState {
  const TrafficStateGreen();
}

final class TrafficStateYellow extends TrafficState {
  const TrafficStateYellow();
}

sealed class TrafficEvent {
  const TrafficEvent();
}

final class TrafficEventNext extends TrafficEvent {
  const TrafficEventNext();
}

Option<TrafficState> trafficTransition(TrafficState state, TrafficEvent event) =>
    switch ((state, event)) {
      (TrafficStateRed(), TrafficEventNext()) => const Some(TrafficStateGreen()),
      (TrafficStateGreen(), TrafficEventNext()) => const Some(TrafficStateYellow()),
      (TrafficStateYellow(), TrafficEventNext()) => const Some(TrafficStateRed()),
    };
