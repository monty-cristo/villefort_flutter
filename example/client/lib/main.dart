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
        builder: (state) {
          return switch (state) {
            ClientStateIdle() => ProcessNodeCard(
              title: 'Request Update',
              description:
                  'Processes an update request and validates the data before writing to the storage system.',
              actions: const ['Validate Request', 'Transform Data'],
              invocations: const [
                'validateData()',
                'saveToDatabase()',
                'notifySubscribers()',
              ],
              actors: const [
                ActorData(name: 'Client', type: ActorIconType.storage),
                ActorData(name: 'API Gateway', type: ActorIconType.hub),
                ActorData(name: 'Update Service', type: ActorIconType.storage),
              ],
            ),
            ClientStateConnecting() => Container(
              width: 300,
              height: 100,
              color: Colors.indigo,
              child: Center(child: Text(state.toString())),
            ),
            ClientStateConnected() => Container(
              width: 200,
              height: 100,
              color: Colors.indigo,
              child: Center(child: Text(state.toString())),
            ),
            ClientStateDisconnecting() => Container(
              width: 400,
              height: 100,
              color: Colors.indigo,
              child: Center(child: Text(state.toString())),
            ),
            ClientStateDisconnected() => Container(
              width: 200,
              height: 100,
              color: Colors.indigo,
              child: Center(child: Text(state.toString())),
            ),
            ClientStateReconnecting() => Container(
              width: 200,
              height: 100,
              color: Colors.indigo,
              child: Center(child: Text(state.toString())),
            ),
            ClientStateReconnected() => Container(
              width: 500,
              height: 100,
              color: Colors.indigo,
              child: Center(child: Text(state.toString())),
            ),
            ClientStateWaitingToRetryConnect() => Container(
              width: 250,
              height: 100,
              color: Colors.indigo,
              child: Center(child: Text(state.toString())),
            ),
            ClientStateWaitingToRetryReconnect() => Container(
              width: 300,
              height: 100,
              color: Colors.indigo,
              child: Center(child: Text(state.toString())),
            ),
            ClientStateError() => Container(
              width: 200,
              height: 100,
              color: Colors.indigo,
              child: Center(child: Text(state.toString())),
            ),
          };
        },
      ),
    );
  }
}
