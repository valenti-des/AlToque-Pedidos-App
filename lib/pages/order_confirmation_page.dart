import 'package:flutter/material.dart';

import '../models/order.dart';

class OrderConfirmationPage extends StatelessWidget {
  const OrderConfirmationPage(this.order, {super.key});

  final Order order;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Pedido confirmado')),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Card(
            color: colorScheme.primaryContainer,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.check_circle_outline,
                    size: 56,
                    color: colorScheme.primary,
                  ),
                  const SizedBox(height: 12),
                  Chip(
                    avatar: const Icon(Icons.schedule, size: 18),
                    label: const Text('Pedido en preparación'),
                    backgroundColor: colorScheme.surface,
                    side: BorderSide.none,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Código de retiro',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  Text(
                    order.pickupCode,
                    style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text('Forma de pago: ${order.paymentMethod}'),
                  const SizedBox(height: 8),
                  const Text(
                    'Presenta este código en el mostrador durante el recreo.',
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  FilledButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Volver al catálogo'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
