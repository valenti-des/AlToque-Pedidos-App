class Empleado {
  const Empleado({
    required this.id,
    required this.email,
    required this.name,
    required this.createdAt,
  });

  factory Empleado.fromJson(Map<String, dynamic> json) => Empleado(
    id: json['id'] as int,
    email: json['email'] as String,
    name: json['name'] as String,
    createdAt: DateTime.parse(json['createdAt'] as String),
  );

  final int id;
  final String email;
  final String name;
  final DateTime createdAt;
}
