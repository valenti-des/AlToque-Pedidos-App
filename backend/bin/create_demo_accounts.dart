import 'dart:io';

import 'package:mysql1/mysql1.dart';

import 'package:al_toque_local_api/security.dart';

const _adminEmail = 'admin.demo@al-toque.local';
const _employeeEmail = 'empleado.demo@al-toque.local';
const _adminPassword = 'Admin123!';
const _employeePassword = 'Empleado123!';

Future<void> main() async {
  if (Platform.environment['ALLOW_DEMO_ACCOUNTS'] != 'true') {
    throw StateError(
      'Para habilitar esta operación local, configura '
      'ALLOW_DEMO_ACCOUNTS=true.',
    );
  }

  final host = Platform.environment['DB_HOST'] ?? '127.0.0.1';
  if (host != '127.0.0.1' && host != 'localhost') {
    throw StateError('Las cuentas de ejemplo solo se crean en MySQL local.');
  }
  final dbPassword = Platform.environment['DB_PASSWORD'] ?? '';
  if (dbPassword.isEmpty &&
      Platform.environment['ALLOW_EMPTY_DB_PASSWORD'] != 'true') {
    throw StateError(
      'Configura DB_PASSWORD o habilita ALLOW_EMPTY_DB_PASSWORD '
      'solo para desarrollo local.',
    );
  }
  final dbPort = int.tryParse(Platform.environment['DB_PORT'] ?? '3306');
  if (dbPort == null || dbPort < 1 || dbPort > 65535) {
    throw const FormatException('DB_PORT debe ser un puerto válido.');
  }

  final adminPassword = _adminPassword;
  final employeePassword = _employeePassword;
  final adminHash = hashPassword(adminPassword);
  final employeeHash = hashPassword(employeePassword);
  final connection = await MySqlConnection.connect(
    ConnectionSettings(
      host: host,
      port: dbPort,
      user: Platform.environment['DB_USER'] ?? 'al_toque_api',
      password: dbPassword.isEmpty ? null : dbPassword,
      db: Platform.environment['DB_NAME'] ?? 'al_toque',
    ),
  );

  try {
    await connection.query('START TRANSACTION');
    try {
      await _upsertDemoAccount(
        connection,
        email: _adminEmail,
        name: 'Administrador de ejemplo',
        role: 'administrador',
        passwordHash: adminHash,
      );
      await _upsertDemoAccount(
        connection,
        email: _employeeEmail,
        name: 'Empleado de ejemplo',
        role: 'empleado',
        passwordHash: employeeHash,
      );
      await connection.query('COMMIT');
    } catch (_) {
      await connection.query('ROLLBACK');
      rethrow;
    }
  } finally {
    await connection.close();
  }

  stdout
    ..writeln('Cuentas de ejemplo creadas/actualizadas (solo desarrollo):')
    ..writeln('Administrador: $_adminEmail')
    ..writeln('Contraseña: $adminPassword')
    ..writeln('Empleado: $_employeeEmail')
    ..writeln('Contraseña: $employeePassword')
    ..writeln('Las claves son fijas para cuentas de demostración local.');
}

Future<void> _upsertDemoAccount(
  MySqlConnection connection, {
  required String email,
  required String name,
  required String role,
  required String passwordHash,
}) async {
  final existing = await connection.query(
    'SELECT id, rol FROM usuarios WHERE email = ? FOR UPDATE',
    [email],
  );
  if (existing.isNotEmpty) {
    if (existing.first.fields['rol'] != role) {
      throw StateError('El correo de ejemplo $email ya tiene otro rol.');
    }
    await connection.query(
      'UPDATE usuarios SET nombre = ?, contrasena_hash = ?, activo = TRUE '
      'WHERE id = ?',
      [name, passwordHash, int.parse('${existing.first.fields['id']}')],
    );
    return;
  }

  if (role == 'administrador') {
    final admins = await connection.query(
      "SELECT id FROM usuarios WHERE rol = 'administrador' LIMIT 1 FOR UPDATE",
    );
    if (admins.isNotEmpty) {
      throw StateError(
        'Ya existe un administrador. No se creó otra cuenta inicial.',
      );
    }
  }

  await connection.query(
    'INSERT INTO usuarios '
    '(email, nombre, rol, activo, contrasena_hash) '
    'VALUES (?, ?, ?, TRUE, ?)',
    [email, name, role, passwordHash],
  );
}
