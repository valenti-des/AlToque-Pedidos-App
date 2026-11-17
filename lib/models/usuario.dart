enum RolUsuario {
  estudiante('cliente', 'Estudiante'),
  empleado('empleado', 'Empleado'),
  administrador('administrador', 'Administrador');

  const RolUsuario(this.apiValue, this.label);

  final String apiValue;
  final String label;

  static RolUsuario fromJson(Object? value) => switch (value) {
    'cliente' || 'estudiante' => RolUsuario.estudiante,
    'empleado' => RolUsuario.empleado,
    'administrador' => RolUsuario.administrador,
    _ => throw FormatException('Rol de usuario inválido: $value'),
  };
}

class Usuario {
  const Usuario({
    required this.id,
    required this.nombre,
    required this.email,
    required this.rol,
    this.cursoODni,
  });

  factory Usuario.fromJson(Map<String, dynamic> json) {
    final id = json['id'] ?? json['userId'];
    final nombre = json['name'] ?? json['nombre'];
    final rol = json['role'] ?? json['rol'];
    final rawCursoODni = json['course'] ?? json['curso'] ?? json['dni'];
    if (id is! int || nombre is! String || json['email'] is! String) {
      throw const FormatException('Los datos del usuario son inválidos.');
    }
    if (rawCursoODni != null &&
        rawCursoODni is! String &&
        rawCursoODni is! num) {
      throw const FormatException('El curso o DNI del usuario es inválido.');
    }
    return Usuario(
      id: id,
      nombre: nombre,
      email: json['email'] as String,
      rol: RolUsuario.fromJson(rol),
      cursoODni: rawCursoODni?.toString(),
    );
  }

  final int id;
  final String nombre;
  final String email;
  final RolUsuario rol;
  final String? cursoODni;

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': nombre,
    'email': email,
    'role': rol.apiValue,
    'course': cursoODni,
  };
}
