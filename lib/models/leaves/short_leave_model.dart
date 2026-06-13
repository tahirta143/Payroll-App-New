int _parseInt(dynamic val) {
  if (val == null) return 0;
  if (val is int) return val;
  if (val is double) return val.toInt();
  if (val is String) return int.tryParse(val) ?? 0;
  return 0;
}

bool _parseBool(dynamic val) {
  if (val == null) return false;
  if (val is bool) return val;
  if (val is int) return val == 1;
  if (val is String) return val.trim() == '1' || val.trim().toLowerCase() == 'true';
  return false;
}

class ShortLeaveModel {
  final int id;
  final int employeeId;
  final String? employeeName;
  final String leaveDate;
  final String fromTime;
  final String toTime;
  final int totalMinutes;
  final String leaveType;
  final String? reason;
  final bool isPaid;
  final String status; // 'pending' | 'approved' | 'rejected'

  ShortLeaveModel({
    required this.id,
    required this.employeeId,
    this.employeeName,
    required this.leaveDate,
    required this.fromTime,
    required this.toTime,
    required this.totalMinutes,
    required this.leaveType,
    this.reason,
    required this.isPaid,
    required this.status,
  });

  factory ShortLeaveModel.fromJson(Map<String, dynamic> json) {
    return ShortLeaveModel(
      id: _parseInt(json['id']),
      employeeId: _parseInt(json['employee_id'] ?? json['employee']?['id']),
      employeeName: json['employee_name']?.toString() ?? json['employee']?['name']?.toString(),
      leaveDate: json['leave_date']?.toString() ?? '',
      fromTime: json['from_time']?.toString() ?? '',
      toTime: json['to_time']?.toString() ?? '',
      totalMinutes: _parseInt(json['total_minutes']),
      leaveType: json['leave_type']?.toString() ?? '',
      reason: json['reason']?.toString(),
      isPaid: _parseBool(json['is_paid']),
      status: json['status']?.toString().toLowerCase() ?? 'pending',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'employee_id': employeeId,
      'leave_date': leaveDate,
      'from_time': fromTime,
      'to_time': toTime,
      'total_minutes': totalMinutes,
      'leave_type': leaveType,
      'reason': reason,
      'is_paid': isPaid,
      'status': status,
    };
  }
}
