import 'item_pedido.dart';
import 'usuario.dart';

enum EstadoPedido {
  pendiente('pendiente', 'Pendiente'),
  enPreparacion('en_preparacion', 'En preparación'),
  listo('listo', 'Listo'),
  entregado('entregado', 'Entregado'),
  cancelado('cancelado', 'Cancelado');

  const EstadoPedido(this.apiValue, this.label);

  final String apiValue;
  final String label;

  static EstadoPedido fromJson(Object? value) {
    for (final estado in EstadoPedido.values) {
      if (estado.apiValue == value) return estado;
    }
    throw FormatException('Estado de pedido inválido: $value');
  }
}

enum ModalidadPago {
  efectivo('En el buffet', 'Efectivo'),
  digital('Billetera virtual', 'Digital');

  const ModalidadPago(this.apiValue, this.label);

  final String apiValue;
  final String label;

  static ModalidadPago fromJson(Object? value) => switch (value) {
    'En el buffet' || 'Efectivo' || 'efectivo' => ModalidadPago.efectivo,
    'Billetera virtual' || 'Digital' || 'digital' => ModalidadPago.digital,
    _ => throw FormatException('Modalidad de pago inválida: $value'),
  };
}

class Pedido {
  const Pedido({
    required this.id,
    required this.pickupCode,
    required this.cliente,
    required this.modalidadPago,
    required this.status,
    required this.total,
    required this.items,
    required this.createdAt,
    this.statusUpdatedAt,
    this.cancellationReason,
  });

  factory Pedido.fromJson(Map<String, dynamic> json) {
    final rawCliente = json['customer'] ?? json['cliente'];
    final clienteJson = rawCliente is Map<String, dynamic>
        ? rawCliente
        : {
            'id': json['customerId'] ?? 0,
            'name': json['customerName'],
            'email': json['customerEmail'] ?? '',
            'role': 'cliente',
            'course': json['course'],
          };
    final rawItems = json['items'];
    final createdAt = json['createdAt'];
    final statusUpdatedAt = json['statusUpdatedAt'];
    if (json['id'] is! int ||
        json['pickupCode'] is! String ||
        rawItems is! List ||
        createdAt is! String ||
        (statusUpdatedAt != null && statusUpdatedAt is! String) ||
        json['total'] is! num) {
      throw const FormatException('Los datos del pedido son inválidos.');
    }

    return Pedido(
      id: json['id'] as int,
      pickupCode: json['pickupCode'] as String,
      cliente: Usuario.fromJson(clienteJson),
      modalidadPago: ModalidadPago.fromJson(json['paymentMethod']),
      status: EstadoPedido.fromJson(json['status']),
      total: (json['total'] as num).toDouble(),
      items: rawItems
          .map((item) => ItemPedido.fromJson(item as Map<String, dynamic>))
          .toList(),
      createdAt: DateTime.parse(createdAt),
      statusUpdatedAt: statusUpdatedAt == null
          ? null
          : DateTime.parse(statusUpdatedAt as String),
      cancellationReason: json['cancellationReason'] as String?,
    );
  }

  final int id;
  final String pickupCode;
  final Usuario cliente;
  final ModalidadPago modalidadPago;
  final EstadoPedido status;
  final double total;
  final List<ItemPedido> items;
  final DateTime createdAt;
  final DateTime? statusUpdatedAt;
  final String? cancellationReason;

  String get customerName => cliente.nombre;
  String get course => cliente.cursoODni ?? '';
  String get displayId =>
      'ORD-${createdAt.year}-${id.toString().padLeft(3, '0')}';
  String get formattedPickupCode =>
      pickupCode.startsWith('#BT-') ? pickupCode : '#BT-$pickupCode';
  bool get isPending =>
      status == EstadoPedido.pendiente || status == EstadoPedido.enPreparacion;

  Map<String, dynamic> toJson() => {
    'id': id,
    'pickupCode': pickupCode,
    'customer': cliente.toJson(),
    'paymentMethod': modalidadPago.apiValue,
    'status': status.apiValue,
    'total': total,
    'items': items.map((item) => item.toJson()).toList(),
    'createdAt': createdAt.toUtc().toIso8601String(),
    'statusUpdatedAt': statusUpdatedAt?.toUtc().toIso8601String(),
    'cancellationReason': cancellationReason,
  };
}
