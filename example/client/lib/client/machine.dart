import 'package:villefort/villefort.dart';

/* -------------------------------------------------------------------------- */
/*                                   STATES                                   */
/* -------------------------------------------------------------------------- */

sealed class ClientState {
  const ClientState();

  @override
  bool operator ==(Object other) {
    return switch ((this, other)) {
      (
        ClientStateConnecting(
          attempt: final attemptA,
          attempts: final attemptsA,
        ),
        ClientStateConnecting(
          attempt: final attemptB,
          attempts: final attemptsB,
        ),
      ) =>
        (attemptA == attemptB) && (attemptsA == attemptsB),
      (ClientStateConnected(), ClientStateConnected()) => true,
      (ClientStateDisconnecting(), ClientStateDisconnecting()) => true,
      (ClientStateDisconnected(), ClientStateDisconnected()) => true,
      (
        ClientStateReconnecting(
          attempt: final attemptA,
          attempts: final attemptsA,
        ),
        ClientStateReconnecting(
          attempt: final attemptB,
          attempts: final attemptsB,
        ),
      ) =>
        (attemptA == attemptB) && (attemptsA == attemptsB),
      (
        ClientStateError(error: final errorA),
        ClientStateError(error: final errorB),
      ) =>
        errorA == errorB,
      (
        ClientStateWaitingToRetryConnect(
          attempt: final attemptA,
          attempts: final attemptsA,
        ),
        ClientStateWaitingToRetryConnect(
          attempt: final attemptB,
          attempts: final attemptsB,
        ),
      ) =>
        (attemptA == attemptB) && (attemptsA == attemptsB),
      (
        ClientStateWaitingToRetryReconnect(
          attempt: final attemptA,
          attempts: final attemptsA,
        ),
        ClientStateWaitingToRetryReconnect(
          attempt: final attemptB,
          attempts: final attemptsB,
        ),
      ) =>
        (attemptA == attemptB) && (attemptsA == attemptsB),
      (ClientStateIdle(), ClientStateIdle()) => true,
      (ClientStateReconnected(), ClientStateReconnected()) => true,
      _ => false,
    };
  }

  @override
  int get hashCode {
    return switch (this) {
      ClientStateConnecting(:final attempt, :final attempts) => Object.hash(
        1,
        attempt,
        attempts,
      ),
      ClientStateConnected() => 2,
      ClientStateDisconnecting() => 3,
      ClientStateDisconnected() => 4,
      ClientStateReconnecting(:final attempt, :final attempts) => Object.hash(
        5,
        attempt,
        attempts,
      ),
      ClientStateError(:final error) => Object.hash(6, error),
      ClientStateWaitingToRetryConnect(:final attempt, :final attempts) =>
        Object.hash(7, attempt, attempts),
      ClientStateWaitingToRetryReconnect(:final attempt, :final attempts) =>
        Object.hash(8, attempt, attempts),
      ClientStateIdle() => 9,
      ClientStateReconnected() => 10,
    };
  }

  @override
  String toString() {
    return switch (this) {
      ClientStateConnecting(:final attempt, :final attempts) =>
        'Connecting(attempt: $attempt, attemps: $attempts)',
      ClientStateConnected() => 'Connected',
      ClientStateDisconnecting() => 'Disconnecting',
      ClientStateDisconnected() => 'Disconnected',
      ClientStateReconnecting(:final attempt, :final attempts) =>
        'Reconnecting(attempt: $attempt, attemps: $attempts)',
      ClientStateError(:final error) => 'Error($error)',
      ClientStateWaitingToRetryConnect() => 'WaitingToRetryConnect',
      ClientStateWaitingToRetryReconnect() => 'WaitingToRetryReconnect',
      ClientStateIdle() => 'Idle',
      ClientStateReconnected() => 'Reconnected',
    };
  }
}

final class ClientStateIdle extends ClientState {
  const ClientStateIdle();
}

final class ClientStateConnecting extends ClientState {
  final int attempt;
  final int attempts;

