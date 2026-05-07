import 'package:flutter/material.dart';
import 'package:villefort/villefort.dart';
import 'package:villefort_flutter/villefort_flutter.dart';

import 'auth/machine.dart';
import 'client/machine.dart';
import 'order/machine.dart';
import 'traffic_light/machine.dart';

void main(List<String> args) {
  runApp(const GraphsApp());
}

// ─── Selector ────────────────────────────────────────────────────────────────

class GraphsApp extends StatelessWidget {
  const GraphsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Villefort Examples',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
        useMaterial3: true,
      ),
      home: Scaffold(
        appBar: AppBar(title: const Text('Pick a machine')),
        body: ListView(
          children: [
            _Tile(
              title: 'Client',
              subtitle: 'Complex machine with reconnect & retry logic',
              app: const ClientMachineViewer(),
            ),
            _Tile(
              title: 'Auth',
              subtitle: 'Login / logout with token refresh back-edges',
              app: const AuthMachineViewer(),
            ),
            _Tile(
              title: 'Order',
              subtitle: 'Branching order flow with multiple back-edges to idle',
              app: const OrderMachineViewer(),
            ),
            _Tile(
              title: 'Traffic Light',
              subtitle: 'Simple 3-state cycle',
              app: const TrafficLightViewer(),
            ),
          ],
        ),
      ),
    );
  }
}

class _Tile extends StatelessWidget {
  final String title;
  final String subtitle;
  final Widget app;

  const _Tile({required this.title, required this.subtitle, required this.app});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: const Icon(Icons.chevron_right),
      onTap: () =>
          Navigator.push(context, MaterialPageRoute(builder: (_) => app)),
    );
  }
}

// ─── Client ───────────────────────────────────────────────────────────────────

