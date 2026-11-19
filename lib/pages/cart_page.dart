import 'package:flutter/material.dart';

import '../models/product.dart';

class CartPage extends StatefulWidget {
  const CartPage({
    required this.items,
    required this.onRemove,
    required this.onComplete,
    super.key,
  });

  final Map<Product, int> items;
  final ValueChanged<Product> onRemove;
  final ValueChanged<Map<Product, int>> onComplete;

  @override
  State<CartPage> createState() => _CartPageState();
}

class _CartPageState extends State<CartPage> {
  late final Map<Product, int> _items;

  @override
  void initState() {
    super.initState();
    _items = Map<Product, int>.of(widget.items);
  }

  void _removeProduct(Product product) {
    setState(() {
      _items.remove(product);
    });
    widget.onRemove(product);
  }

  @override
  Widget build(BuildContext context) {
    final productsInCart = _items.entries.toList();
    final subtotal = _items.entries.fold<int>(
      0,
      (total, entry) =>
          total + _priceAmount(entry.key.price) * entry.value,
    );

    return Scaffold(
      appBar: AppBar(title: const Text('Mi pedido')),
      body: productsInCart.isEmpty
          ? const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.shopping_bag_outlined, size: 64),
                  SizedBox(height: 12),
                  Text('Todavía no agregaste productos'),
                ],
              ),
            )
          : ListView(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
              children: [
                const _CheckoutProgress(),
                const SizedBox(height: 20),
                Text(
                  'Tu pedido',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 12),
                for (final entry in productsInCart) ...[
                  Card(
                    color: Colors.white,
                    elevation: 1,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      leading: CircleAvatar(
                        backgroundColor: entry.key.color,
                        child: Text(
                          entry.key.emoji,
                          style: const TextStyle(fontSize: 22),
                        ),
                      ),
                      title: Text(entry.key.name),
                      subtitle: Text(
                        '${entry.value} '
                        '${entry.value == 1 ? 'unidad' : 'unidades'}'
                        ' · ${entry.key.price}',
                      ),
                      trailing: IconButton(
                        tooltip: 'Eliminar ${entry.key.name}',
                        onPressed: () => _removeProduct(entry.key),
                        icon: const Icon(Icons.delete_outline),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
                const SizedBox(height: 12),
                Card(
                  color: Colors.white,
                  elevation: 1,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      children: [
                        _SummaryRow(
                          label: 'Subtotal',
                          value: _formatAmount(subtotal),
                        ),
                        const SizedBox(height: 10),
                        _SummaryRow(label: 'Descuento', value: '\$ 0'),
                        const Divider(height: 24),
                        _SummaryRow(
                          label: 'Total',
                          value: _formatAmount(subtotal),
                          emphasize: true,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
      bottomNavigationBar: productsInCart.isEmpty
          ? null
          : SafeArea(
              minimum: const EdgeInsets.all(16),
              child: ElevatedButton(
                onPressed: () => widget.onComplete(Map.of(_items)),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: const Text('Confirmar pedido'),
              ),
            ),
    );
  }
}

class _CheckoutProgress extends StatelessWidget {
  const _CheckoutProgress();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const _ProgressStep(number: '1', label: 'Datos', active: true),
        Expanded(
          child: Container(
            height: 1,
            margin: const EdgeInsets.symmetric(horizontal: 10),
            color: const Color(0xFFCBD5E1),
          ),
        ),
        const _ProgressStep(number: '2', label: 'Pago'),
      ],
    );
  }
}

class _ProgressStep extends StatelessWidget {
  const _ProgressStep({
    required this.number,
    required this.label,
    this.active = false,
  });

  final String number;
  final String label;
  final bool active;

  @override
  Widget build(BuildContext context) {
    final color = active ? const Color(0xFF1E6FFF) : const Color(0xFF94A3B8);
    return Row(
      children: [
        CircleAvatar(
          radius: 14,
          backgroundColor: active ? color : const Color(0xFFE2E8F0),
          foregroundColor: active ? Colors.white : const Color(0xFF64748B),
          child: Text(number, style: const TextStyle(fontSize: 13)),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: TextStyle(
            color: active ? const Color(0xFF0F172A) : const Color(0xFF64748B),
            fontWeight: active ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ],
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({
    required this.label,
    required this.value,
    this.emphasize = false,
  });

  final String label;
  final String value;
  final bool emphasize;

  @override
  Widget build(BuildContext context) {
    final style = emphasize
        ? Theme.of(context).textTheme.titleMedium?.copyWith(
            color: const Color(0xFF0F172A),
            fontWeight: FontWeight.w700,
          )
        : Theme.of(context).textTheme.bodyMedium;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [Text(label, style: style), Text(value, style: style)],
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