  const ClientStateConnecting({required this.attempt, required this.attempts});
}

final class ClientStateConnected extends ClientState {
  const ClientStateConnected();
}

final class ClientStateDisconnecting extends ClientState {
  const ClientStateDisconnecting();
}

final class ClientStateDisconnected extends ClientState {
  const ClientStateDisconnected();
}

final class ClientStateReconnecting extends ClientState {
  final int attempt;
  final int attempts;

  const ClientStateReconnecting({
    required this.attempt,
    required this.attempts,
  });
}

final class ClientStateReconnected extends ClientState {
  const ClientStateReconnected();
}

final class ClientStateWaitingToRetryConnect extends ClientState {
  final int attempt;
  final int attempts;

  const ClientStateWaitingToRetryConnect({
    required this.attempt,
    required this.attempts,
  });
}

final class ClientStateWaitingToRetryReconnect extends ClientState {
  final int attempt;
  final int attempts;

  const ClientStateWaitingToRetryReconnect({
    required this.attempt,
    required this.attempts,
  });
}

final class ClientStateError extends ClientState {
  final ClientError error;

  const ClientStateError(this.error);
}

/* -------------------------------------------------------------------------- */
/*                                   EVENTS                                   */
/* -------------------------------------------------------------------------- */

sealed class ClientEvent {
  const ClientEvent();

  @override
  bool operator ==(Object other) {
    return switch ((this, other)) {
      (
        ClientEventConnect(attempts: final attemptsA),
        ClientEventConnect(attempts: final attemptsB),
      ) =>
        attemptsA == attemptsB,
      (ClientEventConnectOk(), ClientEventConnectOk()) => true,
      (
        ClientEventConnectErr(error: final errorA),
        ClientEventConnectErr(error: final errorB),
      ) =>
        errorA == errorB,
      (ClientEventDisconnect(), ClientEventDisconnect()) => true,
      (ClientEventDisconnectOk(), ClientEventDisconnectOk()) => true,
      (
        ClientEventDisconnectErr(error: final errorA),
        ClientEventDisconnectErr(error: final errorB),
      ) =>
        errorA == errorB,
      (
        ClientEventReconnect(attempts: final attemptsA),
        ClientEventReconnect(attempts: final attemptsB),
      ) =>
        attemptsA == attemptsB,
      (ClientEventReconnectOk(), ClientEventReconnectOk()) => true,
      (
        ClientEventReconnectErr(error: final errorA),
        ClientEventReconnectErr(error: final errorB),
      ) =>
        errorA == errorB,
      (ClientEventRetry(), ClientEventRetry()) => true,
      (ClientEventDisconnected(), ClientEventDisconnected()) => true,
      (ClientEventAwaitedRetryConnect(), ClientEventAwaitedRetryConnect()) =>
        true,
      (
        ClientEventAwaitedRetryReconnect(),
        ClientEventAwaitedRetryReconnect(),
      ) =>
        true,
      _ => false,
    };
  }

  @override
  int get hashCode {
    return switch (this) {
      ClientEventConnect(:final attempts) => Object.hash(1, attempts),
      ClientEventConnectOk() => 2,
      ClientEventConnectErr(:final error) => Object.hash(3, error),
      ClientEventDisconnect() => 4,
      ClientEventDisconnectOk() => 5,
      ClientEventDisconnectErr(:final error) => Object.hash(6, error),
      ClientEventReconnect(:final attempts) => Object.hash(8, attempts),
      ClientEventReconnectOk() => 9,
      ClientEventReconnectErr(:final error) => Object.hash(10, error),
      ClientEventRetry() => 11,
      ClientEventDisconnected() => 11,
      ClientEventAwaitedRetryConnect() => 12,
      ClientEventAwaitedRetryReconnect() => 13,
    };
  }

