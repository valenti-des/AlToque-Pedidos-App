import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';

import '../models/pedido.dart';
import '../services/api_service.dart';

class TableroBuffetScreen extends StatefulWidget {
  const TableroBuffetScreen({
    required this.onSignOut,
    this.isAdmin = false,
    this.onManageEmployees,
    super.key,
  });

  final VoidCallback onSignOut;
  final bool isAdmin;
  final VoidCallback? onManageEmployees;

  @override
  State<TableroBuffetScreen> createState() => _TableroBuffetScreenState();
}

class _TableroBuffetScreenState extends State<TableroBuffetScreen> {
  List<Pedido> _orders = [];
  bool _isLoading = true;
  bool _isRefreshing = false;
  bool _refreshRequested = false;
  String? _error;
  String? _refreshError;
  String? _socketError;
  WebSocket? _orderSocket;
  StreamSubscription<dynamic>? _orderSubscription;
  Timer? _reconnectTimer;
  bool _isConnectingSocket = false;

  @override
  void initState() {
    super.initState();
    _loadOrders();
    _connectToOrderUpdates();
  }

  @override
  void dispose() {
    _reconnectTimer?.cancel();
    unawaited(_orderSubscription?.cancel());
    final socket = _orderSocket;
    if (socket != null) unawaited(socket.close());
    super.dispose();
  }

  Future<void> _connectToOrderUpdates() async {
    if (!mounted || _isConnectingSocket) return;
    _isConnectingSocket = true;
    try {
      final socket = await ApiService.instance.connectStaffOrderUpdates();
      if (!mounted) {
        await socket.close();
        return;
      }
      _orderSocket = socket;
      setState(() => _socketError = null);
      _orderSubscription = socket.listen(
        _handleOrderEvent,
        onError: (Object error) => _scheduleReconnect(error),
        onDone: _scheduleReconnect,
        cancelOnError: true,
      );
      await _loadOrders(showLoading: false);
    } catch (error) {
      _scheduleReconnect(error);
    } finally {
      _isConnectingSocket = false;
    }
  }

  void _handleOrderEvent(dynamic message) {
    try {
      final event = jsonDecode(message as String);
      if (event is Map<String, dynamic> &&
          event['type'] == 'orders_updated') {
        _loadOrders(showLoading: false);
      }
    } on FormatException catch (error) {
      _scheduleReconnect(error);
    } on TypeError catch (error) {
      _scheduleReconnect(error);
    }
  }

  void _scheduleReconnect([Object? error]) {
    final subscription = _orderSubscription;
    final socket = _orderSocket;
    _orderSocket = null;
    _orderSubscription = null;
    if (subscription != null) unawaited(subscription.cancel());
    if (socket != null) unawaited(socket.close());
    if (!mounted) return;
    if (error != null) {
      setState(() {
        _socketError = error.toString();
      });
    }
    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(
      const Duration(seconds: 3),
      _connectToOrderUpdates,
    );
  }

  Future<void> _loadOrders({bool showLoading = true}) async {
    if (_isRefreshing) {
      _refreshRequested = true;
      return;
    }
    _isRefreshing = true;
    if (showLoading && mounted) {
      setState(() {
        _isLoading = true;
        _error = null;
      });
    }

    try {
      final orders = await ApiService.instance.getAdminOrders();
      if (!mounted || !context.mounted) return;
      setState(() {
        _orders = orders;
        _isLoading = false;
        _error = null;
        _refreshError = null;
      });
    } catch (error) {
      if (!mounted || !context.mounted) return;
      setState(() {
        _isLoading = false;
        if (_orders.isEmpty) {
          _error = error.toString();
        } else {
          _refreshError = error.toString();
        }
      });
    } finally {
      _isRefreshing = false;
      if (_refreshRequested && mounted) {
        _refreshRequested = false;
        unawaited(_loadOrders(showLoading: false));
      }
    }
  }

