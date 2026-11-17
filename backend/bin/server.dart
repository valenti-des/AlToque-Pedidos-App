import 'dart:convert';
import 'dart:io';

import 'package:mysql1/mysql1.dart';

import 'package:al_toque_local_api/security.dart';

const guestUsername = 'pedido_local';
const _emailPattern = r'^[^@\s]+@[^@\s]+\.[^@\s]+$';

Future<void> main() async {
  final port = int.tryParse(Platform.environment['API_PORT'] ?? '8080');
  if (port == null || port < 1 || port > 65535) {
    throw const FormatException('API_PORT debe ser un puerto válido.');
  }
  _tokenSecret();

  final connection = await _connectToDatabase();
  try {
    await connection.query('SELECT 1');
  } finally {
    await connection.close();
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

    if (request.method == 'POST' && request.uri.path == '/auth/login') {
      await _login(request);
      return;
    }
    if (request.method == 'GET' && request.uri.path == '/products') {
      await _getProducts(request.response);
      return;
    }
    if (request.method == 'POST' && request.uri.path == '/orders') {
      await _createOrder(request);
      return;
    }

    final trackingMatch = RegExp(r'^/orders/(\d+)/status$')
        .firstMatch(request.uri.path);
    if (request.method == 'GET' && trackingMatch != null) {
      await _getOrderStatus(request, int.parse(trackingMatch.group(1)!));
      return;
    }

    if (request.uri.path == '/admin/orders' && request.method == 'GET') {
      await _requireStaff(request);
      await _getAdminOrders(request.response);
      return;
    }

    final readyMatch = RegExp(r'^/admin/orders/(\d+)/ready$')
        .firstMatch(request.uri.path);
    if (request.method == 'PATCH' && readyMatch != null) {
      await _requireStaff(request);
      await _setOrderReady(request.response, int.parse(readyMatch.group(1)!));
      return;
    }

    final cancelMatch = RegExp(r'^/admin/orders/(\d+)/cancel$')
        .firstMatch(request.uri.path);
    if (request.method == 'POST' && cancelMatch != null) {
      await _requireStaff(request);
      await _cancelOrder(request, int.parse(cancelMatch.group(1)!));
      return;
    }

    final rejectItemMatch = RegExp(r'^/admin/orders/(\d+)/items/(\d+)/reject$')
        .firstMatch(request.uri.path);
    if (request.method == 'POST' && rejectItemMatch != null) {
      await _requireStaff(request);
      await _rejectOrderItem(
        request.response,
        int.parse(rejectItemMatch.group(1)!),
        int.parse(rejectItemMatch.group(2)!),
      );
      return;
    }

    if (request.uri.path == '/admin/employees') {
      final user = await _requireAdmin(request);
      if (request.method == 'GET') {
        await _getEmployees(request.response);
        return;
      }
      if (request.method == 'POST') {
        await _createEmployee(request, user.id);
        return;
      }
    }

    final employeeMatch = RegExp(r'^/admin/employees/(\d+)$')
        .firstMatch(request.uri.path);
    if (request.method == 'DELETE' && employeeMatch != null) {
      final user = await _requireAdmin(request);
      await _deactivateEmployee(
        request.response,
        int.parse(employeeMatch.group(1)!),
        user.id,
      );
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
      stderr.writeln(
        'El cliente cerró la conexión antes de recibir respuesta.',
      );
    }
  }
}

Future<MySqlConnection> _connectToDatabase() {
  final port = int.tryParse(Platform.environment['DB_PORT'] ?? '3306');
  if (port == null || port < 1 || port > 65535) {
    throw const FormatException('DB_PORT debe ser un puerto válido.');
  }
  final password = Platform.environment['DB_PASSWORD'] ?? '';
  if (password.isEmpty &&
      Platform.environment['ALLOW_EMPTY_DB_PASSWORD'] != 'true') {
    throw StateError(
      'Configura DB_PASSWORD o habilita ALLOW_EMPTY_DB_PASSWORD '
      'solo para desarrollo local.',
    );
  }

  return MySqlConnection.connect(
    ConnectionSettings(
      host: Platform.environment['DB_HOST'] ?? '127.0.0.1',
      port: port,
      user: Platform.environment['DB_USER'] ?? 'al_toque_api',
      password: password.isEmpty ? null : password,
      db: Platform.environment['DB_NAME'] ?? 'al_toque',
    ),
  );
}