  @override
  String toString() {
    return switch (this) {
      ClientEventConnect(:final attempts) => 'Connect(attemps: $attempts)',
      ClientEventConnectOk() => 'Connect[OK]',
      ClientEventConnectErr(:final error) => 'Connect[Err($error)]',
      ClientEventDisconnect() => 'Disconnect',
      ClientEventDisconnectOk() => 'Disconnect[OK]',
      ClientEventDisconnectErr(:final error) => 'Disconnect[Err($error)]',
      ClientEventReconnect(:final attempts) => 'Connect(attemps: $attempts)',
      ClientEventReconnectOk() => 'Reconnect[OK]',
      ClientEventReconnectErr(:final error) => 'Reconnect[Err($error)]',
      ClientEventRetry() => 'Retry',
      ClientEventDisconnected() => 'Disconnected',
      ClientEventAwaitedRetryConnect() => 'AwaitedRetryConnect',
      ClientEventAwaitedRetryReconnect() => 'AwaitedRetryReconnect',
    };
  }
}

final class ClientEventConnect extends ClientEvent {
  final int attempts;

  const ClientEventConnect({required this.attempts});
}

final class ClientEventConnectOk extends ClientEvent {}

final class ClientEventConnectErr extends ClientEvent {
  final ClientErrorConnect error;

  const ClientEventConnectErr(this.error);
}

final class ClientEventDisconnect extends ClientEvent {}

final class ClientEventDisconnectOk extends ClientEvent {}

final class ClientEventDisconnectErr extends ClientEvent {
  final ClientErrorDisconnect error;

  const ClientEventDisconnectErr(this.error);
}

final class ClientEventReconnect extends ClientEvent {
  final int attempts;

  const ClientEventReconnect({required this.attempts});
}

final class ClientEventReconnectOk extends ClientEvent {}

final class ClientEventReconnectErr extends ClientEvent {
  final ClientErrorReconnect error;

  const ClientEventReconnectErr(this.error);
}

final class ClientEventAwaitedRetryConnect extends ClientEvent {
  const ClientEventAwaitedRetryConnect();
}

final class ClientEventAwaitedRetryReconnect extends ClientEvent {
  const ClientEventAwaitedRetryReconnect();
}

final class ClientEventRetry extends ClientEvent {}

final class ClientEventDisconnected extends ClientEvent {}

/* -------------------------------------------------------------------------- */
/*                                   ERRORS                                   */
/* -------------------------------------------------------------------------- */

sealed class ClientError {
  const ClientError();

  @override
  bool operator ==(Object other) {
    return switch ((this, other)) {
      (ClientErrorConnect(), ClientErrorConnect()) => true,
      (ClientErrorDisconnect(), ClientErrorDisconnect()) => true,
      (ClientErrorReconnect(), ClientErrorReconnect()) => true,
      _ => false,
    };
  }

  @override
  int get hashCode {
    return switch (this) {
      ClientErrorConnect() => 1,
      ClientErrorDisconnect() => 2,
      ClientErrorReconnect() => 3,
    };
  }

  @override
  String toString() {
    return switch (this) {
      ClientErrorConnect() => 'Connect',
      ClientErrorDisconnect() => 'Disconnect',
      ClientErrorReconnect() => 'Reconnect',
    };
  }
}

final class ClientErrorConnect extends ClientError {}

final class ClientErrorDisconnect extends ClientError {}

final class ClientErrorReconnect extends ClientError {}

