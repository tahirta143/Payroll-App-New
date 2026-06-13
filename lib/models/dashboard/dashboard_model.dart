class KpiItem {
  final String key;
  final String label;
  final double value;
  final double change;

  KpiItem({
    required this.key,
    required this.label,
    required this.value,
    required this.change,
  });

  factory KpiItem.fromJson(Map<String, dynamic> json) {
    return KpiItem(
      key: json['key'] as String? ?? '',
      label: json['label'] as String? ?? '',
      value: (double.tryParse(json['value'].toString())) ?? 0.0,
      change: (double.tryParse(json['change'].toString())) ?? 0.0,
    );
  }
}

class TrendItem {
  final String label;
  final double present;
  final double absent;
  final double leaves;
  final double lateCount;

  TrendItem({
    required this.label,
    required this.present,
    required this.absent,
    required this.leaves,
    required this.lateCount,
  });

  factory TrendItem.fromJson(Map<String, dynamic> json) {
    return TrendItem(
      label: json['label'] as String? ?? '',
      present: (double.tryParse(json['present'].toString())) ?? 0.0,
      absent: (double.tryParse(json['absent'].toString())) ?? 0.0,
      leaves: (double.tryParse(json['leaves'].toString())) ?? 0.0,
      lateCount: (double.tryParse((json['late'] ?? json['late_count'] ?? 0).toString())) ?? 0.0,
    );
  }
}

class SourceItem {
  final String label;
  final double value;
  final double percent;

  SourceItem({
    required this.label,
    required this.value,
    required this.percent,
  });

  factory SourceItem.fromJson(Map<String, dynamic> json) {
    return SourceItem(
      label: json['label'] as String? ?? '',
      value: (double.tryParse(json['value'].toString())) ?? 0.0,
      percent: (double.tryParse(json['percent'].toString())) ?? 0.0,
    );
  }
}

class RecentAttendanceItem {
  final int id;
  final String date;
  final String? timeIn;
  final String? timeOut;
  final String employeeName;
  final String? empId;
  final String? departmentName;
  final String status;

  RecentAttendanceItem({
    required this.id,
    required this.date,
    this.timeIn,
    this.timeOut,
    required this.employeeName,
    this.empId,
    this.departmentName,
    required this.status,
  });

  factory RecentAttendanceItem.fromJson(Map<String, dynamic> json) {
    return RecentAttendanceItem(
      id: json['id'] as int? ?? 0,
      date: json['date'] as String? ?? '',
      timeIn: json['time_in'] as String?,
      timeOut: json['time_out'] as String?,
      employeeName: json['employee_name'] as String? ?? 'Employee',
      empId: json['emp_id'] as String?,
      departmentName: json['department_name'] as String?,
      status: json['status'] as String? ?? 'Logged',
    );
  }
}

class RecentEmployeeItem {
  final int id;
  final String? empId;
  final String name;
  final String? hiringDate;
  final String? image;

  RecentEmployeeItem({
    required this.id,
    this.empId,
    required this.name,
    this.hiringDate,
    this.image,
  });

  factory RecentEmployeeItem.fromJson(Map<String, dynamic> json) {
    return RecentEmployeeItem(
      id: json['id'] as int? ?? 0,
      empId: json['emp_id'] as String?,
      name: json['name'] as String? ?? '',
      hiringDate: json['hiring_date'] as String?,
      image: json['image'] as String?,
    );
  }
}

class RecentActivityItem {
  final String id;
  final String type;
  final String title;
  final String subtitle;

  RecentActivityItem({
    required this.id,
    required this.type,
    required this.title,
    required this.subtitle,
  });

  factory RecentActivityItem.fromJson(Map<String, dynamic> json) {
    return RecentActivityItem(
      id: json['id'].toString(),
      type: json['type'] as String? ?? 'Activity',
      title: json['title'] as String? ?? '',
      subtitle: json['subtitle'] as String? ?? '',
    );
  }
}

class AdminDashboardOverview {
  final List<KpiItem> kpis;
  final List<TrendItem> trend;
  final List<SourceItem> sources;
  final List<RecentAttendanceItem> attendance;
  final List<RecentEmployeeItem> recentEmployees;
  final List<RecentActivityItem> recentActivities;
  final int lateToday;

  AdminDashboardOverview({
    required this.kpis,
    required this.trend,
    required this.sources,
    required this.attendance,
    required this.recentEmployees,
    required this.recentActivities,
    required this.lateToday,
  });

  factory AdminDashboardOverview.fromJson(Map<String, dynamic> json) {
    return AdminDashboardOverview(
      kpis: (json['kpis'] as List? ?? [])
          .map((item) => KpiItem.fromJson(item as Map<String, dynamic>))
          .toList(),
      trend: (json['trend'] as List? ?? [])
          .map((item) => TrendItem.fromJson(item as Map<String, dynamic>))
          .toList(),
      sources: (json['sources'] as List? ?? [])
          .map((item) => SourceItem.fromJson(item as Map<String, dynamic>))
          .toList(),
      attendance: (json['attendance'] as List? ?? [])
          .map((item) => RecentAttendanceItem.fromJson(item as Map<String, dynamic>))
          .toList(),
      recentEmployees: (json['recentEmployees'] as List? ?? [])
          .map((item) => RecentEmployeeItem.fromJson(item as Map<String, dynamic>))
          .toList(),
      recentActivities: (json['recentActivities'] as List? ?? [])
          .map((item) => RecentActivityItem.fromJson(item as Map<String, dynamic>))
          .toList(),
      lateToday: json['lateToday'] as int? ?? 0,
    );
  }
}

class EmployeeDashboardSummary {
  final int employeeId;
  final String employeeName;
  final String month;
  final int presentCount;
  final int absentCount;
  final int leaveCount;
  final int shortLeaveCount;
  final int lateCount;
  final List<TrendItem> chartData;

  EmployeeDashboardSummary({
    required this.employeeId,
    required this.employeeName,
    required this.month,
    required this.presentCount,
    required this.absentCount,
    required this.leaveCount,
    required this.shortLeaveCount,
    required this.lateCount,
    required this.chartData,
  });

  factory EmployeeDashboardSummary.fromJson(Map<String, dynamic> json, List<dynamic> chartJson) {
    return EmployeeDashboardSummary(
      employeeId: int.tryParse(json['employee_id'].toString()) ?? 0,
      employeeName: json['employee_name'] as String? ?? 'Employee',
      month: json['month'] as String? ?? '',
      presentCount: json['present_count'] as int? ?? 0,
      absentCount: json['absent_count'] as int? ?? 0,
      leaveCount: json['leave_count'] as int? ?? 0,
      shortLeaveCount: json['short_leave_count'] as int? ?? 0,
      lateCount: json['late_count'] as int? ?? 0,
      chartData: chartJson
          .map((item) => TrendItem.fromJson(item as Map<String, dynamic>))
          .toList(),
    );
  }
}
