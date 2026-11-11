import 'product.dart';

class Order {
  Order(Map<Product, int> items, this.paymentMethod, this.pickupCode)
    : items = Map<Product, int>.unmodifiable(items);

  factory Order.fromJson(Map<String, dynamic> json) {
    final items = <Product, int>{};
    for (final item in json['items'] as List<dynamic>) {
      final data = item as Map<String, dynamic>;
      final product = Product(
        id: data['productId'] as int,
        name: data['name'] as String,
      );
      items[product] = data['quantity'] as int;
    }

    return Order(
      items,
      json['paymentMethod'] as String,
      json['pickupCode'] as String,
    );
  }

  final Map<Product, int> items;
  final String paymentMethod;
  final String pickupCode;
}
