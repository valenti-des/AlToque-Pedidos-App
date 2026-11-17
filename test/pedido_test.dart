import 'package:flutter_test/flutter_test.dart';

import 'package:app/models/pedido.dart';
import 'package:app/models/usuario.dart';

void main() {
  test('order JSON restores customer, product, payment, and state', () {
    final order = Pedido.fromJson({
      'id': 42,
      'pickupCode': '000042',
      'customer': {
        'id': 7,
        'name': 'Ana Perez',
        'email': 'ana@example.com',
        'role': 'cliente',
        'course': '',
      },
      'paymentMethod': 'En el buffet',
      'status': 'listo',
      'total': 7600.0,
      'createdAt': '2026-06-15T12:00:00.000Z',
      'cancellationReason': null,
      'items': [
        {
          'product': {
            'id': 3,
            'name': 'Papas con cheddar',
            'category': 'Comidas',
            'price': 3800.0,
            'imageUrl': null,
          },
          'quantity': 2,
          'unitPrice': 3800.0,
          'status': 'activo',
          'rejectionReason': null,
        },
      ],
    });

    expect(order.cliente.rol, RolUsuario.estudiante);
    expect(order.items.single.producto.nombre, 'Papas con cheddar');
    expect(order.modalidadPago, ModalidadPago.efectivo);
    expect(order.status, EstadoPedido.listo);
    expect(order.displayId, 'ORD-2026-042');
    expect(order.formattedPickupCode, '#BT-000042');

    final restored = Pedido.fromJson(order.toJson());
    expect(restored.status, EstadoPedido.listo);
    expect(restored.total, 7600);
    expect(restored.items.single.subtotal, 7600);
  });

  test('employee and administrator roles keep their API values', () {
    expect(RolUsuario.fromJson('empleado').apiValue, 'empleado');
    expect(RolUsuario.fromJson('administrador').label, 'Administrador');
    expect(EstadoPedido.fromJson('entregado'), EstadoPedido.entregado);
    expect(ModalidadPago.fromJson('Billetera virtual'), ModalidadPago.digital);
  });
}
