import 'dart:convert';
import 'dart:io';

import 'package:mysql1/mysql1.dart';

const guestUsername = 'pedido_local';

Future<void> main() async {
  final port = int.tryParse(Platform.environment['API_PORT'] ?? '8080');
  if (port == null || port < 1 || port > 65535) {
    throw const FormatException('API_PORT debe ser un puerto válido.');
  }

  final server = await HttpServer.bind(InternetAddress.anyIPv4, port);
  stdout.writeln('API local disponible en http://0.0.0.0:$port');
  await for (final request in server) {
    _handleRequest(request);
  }
}

Future<void> _handleRequest(HttpRequest request) async {
  try {
    if (request.method == 'GET' && request.uri.path == '/health') {
      final connection = await _connectToDatabase();
      try {
        await connection.query('SELECT 1');
      } finally {
        await connection.close();
      }
      await _respond(request.response, HttpStatus.ok, {'status': 'ok'});
      return;
    }

    if (request.method == 'GET' && request.uri.path == '/products') {
      await _getProducts(request.response);
      return;
    }

    if (request.method == 'GET' && request.uri.path == '/orders') {
      await _getOrders(request.response);
      return;
    }

    if (request.method == 'POST' && request.uri.path == '/orders') {
      await _createOrder(request);
      return;
    }

    await _respond(request.response, HttpStatus.notFound, {
      'error': 'Ruta no encontrada.',
    });
  } on RequestException catch (error) {
    await _respond(request.response, error.statusCode, {
      'error': error.message,
    });
  } catch (error, stackTrace) {
    stderr.writeln(
      'Error al procesar ${request.method} ${request.uri.path}: $error',
    );
    stderr.writeln(stackTrace);
    try {
      await _respond(request.response, HttpStatus.internalServerError, {
        'error': 'Error interno del servidor.',
      });
    } on StateError {
      stderr.writeln('No se pudo enviar la respuesta de error al cliente.');
    } on SocketException {
      stderr.writeln('El cliente cerró la conexión antes de recibir respuesta.');
    }
  }
}

Future<MySqlConnection> _connectToDatabase() {
  final port = int.tryParse(Platform.environment['DB_PORT'] ?? '3306');
  if (port == null || port < 1 || port > 65535) {
    throw const FormatException('DB_PORT debe ser un puerto válido.');
  }
  final password = Platform.environment['DB_PASSWORD'];
  if (password == null || password.isEmpty) {
    throw StateError('Configura DB_PASSWORD antes de iniciar la API.');
  }

  return MySqlConnection.connect(
    ConnectionSettings(
      host: Platform.environment['DB_HOST'] ?? '127.0.0.1',
      port: port,
      user: Platform.environment['DB_USER'] ?? 'al_toque_api',
      password: password,
      db: Platform.environment['DB_NAME'] ?? 'al_toque',
    ),
  );
}

Future<void> _getProducts(HttpResponse response) async {
  final connection = await _connectToDatabase();
  try {
    final rows = await connection.query(
      'SELECT p.id, c.nombre AS categoria, p.nombre, p.descripcion, '
      'p.precio, p.emoji, p.color '
      'FROM productos p '
      'JOIN categorias c ON c.id = p.categoria_id '
      'WHERE p.disponible = TRUE ORDER BY p.id',
    );
    final products = [
      for (final row in rows)
        {
          'id': _asInt(row.fields['id']),
          'category': row.fields['categoria'],
          'name': row.fields['nombre'],
          'description': row.fields['descripcion'],
          'price': _asDouble(row.fields['precio']),
          'emoji': row.fields['emoji'],
          'color': row.fields['color'],
        },
    ];
    await _respond(response, HttpStatus.ok, products);
  } finally {
    await connection.close();
  }
}

Future<void> _getOrders(HttpResponse response) async {
  final connection = await _connectToDatabase();
  try {
    final guestId = await _getGuestUserId(connection);
    final rows = await connection.query(
      'SELECT o.id AS pedido_id, o.codigo_retiro, o.metodo_pago, o.estado, '
      'pp.producto_id, pp.cantidad, p.nombre AS producto_nombre '
      'FROM pedidos o '
      'LEFT JOIN productos_pedido pp ON pp.pedido_id = o.id '
      'LEFT JOIN productos p ON p.id = pp.producto_id '
      'WHERE o.usuario_id = ? ORDER BY o.creado_en DESC, o.id DESC',
      [guestId],
    );
    final orders = <int, Map<String, dynamic>>{};
    for (final row in rows) {
      final id = _asInt(row.fields['pedido_id']);
      final order = orders.putIfAbsent(
        id,
        () => {
          'id': id,
          'pickupCode': row.fields['codigo_retiro'],
          'paymentMethod': row.fields['metodo_pago'],
          'status': row.fields['estado'],
          'items': <Map<String, dynamic>>[],
        },
      );
      final productId = row.fields['producto_id'];
      if (productId != null) {
        (order['items'] as List<Map<String, dynamic>>).add({
          'productId': _asInt(productId),
          'name': row.fields['producto_nombre'],
          'quantity': _asInt(row.fields['cantidad']),
        });
      }
    }
    await _respond(response, HttpStatus.ok, orders.values.toList());
  } finally {
    await connection.close();
  }
}

