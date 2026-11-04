import 'package:flutter/material.dart';

import '../models/order.dart';

class OrderHistoryPage extends StatelessWidget {
  const OrderHistoryPage(this.orders, {super.key});

  final List<Order> orders;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Mis pedidos')),
      body: orders.isEmpty
          ? const Center(child: Text('Todavía no tienes pedidos confirmados'))
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: orders.length,
              separatorBuilder: (context, index) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final order = orders[orders.length - index - 1];
                final itemCount = order.items.values.fold(
                  0,
                  (total, quantity) => total + quantity,
                );

                return Card(
                  color: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: ListTile(
                    leading: const CircleAvatar(
                      child: Icon(Icons.receipt_long_outlined),
                    ),
                    title: Text('Pedido ${order.pickupCode}'),
                    subtitle: Text(
                      '$itemCount productos · ${order.paymentMethod}'
                      ' · En preparación',
                    ),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      showDialog<void>(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: Text('Pedido ${order.pickupCode}'),
                          content: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              for (final entry in order.items.entries)
                                Text('${entry.value} × ${entry.key.name}'),
                              const SizedBox(height: 12),
                              Text('Pago: ${order.paymentMethod}'),
                              const Text('Estado: En preparación'),
                            ],
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.of(context).pop(),
                              child: const Text('Cerrar'),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                );
              },
            ),
    );
  }
}
