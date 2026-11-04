import 'product.dart';

class Order {
  Order(Map<Product, int> items, this.paymentMethod, this.pickupCode)
    : items = Map<Product, int>.unmodifiable(items);

  final Map<Product, int> items;
  final String paymentMethod;
  final String pickupCode;
}
