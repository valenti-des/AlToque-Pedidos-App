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
  String _paymentMethod = 'En el buffet';

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
    final total = widget.items.entries.fold<int>(
      0,
      (sum, entry) =>
          sum + _priceAmount(entry.key.price) * entry.value,
    );
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
            Text(
              'Elige cómo vas a abonar tu pedido.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 8),
            Text(
              '${widget.items.values.fold(0, (total, quantity) => total + quantity)} '
              'productos en el pedido',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 24),
            Card(
              color: Colors.white,
              elevation: 1,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
              child: Column(
                children: [
                  RadioListTile<String>(
                    value: 'En el buffet',
                    groupValue: _paymentMethod,
                    onChanged: _isSubmitting
                        ? null
                        : (value) => setState(() => _paymentMethod = value!),
                    title: const Text('Efectivo al retirar'),
                    secondary: const Icon(Icons.payments_outlined),
                    activeColor: Theme.of(context).colorScheme.primary,
                  ),
                  const Divider(height: 1, indent: 16, endIndent: 16),
                  RadioListTile<String>(
                    value: 'Billetera virtual',
                    groupValue: _paymentMethod,
                    onChanged: _isSubmitting
                        ? null
                        : (value) => setState(() => _paymentMethod = value!),
                    title: const Text('Transferencia'),
                    secondary: const Icon(Icons.account_balance_outlined),
                    activeColor: Theme.of(context).colorScheme.primary,
                  ),
                ],
              ),
            ),
            const Spacer(),
            FilledButton(
              onPressed: _isSubmitting ? null : () => _selectPayment(_paymentMethod),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 17),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: Text('Confirmar pedido · ${_formatAmount(total)}'),
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

int _priceAmount(String price) =>
    int.tryParse(price.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;

String _formatAmount(int amount) {
  final formatted = amount.toString().replaceAllMapped(
    RegExp(r'\B(?=(\d{3})+(?!\d))'),
    (_) => '.',
  );
  return '\$ $formatted';
}
