import '../attendance/attendance_model.dart';

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
  });

  factory SalarySlipEmployeeInfo.fromJson(Map<String, dynamic> json) {
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
    );
  }
}

class SalarySlipPayrollCalculation {
  final double netPayable;
  final double halfDayDeductionTotal;
  final double fullDayDeductionTotal;
  final double advanceAmountTotal;
  final double overtimeAmountTotal;

  SalarySlipPayrollCalculation({
    required this.netPayable,
    required this.halfDayDeductionTotal,
    required this.fullDayDeductionTotal,
    required this.advanceAmountTotal,
    required this.overtimeAmountTotal,
  });

  factory SalarySlipPayrollCalculation.fromJson(Map<String, dynamic> json) {
    double parseDouble(dynamic val) {
      if (val == null) return 0.0;
      return double.tryParse(val.toString()) ?? 0.0;
    }
    return SalarySlipPayrollCalculation(
      netPayable: parseDouble(json['net_payable']),
      halfDayDeductionTotal: parseDouble(json['half_day_deduction_total']),
      fullDayDeductionTotal: parseDouble(json['full_day_deduction_total']),
      advanceAmountTotal: parseDouble(json['advance_amount_total']),
      overtimeAmountTotal: parseDouble(json['overtime_amount_total']),
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

class SalarySlipResponse {
  final String month;
  final SalarySlipEmployeeInfo employee;
  final SalarySlipStructure salaryStructure;
  final SalarySlipPayrollCalculation payrollCalculation;
  final SalarySlipAttendanceSummary attendanceSummary;
  final dynamic range;

  SalarySlipResponse({
    required this.month,
    required this.employee,
    required this.salaryStructure,
    required this.payrollCalculation,
    required this.attendanceSummary,
    this.range,
  });

  factory SalarySlipResponse.fromJson(Map<String, dynamic> json) {
    return SalarySlipResponse(
      month: json['month']?.toString() ?? '',
      employee: SalarySlipEmployeeInfo.fromJson(json['employee'] ?? {}),
      salaryStructure: SalarySlipStructure.fromJson(json['salary_structure'] ?? {}),
      payrollCalculation: SalarySlipPayrollCalculation.fromJson(json['payroll_calculation'] ?? {}),
      attendanceSummary: SalarySlipAttendanceSummary.fromJson(json['attendance_summary'] ?? {}),
      range: json['range'],
    );
  }
}
