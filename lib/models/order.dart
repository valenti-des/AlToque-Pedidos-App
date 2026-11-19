import 'product.dart';

String _formatPrice(double price) => price
    .toStringAsFixed(0)
    .replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (_) => '.');

class Order {
  Order({
    required this.id,
    required Map<Product, int> items,
    required this.paymentMethod,
    required this.pickupCode,
    this.trackingToken,
    required this.customerName,
    required this.course,
    this.status = 'pendiente',
    this.cancellationReason,
    this.createdAt,
  }) : items = Map<Product, int>.unmodifiable(items);

  final int id;
  final Map<Product, int> items;
  final String paymentMethod;
  final String pickupCode;
  final String? trackingToken;
  final String customerName;
  final String course;
  final String status;
  final String? cancellationReason;
  final DateTime? createdAt;

  factory Order.fromJson(Map<String, dynamic> json) {
    final rawItems = json['items'];
    if (rawItems is! List) {
      throw const FormatException('El pedido no contiene productos válidos.');
    }

    final items = <Product, int>{};
    for (final rawItem in rawItems) {
      if (rawItem is! Map<String, dynamic>) {
        throw const FormatException('El pedido contiene un producto inválido.');
      }
      final product = Product(
        id: rawItem['productId'] as int,
        name: rawItem['name'] as String,
        description: rawItem['description'] as String? ?? '',
        category: rawItem['category'] as String? ?? '',
        emoji: rawItem['emoji'] as String? ?? '',
        price: rawItem['price'] is num
            ? '\$ ${_formatPrice((rawItem['price'] as num).toDouble())}'
            : '',
      );
      items[product] = rawItem['quantity'] as int;
    }

    return Order(
      id: json['id'] as int,
      items: items,
      paymentMethod: json['paymentMethod'] as String,
      pickupCode: json['pickupCode'] as String,
      customerName: json['customerName'] as String,
      course: json['course'] as String,
      status: json['status'] as String,
      cancellationReason: json['cancellationReason'] as String?,
      createdAt: json['createdAt'] is String
          ? DateTime.tryParse(json['createdAt'] as String)
          : null,
    );
  }

  bool get isPending => status == 'pendiente' || status == 'en_preparacion';

  Order copyWith({
    String? status,
    String? cancellationReason,
    DateTime? createdAt,
  }) => Order(
    id: id,
    items: items,
    paymentMethod: paymentMethod,
    pickupCode: pickupCode,
    trackingToken: trackingToken,
    customerName: customerName,
    course: course,
    status: status ?? this.status,
    cancellationReason: cancellationReason ?? this.cancellationReason,
    createdAt: createdAt,
  );
}
