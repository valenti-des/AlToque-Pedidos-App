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
              padding: const EdgeInsets.all(16),
              children: [
                for (final entry in productsInCart) ...[
                  Card(
                    color: Colors.white,
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
                child: const Text('Completar pedido'),
              ),
            ),
    );
  }
}
