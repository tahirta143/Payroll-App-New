class MonthlySalarySheetRow {
  final String? unit;
  final String? employee;
  final String? designation;
  final String? joiningDate;
  final String? bank;
  final String? accountNumber;
  final double lateCount;
  final double leavesCount;
  final double daysCount;
  final double salary;
  final double total;

  MonthlySalarySheetRow({
    this.unit,
    this.employee,
    this.designation,
    this.joiningDate,
    this.bank,
    this.accountNumber,
    required this.lateCount,
    required this.leavesCount,
    required this.daysCount,
    required this.salary,
    required this.total,
  });

  factory MonthlySalarySheetRow.fromJson(Map<String, dynamic> json) {
    double parseDouble(dynamic val) {
      if (val == null) return 0.0;
      return double.tryParse(val.toString()) ?? 0.0;
    }

    return MonthlySalarySheetRow(
      unit: json['unit']?.toString(),
      employee: json['employee']?.toString(),
      designation: json['designation']?.toString(),
      joiningDate: json['joining_date']?.toString(),
      bank: json['bank']?.toString(),
      accountNumber: json['account_no']?.toString(),
      lateCount: parseDouble(json['late']),
      leavesCount: parseDouble(json['leaves']),
      daysCount: parseDouble(json['days']),
      salary: parseDouble(json['salary']),
      total: parseDouble(json['total']),
    );
  }
}

class MonthlySalarySheetTotals {
  final double salarySum;
  final double totalSum;

  MonthlySalarySheetTotals({
    required this.salarySum,
    required this.totalSum,
  });

  factory MonthlySalarySheetTotals.fromJson(Map<String, dynamic> json) {
    double parseDouble(dynamic val) {
      if (val == null) return 0.0;
      return double.tryParse(val.toString()) ?? 0.0;
    }
    return MonthlySalarySheetTotals(
      salarySum: parseDouble(json['salary_sum']),
      totalSum: parseDouble(json['total_sum']),
    );
  }
}

class MonthlySalarySheetResponse {
  final String month;
  final List<MonthlySalarySheetRow> rows;
  final MonthlySalarySheetTotals? totals;
  final dynamic range;

  MonthlySalarySheetResponse({
    required this.month,
    required this.rows,
    this.totals,
    this.range,
  });

  factory MonthlySalarySheetResponse.fromJson(Map<String, dynamic> json) {
    final rowsList = json['rows'] as List? ?? [];
    return MonthlySalarySheetResponse(
      month: json['month']?.toString() ?? '',
      rows: rowsList.map((item) => MonthlySalarySheetRow.fromJson(item)).toList(),
      totals: json['totals'] != null ? MonthlySalarySheetTotals.fromJson(json['totals']) : null,
      range: json['range'],
    );
  }
}

// --- SALARY SLIP MODELS ---
class SalarySlipEmployeeInfo {
  final int id;
  final String? empId;
  final String name;
  final String? machineCode;
  final String? bankName;
  final String? accountNumber;
  final String? departmentName;
  final String? designationName;
  final String? dutyShiftName;
  final String? shiftStart;
  final String? shiftEnd;
  final String? joiningDate;
  final bool allowOvertime;
  final bool allowLateComing;
  final bool allowDeductions;

  SalarySlipEmployeeInfo({
    required this.id,
    this.empId,
    required this.name,
    this.machineCode,
    this.bankName,
    this.accountNumber,
    this.departmentName,
    this.designationName,
    this.dutyShiftName,
    this.shiftStart,
    this.shiftEnd,
    this.joiningDate,
    this.allowOvertime = true,
    this.allowLateComing = true,
    this.allowDeductions = true,
  });

  factory SalarySlipEmployeeInfo.fromJson(Map<String, dynamic> json) {
    bool parseBool(dynamic val, bool fallback) {
      if (val == null) return fallback;
      if (val is bool) return val;
      if (val == 1 || val == '1' || val == 'true') return true;
      if (val == 0 || val == '0' || val == 'false') return false;
      return fallback;
    }

    return SalarySlipEmployeeInfo(
      id: json['id'] is int ? json['id'] : (int.tryParse(json['id']?.toString() ?? '0') ?? 0),
      empId: json['emp_id']?.toString(),
      name: json['name']?.toString() ?? '',
      machineCode: json['machine_code']?.toString(),
      bankName: json['bank_name']?.toString(),
      accountNumber: json['account_number']?.toString(),
      departmentName: json['department_name']?.toString(),
      designationName: json['designation_name']?.toString(),
      dutyShiftName: json['duty_shift_name']?.toString(),
      shiftStart: json['shift_start']?.toString(),
      shiftEnd: json['shift_end']?.toString(),
      joiningDate: json['joining_date']?.toString(),
      allowOvertime: parseBool(json['allow_overtime'], true),
      allowLateComing: parseBool(json['allow_late_coming'], true),
      allowDeductions: parseBool(json['allow_deductions'], true),
    );
  }
}

