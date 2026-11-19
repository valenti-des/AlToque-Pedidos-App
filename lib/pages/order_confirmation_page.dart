import 'package:flutter/material.dart';

import '../models/order.dart';

class OrderConfirmationPage extends StatelessWidget {
  const OrderConfirmationPage(this.order, {super.key});

  final Order order;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final normalizedStatus = order.status.toLowerCase();
    final isCancelled = normalizedStatus.contains('cancel') ||
      normalizedStatus.contains('rechaz');
    final isReady = normalizedStatus.contains('listo') ||
      normalizedStatus.contains('entreg');
    final statusLabel = isCancelled
      ? 'Pedido cancelado'
      : isReady
      ? normalizedStatus.contains('entreg')
        ? 'Pedido entregado'
        : '¡Tu pedido está listo!'
      : 'Pedido en preparación';
    final statusColor = isCancelled
      ? const Color(0xFFEF4444)
      : isReady
      ? const Color(0xFF22C55E)
      : const Color(0xFFF59E0B);
    final progress = isCancelled ? 0 : isReady ? 2 : 1;

    return Scaffold(
      appBar: AppBar(title: const Text('Pedido confirmado')),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Card(
            clipBehavior: Clip.antiAlias,
            color: Colors.white,
            elevation: 1,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: double.infinity,
                  color: colorScheme.primary,
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      const Icon(
                        Icons.receipt_long_outlined,
                        size: 42,
                        color: Colors.white,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        statusLabel,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
                  child: Column(
                    children: [
                      DecoratedBox(
                        decoration: BoxDecoration(
                          color: statusColor.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(30),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 8,
                          ),
                          child: Text(
                            statusLabel,
                            style: TextStyle(
                              color: statusColor,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 18),
                      Text(
                        'CÓDIGO DE RETIRO',
                        style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          color: const Color(0xFF64748B),
                          letterSpacing: 1.2,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        order.pickupCode,
                        style: Theme.of(context).textTheme.displaySmall?.copyWith(
                          color: const Color(0xFF0F172A),
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 22),
                      _OrderProgress(currentStep: progress, cancelled: isCancelled),
                      const SizedBox(height: 12),
                      ExpansionTile(
                        tilePadding: EdgeInsets.zero,
                        title: const Text('Detalle del pedido'),
                        children: [
                          for (final entry in order.items.entries)
                            ListTile(
                              dense: true,
                              contentPadding: EdgeInsets.zero,
                              title: Text(entry.key.name),
                              trailing: Text('× ${entry.value}'),
                            ),
                          ListTile(
                            dense: true,
                            contentPadding: EdgeInsets.zero,
                            title: const Text('Forma de pago'),
                            trailing: Text(order.paymentMethod),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Presenta este código en el mostrador durante el recreo.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Color(0xFF64748B)),
                      ),
                      const SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton(
                          onPressed: () => Navigator.of(context).pop(),
                          child: const Text('Volver al catálogo'),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _OrderProgress extends StatelessWidget {
  const _OrderProgress({required this.currentStep, required this.cancelled});

  final int currentStep;
  final bool cancelled;

  @override
  Widget build(BuildContext context) {
    const labels = ['Recibido', 'Preparando', 'Listo'];
    final color = cancelled
        ? const Color(0xFFEF4444)
        : const Color(0xFF1E6FFF);
    return Row(
      children: [
        for (var index = 0; index < labels.length; index++) ...[
          Column(
            children: [
              CircleAvatar(
                radius: 13,
                backgroundColor: index <= currentStep
                    ? color
                    : const Color(0xFFE2E8F0),
                child: Icon(
                  index < currentStep
                      ? Icons.check
                      : Icons.circle,
                  size: index < currentStep ? 15 : 8,
                  color: index <= currentStep
                      ? Colors.white
                      : const Color(0xFF94A3B8),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                labels[index],
                style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
              ),
            ],
          ),
          if (index < labels.length - 1)
            Expanded(
              child: Container(
                height: 2,
                margin: const EdgeInsets.only(bottom: 20),
                color: index < currentStep ? color : const Color(0xFFE2E8F0),
              ),
            ),
        ],
      ],
    );
  }
}
