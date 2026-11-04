import 'package:flutter/material.dart';

import '../models/order.dart';
import '../models/product.dart';
import 'order_confirmation_page.dart';

class PaymentPage extends StatelessWidget {
  const PaymentPage(this.items, this.onSelectPayment, {super.key});

  final Map<Product, int> items;
  final Order Function(String) onSelectPayment;

  void _selectPayment(BuildContext context, String method) {
    final order = onSelectPayment(method);
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute<void>(
        builder: (context) => OrderConfirmationPage(order),
      ),
      (route) => route.isFirst,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Elegir forma de pago')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              '¿Cómo querés pagar?',
              style: Theme.of(context).textTheme.headlineSmall
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'La selección solo registra tu preferencia. '
              'El pago se realiza en el buffet.',
            ),
            const SizedBox(height: 8),
            Text(
              '${items.values.fold(0, (total, quantity) => total + quantity)} '
              'productos en el pedido',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: () => _selectPayment(context, 'En el buffet'),
              icon: const Icon(Icons.payments_outlined),
              label: const Text('Pagar en físico'),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 18),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
            const SizedBox(height: 14),
            OutlinedButton.icon(
              onPressed: () => _selectPayment(context, 'Billetera virtual'),
              icon: const Icon(Icons.account_balance_wallet_outlined),
              label: const Text('Billetera virtual'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 18),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
