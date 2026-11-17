class AuthSession {
  const AuthSession({
    required this.userId,
    required this.email,
    required this.name,
    this.course,
    required this.role,
    required this.token,
  });

  factory AuthSession.fromJson(Map<String, dynamic> json) => AuthSession(
    userId: json['userId'] as int,
    email: json['email'] as String,
    name: json['name'] as String,
    course: json['course'] as String?,
    role: json['role'] as String,
    token: json['token'] as String,
  );

  final int userId;
  final String email;
  final String name;
  final String? course;
  final String role;
  final String token;

  bool get isAdmin => role == 'administrador';
}
