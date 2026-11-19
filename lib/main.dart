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
import 'widgets/product_detail_sheet.dart';

void main() {
  runApp(const MyApp());
}

const brandBlue = Color(0xFF1E6FFF);
const pageBackground = Color(0xFFF8FAFC);
const inkColor = Color(0xFF0F172A);
const mutedColor = Color(0xFF64748B);

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Al Toque Pedidos',
      theme: ThemeData(
        colorScheme: const ColorScheme.light(
          primary: brandBlue,
          onPrimary: Colors.white,
          secondary: Color(0xFF22C55E),
          error: Color(0xFFEF4444),
          surface: Colors.white,
          onSurface: inkColor,
        ),
        scaffoldBackgroundColor: pageBackground,
        appBarTheme: const AppBarTheme(
          backgroundColor: brandBlue,
          foregroundColor: Colors.white,
          elevation: 0,
          centerTitle: false,
        ),
        cardTheme: CardThemeData(
          color: Colors.white,
          elevation: 1,
          shadowColor: Colors.black.withValues(alpha: 0.04),
          margin: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          hintStyle: const TextStyle(color: mutedColor),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 14,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: brandBlue, width: 1.5),
          ),
        ),
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          backgroundColor: Colors.white,
          selectedItemColor: brandBlue,
          unselectedItemColor: mutedColor,
          type: BottomNavigationBarType.fixed,
          elevation: 8,
        ),
        textTheme: const TextTheme(
          headlineSmall: TextStyle(
            color: inkColor,
            fontWeight: FontWeight.w700,
          ),
          titleLarge: TextStyle(color: inkColor, fontWeight: FontWeight.w700),
          titleMedium: TextStyle(color: inkColor, fontWeight: FontWeight.w600),
          bodyMedium: TextStyle(color: mutedColor),
          bodySmall: TextStyle(color: mutedColor),
        ),
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
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  String _selectedCategory = 'Todos';
  String _searchQuery = '';
  int _selectedTab = 0;
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
      await Navigator.of(context).push(
        MaterialPageRoute<void>(builder: (context) => OrderHistoryPage(orders)),
      );
      if (mounted && _selectedTab == 1) {
        setState(() => _selectedTab = 0);
      }
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
      key: _scaffoldKey,
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
        toolbarHeight: 68,
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
            const Text(
              'AlToque',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
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
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(108),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
            child: Column(
              children: [
                SizedBox(
                  height: 46,
                  child: TextField(
                    onChanged: (value) => setState(() {
                      _searchQuery = value.trim();
                    }),
                    decoration: const InputDecoration(
                      hintText: 'Buscar productos...',
                      prefixIcon: Icon(Icons.search),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  height: 38,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: categories.length,
                    separatorBuilder: (context, index) =>
                        const SizedBox(width: 8),
                    itemBuilder: (context, index) {
                      final category = categories[index];
                      final selected = _selectedCategory == category;
                      return ChoiceChip(
                        label: Text(category),
                        selected: selected,
                        showCheckmark: false,
                        backgroundColor: Colors.white.withValues(alpha: 0.14),
                        selectedColor: Colors.white,
                        labelStyle: TextStyle(
                          color: selected ? brandBlue : Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                        side: BorderSide.none,
                        onSelected: (_) => setState(() {
                          _selectedCategory = category;
                        }),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '¿Qué se te antoja?',
              style: Theme.of(context).textTheme.headlineSmall
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              'Elegí algo rico para disfrutar',
                style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 18),
            const SizedBox(height: 8),
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
                      ?.copyWith(color: mutedColor),
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
                        return ProductCard(
                          product,
                          () => _addToCart(product),
                          onTap: () => _showProductDetails(product),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedTab,
        onTap: (index) {
          if (index == 0) {
            setState(() => _selectedTab = 0);
          } else if (index == 1) {
            setState(() => _selectedTab = 1);
            _openOrderHistory();
          } else {
            _scaffoldKey.currentState?.openDrawer();
          }
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home),
            label: 'Inicio',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.receipt_long_outlined),
            label: 'Mis pedidos',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            label: 'Cuenta',
          ),
        ],
      ),
    );
  }

  void _showProductDetails(Product product) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => ProductDetailSheet(
        product: product,
        onAdd: (quantity) {
          for (var index = 0; index < quantity; index++) {
            _addToCart(product);
          }
        },
      ),
    );
  }
}