class DeductionBreakdownRow {
  final dynamic chargeable;
  final double deductionUnits;
  final double rate;
  final double amount;
  final String note;

  DeductionBreakdownRow({
    required this.chargeable,
    required this.deductionUnits,
    required this.rate,
    required this.amount,
    required this.note,
  });

  factory DeductionBreakdownRow.fromJson(Map<String, dynamic> json) {
    double parseDouble(dynamic val) {
      if (val == null) return 0.0;
      return double.tryParse(val.toString()) ?? 0.0;
    }

    return DeductionBreakdownRow(
      chargeable: json['chargeable'] ?? '-',
      deductionUnits: parseDouble(json['deductionUnits']),
      rate: parseDouble(json['rate']),
      amount: parseDouble(json['amount']),
      note: json['note']?.toString() ?? '',
    );
  }
}

class DeductionBreakdown {
  final DeductionBreakdownRow? lateGrace;
  final DeductionBreakdownRow? latePartial;
  final DeductionBreakdownRow? halfDay;
  final DeductionBreakdownRow? shortLeave;
  final DeductionBreakdownRow? absent;

  DeductionBreakdown({
    this.lateGrace,
    this.latePartial,
    this.halfDay,
    this.shortLeave,
    this.absent,
  });

  factory DeductionBreakdown.fromJson(Map<String, dynamic> json) {
    return DeductionBreakdown(
      lateGrace: json['late_grace'] != null ? DeductionBreakdownRow.fromJson(json['late_grace']) : null,
      latePartial: json['late_partial'] != null ? DeductionBreakdownRow.fromJson(json['late_partial']) : null,
      halfDay: json['half_day'] != null ? DeductionBreakdownRow.fromJson(json['half_day']) : null,
      shortLeave: json['short_leave'] != null ? DeductionBreakdownRow.fromJson(json['short_leave']) : null,
      absent: json['absent'] != null ? DeductionBreakdownRow.fromJson(json['absent']) : null,
    );
  }
}

class SalarySlipSettingsUsed {
  final String? maxLateTime;
  final dynamic halfDayDeductionPercent;
  final dynamic fullDayDeductionPercent;
  final double overtimeRate;

  SalarySlipSettingsUsed({
    this.maxLateTime,
    this.halfDayDeductionPercent,
    this.fullDayDeductionPercent,
    this.overtimeRate = 0.0,
  });

  factory SalarySlipSettingsUsed.fromJson(Map<String, dynamic> json) {
    double parseDouble(dynamic val) {
      if (val == null) return 0.0;
      return double.tryParse(val.toString()) ?? 0.0;
    }

    return SalarySlipSettingsUsed(
      maxLateTime: json['max_late_time']?.toString(),
      halfDayDeductionPercent: json['half_day_deduction_percent'],
      fullDayDeductionPercent: json['full_day_deduction_percent'],
      overtimeRate: parseDouble(json['overtime_rate']),
    );
  }
}

class SalarySlipPayrollCalculation {
  final double netPayable;
  final double halfDayDeductionTotal;
  final double fullDayDeductionTotal;
  final double advanceAmountTotal;
  final double overtimeAmountTotal;
  final double attendanceDeductionTotal;
  final double overtimePerHourSalary;
  final double overtimeMultiplier;
  final double overtimeEffectiveRate;
  final int overtimeMinutesTotal;
  final double perDaySalary;
  final double fullDayRate;
  final double halfDayRate;
  final double thirdDayRate;
  final DeductionBreakdown? deductionBreakdown;

