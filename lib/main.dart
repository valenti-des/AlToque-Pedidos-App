import 'package:flutter/material.dart';

import 'data/products.dart';

import 'models/product.dart';
import 'models/order.dart';
import 'pages/cart_page.dart';
import 'pages/login_page.dart';
import 'pages/order_history_page.dart';
import 'pages/payment_page.dart';
import 'services/api_service.dart';
import 'widgets/product_card.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // ignore: use_full_hex_values_for_flutter_colors
    const brandColor = Color(0x0F76F6);

    return MaterialApp(
      title: 'Al Toque Pedidos',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: brandColor),
        scaffoldBackgroundColor: const Color(0xFFFFFBF7),
        useMaterial3: true,
      ),
      home: LoginPage(_showCatalog),
    );
  }
}

void _showCatalog(BuildContext context) {
  final navigator = Navigator.of(context);
  navigator.pushReplacement(
    MaterialPageRoute<void>(
      builder: (context) => CatalogPage(onSignOut: () => _showLogin(navigator)),
    ),
  );
}

void _showLogin(NavigatorState navigator) {
  navigator.pushAndRemoveUntil(
    MaterialPageRoute<void>(builder: (context) => LoginPage(_showCatalog)),
    (route) => false,
  );
}

class CatalogPage extends StatefulWidget {
  const CatalogPage({required this.onSignOut, super.key});

  final VoidCallback onSignOut;

  @override
  State<CatalogPage> createState() => _CatalogPageState();
}

class _CatalogPageState extends State<CatalogPage> {
  String _selectedCategory = 'Todos';
  String _searchQuery = '';
  List<Product> _products = [];
  bool _isLoadingProducts = true;
  String? _productsError;
  final Map<Product, int> _cartItems = {};

  int get _cartCount =>
      _cartItems.values.fold(0, (total, quantity) => total + quantity);

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  Future<void> _loadProducts() async {
    setState(() {
      _isLoadingProducts = true;
      _productsError = null;
    });

    try {
      final products = await ApiService.instance.getProducts();
      if (!mounted) return;
      setState(() {
        _products = products;
        _isLoadingProducts = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _productsError = error.toString();
        _isLoadingProducts = false;
      });
    }
  }

  List<Product> get _filteredProducts {
    return _products.where((product) {
      final matchesCategory =
          _selectedCategory == 'Todos' || product.category == _selectedCategory;
      final query = _searchQuery.toLowerCase();
      final matchesSearch =
          product.name.toLowerCase().contains(query) ||
          product.description.toLowerCase().contains(query);

      return matchesCategory && matchesSearch;
    }).toList();
  }

  void _addToCart(Product product) {
    setState(() {
      _cartItems.update(product, (quantity) => quantity + 1, ifAbsent: () => 1);
    });
  }

  void _removeFromCart(Product product) {
    setState(() {
      _cartItems.remove(product);
    });
  }

  void _openCart() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => CartPage(
          items: _cartItems,
          onRemove: _removeFromCart,
          onComplete: _openPayment,
        ),
      ),
    );
  }

  void _openPayment(Map<Product, int> items) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => PaymentPage(
          items,
          (paymentMethod) => _createOrder(items, paymentMethod),
        ),
      ),
    );
  }

  Future<Order> _createOrder(
    Map<Product, int> items,
    String paymentMethod,
  ) async {
    final order = await ApiService.instance.createOrder(items, paymentMethod);
    if (!mounted) return order;
    setState(() {
      _cartItems.clear();
    });
    return order;
  }

  Future<void> _openOrderHistory() async {
    try {
      final orders = await ApiService.instance.getOrders();
      if (!mounted) return;
      Navigator.of(context).push(
        MaterialPageRoute<void>(builder: (context) => OrderHistoryPage(orders)),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se pudo cargar el historial: $error')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final visibleProducts = _filteredProducts;

    return Scaffold(
      drawer: Drawer(
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    ClipOval(
                      child: Image.asset(
                        'assets/images/logo.png',
                        width: 72,
                        height: 72,
                        fit: BoxFit.cover,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Al Toque',
                      style: Theme.of(context).textTheme.titleLarge
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.logout),
                title: const Text('Cerrar sesión'),
                onTap: () {
                  Navigator.of(context).pop();
                  widget.onSignOut();
                },
              ),
            ],
          ),
        ),
      ),
      appBar: AppBar(
        title: Row(
          children: [
            Builder(
              builder: (context) => IconButton(
                tooltip: 'Abrir menú',
                onPressed: () => Scaffold.of(context).openDrawer(),
                padding: EdgeInsets.zero,
                icon: Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.16),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: ClipOval(
                    child: Image.asset(
                      'assets/images/logo.png',
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            const Text('Al Toque'),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Mis pedidos',
            onPressed: _openOrderHistory,
            icon: const Icon(Icons.receipt_long_outlined),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Center(
              child: Badge(
                isLabelVisible: _cartCount > 0,
                label: Text('$_cartCount'),
                child: IconButton(
                  tooltip: 'Productos agregados',
                  onPressed: _openCart,
                  icon: const Icon(Icons.shopping_bag_outlined),
                ),
              ),
            ),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              onChanged: (value) {
                setState(() {
                  _searchQuery = value.trim();
                });
              },
              decoration: InputDecoration(
                hintText: 'Buscar productos...',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 22),
            Text(
              '¿Qué se te antoja?',
              style: Theme.of(context).textTheme.headlineSmall
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              'Elegí algo rico para disfrutar',
              style: Theme.of(context).textTheme.bodyMedium
                  ?.copyWith(color: Colors.black54),
            ),
            const SizedBox(height: 18),
            SizedBox(
              height: 42,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: categories.length,
                separatorBuilder: (context, index) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  final category = categories[index];
                  return ChoiceChip(
                    label: Text(category),
                    selected: _selectedCategory == category,
                    onSelected: (selected) {
                      setState(() {
                        _selectedCategory = category;
                      });
                    },
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Nuestro menú',
                  style: Theme.of(context).textTheme.titleLarge
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
                Text(
                  '${visibleProducts.length} productos',
                  style: Theme.of(context).textTheme.bodySmall
                      ?.copyWith(color: Colors.black54),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Expanded(
              child: _isLoadingProducts
                  ? const Center(child: Text('Conectando con el menú...'))
                  : _productsError != null
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text(
                            'No se pudo conectar con el servidor local.',
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 8),
                          TextButton(
                            onPressed: _loadProducts,
                            child: const Text('Volver a intentar'),
                          ),
                        ],
                      ),
                    )
                  : visibleProducts.isEmpty
                  ? const Center(
                      child: Text('No encontramos productos con esa búsqueda'),
                    )
                  : GridView.builder(
                      padding: const EdgeInsets.only(bottom: 20),
                      itemCount: visibleProducts.length,
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            crossAxisSpacing: 14,
                            mainAxisSpacing: 14,
                            childAspectRatio: 0.68,
                          ),
                      itemBuilder: (context, index) {
                        final product = visibleProducts[index];
                        return ProductCard(product, () => _addToCart(product));
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
