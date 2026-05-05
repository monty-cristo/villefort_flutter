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
      ClientEventDisconnect(),
    ],
    ClientStateDisconnecting() => [
      ClientEventDisconnectOk(),
      ClientEventDisconnectErr(ClientErrorDisconnect()),
    ],
    ClientStateDisconnected() => [ClientEventReconnect()],
    ClientStateReconnecting() => [
      ClientEventReconnectOk(),
      ClientEventReconnectErr(ClientErrorReconnect()),
    ],
    ClientStateWaitingToRetryConnect() => [ClientEventAwaitedRetryConnect()],
    ClientStateWaitingToRetryReconnect() => [
      ClientEventAwaitedRetryReconnect(),
    ],
    ClientStateError() => [ClientEventRetry()],
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
        initial: ClientStateConnecting(attempt: 0, attempts: 3),
        transition: transition,
        generate: generate,
      ),
    );
  }
}
