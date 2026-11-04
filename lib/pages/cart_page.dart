import 'package:flutter/material.dart';

import '../models/product.dart';

class CartPage extends StatefulWidget {
  const CartPage({
    required this.items,
    required this.onRemove,
    super.key,
  });

  final Map<Product, int> items;
  final ValueChanged<Product> onRemove;

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
      appBar: AppBar(
        title: const Text('Mi pedido'),
      ),
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
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: productsInCart.length,
              separatorBuilder: (context, index) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final entry = productsInCart[index];
                final product = entry.key;
                final quantity = entry.value;

                return Card(
                  color: Colors.white,
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    leading: CircleAvatar(
                      backgroundColor: product.color,
                      child: Text(
                        product.emoji,
                        style: const TextStyle(fontSize: 22),
                      ),
                    ),
                    title: Text(product.name),
                    subtitle: Text(
                      '$quantity ${quantity == 1 ? 'unidad' : 'unidades'}'
                      ' · ${product.price}',
                    ),
                    trailing: IconButton(
                      tooltip: 'Eliminar ${product.name}',
                      onPressed: () => _removeProduct(product),
                      icon: const Icon(Icons.delete_outline),
                    ),
                  ),
                );
              },
            ),
    );
  }
}
