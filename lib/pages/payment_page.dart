import 'package:flutter/material.dart';

import '../models/order.dart';
import '../models/product.dart';
import 'order_confirmation_page.dart';

class PaymentPage extends StatefulWidget {
  const PaymentPage(this.items, this.onSelectPayment, {super.key});

  final Map<Product, int> items;
  final Future<Order> Function(String) onSelectPayment;

  @override
  State<PaymentPage> createState() => _PaymentPageState();
}

class _PaymentPageState extends State<PaymentPage> {
  bool _isSubmitting = false;

  Future<void> _selectPayment(String method) async {
    if (_isSubmitting) return;
    setState(() => _isSubmitting = true);
    try {
      final order = await widget.onSelectPayment(method);
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute<void>(
          builder: (context) => OrderConfirmationPage(order),
        ),
        (route) => route.isFirst,
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se pudo registrar el pedido: $error')),
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
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
              '${widget.items.values.fold(0, (total, quantity) => total + quantity)} '
              'productos en el pedido',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: _isSubmitting
                  ? null
                  : () => _selectPayment('En el buffet'),
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
              onPressed: _isSubmitting
                  ? null
                  : () => _selectPayment('Billetera virtual'),
              icon: const Icon(Icons.account_balance_wallet_outlined),
              label: const Text('Billetera virtual'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 18),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
            if (_isSubmitting) ...[
              const SizedBox(height: 12),
              const Center(child: CircularProgressIndicator()),
            ],
          ],
        ),
      ),
    );
  }
}