Option<ClientState> transition(ClientState state, ClientEvent event) {
  return switch ((state, event)) {
    /* -------------------------------------------------------------------------- */
    /*                   S: Idle => E: Connect => S: Connecting                   */
    /* -------------------------------------------------------------------------- */
    (ClientStateIdle(), ClientEventConnect(:final attempts)) => Some(
      ClientStateConnecting(attempt: 0, attempts: attempts),
    ),
    /* -------------------------------------------------------------------------- */
    /*                S: Connecting => E: ConnectOk => S: Connected               */
    /* -------------------------------------------------------------------------- */
    (ClientStateConnecting(), ClientEventConnectOk()) => Some(
      ClientStateConnected(),
    ),
    /* -------------------------------------------------------------------------- */
    /*              S: Reconnecting => E: ReconnectOk => S: Reconnected           */
    /* -------------------------------------------------------------------------- */
    (ClientStateReconnecting(), ClientEventReconnectOk()) => Some(
      ClientStateReconnected(),
    ),
    /* -------------------------------------------------------------------------- */
    /*             S: Connected => E: Disconnected => S: Reconnecting             */
    /* -------------------------------------------------------------------------- */
    (ClientStateConnected(), ClientEventDisconnected()) => Some(
      ClientStateReconnecting(attempt: 0, attempts: 3),
    ), //FIXME: hardcoded attempts
    /* -------------------------------------------------------------------------- */
    /*              S: Connected => E: Disconnect => S: Disconnected              */
    /* -------------------------------------------------------------------------- */
    (ClientStateConnected(), ClientEventDisconnect()) => Some(
      ClientStateDisconnecting(),
    ),
    /* -------------------------------------------------------------------------- */
    /*           S: Disconnecting => E: DisconnectOk => S: Disconnected           */
    /* -------------------------------------------------------------------------- */
    (ClientStateDisconnecting(), ClientEventDisconnectOk()) => Some(
      ClientStateDisconnected(),
    ),
    /* -------------------------------------------------------------------------- */
    /*             S: Disconnected => E: Reconnect => S: Reconnecting             */
    /* -------------------------------------------------------------------------- */
    (ClientStateDisconnected(), ClientEventReconnect(:final attempts)) => Some(
      ClientStateReconnecting(attempt: 0, attempts: attempts),
    ),
    // S: Connecting => E: ConnectErr g(attempt < attempts - 1) => S: WaitToRetryConnect
    (
      ClientStateConnecting(:final attempt, :final attempts),
      ClientEventConnectErr(),
    )
        when attempt < attempts - 1 =>
      Some(
        ClientStateWaitingToRetryConnect(
          attempt: attempt + 1,
          attempts: attempts,
        ),
      ),

    // S: WaitingForRetryConnect => E: AwaitedRetryConnect => S: Connecting
    (
      ClientStateWaitingToRetryConnect(:final attempt, :final attempts),
      ClientEventAwaitedRetryConnect(),
    ) =>
      Some(ClientStateConnecting(attempt: attempt, attempts: attempts)),
    /* -------------------------------------------------------------------------- */
    /*                S: Connecting => E: ConnectError => S: Error                */
    /* -------------------------------------------------------------------------- */
    (ClientStateConnecting(), ClientEventConnectErr(:final error)) => Some(
      ClientStateError(error),
    ),
    /* -------------------------------------------------------------------------- */
    /*              S: Reconnecting => E: ReconnectError => S: Error              */
    /* -------------------------------------------------------------------------- */
    (ClientStateReconnecting(), ClientEventReconnectErr(:final error)) => Some(
      ClientStateError(error),
    ),
    /* -------------------------------------------------------------------------- */
    /*             S: Disconnecting => E: DisconnectError => S: Error             */
    /* -------------------------------------------------------------------------- */
    (ClientStateDisconnecting(), ClientEventDisconnectErr(:final error)) =>
      Some(ClientStateError(error)),
    /* -------------------------------------------------------------------------- */
    /*                     S: Error => E: retry => S: S(error)                    */
    /* -------------------------------------------------------------------------- */
    (ClientStateError(:final error), ClientEventRetry()) => Some(
      switch (error) {
        ClientErrorConnect() => ClientStateConnecting(
          attempt: 0,
          attempts: 3,
        ), //FIXME: hardcoded attempts
        ClientErrorDisconnect() => ClientStateDisconnecting(),
        ClientErrorReconnect() => ClientStateReconnecting(
          attempt: 0,
          attempts: 3,
        ), //FIXME: hardcoded attempts
      },
    ),
    (_, _) => const None(),
  };
}
