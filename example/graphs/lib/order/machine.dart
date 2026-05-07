import 'package:villefort/villefort.dart';

sealed class OrderState {
  const OrderState();

  @override
  bool operator ==(Object other) => switch ((this, other)) {
    (OrderStateIdle(), OrderStateIdle()) => true,
    (OrderStatePending(), OrderStatePending()) => true,
    (OrderStateConfirmed(), OrderStateConfirmed()) => true,
    (OrderStateFailed(), OrderStateFailed()) => true,
    (OrderStateCancelled(), OrderStateCancelled()) => true,
    (OrderStateShipped(), OrderStateShipped()) => true,
    (OrderStateDelivered(), OrderStateDelivered()) => true,
    (OrderStateRefunded(), OrderStateRefunded()) => true,
    _ => false,
  };

  @override
  int get hashCode => switch (this) {
    OrderStateIdle() => 1,
    OrderStatePending() => 2,
    OrderStateConfirmed() => 3,
    OrderStateFailed() => 4,
    OrderStateCancelled() => 5,
    OrderStateShipped() => 6,
    OrderStateDelivered() => 7,
    OrderStateRefunded() => 8,
  };
}

final class OrderStateIdle extends OrderState {
  const OrderStateIdle();
}

final class OrderStatePending extends OrderState {
  const OrderStatePending();
}

final class OrderStateConfirmed extends OrderState {
  const OrderStateConfirmed();
}

final class OrderStateFailed extends OrderState {
  const OrderStateFailed();
}

final class OrderStateCancelled extends OrderState {
  const OrderStateCancelled();
}

final class OrderStateShipped extends OrderState {
  const OrderStateShipped();
}

final class OrderStateDelivered extends OrderState {
  const OrderStateDelivered();
}

final class OrderStateRefunded extends OrderState {
  const OrderStateRefunded();
}

sealed class OrderEvent {
  const OrderEvent();
}

final class OrderEventPlace extends OrderEvent {
  const OrderEventPlace();
}

final class OrderEventConfirm extends OrderEvent {
  const OrderEventConfirm();
}

final class OrderEventFail extends OrderEvent {
  const OrderEventFail();
}

final class OrderEventCancel extends OrderEvent {
  const OrderEventCancel();
}

final class OrderEventShip extends OrderEvent {
  const OrderEventShip();
}

final class OrderEventDeliver extends OrderEvent {
  const OrderEventDeliver();
}

final class OrderEventRefund extends OrderEvent {
  const OrderEventRefund();
}

final class OrderEventReset extends OrderEvent {
  const OrderEventReset();
}

List<OrderEvent> generateOrder(OrderState state) => switch (state) {
  OrderStateIdle() => [const OrderEventPlace()],
  OrderStatePending() => [
    const OrderEventConfirm(),
    const OrderEventFail(),
    const OrderEventCancel(),
  ],
  OrderStateConfirmed() => [const OrderEventShip()],
  OrderStateFailed() => [const OrderEventReset()],
  OrderStateCancelled() => [const OrderEventRefund()],
  OrderStateShipped() => [const OrderEventDeliver()],
  OrderStateDelivered() => [const OrderEventReset()],
  OrderStateRefunded() => [const OrderEventReset()],
};

Option<OrderState> orderTransition(OrderState state, OrderEvent event) =>
    switch ((state, event)) {
      (OrderStateIdle(), OrderEventPlace()) => const Some(OrderStatePending()),
      (OrderStatePending(), OrderEventConfirm()) => const Some(
        OrderStateConfirmed(),
      ),
      (OrderStatePending(), OrderEventFail()) => const Some(OrderStateFailed()),
      (OrderStatePending(), OrderEventCancel()) => const Some(
        OrderStateCancelled(),
      ),
      (OrderStateConfirmed(), OrderEventShip()) => const Some(
        OrderStateShipped(),
      ),
      (OrderStateShipped(), OrderEventDeliver()) => const Some(
        OrderStateDelivered(),
      ),
      (OrderStateCancelled(), OrderEventRefund()) => const Some(
        OrderStateRefunded(),
      ),
      (OrderStateFailed(), OrderEventReset()) => const Some(OrderStateIdle()),
      (OrderStateDelivered(), OrderEventReset()) => const Some(OrderStateIdle()),
      (OrderStateRefunded(), OrderEventReset()) => const Some(OrderStateIdle()),
      _ => const None(),
    };
