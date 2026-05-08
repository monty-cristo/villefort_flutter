import 'package:flutter/material.dart';
import 'package:villefort/villefort.dart';
import 'package:villefort_flutter/villefort_flutter.dart';

import 'order/machine.dart';
import 'traffic_light/machine.dart';

// A hard-coded recording of a traffic light session.
final _recording = MachineRecording<TrafficState, TrafficEvent>(
  initial: const TrafficStateRed(),
  transitions: [
    (const TrafficEventNext(), const TrafficStateGreen()),
    (const TrafficEventNext(), const TrafficStateYellow()),
    (const TrafficEventNext(), const TrafficStateRed()),
    (const TrafficEventNext(), const TrafficStateGreen()),
    (const TrafficEventNext(), const TrafficStateYellow()),
  ],
);

// Happy path: place → confirm → ship → deliver, then a cancelled run.
final _orderRecording = MachineRecording<OrderState, OrderEvent>(
  initial: const OrderStateIdle(),
  transitions: [
    (const OrderEventPlace(), const OrderStatePending()),
    (const OrderEventConfirm(), const OrderStateConfirmed()),
    (const OrderEventShip(), const OrderStateShipped()),
    (const OrderEventDeliver(), const OrderStateDelivered()),
    (const OrderEventReset(), const OrderStateIdle()),
    (const OrderEventPlace(), const OrderStatePending()),
    (const OrderEventCancel(), const OrderStateCancelled()),
    (const OrderEventRefund(), const OrderStateRefunded()),
    (const OrderEventReset(), const OrderStateIdle()),
  ],
);

class OrderReplayViewer extends StatelessWidget {
  const OrderReplayViewer({super.key});

  @override
  Widget build(BuildContext context) {
    return MachineReplayViewer<OrderState, OrderEvent>(
      title: 'Order Machine — Replay',
      recording: _orderRecording,
      builder: (state, active) => switch (state) {
        OrderStateIdle() => StatelessNodeCard(title: 'Idle', active: active),
        OrderStatePending() => ProcessNodeCard(
          title: 'Pending',
          description: const Some('Awaiting merchant confirmation'),
          active: active,
        ),
        OrderStateConfirmed() => ProcessNodeCard(
          title: 'Confirmed',
          description: const Some('Order accepted, preparing for shipment'),
          actors: const Some([
            ChipData(name: 'Warehouse', icon: Icons.warehouse),
          ]),
          active: active,
        ),
        OrderStateFailed() => ProcessNodeCard(
          title: 'Failed',
          description: const Some('Payment or validation failed'),
          active: active,
        ),
        OrderStateCancelled() => ProcessNodeCard(
          title: 'Cancelled',
          description: const Some('Order cancelled by customer'),
          active: active,
        ),
        OrderStateShipped() => ProcessNodeCard(
          title: 'Shipped',
          description: const Some('Package in transit'),
          invocation: const Some('trackPackage()'),
          actors: const Some([
            ChipData(name: 'Courier', icon: Icons.local_shipping),
          ]),
          active: active,
        ),
        OrderStateDelivered() => ProcessNodeCard(
          title: 'Delivered',
          description: const Some('Package received by customer'),
          active: active,
        ),
        OrderStateRefunded() => ProcessNodeCard(
          title: 'Refunded',
          description: const Some('Payment returned to customer'),
          active: active,
        ),
      },
    );
  }
}

class TrafficReplayViewer extends StatelessWidget {
  const TrafficReplayViewer({super.key});

  @override
  Widget build(BuildContext context) {
    return MachineReplayViewer<TrafficState, TrafficEvent>(
      title: 'Traffic Light — Replay',
      recording: _recording,
      builder: (state, active) => switch (state) {
        TrafficStateRed() => ProcessNodeCard(
          title: 'Red',
          description: const Some('Stop'),
          active: active,
        ),
        TrafficStateGreen() => ProcessNodeCard(
          title: 'Green',
          description: const Some('Go'),
          active: active,
        ),
        TrafficStateYellow() => ProcessNodeCard(
          title: 'Yellow',
          description: const Some('Prepare to stop'),
          active: active,
        ),
      },
    );
  }
}
