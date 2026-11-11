import 'item_pedido.dart';

class Pedido {
  const Pedido({
    required this.id,
    required this.pickupCode,
    required this.customerName,
    required this.course,
    required this.paymentMethod,
    required this.status,
    required this.total,
    required this.items,
    this.cancellationReason,
  });

  factory Pedido.fromJson(Map<String, dynamic> json) => Pedido(
    id: json['id'] as int,
    pickupCode: json['pickupCode'] as String,
    customerName: json['customerName'] as String,
    course: json['course'] as String,
    paymentMethod: json['paymentMethod'] as String,
    status: json['status'] as String,
    total: (json['total'] as num).toDouble(),
    items: (json['items'] as List<dynamic>)
        .map((item) => ItemPedido.fromJson(item as Map<String, dynamic>))
        .toList(),
    cancellationReason: json['cancellationReason'] as String?,
  );

  final int id;
  final String pickupCode;
  final String customerName;
  final String course;
  final String paymentMethod;
  final String status;
  final double total;
  final List<ItemPedido> items;
  final String? cancellationReason;

  bool get isPending => status == 'pendiente' || status == 'en_preparacion';
}
