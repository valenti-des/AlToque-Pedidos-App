import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../basedate.dart';
import '../models/auth_session.dart';
import '../models/empleado.dart';
import '../models/employee_stats.dart';
import '../models/order.dart';
import '../models/pedido.dart';
import '../models/product.dart';

class ApiService {
  ApiService._();

  static final ApiService instance = ApiService._();

  final http.Client _client = http.Client();
  String? _authToken;
  AuthSession? _session;

  Future<AuthSession> login(String email, String password) async {
    final response = await _client
        .post(
          Uri.parse('${ApiConfig.baseUrl}/auth/login'),
          headers: const {'content-type': 'application/json'},
          body: jsonEncode({'email': email, 'password': password}),
        )
        .timeout(const Duration(seconds: 10));
    final data = _decodeResponse(response);
    if (data is! Map<String, dynamic>) {
      throw const FormatException('La API devolvió una sesión inválida.');
    }

    final session = AuthSession.fromJson(data);
    _authToken = session.token;
    _session = session;
    return session;
  }

  Future<AuthSession> registerCustomer({
    required String name,
    required String email,
    required String password,
  }) async {
    final response = await _client
        .post(
          Uri.parse('${ApiConfig.baseUrl}/auth/register'),
          headers: const {'content-type': 'application/json'},
          body: jsonEncode({
            'name': name,
            'email': email,
            'password': password,
          }),
        )
        .timeout(const Duration(seconds: 10));
    final data = _decodeResponse(response);
    if (data is! Map<String, dynamic>) {
      throw const FormatException('La API devolvió una cuenta inválida.');
    }

    final session = AuthSession.fromJson(data);
    _authToken = session.token;
    _session = session;
    return session;
  }

  bool get isCustomerAuthenticated => _session?.role == 'cliente';

  Future<WebSocket> connectStaffOrderUpdates() async {
    final token = _authToken;
    final role = _session?.role;
    if (token == null || (role != 'empleado' && role != 'administrador')) {
      throw const ApiException(
        'Inicia sesión con una cuenta del personal para ver las comandas.',
      );
    }

    final baseUri = Uri.parse(ApiConfig.baseUrl);
    final socketUri = baseUri.replace(
      scheme: baseUri.scheme == 'https' ? 'wss' : 'ws',
      path: '/ws/orders',
      query: null,
      fragment: null,
    );
    return WebSocket.connect(
      socketUri.toString(),
      headers: {'authorization': 'Bearer $token'},
    ).timeout(const Duration(seconds: 10));
  }

  void logout() {
    _authToken = null;
    _session = null;
  }