  Future<void> _performAction(Future<void> Function() action) async {
    try {
      await action();
      await _loadOrders(showLoading: false);
      if (!mounted || !context.mounted) return;
      if (_refreshError != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'El cambio se guardó, pero no se pudo actualizar la lista.',
            ),
          ),
        );
        return;
      }
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Pedido actualizado.')));
    } catch (error) {
      if (!mounted || !context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se pudo actualizar el pedido: $error')),
      );
    }
  }

  Future<void> _markReady(Pedido order) async {
    await _performAction(() => ApiService.instance.markOrderReady(order.id));
  }

  Future<void> _markDelivered(Pedido order) async {
    await _performAction(
      () => ApiService.instance.markOrderDelivered(order.id),
    );
  }

  Future<void> _showCancelDialog(Pedido order) async {
    final formKey = GlobalKey<FormState>();
    final reasonController = TextEditingController();
    final reason = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Rechazar pedido ${order.formattedPickupCode}'),
        content: Form(
          key: formKey,
          child: TextFormField(
            controller: reasonController,
            autofocus: true,
            maxLength: 255,
            maxLines: 3,
            decoration: const InputDecoration(
              labelText: 'Motivo de cancelación',
              hintText: 'Por ejemplo: no hay stock disponible',
              border: OutlineInputBorder(),
            ),
            validator: (value) => value == null || value.trim().isEmpty
                ? 'Indica el motivo'
                : null,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Volver'),
          ),
          FilledButton(
            onPressed: () {
              if (formKey.currentState!.validate()) {
                Navigator.pop(context, reasonController.text.trim());
              }
            },
            child: const Text('Rechazar pedido'),
          ),
        ],
      ),
    );
    reasonController.dispose();
    if (reason == null || !mounted) return;
    await _performAction(
      () => ApiService.instance.cancelOrder(order.id, reason),
    );
  }

  Future<void> _showOrderDetails(Pedido order) async {
    var selectedOrder = order;
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(
            '${selectedOrder.displayId} · ${selectedOrder.formattedPickupCode}',
          ),
          content: SizedBox(
            width: 520,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    selectedOrder.course.isEmpty
                        ? selectedOrder.customerName
                        : '${selectedOrder.customerName} · ${selectedOrder.course}',
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  const SizedBox(height: 12),
                  for (final item in selectedOrder.items)
                    Card(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: ListTile(
                        title: Text('${item.quantity} × ${item.name}'),
                        subtitle: Text(
                          item.isRejected
                              ? item.rejectionReason ?? 'No disponible'
                              : _formatPrice(item.subtotal),
                        ),
                        trailing: item.isRejected || !selectedOrder.isPending
                            ? Chip(
                                label: Text(
                                  item.isRejected ? 'Rechazado' : 'Disponible',
                                ),
                              )
                            : TextButton(
                                onPressed: () async {
                                  final confirm = await showDialog<bool>(
                                    context: context,
                                    builder: (context) => AlertDialog(
                                      title: const Text('Marcar no disponible'),
                                      content: Text(
                                        '¿Rechazar ${item.name} en este pedido?',
                                      ),
                                      actions: [
                                        TextButton(
                                          onPressed: () =>
                                              Navigator.pop(context, false),
                                          child: const Text('Cancelar'),
                                        ),
                                        FilledButton(
                                          onPressed: () =>
                                              Navigator.pop(context, true),
                                          child: const Text('Confirmar'),
                                        ),
                                      ],
                                    ),
                                  );
                                  if (confirm != true) return;
                                  try {
                                    await ApiService.instance.rejectOrderItem(
                                      selectedOrder.id,
                                      item.productId,
                                    );
                                    await _loadOrders(showLoading: false);
                                    if (!mounted || !context.mounted) return;
                                    if (_refreshError != null) {
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                            const SnackBar(
                                              content: Text(
                                                'El producto se marcó, pero no se pudo actualizar el detalle.',
                                              ),
                                            ),
                                          );
                                      return;
                                    }
                                    final updatedOrder = _orders.firstWhere(
                                      (candidate) =>
                                          candidate.id == selectedOrder.id,
                                    );
                                    setDialogState(
                                      () => selectedOrder = updatedOrder,
                                    );
                                  } catch (error) {
                                    if (!mounted || !context.mounted) return;
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          'No se pudo rechazar el producto: $error',
                                        ),
                                      ),
                                    );
                                  }
                                },
                                child: const Text('Falta stock'),
                              ),
                      ),
                    ),
                  const SizedBox(height: 8),
                  Text(
                    'Total: ${_formatPrice(selectedOrder.total)}',
                    textAlign: TextAlign.end,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cerrar'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pedidos del buffet'),
        actions: [
          IconButton(
            tooltip: 'Actualizar pedidos',
            onPressed: () => _loadOrders(),
            icon: const Icon(Icons.refresh),
          ),
          if (widget.isAdmin && widget.onManageEmployees != null)
            IconButton(
              tooltip: 'Gestionar empleados',
              onPressed: widget.onManageEmployees,
              icon: const Icon(Icons.people_alt_outlined),
            ),
          IconButton(
            tooltip: 'Cerrar sesión',
            onPressed: widget.onSignOut,
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: Column(
        children: [
          if (_refreshError != null || _socketError != null)
            MaterialBanner(
              content: Text(
                _socketError != null
                    ? 'La conexión en tiempo real se interrumpió: $_socketError'
                    : 'No se pudieron actualizar los pedidos: $_refreshError',
              ),
              actions: [
                TextButton(
                  onPressed: _socketError != null
                      ? _connectToOrderUpdates
                      : () => _loadOrders(),
                  child: const Text('Reintentar'),
                ),
              ],
            ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                ? _ErrorState(message: _error!, onRetry: () => _loadOrders())
                : _orders.isEmpty
                ? const Center(child: Text('Todavía no hay pedidos'))
                : RefreshIndicator(
                    onRefresh: _loadOrders,
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final columns = constraints.maxWidth >= 1000
                            ? 3
                            : constraints.maxWidth >= 650
                            ? 2
                            : 1;
                        if (columns == 1) {
                          return ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: _orders.length,
                            itemBuilder: (context, index) => _OrderCard(
                              order: _orders[index],
                              onDoubleTap: () =>
                                  _showOrderDetails(_orders[index]),
                              onMarkReady: () => _markReady(_orders[index]),
                              onMarkDelivered: () =>
                                  _markDelivered(_orders[index]),
                              onCancel: () => _showCancelDialog(_orders[index]),
                              onDetails: () =>
                                  _showOrderDetails(_orders[index]),
                            ),
                          );
                        }
                        return GridView.builder(
                          padding: const EdgeInsets.all(20),
                          gridDelegate:
                              SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: columns,
                                crossAxisSpacing: 16,
                                mainAxisSpacing: 16,
                                mainAxisExtent: 400,
                              ),
                          itemCount: _orders.length,
                          itemBuilder: (context, index) => _OrderCard(
                            order: _orders[index],
                            onDoubleTap: () =>
                                _showOrderDetails(_orders[index]),
                            onMarkReady: () => _markReady(_orders[index]),
                            onMarkDelivered: () =>
                                _markDelivered(_orders[index]),
                            onCancel: () => _showCancelDialog(_orders[index]),
                            onDetails: () =>
                                _showOrderDetails(_orders[index]),
                          ),
                        );
                      },
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

class _OrderCard extends StatelessWidget {
  const _OrderCard({
    required this.order,
    required this.onDoubleTap,
    required this.onMarkReady,
    required this.onMarkDelivered,
    required this.onCancel,
    required this.onDetails,
  });

  final Pedido order;
  final VoidCallback onDoubleTap;
  final VoidCallback onMarkReady;
  final VoidCallback onMarkDelivered;
  final VoidCallback onCancel;
  final VoidCallback onDetails;

  @override
  Widget build(BuildContext context) {
    final activeItems = order.items.where((item) => !item.isRejected).toList();
    return GestureDetector(
      onDoubleTap: onDoubleTap,
      child: Card(
        margin: const EdgeInsets.only(bottom: 12),
        color: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      order.displayId,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleMedium
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                  ),
                  Chip(label: Text(_statusLabel(order.status))),
                ],
              ),
              Text(order.formattedPickupCode),
              Text(
                order.course.isEmpty
                    ? order.customerName
                    : '${order.customerName} · ${order.course}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),
              Text('Pago: ${order.modalidadPago.label}'),
              const SizedBox(height: 8),
              Text(
                activeItems.isEmpty
                    ? 'No quedan productos disponibles'
                    : activeItems
                          .take(3)
                          .map((item) => '${item.quantity} × ${item.name}')
                          .join('\n'),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),
              Text(
                'Total: ${_formatPrice(order.total)}',
                style: Theme.of(context).textTheme.titleSmall
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              if (order.isPending)
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: onCancel,
                        child: const Text('Rechazar pedido'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: FilledButton(
                        onPressed: activeItems.isEmpty ? null : onMarkReady,
                        child: const Text('Marcar como listo'),
                      ),
                    ),
                  ],
                ),
              if (order.status == EstadoPedido.listo)
                FilledButton(
                  onPressed: onMarkDelivered,
                  child: const Text('Marcar como entregado'),
                ),
              const SizedBox(height: 4),
              TextButton(
                onPressed: onDetails,
                child: const Text('Ver más · doble toque para el detalle'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('No se pudieron cargar los pedidos.'),
          const SizedBox(height: 8),
          Text(message, textAlign: TextAlign.center),
          TextButton(onPressed: onRetry, child: const Text('Reintentar')),
        ],
      ),
    ),
  );
}

String _statusLabel(EstadoPedido status) => status.label;

String _formatPrice(double amount) {
  final value = amount.round().toString();
  return '\$ ${value.replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (_) => '.')}';
}
