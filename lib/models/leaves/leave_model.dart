int _parseInt(dynamic val) {
  if (val == null) return 0;
  if (val is int) return val;
  if (val is double) return val.toInt();
  if (val is String) return int.tryParse(val) ?? 0;
  return 0;
}

int? _parseNullableInt(dynamic val) {
  if (val == null) return null;
  if (val is int) return val;
  if (val is double) return val.toInt();
  if (val is String) return int.tryParse(val);
  return null;
}

double _parseDouble(dynamic val) {
  if (val == null) return 0.0;
  if (val is double) return val;
  if (val is int) return val.toDouble();
  if (val is String) return double.tryParse(val) ?? 0.0;
  return 0.0;
}

class LeaveModel {
  final int id;
  final String? leaveId;
  final String? date;
  final String? code;
  final int? departmentId;
  final String? departmentName;
  final int employeeId;
  final String? employeeName;
  final String? designation;
  final int? leaveTypeId;
  final String leaveType;
  final String? fromDate;
  final String? toDate;
  final double days;
  final double? requestedDays;
  final String? reason;
  final String status; // 'pending' | 'approved' | 'rejected'
  final bool allowed;
  final String pay; // 'with_pay' | 'without_pay'
  final String mode; // 'expire' | 'no_expire'
  final String? leaveSource;
  final String? createdAt;

  LeaveModel({
    required this.id,
    this.leaveId,
    this.date,
    this.code,
    this.departmentId,
    this.departmentName,
    required this.employeeId,
    this.employeeName,
    this.designation,
    this.leaveTypeId,
    required this.leaveType,
    this.fromDate,
    this.toDate,
    required this.days,
    this.requestedDays,
    this.reason,
    required this.status,
    required this.allowed,
    required this.pay,
    required this.mode,
    this.leaveSource,
    this.createdAt,
  });

  factory LeaveModel.fromJson(Map<String, dynamic> json) {
    // Determine allowed from status or from the direct allowed field
    final rawStatus = json['status']?.toString().toLowerCase() ?? 'pending';
    final isAllowed = rawStatus == 'approved' || json['allowed'] == 1 || json['allowed'] == true;

    return LeaveModel(
      id: _parseInt(json['id']),
      leaveId: json['leave_id']?.toString(),
      date: json['date']?.toString(),
      code: json['code']?.toString(),
      departmentId: _parseNullableInt(json['department_id']),
      departmentName: json['department_name']?.toString(),
      employeeId: _parseInt(json['employee_id']),
      employeeName: json['employee_name']?.toString(),
      designation: json['designation']?.toString(),
      leaveTypeId: _parseNullableInt(json['leave_type_id']),
      leaveType: json['leave_type']?.toString() ?? '',
      fromDate: json['from_date']?.toString(),
      toDate: json['to_date']?.toString(),
      days: _parseDouble(json['days']),
      requestedDays: _parseDouble(json['requested_days'] ?? json['days']),
      reason: json['reason']?.toString(),
      status: rawStatus,
      allowed: isAllowed,
      pay: json['pay']?.toString() ?? 'with_pay',
      mode: json['mode']?.toString() ?? 'expire',
      leaveSource: json['leave_source']?.toString(),
      createdAt: json['created_at']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'leave_id': leaveId,
      'date': date,
      'code': code,
      'department_id': departmentId,
      'employee_id': employeeId,
      'designation': designation,
      'leave_type_id': leaveTypeId,
      'leave_type': leaveType,
      'from_date': fromDate,
      'to_date': toDate,
      'days': days,
      'requested_days': requestedDays ?? days,
      'reason': reason,
      'status': status,
      'allowed': allowed,
      'pay': pay,
      'mode': mode,
      'leave_source': leaveSource,
    };
  }
}

class LeaveTypeModel {
  final int id;
  final String name;
  final String code;

  LeaveTypeModel({required this.id, required this.name, required this.code});

  factory LeaveTypeModel.fromJson(Map<String, dynamic> json) {
    return LeaveTypeModel(
      id: json['id'] as int? ?? 0,
      name: json['name']?.toString() ?? '',
      code: json['code']?.toString() ?? '',
    );
  }

  String get displayText => code.isNotEmpty ? '$code - $name' : name;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LeaveTypeModel && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
