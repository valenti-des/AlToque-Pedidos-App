import 'dart:async';

import 'package:flutter/material.dart';

import '../models/order.dart';
import '../services/api_service.dart';

class OrderHistoryPage extends StatefulWidget {
  const OrderHistoryPage(this.orders, {super.key});

  final List<Order> orders;

  @override
  State<OrderHistoryPage> createState() => _OrderHistoryPageState();
}

class _OrderHistoryPageState extends State<OrderHistoryPage> {
  late List<Order> _orders;
  Timer? _refreshTimer;
  bool _isRefreshing = false;
  String? _refreshError;

  @override
  void initState() {
    super.initState();
    _orders = List.of(widget.orders);
    if (ApiService.instance.isCustomerAuthenticated) {
      _refreshStatuses();
    }
    _refreshTimer = Timer.periodic(
      const Duration(seconds: 8),
      (_) => _refreshStatuses(),
    );
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _refreshStatuses() async {
    final isCustomer = ApiService.instance.isCustomerAuthenticated;
    if (_isRefreshing || (!isCustomer && _orders.isEmpty)) return;
    _isRefreshing = true;
    try {
      final updated = isCustomer
          ? await ApiService.instance.getCustomerOrders()
          : await Future.wait(
              _orders.map(ApiService.instance.refreshOrderStatus),
            );
      if (!mounted) return;
      setState(() {
        _orders = updated;
        _refreshError = null;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() => _refreshError = error.toString());
    } finally {
      _isRefreshing = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mis pedidos'),
        actions: [
          IconButton(
            tooltip: 'Actualizar estados',
            onPressed: _refreshStatuses,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: _orders.isEmpty
          ? Center(
              child: _refreshError != null
                  ? Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text('No se pudo cargar tu historial.'),
                        const SizedBox(height: 8),
                        Text(_refreshError!),
                        TextButton(
                          onPressed: _refreshStatuses,
                          child: const Text('Reintentar'),
                        ),
                      ],
                    )
                  : _isRefreshing
                  ? const CircularProgressIndicator()
                  : const Text('Todavía no tienes pedidos confirmados'),
            )
          : Column(
              children: [
                if (_refreshError != null)
                  MaterialBanner(
                    content: Text(
                      'No se pudieron actualizar los estados: $_refreshError',
                    ),
                    actions: [
                      TextButton(
                        onPressed: _refreshStatuses,
                        child: const Text('Reintentar'),
                      ),
                    ],
                  ),
                Expanded(
                  child: ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: _orders.length,
                    separatorBuilder: (context, index) =>
                        const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final order = _orders[_orders.length - index - 1];
                      final itemCount = order.items.values.fold(
                        0,
                        (total, quantity) => total + quantity,
                      );
                      final status = _statusLabel(order.status);

                      return Card(
                        child: ListTile(
                          leading: const CircleAvatar(
                            child: Icon(Icons.receipt_long_outlined),
                          ),
                          title: Text('Pedido ${order.pickupCode}'),
                          subtitle: Text(
                            'Realizado: ${_formatDateTime(order.createdAt)}\n'
                            '$itemCount productos · ${order.paymentMethod} · $status',
                          ),
                          isThreeLine: true,
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
                                      Text(
                                        '${entry.value} × ${entry.key.name}',
                                      ),
                                    const SizedBox(height: 12),
                                    Text('Pago: ${order.paymentMethod}'),
                                    Text('Estado: $status'),
                                    Text(
                                      'Realizado: ${_formatDateTime(order.createdAt)}',
                                    ),
                                    Text(
                                      'Estado actualizado: ${_formatDateTime(order.statusUpdatedAt)}',
                                    ),
                                    if (order.cancellationReason != null)
                                      Text(
                                        'Motivo: ${order.cancellationReason}',
                                      ),
                                  ],
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () =>
                                        Navigator.of(context).pop(),
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
                ),
              ],
            ),
    );
  }
}

String _statusLabel(String status) => switch (status) {
  'listo' => 'Listo para retirar',
  'entregado' => 'Entregado',
  'cancelado' => 'Cancelado',
  'en_preparacion' => 'En preparación',
  _ => 'Pendiente',
};

String _formatDateTime(DateTime? value) {
  if (value == null) return 'Sin fecha';
  final date = value.toLocal();
  final day = date.day.toString().padLeft(2, '0');
  final month = date.month.toString().padLeft(2, '0');
  final hour = date.hour.toString().padLeft(2, '0');
  final minute = date.minute.toString().padLeft(2, '0');
  return '$day/$month/${date.year} $hour:$minute';
}
