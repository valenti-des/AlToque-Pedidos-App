import 'dart:convert';

import 'package:http/http.dart' as http;

import '../basedate.dart';
import '../models/order.dart';
import '../models/product.dart';

class ApiService {
  ApiService._();

  static final ApiService instance = ApiService._();

  final http.Client _client = http.Client();

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
  ) async {
    final response = await _client
        .post(
          Uri.parse('${ApiConfig.baseUrl}/orders'),
          headers: const {'content-type': 'application/json'},
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

    return Order(items, paymentMethod, data['pickupCode'] as String);
  }

  Future<List<Order>> getOrders() async {
    final response = await _client
        .get(Uri.parse('${ApiConfig.baseUrl}/orders'))
        .timeout(const Duration(seconds: 10));
    final data = _decodeResponse(response);
    if (data is! List) {
      throw const FormatException('La API devolvió un historial inválido.');
    }

    return data
        .map((item) => Order.fromJson(item as Map<String, dynamic>))
        .toList();
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
