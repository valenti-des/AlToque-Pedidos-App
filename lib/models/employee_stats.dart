class EmployeeStats {
  const EmployeeStats({
    required this.employeeId,
    required this.name,
    required this.email,
    required this.delivered,
    required this.cancelled,
  });

  factory EmployeeStats.fromJson(Map<String, dynamic> json) => EmployeeStats(
    employeeId: json['employeeId'] as int,
    name: json['name'] as String,
    email: json['email'] as String,
    delivered: json['delivered'] as int,
    cancelled: json['cancelled'] as int,
  );

  final int employeeId;
  final String name;
  final String email;
  final int delivered;
  final int cancelled;

  int get total => delivered + cancelled;
  double get effectiveness => total == 0 ? 0 : delivered * 100 / total;
}
