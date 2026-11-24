import 'package:flutter/material.dart';

import 'data/products.dart';

import 'models/auth_session.dart';
import 'models/product.dart';
import 'models/order.dart';
import 'pages/cart_page.dart';
import 'pages/gestion_empleados_screen.dart';
import 'pages/login_page.dart';
import 'pages/order_history_page.dart';
import 'pages/payment_page.dart';
import 'pages/product_detail_page.dart';
import 'pages/tablero_buffet_screen.dart';
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
    const brandColor = Color(0xFF0F76F6);

    return MaterialApp(
      title: 'AlToque Pedidos',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: brandColor),
        scaffoldBackgroundColor: const Color(0xFFFFFBF7),
        useMaterial3: true,
      ),
      home: LoginPage(
        onCustomerContinue: _showCatalog,
        onStaffLogin: _showStaffArea,
      ),
    );
  }
}

void _showCatalog(BuildContext context, String customerName) {
  final navigator = Navigator.of(context);
  navigator.pushReplacement(
    MaterialPageRoute<void>(
      builder: (context) => CatalogPage(
        customerName: customerName,
        onSignOut: () => _showLogin(navigator),
      ),
    ),
  );
}

void _showStaffArea(BuildContext context, AuthSession session) {
  final navigator = Navigator.of(context);
  void onSignOut() => _showLogin(navigator);
  navigator.pushReplacement(
    MaterialPageRoute<void>(
      builder: (_) => TableroBuffetScreen(
        isAdmin: session.isAdmin,
        onSignOut: onSignOut,
        onManageEmployees: session.isAdmin
            ? () => navigator.push(
                MaterialPageRoute<void>(
                  builder: (_) => GestionEmpleadosScreen(onSignOut: onSignOut),
                ),
              )
            : null,
      ),
    ),
  );
}

void _showLogin(NavigatorState navigator) {
  ApiService.instance.logout();
  navigator.pushAndRemoveUntil(
    MaterialPageRoute<void>(
      builder: (context) => LoginPage(
        onCustomerContinue: _showCatalog,
        onStaffLogin: _showStaffArea,
      ),
    ),
    (route) => false,
  );
}

class CatalogPage extends StatefulWidget {
  const CatalogPage({
    required this.customerName,
    required this.onSignOut,
    super.key,
  });

  final String customerName;
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
  final List<Order> _orders = [];

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

  void _openProductDetail(Product product) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => ProductDetailPage(
          product: product,
          onAdd: (quantity) {
            setState(() {
              _cartItems.update(
                product,
                (current) => current + quantity,
                ifAbsent: () => quantity,
              );
            });
          },
        ),
      ),
    );
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
          customerName: widget.customerName,
          onSelectPayment: (paymentMethod) =>
              _createOrder(items, paymentMethod),
        ),
      ),
    );
  }

  Future<Order> _createOrder(
    Map<Product, int> items,
    String paymentMethod,
  ) async {
    final order = await ApiService.instance.createOrder(
      items,
      paymentMethod,
      widget.customerName,
    );
    if (!mounted) return order;
    setState(() {
      _cartItems.clear();
      _orders.add(order);
    });
    return order;
  }

  void _openOrderHistory() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => OrderHistoryPage(List.unmodifiable(_orders)),
      ),
    );
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
        backgroundColor: const Color(0xFFF9FBFF),
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        leading: Builder(
          builder: (context) => IconButton(
            tooltip: 'Abrir menú',
            onPressed: () => Scaffold.of(context).openDrawer(),
            icon: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFF0877F9), width: 2),
              ),
              child: ClipOval(
                child: Image.asset('assets/images/logo.png', fit: BoxFit.cover),
              ),
            ),
          ),
        ),
        titleSpacing: 0,
        title: const Text(
          'Al Toque',
          style: TextStyle(
            color: Color(0xFF0877F9),
            fontWeight: FontWeight.w900,
          ),
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
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 118,
              width: double.infinity,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF0877F9), Color(0xFF2E9EF5)],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Stack(
                children: [
                  const Positioned(
                    left: 18,
                    top: 18,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'CLÁSICO DEL BUFFET',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.5,
                          ),
                        ),
                        SizedBox(height: 6),
                        Text(
                          'Lo rico,\nlisto para vos.',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            height: 1.05,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Positioned(
                    right: 12,
                    bottom: -8,
                    child: Text('🍽️', style: TextStyle(fontSize: 82)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            TextField(
              onChanged: (value) {
                setState(() {
                  _searchQuery = value.trim();
                });
              },
              decoration: InputDecoration(
                hintText: '¿Qué querés pedir hoy?',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: Color(0xFFE1E7EF)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: Color(0xFFE1E7EF)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: Color(0xFF0877F9)),
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
                          Text(
                            _productsError ?? 'Error desconocido.',
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
                            childAspectRatio: 0.70,
                          ),
                      itemBuilder: (context, index) {
                        final product = visibleProducts[index];
                        return ProductCard(
                          product,
                          () => _addToCart(product),
                          onOpen: () => _openProductDetail(product),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: NavigationBar(
        height: 68,
        backgroundColor: Colors.white,
        indicatorColor: const Color(0xFFE8F2FF),
        selectedIndex: 0,
        onDestinationSelected: (index) {
          if (index == 2) _openCart();
          if (index == 3) _openOrderHistory();
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Inicio',
          ),
          NavigationDestination(
            icon: Icon(Icons.grid_view_outlined),
            selectedIcon: Icon(Icons.grid_view),
            label: 'Categorías',
          ),
          NavigationDestination(
            icon: Icon(Icons.shopping_bag_outlined),
            selectedIcon: Icon(Icons.shopping_bag),
            label: 'Pedido',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Mis pedidos',
          ),
        ],
      ),
    );
  }
}
