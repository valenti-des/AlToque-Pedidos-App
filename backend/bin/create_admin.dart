import 'dart:io';

import 'package:mysql1/mysql1.dart';

import 'package:al_toque_local_api/security.dart';

const _emailPattern = r'^[^@\s]+@[^@\s]+\.[^@\s]+$';

Future<void> main() async {
  final email = Platform.environment['ADMIN_EMAIL']?.trim().toLowerCase();
  final password = Platform.environment['ADMIN_PASSWORD'];
  final name = Platform.environment['ADMIN_NAME']?.trim();
  if (email == null ||
      !RegExp(_emailPattern).hasMatch(email) ||
      password == null ||
      password.length < 8 ||
      password.length > 128) {
    throw StateError(
      'Configura ADMIN_EMAIL y ADMIN_PASSWORD (8 a 128 caracteres).',
    );
  }

  final dbPassword = Platform.environment['DB_PASSWORD'];
  if (dbPassword == null || dbPassword.isEmpty) {
    throw StateError('Configura DB_PASSWORD para conectar con MySQL.');
  }
  final dbPort = int.tryParse(Platform.environment['DB_PORT'] ?? '3306');
  if (dbPort == null || dbPort < 1 || dbPort > 65535) {
    throw const FormatException('DB_PORT debe ser un puerto válido.');
  }

  final connection = await MySqlConnection.connect(
    ConnectionSettings(
      host: Platform.environment['DB_HOST'] ?? '127.0.0.1',
      port: dbPort,
      user: Platform.environment['DB_USER'] ?? 'al_toque_api',
      password: dbPassword,
      db: Platform.environment['DB_NAME'] ?? 'al_toque',
    ),
  );
  try {
    final existingAdmins = await connection.query(
      "SELECT id FROM usuarios WHERE rol = 'administrador' LIMIT 1",
    );
    if (existingAdmins.isNotEmpty) {
      throw StateError(
        'Ya existe un administrador. No se creó otra cuenta inicial.',
      );
    }

    await connection.query(
      'INSERT INTO usuarios '
      '(email, nombre, rol, activo, contrasena_hash) '
      'VALUES (?, ?, ?, TRUE, ?)',
      [
        email,
        name == null || name.isEmpty ? email.split('@').first : name,
        'administrador',
        hashPassword(password),
      ],
    );
    stdout.writeln('Cuenta administradora creada para $email.');
  } finally {
    await connection.close();
  }
}
