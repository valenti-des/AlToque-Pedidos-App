class ItemPedido {
  const ItemPedido({
    required this.productId,
    required this.name,
    required this.quantity,
    required this.unitPrice,
    required this.status,
    this.rejectionReason,
  });

  factory ItemPedido.fromJson(Map<String, dynamic> json) => ItemPedido(
    productId: json['productId'] as int,
    name: json['name'] as String,
    quantity: json['quantity'] as int,
    unitPrice: (json['unitPrice'] as num).toDouble(),
    status: json['status'] as String,
    rejectionReason: json['rejectionReason'] as String?,
  );

  final int productId;
  final String name;
  final int quantity;
  final double unitPrice;
  final String status;
  final String? rejectionReason;

  double get subtotal => quantity * unitPrice;
  bool get isRejected => status == 'rechazado';
}