String _tokenSecret() {
  final secret = Platform.environment['API_TOKEN_SECRET'];
  if (secret == null || secret.length < 32) {
    throw StateError('Configura API_TOKEN_SECRET con al menos 32 caracteres.');
  }
  return secret;
}

Future<void> _login(HttpRequest request) async {
  final body = await _readJsonBody(request);
  final email = body['email'];
  final password = body['password'];
  if (email is! String ||
      email.trim().isEmpty ||
      email.trim().length > 254 ||
      password is! String ||
      password.isEmpty ||
      password.length > 128) {
    throw const RequestException(
      HttpStatus.badRequest,
      'Completa el correo y la contraseña.',
    );
  }

  final connection = await _connectToDatabase();
  try {
    final rows = await connection.query(
      'SELECT id, email, nombre, rol, contrasena_hash, activo '
      'FROM usuarios WHERE email = ? AND rol IN (?, ?)',
      [email.trim().toLowerCase(), 'administrador', 'empleado'],
    );
    if (rows.isEmpty ||
        !_asBool(rows.first.fields['activo']) ||
        !verifyPassword(password, '${rows.first.fields['contrasena_hash']}')) {
      throw const RequestException(
        HttpStatus.unauthorized,
        'Correo o contraseña incorrectos.',
      );
    }

    final user = rows.first.fields;
    final userId = _asInt(user['id']);
    await _respond(request.response, HttpStatus.ok, {
      'userId': userId,
      'email': user['email'],
      'name': user['nombre'],
      'role': user['rol'],
      'token': createSessionToken(userId, _tokenSecret()),
    });
  } finally {
    await connection.close();
  }
}

Future<StaffUser> _requireStaff(HttpRequest request) async {
  final user = await _authenticate(request);
  if (user.role != 'empleado' && user.role != 'administrador') {
    throw const RequestException(HttpStatus.forbidden, 'Acceso denegado.');
  }
  return user;
}

Future<StaffUser> _requireAdmin(HttpRequest request) async {
  final user = await _authenticate(request);
  if (user.role != 'administrador') {
    throw const RequestException(
      HttpStatus.forbidden,
      'Solo el administrador puede gestionar empleados.',
    );
  }
  return user;
}