  SalarySlipPayrollCalculation({
    required this.netPayable,
    required this.halfDayDeductionTotal,
    required this.fullDayDeductionTotal,
    required this.advanceAmountTotal,
    required this.overtimeAmountTotal,
    this.attendanceDeductionTotal = 0.0,
    this.overtimePerHourSalary = 0.0,
    this.overtimeMultiplier = 1.0,
    this.overtimeEffectiveRate = 0.0,
    this.overtimeMinutesTotal = 0,
    this.perDaySalary = 0.0,
    this.fullDayRate = 0.0,
    this.halfDayRate = 0.0,
    this.thirdDayRate = 0.0,
    this.deductionBreakdown,
  });

  factory SalarySlipPayrollCalculation.fromJson(Map<String, dynamic> json) {
    double parseDouble(dynamic val) {
      if (val == null) return 0.0;
      return double.tryParse(val.toString()) ?? 0.0;
    }
    int parseInt(dynamic val) {
      if (val == null) return 0;
      return int.tryParse(val.toString()) ?? 0;
    }

    return SalarySlipPayrollCalculation(
      netPayable: parseDouble(json['net_payable']),
      halfDayDeductionTotal: parseDouble(json['half_day_deduction_total']),
      fullDayDeductionTotal: parseDouble(json['full_day_deduction_total']),
      advanceAmountTotal: parseDouble(json['advance_amount_total']),
      overtimeAmountTotal: parseDouble(json['overtime_amount_total']),
      attendanceDeductionTotal: parseDouble(json['attendance_deduction_total']),
      overtimePerHourSalary: parseDouble(json['overtime_per_hour_salary']),
      overtimeMultiplier: parseDouble(json['overtime_multiplier']) == 0 ? 1.0 : parseDouble(json['overtime_multiplier']),
      overtimeEffectiveRate: parseDouble(json['overtime_effective_rate']),
      overtimeMinutesTotal: parseInt(json['overtime_minutes_total']),
      perDaySalary: parseDouble(json['per_day_salary']),
      fullDayRate: parseDouble(json['full_day_rate']),
      halfDayRate: parseDouble(json['half_day_rate']),
      thirdDayRate: parseDouble(json['third_day_rate']),
      deductionBreakdown: json['deduction_breakdown'] != null ? DeductionBreakdown.fromJson(json['deduction_breakdown']) : null,
    );
  }
}

class SalarySlipAttendanceSummary {
  final int monthDays;
  final int presentDays;
  final int leaveDays;
  final int holidayDays;
  final int absentDays;
  final int lateDays;

  SalarySlipAttendanceSummary({
    required this.monthDays,
    required this.presentDays,
    required this.leaveDays,
    required this.holidayDays,
    required this.absentDays,
    required this.lateDays,
  });

  factory SalarySlipAttendanceSummary.fromJson(Map<String, dynamic> json) {
    int parseInt(dynamic val) {
      if (val == null) return 0;
      return int.tryParse(val.toString()) ?? 0;
    }
    return SalarySlipAttendanceSummary(
      monthDays: parseInt(json['month_days']),
      presentDays: parseInt(json['present_days']),
      leaveDays: parseInt(json['leave_days']),
      holidayDays: parseInt(json['holiday_days']),
      absentDays: parseInt(json['absent_days']),
      lateDays: parseInt(json['late_days']),
    );
  }
}

class SalarySlipStructure {
  final double basicSalary;
  final double medicalAllowance;
  final double mobileAllowance;
  final double conveyanceAllowance;
  final double houseAllowance;
  final double utilityAllowance;
  final double miscellaneousAllowance;
  final double grossSalary;
  final double netSalary;
  final double incomeTax;
  final bool noTax;
  final bool salaryByCash;
  final bool salaryByCheque;
  final bool salaryByTransfer;
  final String? accountNumber;

  SalarySlipStructure({
    required this.basicSalary,
    required this.medicalAllowance,
    required this.mobileAllowance,
    required this.conveyanceAllowance,
    required this.houseAllowance,
    required this.utilityAllowance,
    required this.miscellaneousAllowance,
    required this.grossSalary,
    required this.netSalary,
    required this.incomeTax,
    required this.noTax,
    required this.salaryByCash,
    required this.salaryByCheque,
    required this.salaryByTransfer,
    this.accountNumber,
  });

