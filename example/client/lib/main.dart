import 'package:flutter/material.dart';
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
        eventColor: (event) => switch (event) {
          ClientEventConnectOk() => Colors.green,
          ClientEventConnectErr() => Colors.red,
          ClientEventDisconnectOk() => Colors.green,
          ClientEventDisconnectErr() => Colors.red,
          ClientEventReconnectOk() => Colors.green,
          ClientEventReconnectErr() => Colors.red,
          _ => null,
        },
        //sameGroup: (a, b) => a.runtimeType == b.runtimeType,
      ),
    );
  }
}
