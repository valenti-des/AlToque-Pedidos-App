import 'product.dart';

class Order {
  Order({
    required this.id,
    required Map<Product, int> items,
    required this.paymentMethod,
    required this.pickupCode,
    required this.trackingToken,
    required this.customerName,
    required this.course,
    this.status = 'pendiente',
    this.cancellationReason,
  }) : items = Map<Product, int>.unmodifiable(items);

  final int id;
  final Map<Product, int> items;
  final String paymentMethod;
  final String pickupCode;
  final String trackingToken;
  final String customerName;
  final String course;
  final String status;
  final String? cancellationReason;

  bool get isPending => status == 'pendiente' || status == 'en_preparacion';

  Order copyWith({String? status, String? cancellationReason}) => Order(
    id: id,
    items: items,
    paymentMethod: paymentMethod,
    pickupCode: pickupCode,
    trackingToken: trackingToken,
    customerName: customerName,
    course: course,
    status: status ?? this.status,
    cancellationReason: cancellationReason ?? this.cancellationReason,
  );
}
