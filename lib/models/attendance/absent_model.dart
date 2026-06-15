class AbsentModel {
  final int id;
  final String? code;
  final String? designation;
  final String absentDate;
  final String? reason;
  final String? createdAt;
  final int employeeId;
  final String employeeName;
  final int departmentId;
  final String departmentName;

  AbsentModel({
    required this.id,
    this.code,
    this.designation,
    required this.absentDate,
    this.reason,
    this.createdAt,
    required this.employeeId,
    required this.employeeName,
    required this.departmentId,
    required this.departmentName,
  });

  factory AbsentModel.fromJson(Map<String, dynamic> json) {
    return AbsentModel(
      id: json['id'] as int? ?? 0,
      code: json['code']?.toString(),
      designation: json['designation']?.toString(),
      absentDate: json['absent_date']?.toString() ?? '',
      reason: json['reason']?.toString(),
      createdAt: json['created_at']?.toString(),
      employeeId: json['employee_id'] as int? ?? 0,
      employeeName: json['employee_name']?.toString() ?? '',
      departmentId: json['department_id'] as int? ?? 0,
      departmentName: json['department_name']?.toString() ?? '',
    );
  }
}
