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
      _ => false,
    };
  }

  @override
  int get hashCode {
    return switch (this) {
      ClientStateConnecting() => 1,
      ClientStateConnected() => 2,
      ClientStateDisconnecting() => 3,
      ClientStateDisconnected() => 4,
      ClientStateReconnecting() => 5,
      ClientStateError(:final error) => Object.hash(6, error),
      ClientStateWaitingToRetryConnect() => 7,
      ClientStateWaitingToRetryReconnect() => 8,
    };
  }

  @override
  String toString() {
    return switch (this) {
      ClientStateConnecting() => 'Connecting',
      ClientStateConnected() => 'Connected',
      ClientStateDisconnecting() => 'Disconnecting',
      ClientStateDisconnected() => 'Disconnected',
      ClientStateReconnecting() => 'Reconnecting',
      ClientStateError(:final error) => 'Error($error)',
      ClientStateWaitingToRetryConnect() => 'WaitingToRetryConnect',
      ClientStateWaitingToRetryReconnect() => 'WaitingToRetryReconnect',
    };
  }
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
      (ClientEventConnect(), ClientEventConnect()) => true,
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
      (ClientEventReconnect(), ClientEventReconnect()) => true,
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
      ClientEventConnect() => 1,
      ClientEventConnectOk() => 2,
      ClientEventConnectErr(:final error) => Object.hash(3, error),
      ClientEventDisconnect() => 4,
      ClientEventDisconnectOk() => 5,
      ClientEventDisconnectErr(:final error) => Object.hash(6, error),
      ClientEventReconnect() => 8,
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
      ClientEventConnect() => 'Connect',
      ClientEventConnectOk() => 'Connect[OK]',
      ClientEventConnectErr(:final error) => 'Connect[Err($error)]',
      ClientEventDisconnect() => 'Disconnect',
      ClientEventDisconnectOk() => 'Disconnect[OK]',
      ClientEventDisconnectErr(:final error) => 'Disconnect[Err($error)]',
      ClientEventReconnect() => 'Reconnect',
      ClientEventReconnectOk() => 'Reconnect[OK]',
      ClientEventReconnectErr(:final error) => 'Reconnect[Err($error)]',
      ClientEventRetry() => 'Retry',
      ClientEventDisconnected() => 'Disconnected',
      ClientEventAwaitedRetryConnect() => 'AwaitedRetryConnect',
      ClientEventAwaitedRetryReconnect() => 'AwaitedRetryReconnect',
    };
  }
}

final class ClientEventConnect extends ClientEvent {}

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

final class ClientEventReconnect extends ClientEvent {}

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
    /*                S: Connecting => E: ConnectOk => S: Connected               */
    /* -------------------------------------------------------------------------- */
    (ClientStateConnecting(), ClientEventConnectOk()) => Some(
      ClientStateConnected(),
    ),
    /* -------------------------------------------------------------------------- */
    /*              S: Reconnecting => E: ReconnectOk => S: Connected             */
    /* -------------------------------------------------------------------------- */
    (ClientStateReconnecting(), ClientEventReconnectOk()) => Some(
      ClientStateConnected(),
    ),
    /* -------------------------------------------------------------------------- */
    /*             S: Connected => E: Disconnected => S: Reconnecting             */
    /* -------------------------------------------------------------------------- */
    (ClientStateConnected(), ClientEventDisconnected()) =>
      // Some(ClientStateReconnecting()),
      None(),
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
    (ClientStateDisconnected(), ClientEventReconnect()) =>
      // Some(ClientStateReconnecting()),
      None(),
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
    (ClientStateError(:final error), ClientEventRetry()) => None(),
    // Some(switch (error) {
    // // ClientErrorConnect() => ClientStateConnecting(),
    // // ClientErrorDisconnect() => ClientStateDisconnecting(),
    // // ClientErrorReconnect() => ClientStateReconnecting(),
    // }),
    (_, _) => const None(),
  };
}
