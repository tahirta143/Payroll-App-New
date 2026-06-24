class MonthlyAttendanceDay {
  final String date;
  final int day;
  final bool isWeekend;

  MonthlyAttendanceDay({
    required this.date,
    required this.day,
    required this.isWeekend,
  });

  factory MonthlyAttendanceDay.fromJson(Map<String, dynamic> json) {
    return MonthlyAttendanceDay(
      date: json['date']?.toString() ?? '',
      day: json['day'] is int ? json['day'] : int.tryParse(json['day']?.toString() ?? '0') ?? 0,
      isWeekend: json['isWeekend'] == true,
    );
  }
}

class MonthlyAttendanceStatus {
  final String code;
  final String reason;

  MonthlyAttendanceStatus({
    required this.code,
    required this.reason,
  });

  factory MonthlyAttendanceStatus.fromJson(Map<String, dynamic> json) {
    return MonthlyAttendanceStatus(
      code: json['code']?.toString() ?? '',
      reason: json['reason']?.toString() ?? '',
    );
  }
}

class MonthlyAttendanceEmployee {
  final int id;
  final String empId;
  final String name;
  final String departmentName;
  final List<MonthlyAttendanceStatus> statuses;

  MonthlyAttendanceEmployee({
    required this.id,
    required this.empId,
    required this.name,
    required this.departmentName,
    required this.statuses,
  });

  factory MonthlyAttendanceEmployee.fromJson(Map<String, dynamic> json) {
    var statusList = json['statuses'] as List? ?? [];
    return MonthlyAttendanceEmployee(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      empId: json['emp_id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      departmentName: json['department_name']?.toString() ?? 'Others',
      statuses: statusList.map((s) => MonthlyAttendanceStatus.fromJson(s)).toList(),
    );
  }
}

class MonthlyAttendanceSheetResponse {
  final List<MonthlyAttendanceDay> days;
  final List<MonthlyAttendanceEmployee> employees;

  MonthlyAttendanceSheetResponse({
    required this.days,
    required this.employees,
  });

  factory MonthlyAttendanceSheetResponse.fromJson(Map<String, dynamic> json) {
    var daysList = json['days'] as List? ?? [];
    var empList = json['employees'] as List? ?? [];
    return MonthlyAttendanceSheetResponse(
      days: daysList.map((d) => MonthlyAttendanceDay.fromJson(d)).toList(),
      employees: empList.map((e) => MonthlyAttendanceEmployee.fromJson(e)).toList(),
    );
  }
}
