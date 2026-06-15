import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

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

class AttendanceModel {
  final int id;
  final String date;
  final int employeeId;
  final String? employeeName;
  final int departmentId;
  final String? departmentName;
  final int? dutyShiftId;
  final String? dutyShiftName;
  final String? timeIn;
  final String? timeOut;
  final String? machineCode;
  final String? createdAt;
  final String? dutyShiftStart;
  final String? dutyShiftEnd;
  final String? employeeImage;

  AttendanceModel({
    required this.id,
    required this.date,
    required this.employeeId,
    this.employeeName,
    required this.departmentId,
    this.departmentName,
    this.dutyShiftId,
    this.dutyShiftName,
    this.timeIn,
    this.timeOut,
    this.machineCode,
    this.createdAt,
    this.dutyShiftStart,
    this.dutyShiftEnd,
    this.employeeImage,
  });

  factory AttendanceModel.fromJson(Map<String, dynamic> json) {
    return AttendanceModel(
      id: _parseInt(json['id']),
      date: json['date']?.toString() ?? '',
      employeeId: _parseInt(json['employee_id']),
      employeeName: json['employee_name']?.toString(),
      departmentId: _parseInt(json['department_id']),
      departmentName: json['department_name']?.toString(),
      dutyShiftId: _parseNullableInt(json['duty_shift_id']),
      dutyShiftName: json['duty_shift_name']?.toString(),
      timeIn: json['time_in']?.toString(),
      timeOut: json['time_out']?.toString(),
      machineCode: json['machine_code']?.toString(),
      createdAt: json['created_at']?.toString(),
      dutyShiftStart: json['duty_shift_start']?.toString() ?? '09:00',
      dutyShiftEnd: json['duty_shift_end']?.toString() ?? '18:00',
      employeeImage: json['employee_image']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'date': date,
      'employee_id': employeeId,
      'employee_name': employeeName,
      'department_id': departmentId,
      'department_name': departmentName,
      'duty_shift_id': dutyShiftId,
      'duty_shift_name': dutyShiftName,
      'time_in': timeIn,
      'time_out': timeOut,
      'machine_code': machineCode,
      'created_at': createdAt,
      'duty_shift_start': dutyShiftStart,
      'duty_shift_end': dutyShiftEnd,
      'employee_image': employeeImage,
    };
  }

  // ✅ New Logic implementation
  bool get isPresent => timeIn != null && timeIn!.isNotEmpty && timeIn != '--:--';

  DateTime _parseDateTime(String timeStr) {
    try {
      final dt = DateTime.parse(date);
      final parts = timeStr.split(':');
      return DateTime(dt.year, dt.month, dt.day, int.parse(parts[0]), int.parse(parts[1]));
    } catch (_) {
      return DateTime.now();
    }
  }

  int get lateMinutes {
    if (!isPresent) return 0;

    try {
      // Logic from user: 9:15 rule
      // If 9:15 or before -> not late
      // If after 9:15 -> late = timeIn - 9:00
      
      final dt = DateTime.parse(date);
      final officeStart = DateTime(dt.year, dt.month, dt.day, 9, 0);
      final graceDeadline = DateTime(dt.year, dt.month, dt.day, 9, 15);
      final arrival = _parseDateTime(timeIn!);

      if (!arrival.isAfter(graceDeadline)) return 0;

      return arrival.difference(officeStart).inMinutes;
    } catch (_) {
      return 0;
    }
  }

  bool get isLate => lateMinutes > 0;

  int get overtimeMinutes {
    if (timeOut == null || timeOut!.isEmpty || timeOut == '--:--') return 0;
    try {
      final departure = _parseDateTime(timeOut!);
      final shiftEnd = _parseDateTime(dutyShiftEnd ?? '18:00');
      
      if (departure.isAfter(shiftEnd)) {
        return departure.difference(shiftEnd).inMinutes;
      }
    } catch (_) {}
    return 0;
  }
}

class DepartmentModel {
  final int id;
  final String name;

  DepartmentModel({required this.id, required this.name});

  factory DepartmentModel.fromJson(Map<String, dynamic> json) {
    return DepartmentModel(
      id: _parseInt(json['id']),
      name: json['name']?.toString() ?? '',
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DepartmentModel && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}

class DutyShiftModel {
  final int id;
  final String name;
  final String? startFrom;
  final String? endAt;

  DutyShiftModel({
    required this.id,
    required this.name,
    this.startFrom,
    this.endAt,
  });

  factory DutyShiftModel.fromJson(Map<String, dynamic> json) {
    return DutyShiftModel(
      id: _parseInt(json['id']),
      name: json['name']?.toString() ?? '',
      startFrom: json['start_from']?.toString(),
      endAt: json['end_at']?.toString(),
    );
  }

  String get displayText {
    final start = startFrom != null ? (startFrom!.length >= 5 ? startFrom!.substring(0, 5) : startFrom!) : '';
    final end = endAt != null ? (endAt!.length >= 5 ? endAt!.substring(0, 5) : endAt!) : '';
    return '$name ($start–$end)';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DutyShiftModel && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}

class EmployeeModel {
  final int id;
  final String? empId;
  final String name;
  final String? machineCode;
  final String? bankName;
  final String? bankAccountNumber;
  final DutyShiftModel? dutyShift;
  final String? designationName;
  final String? image;

  EmployeeModel({
    required this.id,
    this.empId,
    required this.name,
    this.machineCode,
    this.bankName,
    this.bankAccountNumber,
    this.dutyShift,
    this.designationName,
    this.image,
  });

  factory EmployeeModel.fromJson(Map<String, dynamic> json) {
    DutyShiftModel? shift;
    if (json['duty_shift'] != null && json['duty_shift'] is Map<String, dynamic>) {
      shift = DutyShiftModel.fromJson(json['duty_shift'] as Map<String, dynamic>);
    }

    String? bName = json['bank_name']?.toString();
    if (json['bank'] != null && json['bank'] is Map) {
      bName = json['bank']['name']?.toString() ?? json['bank']['bank_name']?.toString();
    }

    String? desigName;
    if (json['designation'] != null) {
      if (json['designation'] is Map) {
        desigName = json['designation']['name']?.toString();
      } else {
        desigName = json['designation']?.toString();
      }
    }

    return EmployeeModel(
      id: _parseInt(json['id']),
      empId: json['emp_id']?.toString(),
      name: json['name']?.toString() ?? '',
      machineCode: json['machine_code']?.toString(),
      bankName: bName,
      bankAccountNumber: json['bank_account_number']?.toString(),
      dutyShift: shift,
      designationName: desigName,
      image: json['image']?.toString(),
    );
  }

  String get listLabel {
    final bankPart = bankName != null && bankName!.isNotEmpty ? ' | $bankName' : '';
    return '${empId ?? ''} - $name$bankPart';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is EmployeeModel && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
