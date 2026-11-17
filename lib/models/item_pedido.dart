import 'producto.dart';

class ItemPedido {
  const ItemPedido({
    required this.producto,
    required this.quantity,
    required this.unitPrice,
    required this.status,
    this.rejectionReason,
  });

  factory ItemPedido.fromJson(Map<String, dynamic> json) {
    final productData = json['product'] ?? json;
    if (productData is! Map<String, dynamic>) {
      throw const FormatException('El producto del pedido es inválido.');
    }
    final productJson = <String, dynamic>{
      ...productData,
      if (!productData.containsKey('price') && json['unitPrice'] is num)
        'price': json['unitPrice'],
    };
    final unitPrice = json['unitPrice'] ?? productJson['price'];
    final quantity = json['quantity'];
    final status = json['status'];
    if (unitPrice is! num || quantity is! int || status is! String) {
      throw const FormatException('Los datos del ítem del pedido son inválidos.');
    }
    return ItemPedido(
      producto: Producto.fromJson(productJson),
      quantity: quantity,
      unitPrice: unitPrice.toDouble(),
      status: status,
      rejectionReason: json['rejectionReason'] as String?,
    );
  }

  final Producto producto;
  final int quantity;
  final double unitPrice;
  final String status;
  final String? rejectionReason;

  int get productId => producto.id;
  String get name => producto.nombre;
  double get subtotal => quantity * unitPrice;
  bool get isRejected => status == 'rechazado';

  Map<String, dynamic> toJson() => {
    'product': producto.toJson(),
    'quantity': quantity,
    'unitPrice': unitPrice,
    'status': status,
    'rejectionReason': rejectionReason,
  };
}