List<ClientEvent> generateClient(ClientState state) {
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

class ClientMachineViewer extends StatelessWidget {
  const ClientMachineViewer({super.key});

  @override
  Widget build(BuildContext context) {
    return MachineViewer(
      title: 'Client Machine',
      initial: ClientStateIdle(),
      transition: transition,
      generate: generateClient,
      builder: (state) => switch (state) {
        ClientStateIdle() => const _ClientIdle(),
        ClientStateConnecting() => const _Connecting(),
        ClientStateConnected() => const _Connected(),
        ClientStateDisconnecting() => const _Disconnecting(),
        ClientStateDisconnected() => const _Disconnected(),
        ClientStateReconnecting() => const _Reconnecting(),
        ClientStateReconnected() => const _Reconnected(),
        ClientStateWaitingToRetryConnect() => const _WaitingToRetry(
          title: 'Waiting Retry Connect',
        ),
        ClientStateWaitingToRetryReconnect() => const _WaitingToRetry(
          title: 'Waiting Retry Reconnect',
        ),
        ClientStateError(:final error) => _ClientError(error: error),
      },
    );
  }
}

class _ClientIdle extends StatelessWidget {
  const _ClientIdle();

  @override
  Widget build(BuildContext context) => StatelessNodeCard(title: 'Idle');
}

class _Connecting extends StatelessWidget {
  const _Connecting();

  @override
  Widget build(BuildContext context) => ProcessNodeCard(
    title: 'Connecting',
    description: Some('Trying to connect for the first time'),
    invocation: Some('connect()'),
  );
}

class _Disconnecting extends StatelessWidget {
  const _Disconnecting();

  @override
  Widget build(BuildContext context) => ProcessNodeCard(
    title: 'Disconnecting',
    description: Some('Trying to disconnect'),
    invocation: Some('disconnect()'),
  );
}

class _Reconnecting extends StatelessWidget {
  const _Reconnecting();

  @override
  Widget build(BuildContext context) => ProcessNodeCard(
    title: 'Reconnecting',
    description: Some('Trying to reconnect'),
    invocation: Some('connect()'),
  );
}

class _Connected extends StatelessWidget {
  const _Connected();

  @override
  Widget build(BuildContext context) => ProcessNodeCard(
    title: 'Connected',
    description: Some(
      'First time connected. Listens to the connection for disconnects',
    ),
    actors: Some(const [ChipData(name: 'Client', icon: Icons.stream)]),
  );
}

class _Disconnected extends StatelessWidget {
  const _Disconnected();

  @override
  Widget build(BuildContext context) => ProcessNodeCard(
    title: 'Disconnected',
    description: Some(
      'First time connected. Listens to the connection for disconnects',
    ),
  );
}

class _Reconnected extends StatelessWidget {
  const _Reconnected();

  @override
  Widget build(BuildContext context) => ProcessNodeCard(
    title: 'Reconnected',
    description: Some('Listens to the connection for disconnects'),
    actors: Some(const [ChipData(name: 'Client', icon: Icons.stream)]),
  );
}

class _WaitingToRetry extends StatelessWidget {
  final String title;

  const _WaitingToRetry({required this.title});

  @override
  Widget build(BuildContext context) => StatelessNodeCard(title: title);
}

class _ClientError extends StatelessWidget {
  final ClientError error;

  const _ClientError({required this.error});

  @override
  Widget build(BuildContext context) =>
      StatelessNodeCard(title: 'Error($error)');
}

// ─── Auth ─────────────────────────────────────────────────────────────────────

class AuthMachineViewer extends StatelessWidget {
  const AuthMachineViewer({super.key});

  @override
  Widget build(BuildContext context) {
    return MachineViewer(
      title: 'Auth Machine',
      initial: const AuthStateLoggedOut(),
      transition: authTransition,
      generate: generateAuth,
      builder: (state) => switch (state) {
        AuthStateLoggedOut() => StatelessNodeCard(title: 'Logged Out'),
        AuthStateLoggingIn() => ProcessNodeCard(
          title: 'Logging In',
          description: Some('Authenticating with the server'),
          invocation: Some('login(username, password)'),
        ),
        AuthStateLoggedIn(:final userId) => ProcessNodeCard(
          title: 'Logged In',
          description: Some('Session active'),
          actors: Some([ChipData(name: userId, icon: Icons.person)]),
        ),
        AuthStateLoginFailed(:final reason) => ProcessNodeCard(
          title: 'Login Failed',
          description: Some(reason),
        ),
        AuthStateRefreshingToken() => ProcessNodeCard(
          title: 'Refreshing Token',
          description: Some('Obtaining a new access token'),
          invocation: Some('refreshToken()'),
        ),
        AuthStateLoggingOut() => ProcessNodeCard(
          title: 'Logging Out',
          invocation: Some('logout()'),
        ),
      },
    );
  }
}

// ─── Order ────────────────────────────────────────────────────────────────────

class OrderMachineViewer extends StatelessWidget {
  const OrderMachineViewer({super.key});

  @override
  Widget build(BuildContext context) {
    return MachineViewer(
      title: 'Order Machine',
      initial: const OrderStateIdle(),
      transition: orderTransition,
      generate: generateOrder,
      builder: (state) => switch (state) {
        OrderStateIdle() => StatelessNodeCard(title: 'Idle'),
        OrderStatePending() => ProcessNodeCard(
          title: 'Pending',
          description: Some('Awaiting merchant confirmation'),
        ),
        OrderStateConfirmed() => ProcessNodeCard(
          title: 'Confirmed',
          description: Some('Order accepted, preparing for shipment'),
          actors: Some(const [
            ChipData(name: 'Warehouse', icon: Icons.warehouse),
          ]),
        ),
        OrderStateFailed() => ProcessNodeCard(
          title: 'Failed',
          description: Some('Payment or validation failed'),
        ),
        OrderStateCancelled() => ProcessNodeCard(
          title: 'Cancelled',
          description: Some('Order cancelled by customer'),
        ),
        OrderStateShipped() => ProcessNodeCard(
          title: 'Shipped',
          description: Some('Package in transit'),
          invocation: Some('trackPackage()'),
          actors: Some(const [
            ChipData(name: 'Courier', icon: Icons.local_shipping),
          ]),
        ),
        OrderStateDelivered() => ProcessNodeCard(
          title: 'Delivered',
          description: Some('Package received by customer'),
        ),
        OrderStateRefunded() => ProcessNodeCard(
          title: 'Refunded',
          description: Some('Payment returned to customer'),
        ),
      },
    );
  }
}

// ─── Traffic Light ────────────────────────────────────────────────────────────

class TrafficLightViewer extends StatelessWidget {
  const TrafficLightViewer({super.key});

  @override
  Widget build(BuildContext context) {
    return MachineViewer(
      title: 'Traffic Light',
      initial: const TrafficStateRed(),
      transition: trafficTransition,
      generate: (state) => [const TrafficEventNext()],
      builder: (state) => switch (state) {
        TrafficStateRed() => ProcessNodeCard(
          title: 'Red',
          description: Some('Stop'),
        ),
        TrafficStateGreen() => ProcessNodeCard(
          title: 'Green',
          description: Some('Go'),
        ),
        TrafficStateYellow() => ProcessNodeCard(
          title: 'Yellow',
          description: Some('Prepare to stop'),
        ),
      },
    );
  }
}
