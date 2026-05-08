import 'package:flutter/material.dart';
import 'package:villefort/villefort.dart';
import 'package:villefort_flutter/villefort_flutter.dart';

import 'auth/machine.dart';
import 'client/machine.dart';
import 'order/machine.dart';
import 'replay_example.dart';
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
            _Tile(
              title: 'Traffic Light — Replay',
              subtitle: 'Hard-coded traffic light recording played back',
              app: const TrafficReplayViewer(),
            ),
            _Tile(
              title: 'Order Machine — Replay',
              subtitle: 'Happy path then cancelled run, played back',
              app: const OrderReplayViewer(),
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
      builder: (state, active) => switch (state) {
        ClientStateIdle() => _ClientIdle(active: active),
        ClientStateConnecting() => _Connecting(active: active),
        ClientStateConnected() => _Connected(active: active),
        ClientStateDisconnecting() => _Disconnecting(active: active),
        ClientStateDisconnected() => _Disconnected(active: active),
        ClientStateReconnecting() => _Reconnecting(active: active),
        ClientStateReconnected() => _Reconnected(active: active),
        ClientStateWaitingToRetryConnect() => _WaitingToRetry(
          title: 'Waiting Retry Connect',
          active: active,
        ),
        ClientStateWaitingToRetryReconnect() => _WaitingToRetry(
          title: 'Waiting Retry Reconnect',
          active: active,
        ),
        ClientStateError(:final error) => _ClientError(error: error, active: active),
      },
    );
  }
}

class _ClientIdle extends StatelessWidget {
  final bool active;
  const _ClientIdle({this.active = false});

  @override
  Widget build(BuildContext context) => StatelessNodeCard(title: 'Idle', active: active);
}

class _Connecting extends StatelessWidget {
  final bool active;
  const _Connecting({this.active = false});

  @override
  Widget build(BuildContext context) => ProcessNodeCard(
    title: 'Connecting',
    description: Some('Trying to connect for the first time'),
    invocation: Some('connect()'),
    active: active,
  );
}

class _Disconnecting extends StatelessWidget {
  final bool active;
  const _Disconnecting({this.active = false});

  @override
  Widget build(BuildContext context) => ProcessNodeCard(
    title: 'Disconnecting',
    description: Some('Trying to disconnect'),
    invocation: Some('disconnect()'),
    active: active,
  );
}

class _Reconnecting extends StatelessWidget {
  final bool active;
  const _Reconnecting({this.active = false});

  @override
  Widget build(BuildContext context) => ProcessNodeCard(
    title: 'Reconnecting',
    description: Some('Trying to reconnect'),
    invocation: Some('connect()'),
    active: active,
  );
}

class _Connected extends StatelessWidget {
  final bool active;
  const _Connected({this.active = false});

  @override
  Widget build(BuildContext context) => ProcessNodeCard(
    title: 'Connected',
    description: Some(
      'First time connected. Listens to the connection for disconnects',
    ),
    actors: Some(const [ChipData(name: 'Client', icon: Icons.stream)]),
    active: active,
  );
}

class _Disconnected extends StatelessWidget {
  final bool active;
  const _Disconnected({this.active = false});

  @override
  Widget build(BuildContext context) => ProcessNodeCard(
    title: 'Disconnected',
    description: Some(
      'First time connected. Listens to the connection for disconnects',
    ),
    active: active,
  );
}

class _Reconnected extends StatelessWidget {
  final bool active;
  const _Reconnected({this.active = false});

  @override
  Widget build(BuildContext context) => ProcessNodeCard(
    title: 'Reconnected',
    description: Some('Listens to the connection for disconnects'),
    actors: Some(const [ChipData(name: 'Client', icon: Icons.stream)]),
    active: active,
  );
}

class _WaitingToRetry extends StatelessWidget {
  final String title;
  final bool active;

  const _WaitingToRetry({required this.title, this.active = false});

  @override
  Widget build(BuildContext context) => StatelessNodeCard(title: title, active: active);
}

class _ClientError extends StatelessWidget {
  final ClientError error;
  final bool active;

  const _ClientError({required this.error, this.active = false});

  @override
  Widget build(BuildContext context) =>
      StatelessNodeCard(title: 'Error($error)', active: active);
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
      builder: (state, active) => switch (state) {
        AuthStateLoggedOut() => StatelessNodeCard(title: 'Logged Out', active: active),
        AuthStateLoggingIn() => ProcessNodeCard(
          title: 'Logging In',
          description: Some('Authenticating with the server'),
          invocation: Some('login(username, password)'),
          active: active,
        ),
        AuthStateLoggedIn(:final userId) => ProcessNodeCard(
          title: 'Logged In',
          description: Some('Session active'),
          actors: Some([ChipData(name: userId, icon: Icons.person)]),
          active: active,
        ),
        AuthStateLoginFailed(:final reason) => ProcessNodeCard(
          title: 'Login Failed',
          description: Some(reason),
          active: active,
        ),
        AuthStateRefreshingToken() => ProcessNodeCard(
          title: 'Refreshing Token',
          description: Some('Obtaining a new access token'),
          invocation: Some('refreshToken()'),
          active: active,
        ),
        AuthStateLoggingOut() => ProcessNodeCard(
          title: 'Logging Out',
          invocation: Some('logout()'),
          active: active,
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
      builder: (state, active) => switch (state) {
        OrderStateIdle() => StatelessNodeCard(title: 'Idle', active: active),
        OrderStatePending() => ProcessNodeCard(
          title: 'Pending',
          description: Some('Awaiting merchant confirmation'),
          active: active,
        ),
        OrderStateConfirmed() => ProcessNodeCard(
          title: 'Confirmed',
          description: Some('Order accepted, preparing for shipment'),
          actors: Some(const [
            ChipData(name: 'Warehouse', icon: Icons.warehouse),
          ]),
          active: active,
        ),
        OrderStateFailed() => ProcessNodeCard(
          title: 'Failed',
          description: Some('Payment or validation failed'),
          active: active,
        ),
        OrderStateCancelled() => ProcessNodeCard(
          title: 'Cancelled',
          description: Some('Order cancelled by customer'),
          active: active,
        ),
        OrderStateShipped() => ProcessNodeCard(
          title: 'Shipped',
          description: Some('Package in transit'),
          invocation: Some('trackPackage()'),
          actors: Some(const [
            ChipData(name: 'Courier', icon: Icons.local_shipping),
          ]),
          active: active,
        ),
        OrderStateDelivered() => ProcessNodeCard(
          title: 'Delivered',
          description: Some('Package received by customer'),
          active: active,
        ),
        OrderStateRefunded() => ProcessNodeCard(
          title: 'Refunded',
          description: Some('Payment returned to customer'),
          active: active,
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
      builder: (state, active) => switch (state) {
        TrafficStateRed() => ProcessNodeCard(
          title: 'Red',
          description: Some('Stop'),
          active: active,
        ),
        TrafficStateGreen() => ProcessNodeCard(
          title: 'Green',
          description: Some('Go'),
          active: active,
        ),
        TrafficStateYellow() => ProcessNodeCard(
          title: 'Yellow',
          description: Some('Prepare to stop'),
          active: active,
        ),
      },
    );
  }
}
