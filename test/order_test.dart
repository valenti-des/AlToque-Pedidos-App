import 'package:flutter_test/flutter_test.dart';

import 'package:app/models/order.dart';

void main() {
  test('stored customer orders restore their products and status', () {
    final order = Order.fromJson({
      'id': 42,
      'pickupCode': '000042',
      'customerName': 'Ana Perez',
      'course': '3ro A',
      'paymentMethod': 'En el buffet',
      'status': 'listo',
      'cancellationReason': null,
      'items': [
        {
          'productId': 3,
          'name': 'Papas con cheddar',
          'description': 'Papas crocantes con cheddar',
          'category': 'Comidas',
          'price': 3800.0,
          'emoji': '🍟',
          'color': '#FFF0C2',
          'quantity': 2,
        },
      ],
    });

    expect(order.id, 42);
    expect(order.status, 'listo');
    expect(order.items.length, 1);
    expect(order.items.keys.single.name, 'Papas con cheddar');
    expect(order.items.values.single, 2);
    expect(order.trackingToken, isNull);
  });
}