Future<void> _createOrder(HttpRequest request) async {
  if (request.contentLength > 32768) {
    throw const RequestException(
      HttpStatus.requestEntityTooLarge,
      'Pedido demasiado grande.',
    );
  }

  final Map<String, dynamic> body;
  try {
    final decoded = jsonDecode(await utf8.decoder.bind(request).join());
    if (decoded is! Map<String, dynamic>) {
      throw const FormatException();
    }
    body = decoded;
  } on FormatException {
    throw const RequestException(
      HttpStatus.badRequest,
      'El JSON del pedido no es válido.',
    );
  }

  final paymentMethod = body['paymentMethod'];
  final rawItems = body['items'];
  if (paymentMethod is! String ||
      !const {'En el buffet', 'Billetera virtual'}.contains(paymentMethod) ||
      rawItems is! List ||
      rawItems.isEmpty ||
      rawItems.length > 40) {
    throw const RequestException(
      HttpStatus.badRequest,
      'Los datos del pedido no son válidos.',
    );
  }

  final quantities = <int, int>{};
  for (final rawItem in rawItems) {
    if (rawItem is! Map<String, dynamic>) {
      throw const RequestException(
        HttpStatus.badRequest,
        'Hay un producto inválido.',
      );
    }
    final productId = rawItem['productId'];
    final quantity = rawItem['quantity'];
    if (productId is! int ||
        productId < 1 ||
        quantity is! int ||
        quantity < 1 ||
        quantity > 50) {
      throw const RequestException(
        HttpStatus.badRequest,
        'La cantidad o el producto no son válidos.',
      );
    }
    quantities.update(
      productId,
      (current) => current + quantity,
      ifAbsent: () => quantity,
    );
  }

  final connection = await _connectToDatabase();
  var transactionStarted = false;
  try {
    final guestId = await _getGuestUserId(connection);
    final productPrices = <int, double>{};
    for (final productId in quantities.keys) {
      final rows = await connection.query(
        'SELECT precio FROM productos WHERE id = ? AND disponible = TRUE',
        [productId],
      );
      if (rows.isEmpty) {
        throw const RequestException(
          HttpStatus.badRequest,
          'Uno de los productos ya no está disponible.',
        );
      }
      productPrices[productId] = _asDouble(rows.first.fields['precio']);
    }

    await connection.query('START TRANSACTION');
    transactionStarted = true;
    final orderResult = await connection.query(
      'INSERT INTO pedidos (usuario_id, estado, metodo_pago) '
      'VALUES (?, ?, ?)',
      [guestId, 'pendiente', paymentMethod],
    );
    final orderId = _asInt(orderResult.insertId);
    final pickupCode = orderId.toString().padLeft(6, '0');
    await connection.query(
      'UPDATE pedidos SET codigo_retiro = ? WHERE id = ?',
      [pickupCode, orderId],
    );
    for (final entry in quantities.entries) {
      await connection.query(
        'INSERT INTO productos_pedido '
        '(pedido_id, producto_id, cantidad, precio_unitario) '
        'VALUES (?, ?, ?, ?)',
        [orderId, entry.key, entry.value, productPrices[entry.key]],
      );
    }
    await connection.query('COMMIT');
    transactionStarted = false;
    await _respond(request.response, HttpStatus.created, {
      'id': orderId,
      'pickupCode': pickupCode,
    });
  } catch (_) {
    if (transactionStarted) await connection.query('ROLLBACK');
    rethrow;
  } finally {
    await connection.close();
  }
}

Future<int> _getGuestUserId(MySqlConnection connection) async {
  final rows = await connection.query(
    'SELECT id FROM usuarios WHERE nombre_usuario = ?',
    [guestUsername],
  );
  if (rows.isEmpty) {
    throw StateError(
      'Falta el usuario local "$guestUsername". Ejecuta database/seed_local.sql.',
    );
  }
  return _asInt(rows.first.fields['id']);
}

int _asInt(Object? value) => int.parse('$value');

double _asDouble(Object? value) => double.parse('$value');

Future<void> _respond(
  HttpResponse response,
  int statusCode,
  Object body,
) async {
  response.statusCode = statusCode;
  response.headers.contentType = ContentType.json;
  response.write(jsonEncode(body));
  await response.close();
}

class RequestException implements Exception {
  const RequestException(this.statusCode, this.message);

  final int statusCode;
  final String message;
}