Future<StaffUser> _authenticate(HttpRequest request) async {
  final authorization = request.headers.value(HttpHeaders.authorizationHeader);
  if (authorization == null || !authorization.startsWith('Bearer ')) {
    throw const RequestException(HttpStatus.unauthorized, 'Inicia sesión.');
  }

  final userId = readSessionUserId(
    authorization.substring('Bearer '.length),
    _tokenSecret(),
  );
  if (userId == null) {
    throw const RequestException(
      HttpStatus.unauthorized,
      'La sesión venció. Inicia sesión nuevamente.',
    );
  }

  final connection = await _connectToDatabase();
  try {
    final rows = await connection.query(
      'SELECT id, email, nombre, rol FROM usuarios '
      'WHERE id = ? AND activo = TRUE',
      [userId],
    );
    if (rows.isEmpty) {
      throw const RequestException(
        HttpStatus.unauthorized,
        'La cuenta ya no está activa.',
      );
    }
    final user = rows.first.fields;
    return StaffUser(
      id: _asInt(user['id']),
      email: '${user['email']}',
      name: '${user['nombre']}',
      role: '${user['rol']}',
    );
  } finally {
    await connection.close();
  }
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

Future<void> _createOrder(HttpRequest request) async {
  final body = await _readJsonBody(request);
  final paymentMethod = body['paymentMethod'];
  final customerName = body['customerName'];
  final course = body['course'];
  final rawItems = body['items'];
  if (paymentMethod is! String ||
      !const {'En el buffet', 'Billetera virtual'}.contains(paymentMethod) ||
      customerName is! String ||
      customerName.trim().isEmpty ||
      customerName.trim().length > 100 ||
      course is! String ||
      course.trim().isEmpty ||
      course.trim().length > 50 ||
      rawItems is! List ||
      rawItems.isEmpty ||
      rawItems.length > 40) {
    throw const RequestException(
      HttpStatus.badRequest,
      'Revisa los datos del pedido.',
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

    final trackingToken = createTrackingToken();
    await connection.query('START TRANSACTION');
    transactionStarted = true;
    final orderResult = await connection.query(
      'INSERT INTO pedidos '
      '(usuario_id, cliente_nombre, cliente_curso, estado, metodo_pago, '
      'token_seguimiento_hash) VALUES (?, ?, ?, ?, ?, ?)',
      [
        guestId,
        customerName.trim(),
        course.trim(),
        'pendiente',
        paymentMethod,
        hashTrackingToken(trackingToken),
      ],
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
      'trackingToken': trackingToken,
    });
  } catch (_) {
    if (transactionStarted) await connection.query('ROLLBACK');
    rethrow;
  } finally {
    await connection.close();
  }
}

Future<void> _getOrderStatus(HttpRequest request, int orderId) async {
  final token = request.headers.value('x-order-token');
  if (token == null || token.isEmpty) {
    throw const RequestException(
      HttpStatus.unauthorized,
      'Falta el código privado de seguimiento.',
    );
  }
  final connection = await _connectToDatabase();
  try {
    final rows = await connection.query(
      'SELECT codigo_retiro, estado, motivo_cancelacion, '
      'token_seguimiento_hash FROM pedidos WHERE id = ?',
      [orderId],
    );
    if (rows.isEmpty ||
        rows.first.fields['token_seguimiento_hash'] !=
            hashTrackingToken(token)) {
      throw const RequestException(
        HttpStatus.notFound,
        'No se encontró el pedido.',
      );
    }
    final order = rows.first.fields;
    await _respond(request.response, HttpStatus.ok, {
      'id': orderId,
      'pickupCode': order['codigo_retiro'],
      'status': order['estado'],
      'cancellationReason': order['motivo_cancelacion'],
    });
  } finally {
    await connection.close();
  }
}

Future<void> _getAdminOrders(HttpResponse response) async {
  final connection = await _connectToDatabase();
  try {
    final rows = await connection.query(
      'SELECT o.id, o.codigo_retiro, o.cliente_nombre, o.cliente_curso, '
      'o.metodo_pago, o.estado, o.motivo_cancelacion, pp.producto_id, '
      'pp.cantidad, pp.precio_unitario, pp.estado AS estado_item, '
      'pp.motivo_rechazo, p.nombre AS producto_nombre '
      'FROM (SELECT * FROM pedidos '
      'ORDER BY creado_en DESC, id DESC LIMIT 100) o '
      'LEFT JOIN productos_pedido pp ON pp.pedido_id = o.id '
      'LEFT JOIN productos p ON p.id = pp.producto_id '
      'ORDER BY o.creado_en DESC, o.id DESC',
    );

    final orders = <int, Map<String, dynamic>>{};
    for (final row in rows) {
      final id = _asInt(row.fields['id']);
      final order = orders.putIfAbsent(
        id,
        () => {
          'id': id,
          'pickupCode': row.fields['codigo_retiro'] ?? id.toString(),
          'customerName': row.fields['cliente_nombre'],
          'course': row.fields['cliente_curso'],
          'paymentMethod': row.fields['metodo_pago'],
          'status': row.fields['estado'],
          'cancellationReason': row.fields['motivo_cancelacion'],
          'total': 0.0,
          'items': <Map<String, dynamic>>[],
        },
      );
      if (row.fields['producto_id'] == null) continue;

      final item = {
        'productId': _asInt(row.fields['producto_id']),
        'name': row.fields['producto_nombre'],
        'quantity': _asInt(row.fields['cantidad']),
        'unitPrice': _asDouble(row.fields['precio_unitario']),
        'status': row.fields['estado_item'],
        'rejectionReason': row.fields['motivo_rechazo'],
      };
      (order['items'] as List<Map<String, dynamic>>).add(item);
      if (item['status'] == 'activo') {
        order['total'] =
            (order['total'] as double) +
            (item['quantity'] as int) * (item['unitPrice'] as double);
      }
    }
    await _respond(response, HttpStatus.ok, orders.values.toList());
  } finally {
    await connection.close();
  }
}

Future<void> _setOrderReady(HttpResponse response, int orderId) async {
  final connection = await _connectToDatabase();
  try {
    final result = await connection.query(
      "UPDATE pedidos SET estado = 'listo' "
      "WHERE id = ? AND estado IN ('pendiente', 'en_preparacion') "
      "AND EXISTS (SELECT 1 FROM productos_pedido "
      "WHERE pedido_id = ? AND estado = 'activo')",
      [orderId, orderId],
    );
    if (result.affectedRows == 0) {
      throw const RequestException(
        HttpStatus.conflict,
        'El pedido ya no está pendiente o no tiene productos disponibles.',
      );
    }
    await _respond(response, HttpStatus.ok, {'status': 'listo'});
  } finally {
    await connection.close();
  }
}

Future<void> _cancelOrder(HttpRequest request, int orderId) async {
  final body = await _readJsonBody(request);
  final reason = body['reason'];
  if (reason is! String ||
      reason.trim().isEmpty ||
      reason.trim().length > 255) {
    throw const RequestException(
      HttpStatus.badRequest,
      'Indica un motivo de cancelación (máximo 255 caracteres).',
    );
  }

  final connection = await _connectToDatabase();
  try {
    final result = await connection.query(
      "UPDATE pedidos SET estado = 'cancelado', motivo_cancelacion = ? "
      "WHERE id = ? AND estado IN ('pendiente', 'en_preparacion')",
      [reason.trim(), orderId],
    );
    if (result.affectedRows == 0) {
      throw const RequestException(
        HttpStatus.conflict,
        'El pedido ya no se puede cancelar.',
      );
    }
    await _respond(request.response, HttpStatus.ok, {'status': 'cancelado'});
  } finally {
    await connection.close();
  }
}

Future<void> _rejectOrderItem(
  HttpResponse response,
  int orderId,
  int productId,
) async {
  final connection = await _connectToDatabase();
  var transactionStarted = false;
  try {
    await connection.query('START TRANSACTION');
    transactionStarted = true;
    final orderRows = await connection.query(
      "SELECT estado FROM pedidos WHERE id = ? "
      "AND estado IN ('pendiente', 'en_preparacion') FOR UPDATE",
      [orderId],
    );
    if (orderRows.isEmpty) {
      throw const RequestException(
        HttpStatus.conflict,
        'El pedido ya no admite cambios.',
      );
    }

    final result = await connection.query(
      "UPDATE productos_pedido SET estado = 'rechazado', "
      "motivo_rechazo = 'Producto no disponible' "
      "WHERE pedido_id = ? AND producto_id = ? AND estado = 'activo'",
      [orderId, productId],
    );
    if (result.affectedRows == 0) {
      throw const RequestException(
        HttpStatus.notFound,
        'El producto no está disponible en este pedido.',
      );
    }

    final remainingRows = await connection.query(
      "SELECT COUNT(*) AS cantidad FROM productos_pedido "
      "WHERE pedido_id = ? AND estado = 'activo'",
      [orderId],
    );
    final allItemsRejected =
        _asInt(remainingRows.first.fields['cantidad']) == 0;
    if (allItemsRejected) {
      await connection.query(
        "UPDATE pedidos SET estado = 'cancelado', "
        "motivo_cancelacion = 'Todos los productos no están disponibles.' "
        "WHERE id = ?",
        [orderId],
      );
    }
    await connection.query('COMMIT');
    transactionStarted = false;
    await _respond(response, HttpStatus.ok, {
      'status': allItemsRejected ? 'cancelado' : 'pendiente',
      'allItemsRejected': allItemsRejected,
    });
  } catch (_) {
    if (transactionStarted) await connection.query('ROLLBACK');
    rethrow;
  } finally {
    await connection.close();
  }
}

Future<void> _getEmployees(HttpResponse response) async {
  final connection = await _connectToDatabase();
  try {
    final rows = await connection.query(
      'SELECT id, email, nombre, creado_en FROM usuarios '
      "WHERE rol = 'empleado' AND activo = TRUE ORDER BY nombre, email",
    );
    await _respond(response, HttpStatus.ok, [
      for (final row in rows)
        {
          'id': _asInt(row.fields['id']),
          'email': row.fields['email'],
          'name': row.fields['nombre'],
          'createdAt': (row.fields['creado_en'] as DateTime)
              .toUtc()
              .toIso8601String(),
        },
    ]);
  } finally {
    await connection.close();
  }
}

Future<void> _createEmployee(HttpRequest request, int creatorId) async {
  final body = await _readJsonBody(request);
  final email = body['email'];
  final password = body['password'];
  if (email is! String ||
      !RegExp(_emailPattern).hasMatch(email.trim()) ||
      email.trim().length > 254 ||
      password is! String ||
      password.length < 8 ||
      password.length > 128) {
    throw const RequestException(
      HttpStatus.badRequest,
      'Ingresa un correo válido y una contraseña de 8 a 128 caracteres.',
    );
  }

  final normalizedEmail = email.trim().toLowerCase();
  final displayName = normalizedEmail.split('@').first;
  final connection = await _connectToDatabase();
  try {
    final result = await connection.query(
      'INSERT INTO usuarios '
      '(email, nombre, rol, activo, contrasena_hash) '
      'VALUES (?, ?, ?, TRUE, ?)',
      [normalizedEmail, displayName, 'empleado', hashPassword(password)],
    );
    await _respond(request.response, HttpStatus.created, {
      'id': _asInt(result.insertId),
      'email': normalizedEmail,
      'name': displayName,
      'createdBy': creatorId,
    });
  } on MySqlException catch (error) {
    if (error.errorNumber == 1062) {
      throw const RequestException(
        HttpStatus.conflict,
        'Ya existe una cuenta con ese correo.',
      );
    }
    rethrow;
  } finally {
    await connection.close();
  }
}

Future<void> _deactivateEmployee(
  HttpResponse response,
  int employeeId,
  int adminId,
) async {
  if (employeeId == adminId) {
    throw const RequestException(
      HttpStatus.badRequest,
      'No puedes eliminar tu propia cuenta.',
    );
  }
  final connection = await _connectToDatabase();
  try {
    final result = await connection.query(
      "UPDATE usuarios SET activo = FALSE "
      "WHERE id = ? AND rol = 'empleado' AND activo = TRUE",
      [employeeId],
    );
    if (result.affectedRows == 0) {
      throw const RequestException(
        HttpStatus.notFound,
        'No se encontró el empleado activo.',
      );
    }
    await _respond(response, HttpStatus.ok, {'deleted': true});
  } finally {
    await connection.close();
  }
}

Future<Map<String, dynamic>> _readJsonBody(HttpRequest request) async {
  if (request.contentLength > 32768) {
    throw const RequestException(
      HttpStatus.requestEntityTooLarge,
      'La solicitud es demasiado grande.',
    );
  }

  try {
    final source = await utf8.decoder.bind(request).join();
    if (utf8.encode(source).length > 32768) {
      throw const RequestException(
        HttpStatus.requestEntityTooLarge,
        'La solicitud es demasiado grande.',
      );
    }
    final decoded = jsonDecode(source);
    if (decoded is Map<String, dynamic>) return decoded;
  } on FormatException {
    throw const RequestException(
      HttpStatus.badRequest,
      'El JSON de la solicitud no es válido.',
    );
  }
  throw const RequestException(
    HttpStatus.badRequest,
    'El cuerpo de la solicitud debe ser un objeto JSON.',
  );
}

Future<int> _getGuestUserId(MySqlConnection connection) async {
  final rows = await connection.query(
    'SELECT id FROM usuarios WHERE nombre_usuario = ? AND rol = ?',
    [guestUsername, 'cliente'],
  );
  if (rows.isEmpty) {
    throw StateError(
      'Falta el usuario local "$guestUsername". Ejecuta database/seed_local.sql.',
    );
  }
  return _asInt(rows.first.fields['id']);
}

int _asInt(Object? value) => int.parse('$value');

bool _asBool(Object? value) => value == true || value == 1 || value == '1';

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

class StaffUser {
  const StaffUser({
    required this.id,
    required this.email,
    required this.name,
    required this.role,
  });

  final int id;
  final String email;
  final String name;
  final String role;
}

class RequestException implements Exception {
  const RequestException(this.statusCode, this.message);

  final int statusCode;
  final String message;
}
