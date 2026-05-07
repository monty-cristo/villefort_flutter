import 'package:flutter/material.dart';
import 'package:villefort/villefort.dart';
import 'package:villefort_flutter/villefort_flutter.dart';

import 'client/machine.dart';

List<ClientEvent> generate(ClientState state) {
  return switch (state) {
    ClientStateConnecting() => [
      ClientEventConnectOk(),
      ClientEventConnectErr(ClientErrorConnect()),
    ],
    ClientStateConnected() => [
      ClientEventDisconnect(),
      ClientEventDisconnected(),
    ],
    ClientStateDisconnecting() => [
      ClientEventDisconnectOk(),
      ClientEventDisconnectErr(ClientErrorDisconnect()),
    ],
    ClientStateDisconnected() => [ClientEventReconnect(attempts: 3)],
    ClientStateReconnecting() => [
      ClientEventReconnectOk(),
      ClientEventReconnectErr(ClientErrorReconnect()),
    ],
    ClientStateWaitingToRetryConnect() => [ClientEventAwaitedRetryConnect()],
    ClientStateWaitingToRetryReconnect() => [
      ClientEventAwaitedRetryReconnect(),
    ],
    ClientStateError() => [ClientEventRetry()],
    ClientStateIdle() => [ClientEventConnect(attempts: 3)],
    ClientStateReconnected() => [
      ClientEventDisconnect(),
      ClientEventDisconnected(),
    ],
  };
}

void main(List<String> args) {
  runApp(const ClientMachineViewerApp());
}

class ClientMachineViewerApp extends StatelessWidget {
  const ClientMachineViewerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Client Machine Viewer',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
        useMaterial3: true,
      ),
      home: MachineViewer(
        title: 'Client Machine',
        initial: ClientStateIdle(),
        transition: transition,
        generate: generate,
        builder: (state) {
          return switch (state) {
            ClientStateIdle() => Idle(),
            ClientStateConnecting() => Connecting(),
            ClientStateConnected() => Connected(),
            ClientStateDisconnecting() => Disconnecting(),
            ClientStateDisconnected() => Disconnected(),
            ClientStateReconnecting() => Reconnecting(),
            ClientStateReconnected() => Reconnected(),
            ClientStateWaitingToRetryConnect() => WaitingToRetry(
              title: 'Waiting Retry Connect',
            ),
            ClientStateWaitingToRetryReconnect() => WaitingToRetry(
              title: 'Waiting Retry Reconnect',
            ),
            ClientStateError(:final error) => Error(error: error),
          };
        },
      ),
    );
  }
}

class Idle extends StatelessWidget {
  const Idle({super.key});

  @override
  Widget build(BuildContext context) {
    return StatelessNodeCard(title: 'Idle');
  }
}

class Connecting extends StatelessWidget {
  const Connecting({super.key});

  @override
  Widget build(BuildContext context) {
    return ProcessNodeCard(
      title: 'Connecting',
      description: Some('Trying to connect for the first time'),
      invocation: Some('connect()'),
    );
  }
}

class Disconnecting extends StatelessWidget {
  const Disconnecting({super.key});

  @override
  Widget build(BuildContext context) {
    return ProcessNodeCard(
      title: 'Disconnecting',
      description: Some('Trying to disconnect'),
      invocation: Some('disconnect()'),
    );
  }
}

class Reconnecting extends StatelessWidget {
  const Reconnecting({super.key});

  @override
  Widget build(BuildContext context) {
    return ProcessNodeCard(
      title: 'Reconnecting',
      description: Some('Trying to reconnect'),
      invocation: Some('connect()'),
    );
  }
}

class Connected extends StatelessWidget {
  const Connected({super.key});

  @override
  Widget build(BuildContext context) {
    return ProcessNodeCard(
      title: 'Connected',
      description: Some(
        ('First time connected. Listens to the connection for disconnnects'),
      ),
      actors: Some(const [ChipData(name: 'Client', icon: Icons.stream)]),
    );
  }
}

class Disconnected extends StatelessWidget {
  const Disconnected({super.key});

  @override
  Widget build(BuildContext context) {
    return ProcessNodeCard(
      title: 'Disconnected',
      description: Some(
        ('First time connected. Listens to the connection for disconnnects'),
      ),
    );
  }
}

class Reconnected extends StatelessWidget {
  const Reconnected({super.key});

  @override
  Widget build(BuildContext context) {
    return ProcessNodeCard(
      title: 'Reconnected',
      description: Some((' Listens to the connection for disconnnects')),
      actors: Some(const [ChipData(name: 'Client', icon: Icons.stream)]),
    );
  }
}

class WaitingToRetry extends StatelessWidget {
  final String title;

  const WaitingToRetry({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return StatelessNodeCard(title: title);
  }
}

class Error extends StatelessWidget {
  final ClientError error;

  const Error({super.key, required this.error});

  @override
  Widget build(BuildContext context) {
    return StatelessNodeCard(title: 'Error($error)');
  }
}
