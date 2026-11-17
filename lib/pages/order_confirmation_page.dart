import 'dart:async';

import 'package:flutter/material.dart';

import '../models/order.dart';
import '../services/api_service.dart';

class OrderConfirmationPage extends StatefulWidget {
  const OrderConfirmationPage(this.order, {super.key});

  final Order order;

  @override
  State<OrderConfirmationPage> createState() => _OrderConfirmationPageState();
}

class _OrderConfirmationPageState extends State<OrderConfirmationPage> {
  late Order _order;
  Timer? _statusTimer;
  bool _isRefreshing = false;
  String? _refreshError;

  @override
  void initState() {
    super.initState();
    _order = widget.order;
    _statusTimer = Timer.periodic(
      const Duration(seconds: 8),
      (_) => _refreshStatus(),
    );
  }

  @override
  void dispose() {
    _statusTimer?.cancel();
    super.dispose();
  }

  Future<void> _refreshStatus() async {
    if (_isRefreshing || !_order.isPending) return;
    _isRefreshing = true;
    try {
      final updated = await ApiService.instance.refreshOrderStatus(_order);
      if (!mounted) return;
      setState(() {
        _order = updated;
        _refreshError = null;
      });
      if (!_order.isPending) _statusTimer?.cancel();
    } catch (error) {
      if (!mounted) return;
      setState(() => _refreshError = error.toString());
    } finally {
      _isRefreshing = false;
    }
  }

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
                    label: Text(_statusLabel(_order.status)),
                    backgroundColor: colorScheme.surface,
                    side: BorderSide.none,
                  ),
                  if (_refreshError != null)
                    Text(
                      'No se pudo actualizar el estado: $_refreshError',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  if (_order.cancellationReason != null)
                    Text('Motivo: ${_order.cancellationReason}'),
                  const SizedBox(height: 16),
                  Text(
                    'Código de retiro',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  Text(
                    _order.pickupCode,
                    style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text('Forma de pago: ${_order.paymentMethod}'),
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

String _statusLabel(String status) => switch (status) {
  'listo' => 'Listo para retirar',
  'entregado' => 'Entregado',
  'cancelado' => 'Pedido cancelado',
  'en_preparacion' => 'En preparación',
  _ => 'Pedido pendiente',
};