  Future<List<Product>> getProducts() async {
    final response = await _client
        .get(Uri.parse('${ApiConfig.baseUrl}/products'))
        .timeout(const Duration(seconds: 10));
    final data = _decodeResponse(response);
    if (data is! List) {
      throw const FormatException('La API devolvió un catálogo inválido.');
    }

    return data
        .map((item) => Product.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<Order> createOrder(
    Map<Product, int> items,
    String paymentMethod,
    String customerName,
  ) async {
    final response = await _client
        .post(
          Uri.parse('${ApiConfig.baseUrl}/orders'),
          headers: {
            'content-type': 'application/json',
            if (_authToken != null) 'authorization': 'Bearer $_authToken',
          },
          body: jsonEncode({
            'paymentMethod': paymentMethod,
            'items': [
              for (final entry in items.entries)
                {'productId': entry.key.id, 'quantity': entry.value},
            ],
          }),
        )
        .timeout(const Duration(seconds: 10));
    final data = _decodeResponse(response);
    if (data is! Map<String, dynamic>) {
      throw const FormatException('La API devolvió un pedido inválido.');
    }

    return Order(
      id: data['id'] as int,
      items: items,
      paymentMethod: paymentMethod,
      pickupCode: data['pickupCode'] as String,
      trackingToken: data['trackingToken'] as String,
      customerName: customerName,
      course: '',
    );
  }

  Future<List<Order>> getCustomerOrders() async {
    final response = await _client
        .get(
          Uri.parse('${ApiConfig.baseUrl}/customer/orders'),
          headers: _authorizedHeaders(),
        )
        .timeout(const Duration(seconds: 10));
    final data = _decodeResponse(response);
    if (data is! List) {
      throw const FormatException('La API devolvió un historial inválido.');
    }

    return data
        .map((item) => Order.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<List<Pedido>> getBuffetHistory({
    DateTime? startDate,
    DateTime? endDate,
    String? category,
    String? search,
  }) async {
    final query = <String, String>{};
    if (startDate != null) {
      query['fechaInicio'] =
          '${startDate.year}-${startDate.month.toString().padLeft(2, '0')}-${startDate.day.toString().padLeft(2, '0')}';
    }
    if (endDate != null) {
      query['fechaFin'] =
          '${endDate.year}-${endDate.month.toString().padLeft(2, '0')}-${endDate.day.toString().padLeft(2, '0')}';
    }
    if (category != null && category.isNotEmpty) {
      query['categoria'] = category;
    }
    if (search != null && search.trim().isNotEmpty) {
      query['search'] = search.trim();
    }
    final uri = Uri.parse('${ApiConfig.baseUrl}/api/buffet/historial')
        .replace(queryParameters: query);
    final response = await _client
        .get(uri, headers: _authorizedHeaders())
        .timeout(const Duration(seconds: 10));
    final data = _decodeResponse(response);
    if (data is! List) {
      throw const FormatException('La API devolvió un historial inválido.');
    }
    return data
        .map((item) => Pedido.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<Order> refreshOrderStatus(Order order) async {
    final trackingToken = order.trackingToken;
    if (trackingToken == null) {
      throw const ApiException(
        'Inicia sesión para actualizar el estado de este pedido.',
      );
    }
    final response = await _client
        .get(
          Uri.parse('${ApiConfig.baseUrl}/orders/${order.id}/status'),
          headers: {'x-order-token': trackingToken},
        )
        .timeout(const Duration(seconds: 10));
    final data = _decodeResponse(response);
    if (data is! Map<String, dynamic>) {
      throw const FormatException('La API devolvió un estado inválido.');
    }
    return order.copyWith(
      status: data['status'] as String,
      cancellationReason: data['cancellationReason'] as String?,
    );
  }

  Future<List<Pedido>> getAdminOrders() async {
    final response = await _client
        .get(
          Uri.parse('${ApiConfig.baseUrl}/admin/orders'),
          headers: _authorizedHeaders(),
        )
        .timeout(const Duration(seconds: 10));
    final data = _decodeResponse(response);
    if (data is! List) {
      throw const FormatException('La API devolvió pedidos inválidos.');
    }

    return data
        .map((item) => Pedido.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<void> markOrderReady(int orderId) async {
    final response = await _client
        .patch(
          Uri.parse('${ApiConfig.baseUrl}/admin/orders/$orderId/ready'),
          headers: _authorizedHeaders(),
        )
        .timeout(const Duration(seconds: 10));
    _decodeResponse(response);
  }

  Future<void> markOrderDelivered(int orderId) async {
    final response = await _client
        .patch(
          Uri.parse('${ApiConfig.baseUrl}/admin/orders/$orderId/delivered'),
          headers: _authorizedHeaders(),
        )
        .timeout(const Duration(seconds: 10));
    _decodeResponse(response);
  }

  Future<void> cancelOrder(int orderId, String reason) async {
    final response = await _client
        .post(
          Uri.parse('${ApiConfig.baseUrl}/admin/orders/$orderId/cancel'),
          headers: _authorizedHeaders(json: true),
          body: jsonEncode({'reason': reason}),
        )
        .timeout(const Duration(seconds: 10));
    _decodeResponse(response);
  }

  Future<void> rejectOrderItem(int orderId, int productId) async {
    final response = await _client
        .post(
          Uri.parse(
            '${ApiConfig.baseUrl}/admin/orders/$orderId/items/$productId/reject',
          ),
          headers: _authorizedHeaders(),
        )
        .timeout(const Duration(seconds: 10));
    _decodeResponse(response);
  }

  Future<List<Empleado>> getEmployees() async {
    final response = await _client
        .get(
          Uri.parse('${ApiConfig.baseUrl}/admin/employees'),
          headers: _authorizedHeaders(),
        )
        .timeout(const Duration(seconds: 10));
    final data = _decodeResponse(response);
    if (data is! List) {
      throw const FormatException('La API devolvió empleados inválidos.');
    }

    return data
        .map((item) => Empleado.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<List<EmployeeStats>> getEmployeeStats() async {
    final response = await _client
        .get(
          Uri.parse('${ApiConfig.baseUrl}/api/admin/estadisticas-empleados'),
          headers: _authorizedHeaders(),
        )
        .timeout(const Duration(seconds: 10));
    final data = _decodeResponse(response);
    if (data is! List) {
      throw const FormatException(
        'La API devolvió estadísticas de empleados inválidas.',
      );
    }
    return data
        .map((item) => EmployeeStats.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<void> createEmployee(String email, String password) async {
    final response = await _client
        .post(
          Uri.parse('${ApiConfig.baseUrl}/admin/employees'),
          headers: _authorizedHeaders(json: true),
          body: jsonEncode({'email': email, 'password': password}),
        )
        .timeout(const Duration(seconds: 10));
    _decodeResponse(response);
  }

  Future<void> deleteEmployee(int employeeId) async {
    final response = await _client
        .delete(
          Uri.parse('${ApiConfig.baseUrl}/admin/employees/$employeeId'),
          headers: _authorizedHeaders(),
        )
        .timeout(const Duration(seconds: 10));
    _decodeResponse(response);
  }

  Map<String, String> _authorizedHeaders({bool json = false}) {
    final token = _authToken;
    if (token == null) {
      throw const ApiException('Inicia sesión para realizar esta acción.');
    }
    return {
      if (json) 'content-type': 'application/json',
      'authorization': 'Bearer $token',
    };
  }

  Object _decodeResponse(http.Response response) {
    final dynamic data;
    try {
      data = jsonDecode(response.body);
    } on FormatException {
      throw const FormatException('La API devolvió una respuesta inválida.');
    }

    if (response.statusCode < 200 || response.statusCode >= 300) {
      final message = data is Map<String, dynamic>
          ? data['error'] as String? ?? 'Error HTTP ${response.statusCode}'
          : 'Error HTTP ${response.statusCode}';
      throw ApiException(message);
    }
    return data;
  }
}

class ApiException implements Exception {
  const ApiException(this.message);

  final String message;

  @override
  String toString() => message;
}