  factory SalarySlipStructure.fromJson(Map<String, dynamic> json) {
    double parseDouble(dynamic val) {
      if (val == null) return 0.0;
      return double.tryParse(val.toString()) ?? 0.0;
    }
    return SalarySlipStructure(
      basicSalary: parseDouble(json['basic_salary']),
      medicalAllowance: parseDouble(json['medical_allowance']),
      mobileAllowance: parseDouble(json['mobile_allowance']),
      conveyanceAllowance: parseDouble(json['conveyance_allowance']),
      houseAllowance: parseDouble(json['house_allowance']),
      utilityAllowance: parseDouble(json['utility_allowance']),
      miscellaneousAllowance: parseDouble(json['miscellaneous_allowance']),
      grossSalary: parseDouble(json['gross_salary']),
      netSalary: parseDouble(json['net_salary']),
      incomeTax: parseDouble(json['income_tax']),
      noTax: json['no_tax'] == 1 || json['no_tax'] == true,
      salaryByCash: json['salary_by_cash'] == 1 || json['salary_by_cash'] == true,
      salaryByCheque: json['salary_by_cheque'] == 1 || json['salary_by_cheque'] == true,
      salaryByTransfer: json['salary_by_transfer'] == 1 || json['salary_by_transfer'] == true,
      accountNumber: json['account_number']?.toString(),
    );
  }
}

class SalarySlipDayDetail {
  final String date;
  final String? weekday;
  final String status;
  final String? timeIn;
  final String? timeOut;
  final int lateMinutes;
  final String? lateLabel;
  final String? durationLabel;
  final String? remarks;

  SalarySlipDayDetail({
    required this.date,
    this.weekday,
    required this.status,
    this.timeIn,
    this.timeOut,
    this.lateMinutes = 0,
    this.lateLabel,
    this.durationLabel,
    this.remarks,
  });

  factory SalarySlipDayDetail.fromJson(Map<String, dynamic> json) {
    int parseInt(dynamic val) {
      if (val == null) return 0;
      return int.tryParse(val.toString()) ?? 0;
    }

    String? remarks;
    if (json['on_duty'] != null) {
      remarks = json['on_duty']['reason'] ?? json['on_duty']['location'];
    } else if (json['leave'] != null) {
      remarks = json['leave']['reason'] ?? json['leave']['nature_of_leave'];
    } else if (json['holiday'] != null) {
      remarks = json['holiday']['reason'];
    } else if (json['absent'] != null) {
      remarks = json['absent']['reason'];
    } else {
      remarks = json['duration_label'];
    }

    return SalarySlipDayDetail(
      date: json['date']?.toString() ?? '',
      weekday: json['weekday']?.toString(),
      status: json['status']?.toString() ?? '',
      timeIn: json['time_in']?.toString(),
      timeOut: json['time_out']?.toString(),
      lateMinutes: parseInt(json['late_minutes']),
      lateLabel: json['late_label']?.toString(),
      durationLabel: json['duration_label']?.toString(),
      remarks: remarks,
    );
  }
}

class SalarySlipResponse {
  final String month;
  final SalarySlipEmployeeInfo employee;
  final SalarySlipStructure salaryStructure;
  final SalarySlipPayrollCalculation payrollCalculation;
  final SalarySlipAttendanceSummary attendanceSummary;
  final SalarySlipSettingsUsed? settingsUsed;
  final List<SalarySlipDayDetail> days;
  final dynamic range;

  SalarySlipResponse({
    required this.month,
    required this.employee,
    required this.salaryStructure,
    required this.payrollCalculation,
    required this.attendanceSummary,
    this.settingsUsed,
    this.days = const [],
    this.range,
  });

  factory SalarySlipResponse.fromJson(Map<String, dynamic> json) {
    final daysList = json['days'] as List? ?? [];
    return SalarySlipResponse(
      month: json['month']?.toString() ?? '',
      employee: SalarySlipEmployeeInfo.fromJson(json['employee'] ?? {}),
      salaryStructure: SalarySlipStructure.fromJson(json['salary_structure'] ?? {}),
      payrollCalculation: SalarySlipPayrollCalculation.fromJson(json['payroll_calculation'] ?? {}),
      attendanceSummary: SalarySlipAttendanceSummary.fromJson(json['attendance_summary'] ?? {}),
      settingsUsed: json['settings_used'] != null ? SalarySlipSettingsUsed.fromJson(json['settings_used']) : null,
      days: daysList.map((d) => SalarySlipDayDetail.fromJson(d)).toList(),
      range: json['range'],
    );
  }
}
