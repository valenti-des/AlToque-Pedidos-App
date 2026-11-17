import 'usuario.dart';

class AuthSession {
  const AuthSession({
    required this.userId,
    required this.email,
    required this.name,
    required this.role,
    required this.token,
  });

  factory AuthSession.fromJson(Map<String, dynamic> json) => AuthSession(
    userId: json['userId'] as int,
    email: json['email'] as String,
    name: json['name'] as String,
    role: json['role'] as String,
    token: json['token'] as String,
  );

  final int userId;
  final String email;
  final String name;
  final String role;
  final String token;

  RolUsuario get rol => RolUsuario.fromJson(role);
  Usuario get usuario => Usuario(
    id: userId,
    nombre: name,
    email: email,
    rol: rol,
  );
  bool get isAdmin => rol == RolUsuario.administrador;

  Map<String, dynamic> toJson() => {
    'userId': userId,
    'email': email,
    'name': name,
    'role': role,
    'token': token,
  };
}
